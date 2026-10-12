"""Checks that personas are consistent everywhere they appear: the dataset is
valid, local Supabase holds exactly those accounts with the right state and
profile, and the fixtures have a folder for each active persona and no other.
Run by `make data-check` after a reset."""

import sys
from datetime import datetime, timezone

import dataset
from local_supabase import LocalSupabase


def is_banned(user: dict) -> bool:
    banned_until = user.get("banned_until")
    if not banned_until:
        return False
    return datetime.fromisoformat(banned_until.replace("Z", "+00:00")) > datetime.now(timezone.utc)


def main() -> int:
    problems: list[str] = []
    try:
        data = dataset.load()
    except dataset.DatasetError as error:
        print(f"dataset.json: {error}")
        return 1

    supabase = LocalSupabase()
    users = supabase.request("GET", "/auth/v1/admin/users?per_page=1000", service=True)["users"]
    users_by_email = {u["email"]: u for u in users}
    profiles = {
        p["id"]: p["display_name"]
        for p in supabase.request("GET", "/rest/v1/profiles?select=id,display_name", service=True)
    }

    expected_emails = {p["email"] for p in data["personas"]}
    for email in sorted(set(users_by_email) - expected_emails):
        if email.endswith("@parkhill.test"):
            problems.append(f"account {email} is not in dataset.json")

    for persona in data["personas"]:
        user = users_by_email.get(persona["email"])
        if user is None:
            problems.append(f"{persona['id']}: no account for {persona['email']}")
            continue
        if user["id"] != dataset.persona_uuid(persona["id"]):
            problems.append(f"{persona['id']}: account id {user['id']} is not the persona's stable id")
        if is_banned(user) != (persona["state"] == "banned"):
            problems.append(f"{persona['id']}: banned state does not match '{persona['state']}'")
        if profiles.get(user["id"]) != persona["display_name"]:
            problems.append(f"{persona['id']}: profile display name {profiles.get(user['id'])!r} != {persona['display_name']!r}")

    root = dataset.FIXTURES_PATH
    fixture_dirs = {d.name for d in root.iterdir() if d.is_dir()} if root.exists() else set()
    active = {p["id"] for p in dataset.active_personas(data)}
    for missing in sorted(active - fixture_dirs):
        problems.append(f"fixtures: no folder for active persona {missing}")
    for extra in sorted(fixture_dirs - active):
        problems.append(f"fixtures: folder {extra} is not an active persona")

    for problem in problems:
        print(problem)
    if problems:
        return 1
    print(f"Personas consistent: {', '.join(p['id'] for p in data['personas'])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
