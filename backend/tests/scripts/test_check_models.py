"""Unit tests for scripts/check_models.py: the responses.json mapping rules
that make `make data-check` fail. No Supabase stack needed."""

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts"))

import check_models  # noqa: E402
import dataset  # noqa: E402
import screens  # noqa: E402


def described_type(name, properties=None):
    return {"title": name, "properties": properties or {}, "required": []}


TYPES = {
    "Envelope": described_type("Envelope"),
    "Tabs": described_type("Tabs", {"tabs": {"type": "array", "items": {"$ref": "Tab.schema.json"}}}),
    "Tab": described_type("Tab"),
}
RESPONSES = {"get_entry": "Envelope", "get_tabs": "Tabs"}


class Mapping(unittest.TestCase):
    def test_a_complete_mapping_has_no_problems(self):
        self.assertEqual(check_models.mapping_problems({"get_entry", "get_tabs"}, RESPONSES, {}, TYPES), [])

    def test_a_recorded_response_with_no_type_is_named(self):
        found = check_models.mapping_problems({"get_entry", "get_tabs", "whoami"}, RESPONSES, {}, TYPES)
        self.assertEqual(found, ["mock response whoami: no type in contract/responses.json"])

    def test_a_mapping_with_no_recorded_response_is_named(self):
        found = check_models.mapping_problems({"get_entry"}, RESPONSES, {}, TYPES)
        self.assertEqual(found, ["contract/responses.json get_tabs: no recorded response has this name"])

    def test_a_mapping_to_a_missing_type_is_named(self):
        responses = {**RESPONSES, "whoami": "Profile"}
        found = check_models.mapping_problems({"get_entry", "get_tabs", "whoami"}, responses, {}, TYPES)
        self.assertEqual(found, ["contract/responses.json whoami: type Profile has no file in contract/types"])

    def test_an_unused_type_is_named(self):
        types = {**TYPES, "Unused": described_type("Unused")}
        found = check_models.mapping_problems({"get_entry", "get_tabs"}, RESPONSES, {}, types)
        self.assertEqual(found, [f"contract/types/Unused{screens.SUFFIX}: used by no description and no mapping in responses.json"])

    def test_a_type_with_an_example_is_used(self):
        types = {**TYPES, "Row": described_type("Row")}
        self.assertEqual(check_models.mapping_problems({"get_entry", "get_tabs"}, RESPONSES, {}, types, {"Row"}), [])

    def test_a_type_used_only_by_a_screen_is_used(self):
        types = {**TYPES, "Row": described_type("Row")}
        screen = described_type("ScreenData", {"row": {"$ref": "../types/Row.schema.json"}})
        self.assertEqual(check_models.mapping_problems({"get_entry", "get_tabs"}, RESPONSES, {"s": screen}, types), [])


class CommittedMapping(unittest.TestCase):
    def test_every_mock_response_has_a_type_and_matches_it(self):
        described, types = screens.load_all()
        responses = screens.load_responses()
        paths = sorted(dataset.MOCK_RESPONSES_PATH.rglob("*.json"))
        examples = {p.stem for p in screens.EXAMPLES_PATH.glob("*.json")}
        self.assertEqual(check_models.mapping_problems({dataset.response_name(p.stem) for p in paths}, responses, described, types, examples), [])
        self.assertEqual(check_models.example_problems(types), [])
        for path in paths:
            with self.subTest(path=path.name):
                kind = responses[dataset.response_name(path.stem)]
                value = json.loads(path.read_text())
                self.assertEqual(screens.problems(types[kind], value, path.name, types), [])


if __name__ == "__main__":
    unittest.main()
