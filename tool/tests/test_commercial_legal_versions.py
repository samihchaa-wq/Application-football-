"""Les versions des textes légaux affichées par l'appli et celles acceptées
par le serveur doivent être identiques : sinon l'inscription est refusée, ou
la preuve enregistrée ne correspond pas aux textes présentés."""

import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
DART = ROOT / "lib/features/legal/domain/legal_documents.dart"
CONSENT_FILES = [
    ROOT / "supabase/functions/register-account/consent.ts",
    ROOT / "supabase/functions/claim-club/consent.ts",
]


def _dart_const(name: str) -> str:
    match = re.search(rf"const String {name} = '([^']+)';", DART.read_text())
    assert match, name
    return match.group(1)


def _ts_const(path: pathlib.Path, name: str) -> str:
    match = re.search(rf'export const {name} = "([^"]+)";', path.read_text())
    assert match, (path, name)
    return match.group(1)


class LegalVersionsTest(unittest.TestCase):
    def test_server_accepts_exactly_the_published_versions(self) -> None:
        terms = _dart_const("legalVersion")
        contract = _dart_const("clubContractVersion")
        for path in CONSENT_FILES:
            with self.subTest(path=path.name):
                self.assertEqual(_ts_const(path, "CURRENT_TERMS_VERSION"), terms)
                self.assertEqual(
                    _ts_const(path, "CURRENT_CLUB_CONTRACT_VERSION"), contract
                )

    def test_both_registration_paths_share_the_same_rules(self) -> None:
        first, second = (path.read_text() for path in CONSENT_FILES)
        self.assertEqual(first, second)


if __name__ == "__main__":
    unittest.main()
