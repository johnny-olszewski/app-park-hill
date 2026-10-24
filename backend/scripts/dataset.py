"""Loads and validates /contract/seed/dataset.json, the single source of
personas and seed data. Shared by the generators and the persona check."""

import json
import re
import uuid
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
DATASET_PATH = REPO / "contract" / "seed" / "dataset.json"
SEED_PATH = REPO / "backend" / "supabase" / "seed.sql"
MOCK_RESPONSES_PATH = REPO / "contract" / "mock_responses"

STATES = {"active", "banned"}
PERSONA_ID = re.compile(r"^[a-z][a-z0-9_]*$")
PERSONA_NAMESPACE = uuid.UUID("6f1c8a52-3b0e-4f5e-9d3a-2a7c1e0b9d41")
GROUP_NAMESPACE = uuid.UUID("0d3e6b7a-58c4-4b8e-a1f2-7c9e4d2b6a10")
MEETING_TIME = re.compile(r"^([01][0-9]|2[0-3]):[0-5][0-9]$")


class DatasetError(Exception):
    pass


def persona_uuid(persona_id: str) -> str:
    """Stable account id for a persona, so generated data never churns."""
    return str(uuid.uuid5(PERSONA_NAMESPACE, persona_id))


def group_uuid(group_id: str) -> str:
    """Stable id for a seed group, so generated data never churns."""
    return str(uuid.uuid5(GROUP_NAMESPACE, group_id))


def load() -> dict:
    data = json.loads(DATASET_PATH.read_text())
    validate(data)
    return data


def validate(data: dict) -> None:
    if not isinstance(data.get("local_password"), str) or len(data["local_password"]) < 6:
        raise DatasetError("local_password must be a string of at least 6 characters")
    personas = data.get("personas")
    if not isinstance(personas, list) or not personas:
        raise DatasetError("personas must be a non-empty list")
    ids, emails = set(), set()
    for persona in personas:
        pid = persona.get("id")
        if not isinstance(pid, str) or not PERSONA_ID.match(pid):
            raise DatasetError(f"invalid persona id: {pid!r}")
        if pid in ids:
            raise DatasetError(f"duplicate persona id: {pid}")
        ids.add(pid)
        email = persona.get("email", "")
        if not email.endswith("@parkhill.test"):
            raise DatasetError(f"{pid}: email must end with @parkhill.test (local only)")
        if email in emails:
            raise DatasetError(f"duplicate email: {email}")
        emails.add(email)
        for field in ("display_name", "description"):
            if not isinstance(persona.get(field), str) or not persona[field]:
                raise DatasetError(f"{pid}: {field} is required")
        if persona.get("state") not in STATES:
            raise DatasetError(f"{pid}: state must be one of {sorted(STATES)}")
        roles = persona.get("roles", [])
        if not isinstance(roles, list) or not all(isinstance(r, str) and PERSONA_ID.match(r) for r in roles):
            raise DatasetError(f"{pid}: roles must be a list of role keys")
    validate_groups(data.get("groups", []), ids)


def validate_groups(groups, persona_ids: set[str]) -> None:
    if not isinstance(groups, list):
        raise DatasetError("groups must be a list")
    ids = set()
    for group in groups:
        gid = group.get("id")
        if not isinstance(gid, str) or not PERSONA_ID.match(gid):
            raise DatasetError(f"invalid group id: {gid!r}")
        if gid in ids:
            raise DatasetError(f"duplicate group id: {gid}")
        ids.add(gid)
        for field in ("type", "name"):
            if not isinstance(group.get(field), str) or not group[field]:
                raise DatasetError(f"{gid}: {field} is required")
        for field in ("description", "location"):
            if not isinstance(group.get(field, ""), str):
                raise DatasetError(f"{gid}: {field} must be a string")
        day = group.get("meeting_day")
        if day is not None and (not isinstance(day, int) or not 1 <= day <= 7):
            raise DatasetError(f"{gid}: meeting_day must be 1 (Monday) to 7 (Sunday)")
        time = group.get("meeting_time")
        if time is not None and (not isinstance(time, str) or not MEETING_TIME.match(time)):
            raise DatasetError(f"{gid}: meeting_time must be HH:MM")
        members, leaders = group.get("members", []), group.get("leaders", [])
        for field, people in (("members", members), ("leaders", leaders)):
            if not isinstance(people, list) or not all(p in persona_ids for p in people):
                raise DatasetError(f"{gid}: {field} must list persona ids")
        if not set(leaders) <= set(members):
            raise DatasetError(f"{gid}: every leader must also be a member")


def active_personas(data: dict) -> list[dict]:
    return [p for p in data["personas"] if p["state"] == "active"]
