"""Garde-fou documentaire : aucune ligne de recette ne disparaît sans trace.

Ce test ne simule pas le club et ne prétend pas valider l'application.
"""
import re
import unittest
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
AUDIT = ROOT / "docs" / "AUDIT_FONCTIONNALITES_DETAILLE.md"
GRID = ROOT / "docs" / "recette" / "2026-11-13" / "GRILLE_INTEGRALE.md"
CARNET = ROOT / "docs" / "recette" / "2026-11-13" / "CARNET_30_MATCHS.md"


class RecetteTraceabilityTest(unittest.TestCase):
    def test_all_audit_features_have_one_explicit_result(self):
        audit = AUDIT.read_text(encoding="utf-8")
        grid = GRID.read_text(encoding="utf-8")
        pattern = re.compile(r"^\|\s*([A-N][0-9]{2})\s*\|", re.MULTILINE)
        expected = pattern.findall(audit)
        actual = pattern.findall(grid)
        self.assertEqual(len(expected), 164, "Revoir la source si elle évolue")
        self.assertEqual(Counter(actual), Counter(expected))
        for line in grid.splitlines():
            if re.match(r"^\|\s*[A-N][0-9]{2}\s*\|", line):
                self.assertIn("|", line)
                self.assertRegex(line, r"\|\s*(?:Non vérifié|Testé à l'écran|Testé en base)\s*\|")

    def test_thirty_matches_have_eleven_statuses_each(self):
        carnet = CARNET.read_text(encoding="utf-8")
        counts = Counter(
            re.findall(r"^\|\s*(M[0-9]{2})\s*\|", carnet, re.MULTILINE)
        )
        expected = {f"M{i:02d}": 11 for i in range(1, 31)}
        self.assertEqual(counts, expected)
        for line in carnet.splitlines():
            if re.match(r"^\|\s*M[0-9]{2}\s*\|", line):
                self.assertRegex(line, r"\|\s*(?:Non vérifié|Testé à l'écran|Testé en base)\s*\|")

    def test_presence_does_not_count_as_functional_validation(self):
        grid = GRID.read_text(encoding="utf-8")
        self.assertIn("RPC SQL publiques", grid)
        self.assertIn("Non vérifié", grid)
        self.assertIn("Ce registre n\'est PAS une validation E2E", grid)


if __name__ == "__main__":
    unittest.main()
