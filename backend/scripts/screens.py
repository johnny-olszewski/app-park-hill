"""Loads /contract/screens, one JSON Schema description per backend screen
key, and checks values against them. Shared by the model generator and the
mock response check.

Only a subset of JSON Schema is supported, and anything else is refused, so a
description never says more than the generator and the check understand:

  screen       $schema, title (the model's type name), description,
               type "object", properties, required, additionalProperties false
  property     description, and either type ("string", "integer", "number",
               "boolean", or "array" with items), or nothing else: any JSON
  items        a property schema without description

Add a keyword here, in the generator and in the check when a screen first
needs one (for example $ref for shared types, or enum).
"""

import json
import re
from pathlib import Path

from dataset import REPO

SCREENS_PATH = REPO / "contract" / "screens"
SUFFIX = ".schema.json"
DRAFT = "https://json-schema.org/draft/2020-12/schema"

SCREEN_KEYWORDS = {"$schema", "title", "description", "type", "properties", "required", "additionalProperties"}
PROPERTY_KEYWORDS = {"description", "type", "items"}
SCALARS = {"string", "integer", "number", "boolean"}
TYPE_NAME = re.compile(r"^[A-Z][A-Za-z0-9]*$")
FIELD_NAME = re.compile(r"^[a-z][a-z0-9_]*$")


class ScreensError(Exception):
    pass


def key_of(path: Path) -> str:
    return path.name.removesuffix(SUFFIX)


def load() -> dict[str, dict]:
    """Every description, by screen key, validated against the subset."""
    screens = {}
    for path in sorted(SCREENS_PATH.glob(f"*{SUFFIX}")):
        schema = json.loads(path.read_text())
        validate_screen(schema, path.name)
        screens[key_of(path)] = schema
    titles = [s["title"] for s in screens.values()]
    if len(set(titles)) != len(titles):
        raise ScreensError("two screens use the same title")
    return screens


def validate_screen(schema: dict, where: str) -> None:
    unknown = set(schema) - SCREEN_KEYWORDS
    if unknown:
        raise ScreensError(f"{where}: unsupported keywords {sorted(unknown)}")
    if schema.get("$schema") != DRAFT:
        raise ScreensError(f"{where}: $schema must be {DRAFT}")
    if not TYPE_NAME.match(schema.get("title", "")):
        raise ScreensError(f"{where}: title must be the model's type name, for example SignInScreenData")
    if schema.get("type") != "object" or schema.get("additionalProperties") is not False:
        raise ScreensError(f'{where}: a screen is "type": "object" with "additionalProperties": false')
    properties = schema.get("properties")
    required = schema.get("required")
    if not isinstance(properties, dict) or not isinstance(required, list):
        raise ScreensError(f"{where}: properties (an object) and required (a list) are both needed, even when empty")
    for name in required:
        if name not in properties:
            raise ScreensError(f"{where}: required field {name!r} is not in properties")
    for name, field in properties.items():
        if not FIELD_NAME.match(name):
            raise ScreensError(f"{where}: field {name!r} must be snake_case")
        validate_property(field, f"{where} {name}", allow_description=True)


def validate_property(field: dict, where: str, allow_description: bool) -> None:
    allowed = PROPERTY_KEYWORDS if allow_description else PROPERTY_KEYWORDS - {"description"}
    unknown = set(field) - allowed
    if unknown:
        raise ScreensError(f"{where}: unsupported keywords {sorted(unknown)}")
    kind = field.get("type")
    if kind is None:
        if "items" in field:
            raise ScreensError(f'{where}: items needs "type": "array"')
    elif kind == "array":
        if not isinstance(field.get("items"), dict):
            raise ScreensError(f"{where}: an array needs items")
        validate_property(field["items"], f"{where} items", allow_description=False)
    elif kind in SCALARS:
        if "items" in field:
            raise ScreensError(f"{where}: items is only for arrays")
    else:
        raise ScreensError(f"{where}: unsupported type {kind!r}")


def problems(schema: dict, value, where: str) -> list[str]:
    """What is wrong with a value against a screen or property schema; empty when it matches."""
    kind = schema.get("type")
    if kind is None:
        return []
    if kind == "object":
        if not isinstance(value, dict):
            return [f"{where}: expected an object"]
        found = [f"{where}: missing required field {name!r}" for name in schema["required"] if name not in value]
        found += [f"{where}: field {name!r} is not in the description" for name in value if name not in schema["properties"]]
        for name, field in schema["properties"].items():
            if name in value:
                found += problems(field, value[name], f"{where}.{name}")
        return found
    if kind == "array":
        if not isinstance(value, list):
            return [f"{where}: expected an array"]
        return sum((problems(schema["items"], item, f"{where}[{i}]") for i, item in enumerate(value)), [])
    expected = {
        "string": lambda v: isinstance(v, str),
        "integer": lambda v: isinstance(v, int) and not isinstance(v, bool),
        "number": lambda v: isinstance(v, (int, float)) and not isinstance(v, bool),
        "boolean": lambda v: isinstance(v, bool),
    }[kind]
    return [] if expected(value) else [f"{where}: expected {kind}"]
