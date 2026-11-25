"""Tests locaux sans base de données ni accès réseau."""
import unittest

from tool.check_migration_history import duplicate_versions, violations


class MigrationHistoryGuardTests(unittest.TestCase):
    def test_new_migration_with_timestamp_is_allowed(self):
        self.assertEqual(violations("A\tsupabase/migrations/20261112110000_example.sql"), [])

    def test_modified_existing_migration_is_refused(self):
        self.assertEqual(len(violations("M\tsupabase/migrations/20261112050000_previous.sql")), 1)

    def test_deleted_existing_migration_is_refused(self):
        self.assertEqual(len(violations("D\tsupabase/migrations/20261112050000_previous.sql")), 1)

    def test_renamed_existing_migration_is_refused(self):
        diff = ("R100\tsupabase/migrations/20261112050000_old.sql"
                "\tsupabase/migrations/20261112120000_new.sql")
        self.assertEqual(len(violations(diff)), 1)

    def test_copy_of_existing_migration_is_refused(self):
        diff = ("C100\tsupabase/migrations/20261112050000_old.sql"
                "\tsupabase/migrations/20261112120000_new.sql")
        self.assertEqual(len(violations(diff)), 1)

    def test_noncanonical_new_migration_is_refused(self):
        self.assertEqual(len(violations("A\tsupabase/migrations/new-one.sql")), 1)

    def test_unrelated_files_can_change(self):
        self.assertEqual(violations("M\tlib/main.dart\nA\tdocs/notes.md"), [])

    def test_empty_diff_is_allowed(self):
        self.assertEqual(violations(""), [])

    def test_unparseable_diff_is_refused(self):
        self.assertEqual(len(violations("unrecognized")), 1)

    def test_duplicate_version_number_is_refused(self):
        paths = [
            "supabase/migrations/20261206000000_logo.sql",
            "supabase/migrations/20261206000000_paiement.sql",
        ]
        self.assertEqual(len(duplicate_versions(paths)), 1)

    def test_distinct_version_numbers_are_allowed(self):
        paths = [
            "supabase/migrations/20261206000000_logo.sql",
            "supabase/migrations/20261206010000_paiement.sql",
        ]
        self.assertEqual(duplicate_versions(paths), [])

    def test_current_repository_has_no_duplicate_version(self):
        import glob
        self.assertEqual(duplicate_versions(sorted(glob.glob("supabase/migrations/*.sql"))), [])


if __name__ == "__main__":
    unittest.main()
