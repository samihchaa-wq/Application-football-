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
        preflight = step_text(
            workflow, "Fail closed if secrets, encryption or project identity are unsafe"
        )
        self.assertIn("python3 tool/qa/commercial_backup_bundle.py preflight", preflight)
        self.assertIn("SUPABASE_PROJECT_REF: jvxkhgdopslctpcjrhzw", workflow)
        self.assertIn("PRODUCTION_DB_URL:", workflow)
        self.assertIn("SUPABASE_ACCESS_TOKEN:", workflow)
        self.assertIn("SUPABASE_DB_PASSWORD:", workflow)
        self.assertIn("BACKUP_PASSPHRASE:", workflow)
        source = (ROOT / "tool/qa/commercial_backup_bundle.py").read_text()
        self.assertIn("validate_database_url(", source)
        self.assertIn("len(phrase) < 48", source)
        self.assertIn("SUPABASE_ACCESS_TOKEN", source)
        self.assertNotIn("Skip when no production database is configured", workflow)

    def test_backup_still_encrypted_and_conditional(self):
        workflow = (WORKFLOWS / "production_backup.yml").read_text()
        export = step_text(
            workflow, "Export commercial PostgreSQL and all Storage bytes and encrypt"
        )
        archive = step_text(workflow, "Retain encrypted archive only")
        self.assertIn("python3 tool/qa/commercial_backup_bundle.py verify", export)
        self.assertIn("supabase storage cp", export)
        self.assertIn("--symmetric", export)
        self.assertIn("--cipher-algo AES256", export)
        self.assertIn("gpg --batch --yes --pinentry-mode loopback", export)
        self.assertIn("trap 'rm -rf", export)
        self.assertIn("if-no-files-found: error", archive)
        self.assertIn("tar.gz.gpg", archive)
        self.assertNotIn("data.sql", archive)
        self.assertIn("retention-days: 90", archive)


if __name__ == "__main__":
    unittest.main()
