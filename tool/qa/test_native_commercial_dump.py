"""Exports avec faux clients locaux : aucun contact avec une base réelle."""
from __future__ import annotations

import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
from commercial_backup_bundle import PROJECT_REF, UnsafeBackup
from native_commercial_dump import database_environment, dump_database


class NativeDumpTests(unittest.TestCase):
    url = (
        f"postgresql://postgres.{PROJECT_REF}:p%40ss%24%28noop%29%5C%22@"
        "aws-1-eu-west-3.pooler.supabase.com:5432/postgres"
    )
    password = 'p@ss$(noop)\\"'

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.binary = self.root / "bin"
        self.binary.mkdir()
        self.calls = self.root / "calls.jsonl"
        self.output = self.root / "sql"
        self.install_clients()
        self.environment = patch.dict(os.environ, {"PATH": f"{self.binary}:{os.environ['PATH']}"})
        self.environment.start()
        self.addCleanup(self.environment.stop)

    def install_clients(self, major=17, fail=False, connection_fail=False, malformed_version=False):
        # Le programme vérifie les vrais arguments et l'environnement transmis
        # par bash, mais ne se connecte nulle part et ne lance aucune commande.
        source = f'''#!{sys.executable}
import json,os,pathlib,sys
program=pathlib.Path(sys.argv[0]).name
if "--version" in sys.argv:
    print(program + " (PostgreSQL) {major}.6")
    raise SystemExit(0)
assert os.environ["BACKUP_DATABASE_URI"] == {self.url!r}
assert os.environ["BACKUP_DATABASE_URI"] in sys.argv
assert "PGPASSWORD" not in os.environ
with open({str(self.calls)!r}, "a") as out:
    out.write(json.dumps({{"program": program,"args":sys.argv[1:]}}) + "\\n")
if program == "psql":
    if {connection_fail!r}:
        print("FATAL: password authentication failed " + os.environ["BACKUP_DATABASE_URI"], file=sys.stderr)
        raise SystemExit(2)
    print("unexpected" if {malformed_version!r} else "170006")
elif {fail!r}:
    print("partial export")
    print(os.environ["BACKUP_DATABASE_URI"], file=sys.stderr)
    raise SystemExit(2)
elif program == "pg_dumpall":
    print('CREATE ROLE "postgres";')
    print('CREATE ROLE "custom_role";')
elif "--schema-only" in sys.argv:
    print('CREATE TABLE "public"."fixture" (id integer);')
    print('SET transaction_timeout = 0;')
else:
    print('COPY "auth"."users" (id) FROM stdin;')
    print('-- private content that must survive the data export')
    print('\\\\.')
'''
        for name in ("psql", "pg_dump", "pg_dumpall"):
            file = self.binary / name
            file.write_text(source)
            file.chmod(0o700)

    def test_connection_uses_the_exact_verified_uri_without_shell_expansion(self):
        env = database_environment(" \t" + self.url + "\r\n")
        self.assertEqual(env["BACKUP_DATABASE_URI"], self.url)
        self.assertNotIn("PGPASSWORD", env)
        self.assertNotIn("SUPABASE_ACCESS_TOKEN", env)
        self.assertNotIn("BACKUP_PASSPHRASE", env)

    def test_refuses_another_project_before_starting_a_client(self):
        with self.assertRaises(UnsafeBackup):
            dump_database(self.url.replace(PROJECT_REF, "another_project"), self.output)
        self.assertFalse(self.calls.exists())

    def test_three_exports_preserve_auth_data_and_supabase_role_filters(self):
        dump_database(self.url, self.output)
        self.assertEqual({p.name for p in self.output.iterdir()}, {"roles.sql", "schema.sql", "data.sql"})
        roles = (self.output / "roles.sql").read_text()
        self.assertIn('CREATE ROLE "custom_role"', roles)
        self.assertNotIn('CREATE ROLE "postgres"', roles)
        schema = (self.output / "schema.sql").read_text()
        self.assertIn('CREATE TABLE IF NOT EXISTS "public"', schema)
        self.assertNotIn('SET transaction_timeout', schema)
        data = (self.output / "data.sql").read_text()
        self.assertIn('COPY "auth"."users"', data)
        self.assertIn('-- private content', data)
        calls = [json.loads(line) for line in self.calls.read_text().splitlines()]
        role = next(call for call in calls if call["program"] == "pg_dumpall")
        self.assertIn(self.url, role["args"])
        for output in self.output.iterdir():
            self.assertEqual(output.stat().st_mode & 0o777, 0o600)
            self.assertNotIn(self.password, output.read_text())
        dumps = [call for call in calls if call["program"] == "pg_dump"]
        self.assertTrue(all(self.url in call["args"] for call in dumps))
        data_call = next(call for call in dumps if "--data-only" in call["args"])
        exclusions = data_call["args"][data_call["args"].index("--exclude-schema") + 1].split("|")
        self.assertNotIn("auth", exclusions)
        self.assertNotIn("storage", exclusions)
        self.assertIn("storage.vector_indexes", data_call["args"])

    def test_refuses_a_client_older_than_the_server(self):
        self.install_clients(major=16)
        with self.assertRaisesRegex(UnsafeBackup, "plus ancien"):
            dump_database(self.url, self.output)
        self.assertFalse(self.output.exists())

    def test_partial_exports_are_rejected_without_exposing_stderr(self):
        self.install_clients(fail=True)
        with self.assertRaises(UnsafeBackup) as failure:
            dump_database(self.url, self.output)
        self.assertNotIn(self.password, str(failure.exception))
        self.assertNotIn(self.url, str(failure.exception))
        self.assertFalse((self.output / "roles.sql").exists())

    def test_connection_errors_are_classified_without_exposing_the_uri(self):
        self.install_clients(connection_fail=True)
        with self.assertRaisesRegex(UnsafeBackup, "authentification refusée") as failure:
            dump_database(self.url, self.output)
        self.assertNotIn(self.url, str(failure.exception))
        self.assertFalse(self.output.exists())

    def test_malformed_server_version_is_rejected_before_exports(self):
        self.install_clients(malformed_version=True)
        with self.assertRaisesRegex(UnsafeBackup, "format inattendu"):
            dump_database(self.url, self.output)
        self.assertFalse(self.output.exists())


if __name__ == "__main__":
    unittest.main()
