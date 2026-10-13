"""Minimal HTTP access to the running local Supabase stack, using only the
standard library. Reads URLs and local keys from `supabase status`."""

import json
import subprocess
import urllib.error
import urllib.request
from pathlib import Path

BACKEND = Path(__file__).resolve().parents[1]


class RequestFailed(Exception):
    def __init__(self, status: int, body: str):
        super().__init__(f"HTTP {status}: {body}")
        self.status = status
        self.body = body


class LocalSupabase:
    def __init__(self) -> None:
        result = subprocess.run(
            ["supabase", "status", "-o", "json"],
            cwd=BACKEND, capture_output=True, text=True,
        )
        if result.returncode != 0:
            raise SystemExit("Local Supabase is not running. Start it: cd backend && supabase start")
        status = json.loads(result.stdout[result.stdout.index("{"):])
        self.api_url = status["API_URL"].rstrip("/")
        self.anon_key = status["ANON_KEY"]
        self.service_key = status["SERVICE_ROLE_KEY"]

    def request(self, method: str, path: str, body=None, token: str | None = None, service: bool = False,
                headers: dict | None = None):
        key = self.service_key if service else self.anon_key
        headers = {"apikey": key, "Content-Type": "application/json", **(headers or {})}
        bearer = self.service_key if service else token
        if bearer:
            headers["Authorization"] = f"Bearer {bearer}"
        data = None if body is None else json.dumps(body).encode()
        req = urllib.request.Request(self.api_url + path, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req) as response:
                return json.loads(response.read() or b"null")
        except urllib.error.HTTPError as error:
            raise RequestFailed(error.code, error.read().decode()) from None

    def rpc(self, function: str, params: dict, token: str | None = None):
        return self.request("POST", f"/rest/v1/rpc/{function}", params, token=token)

    def call_function(self, name: str, body: bytes, headers: dict | None = None, method: str = "POST"):
        """Calls an Edge Function and returns (status, parsed JSON body), never raising on HTTP errors."""
        all_headers = {"apikey": self.anon_key, "Content-Type": "application/json", **(headers or {})}
        req = urllib.request.Request(
            f"{self.api_url}/functions/v1/{name}",
            data=body if method != "GET" else None,
            headers=all_headers,
            method=method,
        )
        try:
            with urllib.request.urlopen(req) as response:
                return response.status, json.loads(response.read())
        except urllib.error.HTTPError as error:
            return error.code, json.loads(error.read() or b"null")

    def sign_in(self, email: str, password: str) -> str:
        """Signs in with Supabase Auth directly and returns the access token."""
        session = self.request(
            "POST", "/auth/v1/token?grant_type=password", {"email": email, "password": password}
        )
        return session["access_token"]
