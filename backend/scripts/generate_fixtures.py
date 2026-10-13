"""Regenerates /contract/fixtures from the real backend. Run with
`make fixtures`, which resets local Supabase from migrations and the generated
seed first. Never edit fixtures by hand.

Layout:
  get_entry.json, get_screen.<key>.json            signed out
  <persona>/get_screen.<key>.json                  signed in as an active persona
A screen a caller may not see (any 4xx) gets no file for that caller.
"""

import json
import shutil
from pathlib import Path

import dataset
from local_supabase import LocalSupabase, RequestFailed

LOCALE = "en"


def write(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n")
    print(f"  {path.relative_to(dataset.REPO)}")


def screen_keys(supabase: LocalSupabase) -> list[str]:
    rows = supabase.request("GET", "/rest/v1/screens?select=key&order=key", service=True)
    return [row["key"] for row in rows]


def capture(path: Path, call) -> None:
    try:
        write(path, call())
    except RequestFailed as error:
        if 400 <= error.status < 500:
            return
        raise


def clear(root: Path) -> None:
    if root.exists():
        for child in root.iterdir():
            if child.is_dir():
                shutil.rmtree(child)
            elif child.suffix == ".json":
                child.unlink()


def main() -> None:
    data = dataset.load()
    supabase = LocalSupabase()
    keys = screen_keys(supabase)
    root = dataset.FIXTURES_PATH
    clear(root)

    print("Signed out:")
    capture(root / "get_entry.json", lambda: supabase.rpc("get_entry", {"p_locale": LOCALE}))
    for key in keys:
        capture(
            root / f"get_screen.{key}.json",
            lambda key=key: supabase.rpc("get_screen", {"p_key": key, "p_locale": LOCALE, "p_params": {}}),
        )

    for persona in dataset.active_personas(data):
        print(f"{persona['id']}:")
        token = supabase.sign_in(persona["email"], data["local_password"])
        for key in keys:
            capture(
                root / persona["id"] / f"get_screen.{key}.json",
                lambda key=key: supabase.rpc(
                    "get_screen", {"p_key": key, "p_locale": LOCALE, "p_params": {}}, token=token
                ),
            )


if __name__ == "__main__":
    main()
