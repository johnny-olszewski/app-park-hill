"""Unit tests for scripts/screens.py: the description subset and the value
check that makes `make data-check` fail. No Supabase stack needed."""

import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

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
TYPE = {
    "$schema": screens.DRAFT,
    "title": "Item",
    "description": "A shared type.",
    "type": "object",
    "properties": {"id": {"type": "string"}},
    "required": ["id"],
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

    def test_an_object_without_properties_accepts_any_object(self):
        anything = {"type": "object"}
        self.assertEqual(screens.problems(anything, {"a": [1], "b": None}, "x"), [])
        self.assertEqual(screens.problems(anything, [], "x"), ["x: expected an object"])

    def test_a_ref_is_checked_against_its_type(self):
        types = {"Item": TYPE}
        field = {"$ref": "../types/Item.schema.json"}
        self.assertEqual(screens.problems(field, {"id": "a"}, "x", types), [])
        self.assertEqual(screens.problems(field, {}, "x", types), ["x: missing required field 'id'"])
        listed = {"type": "array", "items": field}
        self.assertEqual(screens.problems(listed, [{"id": 1}], "x", types), ["x[0].id: expected string"])


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

    def test_an_object_field_is_any_object_and_takes_no_properties(self):
        screens.validate_screen({**SCHEMA, "properties": {"a": {"type": "object"}}, "required": []}, "x")
        field = {"type": "object", "properties": {}}
        self.assert_refused({**SCHEMA, "properties": {"a": field}, "required": []}, "unsupported keywords")

    def test_refs_use_the_path_for_where_they_are(self):
        def with_ref(ref):
            return {**SCHEMA, "properties": {"a": {"$ref": ref, "description": "A."}}, "required": []}

        screens.validate_screen(with_ref("../types/Item.schema.json"), "x")
        screens.validate_screen(with_ref("Item.schema.json"), "x", screens.TYPE_REF)
        self.assert_refused(with_ref("Item.schema.json"), "../types/<TypeName>.schema.json")
        with self.assertRaises(screens.ScreensError):
            screens.validate_screen(with_ref("../types/Item.schema.json"), "x", screens.TYPE_REF)
        self.assert_refused(with_ref("#/$defs/Item"), "$ref must be")

    def test_a_ref_stands_alone(self):
        field = {"$ref": "../types/Item.schema.json", "type": "object"}
        self.assert_refused({**SCHEMA, "properties": {"a": field}, "required": []}, "stands alone")

    def test_refs_are_found_in_fields_and_array_items(self):
        properties = {
            "a": {"$ref": "../types/A.schema.json"},
            "b": {"type": "array", "items": {"$ref": "../types/B.schema.json"}},
            "c": {"type": "string"},
        }
        self.assertEqual(screens.refs({**SCHEMA, "properties": properties}), {"A", "B"})


class Loading(unittest.TestCase):
    """load_all against descriptions written to a temporary contract folder."""

    def load(self, screen_files: dict, type_files: dict):
        with tempfile.TemporaryDirectory() as root:
            for folder, files in (("screens", screen_files), ("types", type_files)):
                (Path(root) / folder).mkdir()
                for name, schema in files.items():
                    (Path(root) / folder / f"{name}{screens.SUFFIX}").write_text(json.dumps(schema))
            with mock.patch.object(screens, "SCREENS_PATH", Path(root) / "screens"), \
                    mock.patch.object(screens, "TYPES_PATH", Path(root) / "types"):
                return screens.load_all()

    def screen_using(self, ref):
        return {**SCHEMA, "properties": {"item": {"$ref": ref}}, "required": ["item"]}

    def test_screens_and_types_load_by_key_and_name(self):
        described, types = self.load({"example": self.screen_using("../types/Item.schema.json")}, {"Item": TYPE})
        self.assertEqual(list(described), ["example"])
        self.assertEqual(list(types), ["Item"])

    def test_a_ref_to_a_missing_type_is_named(self):
        with self.assertRaises(screens.ScreensError) as raised:
            self.load({"example": self.screen_using("../types/Missing.schema.json")}, {})
        self.assertIn("screens/example.schema.json: $ref to Missing", str(raised.exception))

    def test_a_type_is_titled_by_its_file_name(self):
        with self.assertRaises(screens.ScreensError) as raised:
            self.load({}, {"Other": TYPE})
        self.assertIn("title must be the file name, Other", str(raised.exception))

    def test_a_title_used_twice_is_named(self):
        with self.assertRaises(screens.ScreensError) as raised:
            self.load({"example": {**SCHEMA, "title": "Item"}}, {"Item": TYPE})
        self.assertIn("title Item", str(raised.exception))


class CommittedDescriptions(unittest.TestCase):
    def test_every_description_loads_and_matches_its_signed_out_mock_response(self):
        described = screens.load()
        mock_responses = screens.REPO / "contract" / "mock_responses"
        envelope = json.loads((mock_responses / "get_entry.json").read_text())
        self.assertEqual(screens.problems(described[envelope["key"]], envelope["data"], "get_entry"), [])


if __name__ == "__main__":
    unittest.main()
