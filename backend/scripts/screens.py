"""Loads the contract descriptions: /contract/screens, one JSON Schema
description per backend screen key, and /contract/types, one per shared type
(a response, or a part of one used in several places). Checks values against
them. Shared by the model generator and the mock response check.

Only a subset of JSON Schema is supported, and anything else is refused, so a
description never says more than the generator and the check understand:

  screen, type $schema, title (the model's type name), description,
               type "object", properties, required, additionalProperties false
  property     description, and one of: type ("string", "integer", "number",
               "boolean", "object" with nothing else: any JSON object, or
               "array" with items); $ref to a shared type; or nothing else:
               any JSON
  items        a property schema without description

A $ref names a file in /contract/types: `../types/<TypeName>.schema.json` from
a screen, `<TypeName>.schema.json` from another type. A type's file name is its
title.

Add a keyword here, in the generator and in the check when a screen first
needs one (for example enum).
"""

import json
import re
from pathlib import Path

from dataset import REPO

SCREENS_PATH = REPO / "contract" / "screens"
TYPES_PATH = REPO / "contract" / "types"
SUFFIX = ".schema.json"
DRAFT = "https://json-schema.org/draft/2020-12/schema"

SCREEN_KEYWORDS = {"$schema", "title", "description", "type", "properties", "required", "additionalProperties"}
PROPERTY_KEYWORDS = {"description", "type", "items", "$ref"}
SCALARS = {"string", "integer", "number", "boolean"}
TYPE_NAME = re.compile(r"^[A-Z][A-Za-z0-9]*$")
FIELD_NAME = re.compile(r"^[a-z][a-z0-9_]*$")
SCREEN_REF = re.compile(r"^\.\./types/([A-Z][A-Za-z0-9]*)\.schema\.json$")
TYPE_REF = re.compile(r"^([A-Z][A-Za-z0-9]*)\.schema\.json$")


class ScreensError(Exception):
    pass


def key_of(path: Path) -> str:
    return path.name.removesuffix(SUFFIX)


def load() -> dict[str, dict]:
    """Every screen description, by screen key, validated against the subset."""
    return load_all()[0]


def load_types() -> dict[str, dict]:
    """Every shared type, by type name, validated against the subset."""
    return load_all()[1]


def load_all() -> tuple[dict[str, dict], dict[str, dict]]:
    """Screens by key and types by name. Fails on a title used twice (the
    generated files share a folder) and on a $ref to a type that does not exist."""
    screens = _load(SCREENS_PATH, SCREEN_REF)
    types = _load(TYPES_PATH, TYPE_REF)
    for name, schema in types.items():
        if schema["title"] != name:
            raise ScreensError(f"types/{name}{SUFFIX}: title must be the file name, {name}")
    titles = [s["title"] for s in screens.values()] + list(types)
    duplicates = sorted({t for t in titles if titles.count(t) > 1})
    if duplicates:
        raise ScreensError(f"two descriptions use the title {', '.join(duplicates)}")
    for folder, described in (("screens", screens), ("types", types)):
        for key, schema in described.items():
            for name in refs(schema):
                if name not in types:
                    raise ScreensError(f"{folder}/{key}{SUFFIX}: $ref to {name}, which has no file in contract/types")
    return screens, types


def _load(folder: Path, ref_pattern: re.Pattern) -> dict[str, dict]:
    found = {}
    for path in sorted(folder.glob(f"*{SUFFIX}")):
        schema = json.loads(path.read_text())
        validate_screen(schema, f"{folder.name}/{path.name}", ref_pattern)
        found[key_of(path)] = schema
    return found


def ref_name(ref: str) -> str:
    """The type a validated $ref names, from a screen or from another type."""
    match = SCREEN_REF.match(ref) or TYPE_REF.match(ref)
    return match.group(1)


def refs(schema: dict) -> set[str]:
    """Every type name a screen or type refers to, directly or in array items."""
    found = set()
    for field in schema["properties"].values():
        while field.get("type") == "array":
            field = field["items"]
        if "$ref" in field:
            found.add(ref_name(field["$ref"]))
    return found


def validate_screen(schema: dict, where: str, ref_pattern: re.Pattern = SCREEN_REF) -> None:
    unknown = set(schema) - SCREEN_KEYWORDS
    if unknown:
        raise ScreensError(f"{where}: unsupported keywords {sorted(unknown)}")
    if schema.get("$schema") != DRAFT:
        raise ScreensError(f"{where}: $schema must be {DRAFT}")
    if not TYPE_NAME.match(schema.get("title", "")):
        raise ScreensError(f"{where}: title must be the model's type name, for example SignInScreenData")
    if schema.get("type") != "object" or schema.get("additionalProperties") is not False:
        raise ScreensError(f'{where}: a screen or type is "type": "object" with "additionalProperties": false')
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
        validate_property(field, f"{where} {name}", allow_description=True, ref_pattern=ref_pattern)


def validate_property(field: dict, where: str, allow_description: bool, ref_pattern: re.Pattern = SCREEN_REF) -> None:
    allowed = PROPERTY_KEYWORDS if allow_description else PROPERTY_KEYWORDS - {"description"}
    unknown = set(field) - allowed
    if unknown:
        raise ScreensError(f"{where}: unsupported keywords {sorted(unknown)}")
    kind = field.get("type")
    if "$ref" in field:
        if kind is not None or "items" in field:
            raise ScreensError(f"{where}: $ref stands alone, with at most a description")
        if not isinstance(field["$ref"], str) or not ref_pattern.match(field["$ref"]):
            expected = "../types/<TypeName>.schema.json" if ref_pattern is SCREEN_REF else "<TypeName>.schema.json"
            raise ScreensError(f"{where}: $ref must be {expected}")
    elif kind is None:
        if "items" in field:
            raise ScreensError(f'{where}: items needs "type": "array"')
    elif kind == "array":
        if not isinstance(field.get("items"), dict):
            raise ScreensError(f"{where}: an array needs items")
        validate_property(field["items"], f"{where} items", allow_description=False, ref_pattern=ref_pattern)
    elif kind in SCALARS or kind == "object":
        if "items" in field:
            raise ScreensError(f"{where}: items is only for arrays")
    else:
        raise ScreensError(f"{where}: unsupported type {kind!r}")


def problems(schema: dict, value, where: str, types: dict[str, dict] | None = None) -> list[str]:
    """What is wrong with a value against a screen, type or property schema;
    empty when it matches. `types` resolves $ref."""
    if "$ref" in schema:
        return problems((types or {})[ref_name(schema["$ref"])], value, where, types)
    kind = schema.get("type")
    if kind is None:
        return []
    if kind == "object":
        if not isinstance(value, dict):
            return [f"{where}: expected an object"]
        if "properties" not in schema:
            return []
        found = [f"{where}: missing required field {name!r}" for name in schema["required"] if name not in value]
        found += [f"{where}: field {name!r} is not in the description" for name in value if name not in schema["properties"]]
        for name, field in schema["properties"].items():
            if name in value:
                found += problems(field, value[name], f"{where}.{name}", types)
        return found
    if kind == "array":
        if not isinstance(value, list):
            return [f"{where}: expected an array"]
        return sum((problems(schema["items"], item, f"{where}[{i}]", types) for i, item in enumerate(value)), [])
    expected = {
        "string": lambda v: isinstance(v, str),
        "integer": lambda v: isinstance(v, int) and not isinstance(v, bool),
        "number": lambda v: isinstance(v, (int, float)) and not isinstance(v, bool),
        "boolean": lambda v: isinstance(v, bool),
    }[kind]
    return [] if expected(value) else [f"{where}: expected {kind}"]
