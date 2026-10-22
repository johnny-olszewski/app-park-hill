"""Checks the recorded responses in /contract/fixtures against the screen
descriptions in /contract/screens. Fails when a backend screen key has no
description, a description has no screen key in names.json, or a recorded
screen's data does not match its description. Run by `make data-check` after
`make fixtures`.

A screen envelope is any object with a string `key` and an object `data`,
wherever it appears: a whole response (`get_entry`, `get_screen`) or embedded
in one (each tab's `screen` in `get_tabs`)."""

import json
import sys

import dataset
import names
import screens


def envelopes(value, where: str):
    if isinstance(value, dict):
        if isinstance(value.get("key"), str) and isinstance(value.get("data"), dict):
            yield where, value
            return
        for name, child in value.items():
            yield from envelopes(child, f"{where}.{name}")
    elif isinstance(value, list):
        for i, child in enumerate(value):
            yield from envelopes(child, f"{where}[{i}]")


def main() -> int:
    try:
        listed = set(names.load()["screen_keys"])
        described = screens.load()
    except (names.NamesError, screens.ScreensError) as error:
        print(error)
        return 1

    problems: list[str] = []
    for key in sorted(listed - set(described)):
        problems.append(f"screen key {key}: no description in contract/screens")
    for key in sorted(set(described) - listed):
        problems.append(f"contract/screens/{key}{screens.SUFFIX}: not a screen key in names.json")

    checked = 0
    for path in sorted(dataset.FIXTURES_PATH.rglob("*.json")):
        where = str(path.relative_to(dataset.FIXTURES_PATH))
        for location, envelope in envelopes(json.loads(path.read_text()), where):
            key = envelope["key"]
            if key not in described:
                problems.append(f"{location}: screen key {key} has no description in contract/screens")
                continue
            problems += screens.problems(described[key], envelope["data"], f"{location} {key} data")
            checked += 1

    for problem in problems:
        print(problem)
    if problems:
        return 1
    print(f"Screen data matches its description in {checked} recorded screens: {', '.join(sorted(described))}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
