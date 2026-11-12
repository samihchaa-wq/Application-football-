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
        self, *, fail_phase: str = "", progress_only: bool = False
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
                "sys.exit(17 if os.environ.get('FAIL_PHASE') == phase else 0)\n",
                encoding="utf-8",
            )
            pgbench.chmod(0o755)
            environment = dict(os.environ)
            environment.update(
                PATH=f"{fake_bin}{os.pathsep}{environment.get('PATH', '')}",
                FAIL_PHASE=fail_phase,
                PROGRESS_ONLY="1" if progress_only else "0",
                DB_URL="postgresql://postgres:postgres@127.0.0.1:54322/postgres",
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

    def test_empty_filtered_output_is_not_failure(self) -> None:
        run = self._run_with_fake_database(progress_only=True)
        self.assertEqual(run.returncode, 0, run.stdout + run.stderr)
        self.assertNotIn("progress:", run.stdout)


if __name__ == "__main__":
    unittest.main()
