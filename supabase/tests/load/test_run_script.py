"""Test sans base réelle : les échecs de pgbench doivent faire échouer la charge."""

from __future__ import annotations

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


RUNNER = Path(__file__).with_name("run.sh")


class LoadRunnerExitStatusTests(unittest.TestCase):
    def _run_with_fake_database(
        self, *, fail_phase: str = "", progress_only: bool = False, zero_exit_failure: bool = False, db_url: str = "postgresql://postgres:postgres@127.0.0.1:54322/postgres"
    ) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as folder:
            fake_bin = Path(folder)
            psql = fake_bin / "psql"
            psql.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
            psql.chmod(0o755)

            pgbench = fake_bin / "pgbench"
            pgbench.write_text(
                "#!/usr/bin/env python3\n"
                "import os, sys\n"
                "phase = 'read' if any('read.pgbench' in a for a in sys.argv) else 'write'\n"
                "print('progress: irrelevant line')\n"
                "if os.environ.get('PROGRESS_ONLY') != '1':\n"
                "    print('result: ' + phase)\n"
                "    print('number of transactions actually processed: 250')\n"
                "    print('number of failed transactions: ' + ('2' if os.environ.get('ZERO_EXIT_FAILURE') == '1' else '0'))\n"
                "    print('tps = 12.5 (without initial connection time)')\n"
                "sys.exit(17 if os.environ.get('FAIL_PHASE') == phase else 0)\n",
                encoding="utf-8",
            )
            pgbench.chmod(0o755)
            environment = dict(os.environ)
            environment.update(
                PATH=f"{fake_bin}{os.pathsep}{environment.get('PATH', '')}",
                FAIL_PHASE=fail_phase,
                PROGRESS_ONLY="1" if progress_only else "0",
                ZERO_EXIT_FAILURE="1" if zero_exit_failure else "0",
                DB_URL=db_url,
            )
            return subprocess.run(
                ["bash", str(RUNNER), "1", "2", "1", "3", "1"],
                env=environment,
                capture_output=True,
                text=True,
                timeout=10,
                check=False,
            )

    def test_success_runs_both_phases_and_filters_progress(self) -> None:
        run = self._run_with_fake_database()
        self.assertEqual(run.returncode, 0, run.stdout + run.stderr)
        self.assertIn("result: read", run.stdout)
        self.assertIn("result: write", run.stdout)
        self.assertNotIn("progress:", run.stdout)

    def test_failure_in_read_fails_runner_and_stops_before_write(self) -> None:
        run = self._run_with_fake_database(fail_phase="read")
        self.assertEqual(run.returncode, 17, run.stdout + run.stderr)
        self.assertIn("result: read", run.stdout)
        self.assertNotIn("result: write", run.stdout)

    def test_failure_in_write_fails_runner(self) -> None:
        run = self._run_with_fake_database(fail_phase="write")
        self.assertEqual(run.returncode, 17, run.stdout + run.stderr)
        self.assertIn("result: read", run.stdout)
        self.assertIn("result: write", run.stdout)

    def test_remote_database_is_rejected_before_any_mutation(self) -> None:
        run = self._run_with_fake_database(
            db_url="postgresql://postgres:postgres@commercial.example:5432/postgres"
        )
        self.assertEqual(run.returncode, 2)
        self.assertIn("base PostgreSQL sur localhost", run.stderr)
        self.assertNotIn("result: read", run.stdout)

    def test_empty_filtered_output_is_failure(self) -> None:
        run = self._run_with_fake_database(progress_only=True)
        self.assertEqual(run.returncode, 1, run.stdout + run.stderr)
        self.assertNotIn("progress:", run.stdout)

    def test_zero_exit_with_failed_transactions_is_failure(self) -> None:
        run = self._run_with_fake_database(zero_exit_failure=True)
        self.assertEqual(run.returncode, 1, run.stdout + run.stderr)
        self.assertIn("Au moins une transaction a échoué", run.stderr)
        self.assertNotIn("result: write", run.stdout)


if __name__ == "__main__":
    unittest.main()
