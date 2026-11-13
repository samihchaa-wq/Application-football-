"""Tests for the commercial, read-only Auth contract guard."""

from __future__ import annotations

import json
import shutil
import tempfile
import unittest
from pathlib import Path

from tool.check_auth_password_contract import ContractError, validate

ROOT = Path(__file__).resolve().parents[2]
SOURCES = (
    "lib/core/security/password_policy.dart",
    "supabase/functions/register-account/password_policy.ts",
    "supabase/functions/register-account/index.ts",
    "config/production.json",
)


class AuthPasswordContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.workspace = tempfile.TemporaryDirectory()
        self.addCleanup(self.workspace.cleanup)
        self.root = Path(self.workspace.name)
        for relative in SOURCES:
            destination = self.root / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / relative, destination)

    def replace(self, relative: str, before: str, after: str) -> None:
        path = self.root / relative
        source = path.read_text(encoding="utf-8")
        self.assertIn(before, source)
        path.write_text(source.replace(before, after, 1), encoding="utf-8")

    def test_current_commercial_contract_passes(self) -> None:
        self.assertEqual(validate(self.root), (12, 72))

    def test_edge_and_flutter_lengths_must_match(self) -> None:
        self.replace(
            "supabase/functions/register-account/password_policy.ts",
            "MIN_PASSWORD_LENGTH = 12",
            "MIN_PASSWORD_LENGTH = 10",
        )
        with self.assertRaisesRegex(ContractError, "minimum.*disagree"):
            validate(self.root)

    def test_missing_server_validation_is_rejected(self) -> None:
        self.replace(
            "supabase/functions/register-account/index.ts",
            "validatePassword(password)",
            "null /* validator removed */",
        )
        with self.assertRaisesRegex(ContractError, "no longer invokes"):
            validate(self.root)

    def test_unequal_character_rules_are_rejected(self) -> None:
        self.replace(
            "supabase/functions/register-account/password_policy.ts",
            "/[A-Z]/",
            "/[À-Ÿ]/",
        )
        with self.assertRaisesRegex(ContractError, "category"):
            validate(self.root)

    def test_original_project_ref_is_rejected(self) -> None:
        path = self.root / "config/production.json"
        config = json.loads(path.read_text(encoding="utf-8"))
        config["SUPABASE_URL"] = "https://ovzijmqrnsgcmryinkfa.supabase.co"
        path.write_text(json.dumps(config), encoding="utf-8")
        with self.assertRaisesRegex(ContractError, "does not target Petit Filet"):
            validate(self.root)

    def test_old_club_username_domain_is_rejected(self) -> None:
        path = self.root / "config/production.json"
        config = json.loads(path.read_text(encoding="utf-8"))
        config["USERNAME_DOMAIN"] = "pronos.as-grinta.local"
        path.write_text(json.dumps(config), encoding="utf-8")
        with self.assertRaisesRegex(ContractError, "old club"):
            validate(self.root)


if __name__ == "__main__":
    unittest.main()
