"""Unit tests for mock responses of screens with params: their file names and
the navigate actions the generator follows. No Supabase stack needed."""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts"))

import dataset  # noqa: E402
import generate_mock_responses  # noqa: E402


class Names(unittest.TestCase):
    def test_params_are_appended_sorted_by_name(self):
        self.assertEqual(dataset.mock_response_name("get_screen.home.root", {}), "get_screen.home.root")
        self.assertEqual(
            dataset.mock_response_name("get_screen.community.group", {"z": 1, "group_id": "g"}),
            "get_screen.community.group@group_id=g&z=1",
        )

    def test_responses_json_maps_the_name_without_params(self):
        self.assertEqual(dataset.response_name("get_screen.community.group@group_id=g"), "get_screen.community.group")
        self.assertEqual(dataset.response_name("get_tabs"), "get_tabs")


class Targets(unittest.TestCase):
    def test_navigate_actions_with_params_are_found_anywhere(self):
        go = {"type": "navigate", "screen_key": "community.group", "params": {"group_id": "g"}, "presentation": "push"}
        plain = {"type": "navigate", "screen_key": "home.root", "params": {}, "presentation": "push"}
        response = {"data": {"my_groups": {"rows": [{"action": go}, {"action": plain}]}}}
        self.assertEqual(generate_mock_responses.navigate_targets(response), [("community.group", {"group_id": "g"})])


if __name__ == "__main__":
    unittest.main()
