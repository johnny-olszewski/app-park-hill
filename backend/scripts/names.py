"""Loads and validates /contract/names.json, the one hand-written list of
backend function names and screen keys clients use. Shared by the generator
and the check."""

import json
import re

from dataset import REPO

NAMES_PATH = REPO / "contract" / "names.json"
GENERATED_PATH = REPO / "contract" / "generated"

GROUPS = ("rpc_functions", "edge_functions", "screen_keys")
FUNCTION_NAME = re.compile(r"^[a-z][a-z0-9_]*$")
SCREEN_KEY = re.compile(r"^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$")


class NamesError(Exception):
    pass


def load() -> dict:
    data = json.loads(NAMES_PATH.read_text())
    validate(data)
    return data


def validate(data: dict) -> None:
    if set(data) != set(GROUPS):
        raise NamesError(f"expected exactly the groups {', '.join(GROUPS)}")
    for group in GROUPS:
        names = data[group]
        if not isinstance(names, list) or not all(isinstance(n, str) for n in names):
            raise NamesError(f"{group} must be a list of strings")
        if len(set(names)) != len(names):
            raise NamesError(f"{group} has duplicates")
        pattern = SCREEN_KEY if group == "screen_keys" else FUNCTION_NAME
        for name in names:
            if not pattern.match(name):
                raise NamesError(f"{group}: {name!r} is not a valid name")
            if name.endswith(".mock"):
                raise NamesError(f"{group}: {name!r} is mock-only and stays in client mock sources")
    for group in GROUPS:
        identifiers = [identifier(n) for n in data[group]]
        if len(set(identifiers)) != len(identifiers):
            raise NamesError(f"{group}: two names give the same identifier")


def identifier(name: str) -> str:
    """Lower camel case: `get_entry` -> `getEntry`, `auth.sign_in` -> `authSignIn`."""
    first, *rest = re.split(r"[._]", name)
    return first + "".join(part.capitalize() for part in rest)
