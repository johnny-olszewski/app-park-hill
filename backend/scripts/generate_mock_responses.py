"""Regenerates /contract/mock_responses from the real backend. Run with
`make mock-responses`, which resets local Supabase from migrations and the generated
seed first. Never edit mock responses by hand.

Layout:
  get_entry.json, get_screen.<key>.json            signed out
  <persona>/get_screen.<key>.json                  signed in as an active persona
  <persona>/whoami.json                            whoami() as that persona
  <persona>/get_tabs.json                          get_tabs() as that persona
  sign_in.ok.json, sign_in.error.json              the sign_in Edge Function
  sign_in.error.<code>.json                        each other sign_in refusal
A screen a caller may not see (any 4xx) gets no file for that caller.
Session tokens in sign_in.ok.json are placeholders, so it never churns.
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


def write_sign_in_mock_responses(supabase: LocalSupabase, data: dict) -> None:
    attendee = next(p for p in dataset.active_personas(data) if p["id"] == "attendee")
    headers = {"X-Forwarded-For": "mock-responses"}

    def call(password: str):
        body = json.dumps({"email": attendee["email"], "password": password, "locale": LOCALE}).encode()
        return supabase.call_function("sign_in", body, headers)

    status, error = call("not-the-password")
    if status != 401:
        raise SystemExit(f"sign_in error mock response: expected 401, got {status}: {error}")
    write(dataset.MOCK_RESPONSES_PATH / "sign_in.error.json", error)

    status, ok = call(data["local_password"])
    if status != 200:
        raise SystemExit(f"sign_in ok mock response: expected 200, got {status}: {ok}")
    ok["session"].update(access_token="<access_token>", refresh_token="<refresh_token>", expires_at=0)
    write(dataset.MOCK_RESPONSES_PATH / "sign_in.ok.json", ok)

    write_refusal_mock_responses(supabase, data)


def write_refusal_mock_responses(supabase: LocalSupabase, data: dict) -> None:
    """Every other sign_in refusal, for the mock menu's results. Each trigger
    uses its own client address, and the attempt limit is reached with an email
    that has no account, so no persona is left locked."""

    def refusal(code: str, body: dict, address: str) -> dict:
        status, error = supabase.call_function("sign_in", json.dumps(body).encode(), {"X-Forwarded-For": address})
        if error.get("code") != code:
            raise SystemExit(f"sign_in {code} mock response: got {status}: {error}")
        return error

    def write_refusal(error: dict) -> None:
        write(dataset.MOCK_RESPONSES_PATH / f"sign_in.error.{error['code']}.json", error)

    disabled = next(p for p in data["personas"] if p["state"] == "banned")
    write_refusal(refusal(
        "account_disabled",
        {"email": disabled["email"], "password": data["local_password"], "locale": LOCALE},
        "mock-responses-disabled",
    ))

    write_refusal(refusal("invalid_request", {"email": disabled["email"], "locale": LOCALE}, "mock-responses-invalid"))

    unknown_email = {"email": "attempt-limit@mock-responses.test", "password": "not-the-password", "locale": LOCALE}
    for _ in range(10):
        status, error = supabase.call_function(
            "sign_in", json.dumps(unknown_email).encode(), {"X-Forwarded-For": "mock-responses-limit"}
        )
        if error.get("code") == "too_many_attempts":
            write_refusal(error)
            break
    else:
        raise SystemExit("sign_in too_many_attempts mock response: the attempt limit was never reached")

    # `unknown` cannot be triggered on demand: built from the same message the
    # function sends, in the shape it sends it (specs/AUTH.md 5.5).
    message = supabase.request(
        "POST", "/rest/v1/rpc/sign_in_error_message", {"p_code": "unknown", "p_locale": LOCALE}, service=True
    )
    write_refusal({"status": "error", "code": "unknown", "message": message})


def main() -> None:
    data = dataset.load()
    supabase = LocalSupabase()
    keys = screen_keys(supabase)
    root = dataset.MOCK_RESPONSES_PATH
    clear(root)

    print("Signed out:")
    capture(root / "get_entry.json", lambda: supabase.rpc("get_entry", {"p_locale": LOCALE}))
    for key in keys:
        capture(
            root / f"get_screen.{key}.json",
            lambda key=key: supabase.rpc("get_screen", {"p_key": key, "p_locale": LOCALE, "p_params": {}}),
        )

    print("sign_in:")
    write_sign_in_mock_responses(supabase, data)

    for persona in dataset.active_personas(data):
        print(f"{persona['id']}:")
        token = supabase.sign_in(persona["email"], data["local_password"])
        capture(root / persona["id"] / "whoami.json", lambda token=token: supabase.rpc("whoami", {}, token=token))
        capture(
            root / persona["id"] / "get_tabs.json",
            lambda token=token: supabase.rpc("get_tabs", {"p_locale": LOCALE}, token=token),
        )
        for key in keys:
            capture(
                root / persona["id"] / f"get_screen.{key}.json",
                lambda key=key: supabase.rpc(
                    "get_screen", {"p_key": key, "p_locale": LOCALE, "p_params": {}}, token=token
                ),
            )


if __name__ == "__main__":
    main()
