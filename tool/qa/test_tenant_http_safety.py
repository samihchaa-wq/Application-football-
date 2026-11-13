"""Sécurité du smoke test HTTP: tests unitaires sans aucun réseau."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from tenant_http_smoke import assert_local, parse_status


class TenantSmokeSafetyTests(unittest.TestCase):
    def test_parse(self):
        self.assertEqual(parse_status('API_URL="http://127.0.0.1:54321"\nANON_KEY="abc"\n'),
                         {"API_URL": "http://127.0.0.1:54321", "ANON_KEY": "abc"})

    def test_local_only(self):
        db = "postgresql://postgres:postgres@127.0.0.1:54322/postgres"
        assert_local("http://127.0.0.1:54321", db)
        for api in ("https://example.invalid", "http://localhost:54321", "http://127.0.0.1:54322"):
            with self.subTest(api=api), self.assertRaises(RuntimeError):
                assert_local(api, db)

    def test_remote_db_is_forbidden(self):
        with self.assertRaises(RuntimeError):
            assert_local("http://127.0.0.1:54321",
                         "postgresql://postgres:postgres@remote.invalid:5432/postgres")


if __name__ == "__main__":
    unittest.main()
