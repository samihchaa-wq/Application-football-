"""Contrats : un contrôle de production non exécuté ne doit pas être vert.

Analyse statique locale des workflows GitHub (aucun secret ni accès distant).
"""
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS = ROOT / ".github" / "workflows"


def step_text(workflow: str, name: str) -> str:
    anchor = f"      - name: {name}\n"
    if anchor not in workflow:
        raise AssertionError(f"Étape manquante : {name}")
    return workflow.split(anchor, 1)[1].split("\n      - name:", 1)[0]


class ProductionWorkflowsFailClosedTests(unittest.TestCase):
    def test_watch_missing_connection_must_fail(self):
        workflow = (WORKFLOWS / "production_watch.yml").read_text()
        missing = step_text(workflow, "Require configured production database")
        self.assertIn("if: env.DB_URL == ''", missing)
        self.assertIn("::error::", missing)
        self.assertIn("exit 1", missing)
        self.assertNotIn("Skip when no production database is configured", workflow)

    def test_watch_real_query_requires_connection(self):
        workflow = (WORKFLOWS / "production_watch.yml").read_text()
        check = step_text(workflow, "Check scheduled jobs and notifications")
        self.assertIn("if: env.DB_URL != ''", check)
        self.assertIn('psql "$DB_URL"', check)
        self.assertIn("ON_ERROR_STOP=1", check)

    def test_backup_missing_inputs_must_fail(self):
        workflow = (WORKFLOWS / "production_backup.yml").read_text()
        missing = step_text(
            workflow, "Require configured database and backup passphrase"
        )
        self.assertIn(
            "if: env.DB_URL == '' || env.BACKUP_PASSPHRASE == ''", missing
        )
        self.assertIn("::error::", missing)
        self.assertIn("exit 1", missing)
        self.assertNotIn("Skip when no production database is configured", workflow)

    def test_backup_still_encrypted_and_conditional(self):
        workflow = (WORKFLOWS / "production_backup.yml").read_text()
        archive = step_text(workflow, "Keep the encrypted backup")
        self.assertIn(
            "if: env.DB_URL != '' && env.BACKUP_PASSPHRASE != ''", archive
        )
        self.assertIn("backup-*.tar.gz.gpg", archive)
        self.assertIn("retention-days: 90", archive)
        self.assertIn("--symmetric --cipher-algo AES256", workflow)


if __name__ == "__main__":
    unittest.main()
