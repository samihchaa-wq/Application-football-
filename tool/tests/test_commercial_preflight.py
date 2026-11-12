"""Tests sans accès réseau du verrou de déploiement commercial."""
from __future__ import annotations

import base64
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from check_commercial_deploy import (  # noqa: E402
    EXPECTED_PUBLIC_URL,
    ROOT,
    check,
)


class CommercialPreflightTests(unittest.TestCase):
    def setUp(self) -> None:
        self.valid = {
            "SUPABASE_URL": "https://aaaaaaaaaaaaaaaaaaaa.supabase.co",
            "SUPABASE_ANON_KEY": "sb_publishable_" + "a" * 32,
            "PUBLIC_APP_URL": EXPECTED_PUBLIC_URL,
            "USERNAME_DOMAIN": "comptes.club-app.local",
        }

    @staticmethod
    def jwt(role: str) -> str:
        def encoded(obj: dict[str, str]) -> str:
            raw = json.dumps(obj).encode("utf-8")
            return base64.urlsafe_b64encode(raw).decode("ascii").rstrip("=")

        return f"{encoded({'alg': 'HS256'})}.{encoded({'role': role})}.signature"

    def test_valid_publication(self) -> None:
        self.assertEqual(check(self.valid), [])

    def test_valid_legacy_anon_key(self) -> None:
        self.valid["SUPABASE_ANON_KEY"] = self.jwt("anon")
        self.assertEqual(check(self.valid), [])

    def test_current_config_cannot_be_published(self) -> None:
        current = json.loads((ROOT / "config" / "production.json").read_text())
        self.assertTrue(check(current))

    def test_private_as_grinta_project_is_forbidden(self) -> None:
        self.valid["SUPABASE_URL"] = "https://ovzijmqrnsgcmryinkfa.supabase.co"
        self.assertTrue(any("personnelle" in error for error in check(self.valid)))

    def test_private_party_project_is_forbidden(self) -> None:
        self.valid["SUPABASE_URL"] = "https://yqfewxadpyulgxehhpcu.supabase.co"
        self.assertTrue(check(self.valid))

    def test_http_and_wrong_hostname_are_forbidden(self) -> None:
        for url in (
            "http://aaaaaaaaaaaaaaaaaaaa.supabase.co",
            "https://A-REMPLACER.supabase.co",
            "https://example.com",
        ):
            with self.subTest(url=url):
                self.valid["SUPABASE_URL"] = url
                self.assertTrue(check(self.valid))

    def test_secret_key_is_forbidden(self) -> None:
        for key in ("sb_secret_" + "a" * 32, self.jwt("service_role")):
            with self.subTest(key_type=key.split("_")[0]):
                self.valid["SUPABASE_ANON_KEY"] = key
                self.assertTrue(check(self.valid))

    def test_wrong_pages_destination_is_forbidden(self) -> None:
        self.valid["PUBLIC_APP_URL"] = "https://samihchaa-wq.github.io/AS-Grinta/"
        self.assertTrue(check(self.valid))

    def test_missing_username_domain_is_forbidden(self) -> None:
        self.valid["USERNAME_DOMAIN"] = ""
        self.assertTrue(check(self.valid))


if __name__ == "__main__":
    unittest.main()
