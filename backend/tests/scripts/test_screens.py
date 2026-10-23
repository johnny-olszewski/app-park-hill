"""Unit tests for scripts/screens.py: the description subset and the value
check that makes `make data-check` fail. No Supabase stack needed."""

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts"))

import screens  # noqa: E402

SCHEMA = {
    "$schema": screens.DRAFT,
    "title": "ExampleData",
    "description": "Example.",
    "type": "object",
    "properties": {
        "title": {"type": "string"},
        "count": {"type": "integer"},
        "ratio": {"type": "number"},
        "on": {"type": "boolean"},
        "labels": {"type": "array", "items": {"type": "string"}},
        "anything": {"type": "array", "items": {}},
        "note": {"type": "string"},
    },
    "required": ["title", "count", "ratio", "on", "labels", "anything"],
    "additionalProperties": False,
}
VALID = {"title": "T", "count": 1, "ratio": 0.5, "on": True, "labels": ["a"], "anything": [1, "x", {"k": None}]}


def with_(**changes):
    value = dict(VALID)
    value.update(changes)
    return value


class ValueCheck(unittest.TestCase):
    def test_a_matching_value_has_no_problems(self):
        self.assertEqual(screens.problems(SCHEMA, VALID, "x"), [])
        self.assertEqual(screens.problems(SCHEMA, with_(note="optional"), "x"), [])

    def test_a_missing_required_field_is_named(self):
        value = dict(VALID)
        del value["title"]
        self.assertEqual(screens.problems(SCHEMA, value, "x"), ["x: missing required field 'title'"])

    def test_an_undescribed_field_is_named(self):
        self.assertEqual(screens.problems(SCHEMA, with_(extra=1), "x"), ["x: field 'extra' is not in the description"])

    def test_wrong_types_are_named(self):
        cases = {"title": 1, "count": "1", "ratio": "0.5", "on": 1, "labels": "a"}
        for field, wrong in cases.items():
            with self.subTest(field=field):
                found = screens.problems(SCHEMA, with_(**{field: wrong}), "x")
                self.assertEqual(len(found), 1)
                self.assertTrue(found[0].startswith(f"x.{field}: expected"), found)

    def test_booleans_are_not_numbers(self):
        self.assertEqual(screens.problems(SCHEMA, with_(count=True), "x"), ["x.count: expected integer"])
        self.assertEqual(screens.problems(SCHEMA, with_(ratio=False), "x"), ["x.ratio: expected number"])

    def test_a_wrong_array_item_is_named_by_index(self):
        self.assertEqual(screens.problems(SCHEMA, with_(labels=["a", 2]), "x"), ["x.labels[1]: expected string"])

    def test_items_without_a_type_accept_any_json(self):
        self.assertEqual(screens.problems(SCHEMA, with_(anything=[[], {}, None, 3.2]), "x"), [])

    def test_a_non_object_screen_is_refused(self):
        self.assertEqual(screens.problems(SCHEMA, [], "x"), ["x: expected an object"])


class DescriptionSubset(unittest.TestCase):
    def assert_refused(self, schema, message):
        with self.assertRaises(screens.ScreensError) as raised:
            screens.validate_screen(schema, "x")
        self.assertIn(message, str(raised.exception))

    def test_the_example_is_accepted(self):
        screens.validate_screen(SCHEMA, "x")

    def test_unsupported_keywords_are_refused(self):
        self.assert_refused({**SCHEMA, "oneOf": []}, "unsupported keywords")
        properties = {**SCHEMA["properties"], "title": {"type": "string", "enum": ["a"]}}
        self.assert_refused({**SCHEMA, "properties": properties}, "unsupported keywords")

    def test_screens_must_be_closed_objects(self):
        self.assert_refused({**SCHEMA, "additionalProperties": True}, "additionalProperties")

    def test_required_fields_must_be_described(self):
        self.assert_refused({**SCHEMA, "required": ["missing"]}, "required field 'missing'")

    def test_field_names_are_snake_case(self):
        self.assert_refused({**SCHEMA, "properties": {"Title": {"type": "string"}}, "required": []}, "snake_case")

    def test_arrays_need_items(self):
        self.assert_refused({**SCHEMA, "properties": {"a": {"type": "array"}}, "required": []}, "needs items")


class CommittedDescriptions(unittest.TestCase):
    def test_every_description_loads_and_matches_its_signed_out_fixture(self):
        described = screens.load()
        fixtures = screens.REPO / "contract" / "fixtures"
        envelope = json.loads((fixtures / "get_entry.json").read_text())
        self.assertEqual(screens.problems(described[envelope["key"]], envelope["data"], "get_entry"), [])


if __name__ == "__main__":
    unittest.main()
