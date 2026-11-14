"""Tests hors ligne de l'intégrité d'une sauvegarde commerciale réelle (fictive)."""
from __future__ import annotations

import hashlib
import io
import json
import sys
import tarfile
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from verify_commercial_backup_tar import verify_archive  # noqa: E402
from commercial_backup_bundle import PROJECT_REF, UnsafeBackup  # noqa: E402


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


class VerifyCommercialBackupTarTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name) / "archive.tar.gz"
        self.file = "payload/storage/club-logos/team/a.png"
        self.storage_bytes = b"\x89PNG\r\n\x1a\nfixture"
        self.inventory = {
            "buckets": ["club-logos"],
            "objects": [{
                "bucket_id": "club-logos", "name": "team/a.png",
                "id": "id-1", "updated_at": "2026-11-14T16:00:00Z",
            }]
        }
        self.manifest = {
            "version": 1, "project_ref": PROJECT_REF,
            "bucket_count": 1, "object_count": 1,
            "objects": [{
                "bucket_id": "club-logos", "name": "team/a.png",
                "storage_id": "id-1", "updated_at": "2026-11-14T16:00:00Z",
                "sha256": digest(self.storage_bytes), "bytes": len(self.storage_bytes),
            }],
        }
        self.files = {
            "payload/PROJECT_REF": (PROJECT_REF + "\n").encode(),
            "payload/database/roles.sql": b"-- roles fixture\n",
            "payload/database/schema.sql": b"create table t(x int);\n",
            "payload/database/data.sql": b"COPY t(x) FROM stdin;\n1\n\\.\n",
            "payload/inventory-before.json": json.dumps(self.inventory).encode(),
            "payload/inventory-after.json": json.dumps(self.inventory).encode(),
            "payload/manifest.json": json.dumps(self.manifest).encode(),
            self.file: self.storage_bytes,
        }
        self.update_checksum()

    def update_checksum(self):
        rows = []
        for name in ("roles.sql", "schema.sql", "data.sql"):
            rows.append(
                digest(self.files[f"payload/database/{name}"])
                + "  " + name + "\n"
            )
        self.files["payload/database/sha256sums.txt"] = "".join(rows).encode()

    def build(self, extra_link=False):
        with tarfile.open(self.path, "w:gz") as archive:
            for name, data in self.files.items():
                info = tarfile.TarInfo(name)
                info.size = len(data)
                archive.addfile(info, io.BytesIO(data))
            if extra_link:
                link = tarfile.TarInfo("payload/storage/club-logos/malicious")
                link.type = tarfile.SYMTYPE
                link.linkname = "../outside"
                archive.addfile(link)

    def assert_rejects(self):
        self.build()
        with self.assertRaises(UnsafeBackup):
            verify_archive(self.path)

    def test_valid_archive_checks_all_byte_digests(self):
        self.build()
        summary = verify_archive(self.path)
        self.assertEqual(summary["project_ref"], PROJECT_REF)
        self.assertEqual(summary["objects_checked"], 1)
        self.assertEqual(summary["sql_files_checked"], 3)

    def test_changed_object_byte_is_rejected(self):
        self.files[self.file] = b"altered"
        self.assert_rejects()

    def test_changed_sql_byte_is_rejected(self):
        self.files["payload/database/data.sql"] += b"-- tamper\n"
        self.assert_rejects()

    def test_missing_object_is_rejected(self):
        del self.files[self.file]
        self.assert_rejects()

    def test_unexpected_object_is_rejected(self):
        self.files["payload/secret.txt"] = b"should not be included"
        self.assert_rejects()

    def test_wrong_project_is_rejected(self):
        self.files["payload/PROJECT_REF"] = b"ovzijmqrnsgcmryinkfa\n"
        self.assert_rejects()

    def test_changed_storage_inventory_is_rejected(self):
        wrong = dict(self.inventory)
        wrong["objects"] = []
        self.files["payload/inventory-after.json"] = json.dumps(wrong).encode()
        self.assert_rejects()

    def test_symlink_in_archive_is_rejected(self):
        self.build(extra_link=True)
        with self.assertRaises(UnsafeBackup):
            verify_archive(self.path)

    def test_duplicate_file_is_rejected(self):
        with tarfile.open(self.path, "w:gz") as archive:
            for name, data in self.files.items():
                info = tarfile.TarInfo(name)
                info.size = len(data)
                archive.addfile(info, io.BytesIO(data))
            duplicate = tarfile.TarInfo(self.file)
            duplicate.size = 2
            archive.addfile(duplicate, io.BytesIO(b"xx"))
        with self.assertRaises(UnsafeBackup):
            verify_archive(self.path)


if __name__ == "__main__":
    unittest.main()
