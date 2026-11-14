"""Contract tests: never backup an unknown project or incomplete Storage."""
from __future__ import annotations

import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from commercial_backup_bundle import (  # noqa: E402
    PROJECT_REF, UnsafeBackup, check_environment, database_password,
    read_inventory, validate_database_url, verify_and_manifest,
    write_bucket_list,
)


class CommercialBackupTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.storage = self.root / "storage"
        self.storage.mkdir()
        self.before = self.root / "before.json"
        self.after = self.root / "after.json"
        self.manifest = self.root / "manifest.json"
        self.good = {
            "buckets": ["profile-photos", "club-logos", "empty-bucket"],
            "objects": [
                {
                    "bucket_id": "profile-photos", "name": "club-a/joueur.png",
                    "id": "f1", "updated_at": "2026-11-14T14:00:00Z",
                },
                {
                    "bucket_id": "club-logos", "name": "a/logo.png",
                    "id": "f2", "updated_at": "2026-11-14T14:00:01Z",
                },
            ],
        }
        self.write(self.good)
        for bucket, name, value in [
            ("profile-photos", "club-a/joueur.png", b"\x00PNG\xfe"),
            ("club-logos", "a/logo.png", b"another image"),
        ]:
            file = self.storage / bucket / name
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_bytes(value)

    def write(self, before, after=None):
        self.before.write_text(json.dumps(before), encoding="utf-8")
        self.after.write_text(
            json.dumps(before if after is None else after), encoding="utf-8"
        )

    def test_commercial_db_direct_or_pooler_only(self):
        for value in [
            f"postgresql://postgres:secret@db.{PROJECT_REF}.supabase.co:5432/postgres",
            f"postgresql://postgres.{PROJECT_REF}:secret@eu.pooler.supabase.com:5432/postgres",
        ]:
            validate_database_url(value)
        for value in [
            "postgres://postgres:secret@db.ovzijmqrnsgcmryinkfa.supabase.co/postgres",
            "postgres://postgres.ovzijmqrnsgcmryinkfa:secret@eu.pooler.supabase.com/postgres",
            "postgres://postgres:secret@localhost/postgres",
            f"postgresql://postgres:secret@db.{PROJECT_REF}.supabase.co/mydb",
            f"postgresql://postgres@db.{PROJECT_REF}.supabase.co/postgres",
            "garbage",
        ]:
            with self.subTest(value=value), self.assertRaises(UnsafeBackup):
                validate_database_url(value)

    def test_preflight_rejects_weak_keys_and_wrong_project(self):
        valid = {
            "SUPABASE_PROJECT_REF": PROJECT_REF,
            "PRODUCTION_DB_URL": (
                f"postgresql://postgres:secret@db.{PROJECT_REF}.supabase.co/postgres"
            ),
            "SUPABASE_ACCESS_TOKEN": "token",
            "BACKUP_PASSPHRASE": "b123XyZ@!nP70Qrs#$2TuVw89GhJkiLM*5cdeFG67hiKLN9@zP4q",
        }
        check_environment(valid)
        for key, replacement in [
            ("SUPABASE_PROJECT_REF", "ovzijmqrnsgcmryinkfa"),
            ("SUPABASE_ACCESS_TOKEN", ""),
            ("PRODUCTION_DB_URL", ""),
            ("BACKUP_PASSPHRASE", "a" * 60),
        ]:
            with self.subTest(key=key), self.assertRaises(UnsafeBackup):
                check_environment({**valid, key: replacement})

    def test_password_from_commercial_url_is_decoded_and_project_checked(self):
        url = (
            f"postgresql://postgres:pa%24%40%3A%23secret@"
            f"db.{PROJECT_REF}.supabase.co/postgres"
        )
        self.assertEqual(database_password(url), "pa$@:#secret")
        with self.assertRaises(UnsafeBackup):
            database_password(
                "postgresql://postgres:fake@"
                "db.ovzijmqrnsgcmryinkfa.supabase.co/postgres"
            )
        with self.assertRaises(UnsafeBackup):
            database_password(
                f"postgresql://postgres:%00@db.{PROJECT_REF}.supabase.co/postgres"
            )

    def test_hashes_all_objects_and_preserves_empty_bucket(self):
        m = verify_and_manifest(
            self.before, self.after, self.storage, self.manifest
        )
        self.assertEqual(m["project_ref"], PROJECT_REF)
        self.assertEqual(m["object_count"], 2)
        self.assertEqual(m["bucket_count"], 3)
        actual = {
            (o["bucket_id"], o["name"]): o["sha256"] for o in m["objects"]
        }
        self.assertEqual(
            actual[("profile-photos", "club-a/joueur.png")],
            hashlib.sha256(b"\x00PNG\xfe").hexdigest(),
        )
        bpath = self.root / "buckets.txt"
        self.assertEqual(write_bucket_list(self.before, bpath), 2)
        self.assertEqual(
            bpath.read_text().splitlines(), ["club-logos", "profile-photos"]
        )

    def test_refuses_missing_or_extra_storage_bytes(self):
        missing = self.storage / "club-logos/a/logo.png"
        missing.unlink()
        with self.assertRaises(UnsafeBackup):
            verify_and_manifest(
                self.before, self.after, self.storage, self.manifest
            )
        missing.write_bytes(b"another image")
        extra = self.storage / "profile-photos/intrus.png"
        extra.write_bytes(b"unexpected")
        with self.assertRaises(UnsafeBackup):
            verify_and_manifest(
                self.before, self.after, self.storage, self.manifest
            )

    def test_refuses_changed_metadata_during_export(self):
        updated = json.loads(json.dumps(self.good))
        updated["objects"][0]["updated_at"] = "later"
        self.write(self.good, updated)
        with self.assertRaises(UnsafeBackup):
            verify_and_manifest(
                self.before, self.after, self.storage, self.manifest
            )

    def test_refuses_path_traversal_and_unknown_buckets(self):
        for path in ["../outside", "club-a/../../outside", "/root", "a//b", "a\\b"]:
            bad = json.loads(json.dumps(self.good))
            bad["objects"][0]["name"] = path
            with self.subTest(path=path):
                self.write(bad)
                with self.assertRaises(UnsafeBackup):
                    read_inventory(self.before)
        bad = json.loads(json.dumps(self.good))
        bad["objects"][0]["bucket_id"] = "other"
        self.write(bad)
        with self.assertRaises(UnsafeBackup):
            read_inventory(self.before)

    def test_refuses_symlink_and_duplicate_path(self):
        destination = self.storage / "club-logos/shortcut"
        destination.symlink_to("a/logo.png")
        with self.assertRaises(UnsafeBackup):
            verify_and_manifest(
                self.before, self.after, self.storage, self.manifest
            )
        destination.unlink()
        bad = json.loads(json.dumps(self.good))
        bad["objects"].append(bad["objects"][0].copy())
        self.write(bad)
        with self.assertRaises(UnsafeBackup):
            read_inventory(self.before)

    def test_empty_buckets_are_supported(self):
        self.write({"buckets": ["empty-bucket"], "objects": []})
        self.storage.rmdir() if not any(self.storage.iterdir()) else None
        # Empty export is legitimate when no DB object exists, but extra files fail.
        for bucket in (self.storage / "profile-photos", self.storage / "club-logos"):
            for file in list(bucket.rglob("*"))[::-1]:
                if file.is_file():
                    file.unlink()
                elif file.is_dir():
                    file.rmdir()
            bucket.rmdir()
        m = verify_and_manifest(
            self.before, self.after, self.storage, self.manifest
        )
        self.assertEqual(m["object_count"], 0)


if __name__ == "__main__":
    unittest.main()
