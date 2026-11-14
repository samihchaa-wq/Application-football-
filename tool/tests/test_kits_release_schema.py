"""Régressions fail-closed du contrôle de schéma maillots avant Cloudflare."""
from __future__ import annotations

import io
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from check_kits_release_schema import READINESS_SQL, REQUIRED_FIELDS, run  # noqa: E402
from commercial_supabase_setup import COMMERCIAL_REF  # noqa: E402


class KitsReleaseSchemaTests(unittest.TestCase):
    def setUp(self) -> None:
        self.workspace = tempfile.TemporaryDirectory()
        self.addCleanup(self.workspace.cleanup)
        self.migration = Path(self.workspace.name) / (
            "20261120000000_kits_illimites_par_club.sql"
        )
        self.migration.write_text("-- fixture\n", encoding="utf-8")

    def invoke(self, data):
        with patch("check_kits_release_schema.query", return_value=data) as q:
            with redirect_stdout(io.StringIO()) as output:
                code = run(COMMERCIAL_REF, "faux-jeton", self.migration)
            return code, q, output.getvalue()

    def test_older_release_without_migration_does_not_require_new_schema(self):
        self.migration.unlink()
        with patch("check_kits_release_schema.query") as q:
            self.assertEqual(run(COMMERCIAL_REF, "", self.migration), 0)
            q.assert_not_called()

    def test_wrong_project_and_missing_token_fail_without_query(self):
        with patch("check_kits_release_schema.query") as q:
            self.assertEqual(run("ovzijmqrnsgcmryinkfa", "fake", self.migration), 2)
            self.assertEqual(run(COMMERCIAL_REF, "", self.migration), 2)
            q.assert_not_called()

    def test_all_requirements_true_permit_release(self):
        code, q, _ = self.invoke([{name: True for name in REQUIRED_FIELDS}])
        self.assertEqual(code, 0)
        q.assert_called_once()
        self.assertEqual(q.call_args.args[0], COMMERCIAL_REF)
        self.assertTrue(q.call_args.args[2].lstrip().lower().startswith("select "))
        self.assertNotIn("insert into", READINESS_SQL.lower())
        self.assertNotIn("delete from", READINESS_SQL.lower())

    def test_each_missing_requirement_blocks(self):
        for missing in REQUIRED_FIELDS:
            with self.subTest(missing=missing):
                data = {name: True for name in REQUIRED_FIELDS}
                data[missing] = False
                code, _, output = self.invoke([data])
                self.assertEqual(code, 1)
                self.assertIn(missing, output)

    def test_unknown_and_malformed_response_fail_closed(self):
        for data in ([], None, {}, [{}], [{"migration_registered": "true"}]):
            with self.subTest(data=data):
                code, _, _ = self.invoke(data)
                self.assertNotEqual(code, 0)

    def test_read_error_fails_closed(self):
        with patch("check_kits_release_schema.query", side_effect=OSError("offline")):
            self.assertEqual(run(COMMERCIAL_REF, "fake", self.migration), 2)


if __name__ == "__main__":
    unittest.main()
