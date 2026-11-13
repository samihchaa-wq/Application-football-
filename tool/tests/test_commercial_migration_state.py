"""Tests locaux de l'audit read-only des migrations commerciales."""
from __future__ import annotations

import io
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from check_commercial_migration_state import compare_migrations, run  # noqa: E402
from commercial_supabase_setup import COMMERCIAL_REF  # noqa: E402


class MigrationAuditTests(unittest.TestCase):
    FILES = [
        "20261113005335_active_club_admin_permissions.sql",
        "20261113010000_journal_incidents_par_club.sql",
        "20261115000000_waitlist_credits_admin_only.sql",
    ]

    def test_all_applied(self) -> None:
        s = compare_migrations(self.FILES, [x[:14] for x in self.FILES])
        self.assertEqual(s["pending"], [])
        self.assertEqual(s["unknown"], [])
        self.assertEqual(s["backfilled"], [])

    def test_pending_and_retroactive_migration_are_visible(self) -> None:
        s = compare_migrations(self.FILES, ["20261113010000"])
        self.assertEqual(s["pending"], [self.FILES[0], self.FILES[2]])
        self.assertEqual(s["backfilled"], [self.FILES[0]])

    def test_unknown_remote_migration_fails_closed(self) -> None:
        s = compare_migrations(self.FILES, ["20261113010000", "20261201000000"])
        self.assertEqual(s["unknown"], ["20261201000000"])

    def test_malformed_and_duplicate_local_versions_are_refused(self) -> None:
        s = compare_migrations(
            self.FILES + ["20261113010000_conflict.sql", "non_sql_migration.sql"],
            [],
        )
        self.assertIn("non_sql_migration.sql", s["invalid"])
        self.assertIn("20261113010000_conflict.sql", s["invalid"])
        self.assertIn(self.FILES[1], s["invalid"])

    def test_duplicate_remote_version_is_refused(self) -> None:
        s = compare_migrations(self.FILES, ["20261113010000"] * 2)
        self.assertEqual(s["duplicates"], ["20261113010000"])

    def test_only_commercial_project_can_be_queried(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            with patch("check_commercial_migration_state.query") as q:
                with redirect_stdout(io.StringIO()):
                    code = run("ovzijmqrnsgcmryinkfa", "fake", Path(tmp))
                self.assertEqual(code, 2)
                q.assert_not_called()

    def test_read_only_query_and_pending_are_not_executed(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            for path in self.FILES:
                (Path(tmp) / path).write_text("-- test", encoding="utf-8")
            with patch("check_commercial_migration_state.query", return_value=[
                {"version": "20261113010000"}
            ]) as q:
                with redirect_stdout(io.StringIO()) as out:
                    code = run(COMMERCIAL_REF, "dummy", Path(tmp))
            self.assertEqual(code, 0)
            self.assertIn("À appliquer uniquement sur autorisation", out.getvalue())
            q.assert_called_once()
            self.assertTrue(q.call_args.args[2].lower().startswith("select "))

    def test_unknown_production_version_blocks(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            (Path(tmp) / self.FILES[0]).write_text("-- test", encoding="utf-8")
            with patch("check_commercial_migration_state.query", return_value=[
                {"version": "20261001000000"}
            ]):
                with redirect_stdout(io.StringIO()):
                    self.assertEqual(run(COMMERCIAL_REF, "dummy", Path(tmp)), 1)


if __name__ == "__main__":
    unittest.main()
