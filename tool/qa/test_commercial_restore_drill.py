"""Tests sans réseau ni donnée réelle de l'exercice de restauration."""
from __future__ import annotations

import os
import sys
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
import commercial_restore_drill as drill  # noqa: E402


class SanitizeTest(unittest.TestCase):
    def test_keeps_identifiers_and_hides_values(self):
        message = drill._sanitize_sql_error(
            b'ERROR:  duplicate key value violates unique constraint "users_pkey"\n'
            b'DETAIL:  Key (id)=(1234) already exists.\n')
        self.assertIn('"users_pkey"', message)
        self.assertNotIn("1234", message)

    def test_hides_quoted_values(self):
        message = drill._sanitize_sql_error(
            b'ERROR:  invalid input syntax for type uuid: "jean dupont@example.org"\n')
        self.assertNotIn("dupont", message)
        message = drill._sanitize_sql_error(b"ERROR:  value 'secret' is wrong\n")
        self.assertNotIn("secret", message)

    def test_no_error_line(self):
        self.assertIn("sans message", drill._sanitize_sql_error(b"rien"))


class EgressTest(unittest.TestCase):
    HEADER = "Iface\tDestination\tGateway\n"

    def test_default_route_refused(self):
        with self.assertRaises(drill.UnsafeRestore):
            drill.assert_no_egress(self.HEADER + "eth0\t00000000\t0101A8C0\n",
                                   probe=lambda: (_ for _ in ()).throw(OSError()))

    def test_reachable_internet_refused(self):
        with self.assertRaises(drill.UnsafeRestore):
            drill.assert_no_egress(self.HEADER, probe=lambda: None)

    def test_docker_bridge_without_exit_accepted(self):
        def blocked():
            raise OSError("unreachable")
        drill.assert_no_egress(self.HEADER + "br-1\t000013AC\t00000000\n", probe=blocked)


class RefusalTest(unittest.TestCase):
    def test_every_command_refuses_outside_isolation(self):
        # Sur une machine ordinaire (interface réseau réelle, URL absente),
        # chaque étape doit refuser avant de toucher à quoi que ce soit.
        with mock.patch.dict(os.environ, {}, clear=True):
            for argv in (["import", "/nonexistent"], ["storage", "/nonexistent"], ["access"]):
                self.assertEqual(drill.main(argv), 1)

    def test_usage(self):
        self.assertEqual(drill.main([]), 1)


if __name__ == "__main__":
    unittest.main()
