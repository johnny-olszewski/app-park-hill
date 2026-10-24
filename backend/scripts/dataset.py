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


class DatasetError(Exception):
    pass


def persona_uuid(persona_id: str) -> str:
    """Stable account id for a persona, so generated data never churns."""
    return str(uuid.uuid5(PERSONA_NAMESPACE, persona_id))


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


def active_personas(data: dict) -> list[dict]:
    return [p for p in data["personas"] if p["state"] == "active"]
