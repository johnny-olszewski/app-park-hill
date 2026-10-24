"""sign_in Edge Function tests (SUP-006 AC1 to AC7), black box over HTTP
against local Supabase. Run with `make test-functions`."""

import json
import subprocess
import sys
import unittest
import uuid
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts"))

import dataset  # noqa: E402
from local_supabase import LocalSupabase  # noqa: E402

FUNCTIONS_CONTAINER = "supabase_edge_runtime_app-park-hill"
ERROR_KEYS = {"status", "code", "message"}


class SignInTests(unittest.TestCase):
    supabase: LocalSupabase
    data: dict

    @classmethod
    def setUpClass(cls):
        cls.supabase = LocalSupabase()
        cls.data = dataset.load()

    def setUp(self):
        self.supabase.request("DELETE", "/rest/v1/auth_attempts?id=gte.0", service=True)
        # A fresh client address per test keeps the per-address limit isolated.
        self.address = f"198.51.100.{uuid.uuid4().int % 250 + 1}, 10.0.0.1"

    # Helpers

    def sign_in(self, email, password, locale="en", address=None):
        body = json.dumps({"email": email, "password": password, "locale": locale}).encode()
        return self.supabase.call_function("sign_in", body, {"X-Forwarded-For": address or self.address})

    def persona(self, persona_id):
        return next(p for p in self.data["personas"] if p["id"] == persona_id)

    def assert_error(self, result, status, code):
        actual_status, body = result
        self.assertEqual(actual_status, status, body)
        self.assertEqual(set(body), ERROR_KEYS, body)
        self.assertEqual(body["status"], "error")
        self.assertEqual(body["code"], code)
        self.assertTrue(body["message"])
        return body

    def set_string(self, key, locale, value):
        self.supabase.request(
            "POST", "/rest/v1/strings?on_conflict=key,locale",
            {"key": key, "locale": locale, "value": value}, service=True,
            headers={"Prefer": "resolution=merge-duplicates"},
        )

    def get_string(self, key, locale):
        rows = self.supabase.request("GET", f"/rest/v1/strings?key=eq.{key}&locale=eq.{locale}&select=value", service=True)
        return rows[0]["value"] if rows else None

    def delete_string(self, key, locale):
        self.supabase.request("DELETE", f"/rest/v1/strings?key=eq.{key}&locale=eq.{locale}", service=True)

    # AC1

    def test_correct_credentials_return_a_session_matching_the_mock_response(self):
        attendee = self.persona("attendee")
        status, body = self.sign_in(attendee["email"], self.data["local_password"])
        self.assertEqual(status, 200, body)
        self.assertEqual(body["status"], "ok")
        mock_response = json.loads((dataset.MOCK_RESPONSES_PATH / "sign_in.ok.json").read_text())
        self.assertEqual(set(body), set(mock_response))
        self.assertEqual(set(body["session"]), set(mock_response["session"]))
        self.assertEqual(body["session"]["user_id"], dataset.persona_uuid("attendee"))
        self.assertTrue(body["session"]["access_token"])
        self.assertTrue(body["session"]["refresh_token"])
        self.assertGreater(body["session"]["expires_at"], datetime.now(timezone.utc).timestamp())

    # AC2

    def test_wrong_password_and_unknown_email_are_indistinguishable(self):
        wrong_password = self.sign_in(self.persona("attendee")["email"], "not-the-password")
        unknown_email = self.sign_in("nobody@parkhill.test", "not-the-password")
        self.assert_error(wrong_password, 401, "invalid_credentials")
        self.assertEqual(wrong_password, unknown_email)

    # AC3

    def test_disabled_account_is_refused(self):
        body = self.assert_error(
            self.sign_in(self.persona("disabled")["email"], self.data["local_password"]), 403, "account_disabled"
        )
        self.assertEqual(body["message"], self.get_string("auth.error.account_disabled", "en"))

    # AC4

    def test_five_failures_for_an_email_lock_it_without_calling_auth(self):
        attendee = self.persona("attendee")
        for _ in range(5):
            self.assert_error(self.sign_in(attendee["email"], "wrong"), 401, "invalid_credentials")
        # The correct password would succeed if Supabase's auth service were called.
        self.assert_error(self.sign_in(attendee["email"], self.data["local_password"]), 429, "too_many_attempts")
        # Email matching ignores case and surrounding spaces; another address does not help.
        self.assert_error(
            self.sign_in(f"  {attendee['email'].upper()} ", self.data["local_password"], address="192.0.2.77"),
            429, "too_many_attempts",
        )

    def test_twenty_failures_from_an_address_lock_it_without_calling_auth(self):
        for n in range(20):
            self.assert_error(self.sign_in(f"guess{n}@parkhill.test", "wrong"), 401, "invalid_credentials")
        attendee = self.persona("attendee")
        self.assert_error(self.sign_in(attendee["email"], self.data["local_password"]), 429, "too_many_attempts")
        status, _ = self.sign_in(attendee["email"], self.data["local_password"], address="192.0.2.88")
        self.assertEqual(status, 200)

    def test_a_disabled_attempt_does_not_count_as_a_failure(self):
        disabled = self.persona("disabled")
        for _ in range(6):
            self.assert_error(self.sign_in(disabled["email"], self.data["local_password"]), 403, "account_disabled")

    # AC5

    def test_messages_come_from_strings_for_the_locale_with_english_fallback(self):
        key = "auth.error.invalid_credentials"
        original = self.get_string(key, "en")
        email = self.persona("attendee")["email"]
        try:
            body = self.assert_error(self.sign_in(email, "wrong", locale="es"), 401, "invalid_credentials")
            self.assertEqual(body["message"], original)

            self.set_string(key, "es", "El correo y la contraseña no coinciden.")
            body = self.assert_error(self.sign_in(email, "wrong", locale="es"), 401, "invalid_credentials")
            self.assertEqual(body["message"], "El correo y la contraseña no coinciden.")

            self.set_string(key, "en", "Changed wording.")
            body = self.assert_error(self.sign_in(email, "wrong"), 401, "invalid_credentials")
            self.assertEqual(body["message"], "Changed wording.")
        finally:
            self.set_string(key, "en", original)
            self.delete_string(key, "es")

    # AC6

    def test_malformed_requests_return_invalid_request(self):
        cases = [
            b"not json",
            b"[]",
            json.dumps({"email": "attendee@parkhill.test"}).encode(),
            json.dumps({"email": 7, "password": "x"}).encode(),
            json.dumps({"email": "no-at-sign", "password": "x"}).encode(),
            json.dumps({"email": "attendee@parkhill.test", "password": ""}).encode(),
            json.dumps({"email": "attendee@parkhill.test", "password": "x", "locale": 3}).encode(),
        ]
        for body in cases:
            with self.subTest(body=body):
                self.assert_error(self.supabase.call_function("sign_in", body), 400, "invalid_request")
        self.assert_error(self.supabase.call_function("sign_in", b"", method="GET"), 400, "invalid_request")

    def test_unexpected_failures_return_unknown_with_a_generic_message(self):
        key = "auth.error.invalid_credentials"
        original = self.get_string(key, "en")
        try:
            self.delete_string(key, "en")
            body = self.assert_error(self.sign_in(self.persona("attendee")["email"], "wrong"), 400, "unknown")
            self.assertEqual(body["message"], self.get_string("auth.error.unknown", "en"))
        finally:
            self.set_string(key, "en", original)

    # AC7

    def test_no_password_or_plain_email_in_logs_or_attempts(self):
        started = datetime.now(timezone.utc).isoformat()
        marker = uuid.uuid4().hex
        email = f"leak-check-{marker}@parkhill.test"
        password = f"password-{marker}"
        attendee_password_marker = f"attendee-{marker}"

        self.sign_in(email, password)
        self.sign_in(self.persona("attendee")["email"], attendee_password_marker)
        self.sign_in(self.persona("attendee")["email"], self.data["local_password"])

        logs = subprocess.run(
            ["docker", "logs", "--since", started, FUNCTIONS_CONTAINER],
            capture_output=True, text=True, check=True,
        )
        log_text = logs.stdout + logs.stderr
        self.assertIn('"fn":"sign_in"', log_text, "expected the function's own log lines")
        for secret in (email, password, attendee_password_marker, self.data["local_password"], "attendee@parkhill.test"):
            self.assertNotIn(secret, log_text)

        rows = self.supabase.request("GET", "/rest/v1/auth_attempts?select=*", service=True)
        self.assertEqual(len(rows), 3)
        stored = json.dumps(rows)
        for secret in (email, password, attendee_password_marker, self.data["local_password"], "attendee@parkhill.test"):
            self.assertNotIn(secret, stored)
        for row in rows:
            self.assertRegex(row["email_hash"], r"^[0-9a-f]{64}$")


if __name__ == "__main__":
    unittest.main()
