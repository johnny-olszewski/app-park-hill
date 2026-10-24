"""Checks the recorded responses in /contract/mock_responses against the
contract descriptions in /contract/screens and /contract/types. Run by
`make data-check` after `make mock-responses`. Fails when:

- a backend screen key has no description, or a description has no screen key
  in names.json;
- a recorded response has no type in responses.json, a mapping names no
  recorded response or no type, or a type is used by no description and no
  mapping;
- a recorded response does not match its type, or a recorded screen's data
  does not match its screen's description;
- an example in /contract/types/examples names no type or does not match it.

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


def mapping_problems(
    recorded: set[str], responses: dict[str, str], described: dict, types: dict, examples: set[str] = frozenset()
) -> list[str]:
    """What is wrong with responses.json, given the recorded response names. A
    type with an example counts as used."""
    found = [f"mock response {name}: no type in contract/responses.json" for name in sorted(recorded - set(responses))]
    found += [f"contract/responses.json {name}: no recorded response has this name" for name in sorted(set(responses) - recorded)]
    found += [
        f"contract/responses.json {name}: type {kind} has no file in contract/types"
        for name, kind in sorted(responses.items())
        if kind not in types
    ]
    used = set(responses.values()).union(examples, *(screens.refs(s) for s in [*described.values(), *types.values()]))
    found += [
        f"contract/types/{name}{screens.SUFFIX}: used by no description and no mapping in responses.json"
        for name in sorted(set(types) - used)
    ]
    return found


def example_problems(types: dict) -> list[str]:
    """Each example, named by its type, checked against that type."""
    found = []
    for path in sorted(screens.EXAMPLES_PATH.glob("*.json")):
        where = f"contract/types/examples/{path.name}"
        if path.stem not in types:
            found.append(f"{where}: no type {path.stem} in contract/types")
            continue
        found += screens.problems(types[path.stem], json.loads(path.read_text()), where, types)
    return found


def main() -> int:
    try:
        listed = set(names.load()["screen_keys"])
        described, types = screens.load_all()
        responses = screens.load_responses()
    except (names.NamesError, screens.ScreensError) as error:
        print(error)
        return 1

    problems: list[str] = []
    for key in sorted(listed - set(described)):
        problems.append(f"screen key {key}: no description in contract/screens")
    for key in sorted(set(described) - listed):
        problems.append(f"contract/screens/{key}{screens.SUFFIX}: not a screen key in names.json")

    paths = sorted(dataset.MOCK_RESPONSES_PATH.rglob("*.json"))
    examples = {path.stem for path in screens.EXAMPLES_PATH.glob("*.json")}
    problems += mapping_problems({dataset.response_name(path.stem) for path in paths}, responses, described, types, examples)
    problems += example_problems(types)

    checked = 0
    for path in paths:
        where = str(path.relative_to(dataset.MOCK_RESPONSES_PATH))
        value = json.loads(path.read_text())
        if responses.get(dataset.response_name(path.stem)) in types:
            kind = responses[dataset.response_name(path.stem)]
            problems += screens.problems(types[kind], value, f"{where} {kind}", types)
        for location, envelope in envelopes(value, where):
            key = envelope["key"]
            if key not in described:
                problems.append(f"{location}: screen key {key} has no description in contract/screens")
                continue
            problems += screens.problems(described[key], envelope["data"], f"{location} {key} data", types)
            checked += 1

    for problem in problems:
        print(problem)
    if problems:
        return 1
    print(
        f"Every one of {len(paths)} recorded responses matches its type, the data in {checked} recorded screens"
        f" matches its description, and {len(examples)} type examples match their types"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
