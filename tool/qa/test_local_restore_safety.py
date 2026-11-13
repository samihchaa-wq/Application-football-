"""Tests de sécurité et d'intégrité du drill local DB + Storage."""
import io
import sys
import tarfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from local_restore_drill import assert_local, archive_bytes, extract_archive


class RestoreDrillTests(unittest.TestCase):
    def test_local_only(self):
        assert_local("http://127.0.0.1:54321")
        for url in ("https://jvxkhgdopslctpcjrhzw.supabase.co",
                    "http://localhost:54321", "http://127.0.0.1:54320"):
            with self.subTest(url=url), self.assertRaises(RuntimeError):
                assert_local(url)

    def test_roundtrip_exact_files(self):
        entries = {
            "fixtures.csv": b"label,actor_id,path,digest\n",
            "alpha.png": b"image-1",
            "bravo.png": b"image-2",
            "manifest.json": b'{"alpha":"a"}',
        }
        self.assertEqual(extract_archive(archive_bytes(entries)), entries)

    def test_refuse_missing_files(self):
        with self.assertRaises(AssertionError):
            extract_archive(archive_bytes({"fixtures.csv": b"test"}))

    def test_refuse_tar_path_traversal(self):
        archive = io.BytesIO()
        with tarfile.open(fileobj=archive, mode="w:gz") as tar:
            item = tarfile.TarInfo("../../outside.txt")
            item.size = 3
            tar.addfile(item, io.BytesIO(b"bad"))
        with self.assertRaises(AssertionError):
            extract_archive(archive.getvalue())


if __name__ == "__main__":
    unittest.main()
