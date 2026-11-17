"""Chiffrement réel de données fictives ; aucune connexion distante."""
import hashlib
import shutil
import subprocess
import unittest
from pathlib import Path
from unittest.mock import patch
import test_verify_commercial_backup_tar as fixtures
from check_encrypted_backup import check_encrypted
from commercial_backup_bundle import UnsafeBackup


@unittest.skipUnless(shutil.which('gpg'), 'GPG requis pour les tests cryptographiques')
class EncryptedBackupTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Ne jamais lancer un démon persistant avec capture_output=True :
        # ses descripteurs hérités peuvent bloquer le runner indéfiniment.
        import tempfile
        with tempfile.TemporaryDirectory() as folder:
            home = Path(folder) / 'gnupg'
            home.mkdir(mode=0o700)
            sample = Path(folder) / 'probe.txt'
            encrypted = Path(folder) / 'probe.gpg'
            sample.write_bytes(b'local-only-probe')
            try:
                probe = subprocess.run(
                    ['gpg', '--no-options', '--homedir', str(home), '--batch',
                     '--no-tty', '--pinentry-mode', 'loopback', '--passphrase-fd',
                     '0', '--symmetric', '--output', str(encrypted), str(sample)],
                    input=b'local-probe-secret\n', capture_output=True, timeout=20,
                )
            except (OSError, subprocess.TimeoutExpired) as exc:
                raise unittest.SkipTest('GPG local indisponible ou trop lent') from exc
            if probe.returncode or not encrypted.is_file():
                raise unittest.SkipTest('Chiffrement GPG local indisponible')

    def setUp(self):
        self.fixture = fixtures.VerifyCommercialBackupTarTests()
        self.fixture.setUp()
        self.addCleanup(self.fixture.doCleanups)
        self.fixture.build()
        self.phrase = b'fictive-recovery-phrase-for-local-unit-test-only'
        self.encrypted = self.fixture.path.parent / 'fixture.gpg'
        home = self.fixture.path.parent / 'gnupg'
        home.mkdir(mode=0o700)
        subprocess.run(['gpg', '--no-options', '--homedir', str(home), '--batch',
                        '--pinentry-mode', 'loopback', '--passphrase-fd', '0',
                        '--symmetric', '--output', str(self.encrypted),
                        str(self.fixture.path)], input=self.phrase+b'\n',
                       capture_output=True, check=True, timeout=30)
        self.digest = hashlib.sha256(self.encrypted.read_bytes()).hexdigest()

    def test_real_decryption_and_integrity(self):
        result = check_encrypted(self.encrypted, self.digest, self.phrase)
        self.assertEqual(result['objects_checked'], 1)
        self.assertFalse(result['full_restore_performed'])

    def test_tampering_stops_before_decryption(self):
        with self.encrypted.open('ab') as file:
            file.write(b'tamper')
        with patch('check_encrypted_backup.subprocess.run') as run:
            with self.assertRaises(UnsafeBackup):
                check_encrypted(self.encrypted, self.digest, self.phrase)
            run.assert_not_called()

    def test_wrong_phrase_is_sanitized(self):
        with self.assertRaisesRegex(UnsafeBackup, 'Déchiffrement refusé') as result:
            check_encrypted(self.encrypted, self.digest, b'wrong-secret')
        self.assertNotIn('wrong-secret', str(result.exception))

    def test_temporary_plaintext_removed_after_success_and_failure(self):
        import tempfile
        real = tempfile.TemporaryDirectory
        folders = []
        def tracked(*args, **kwargs):
            temp = real(*args, **kwargs)
            folders.append(Path(temp.name))
            return temp
        with patch('check_encrypted_backup.tempfile.TemporaryDirectory', side_effect=tracked):
            check_encrypted(self.encrypted, self.digest, self.phrase)
            with self.assertRaises(UnsafeBackup):
                check_encrypted(self.encrypted, self.digest, b'wrong')
        self.assertTrue(folders)
        self.assertTrue(all(not folder.exists() for folder in folders))

    def test_decrypted_corruption_rejected(self):
        self.fixture.files[self.fixture.file] = b'changed-photo'
        self.fixture.build()
        self.encrypted.unlink()
        subprocess.run(['gpg','--no-options','--homedir',str(self.fixture.path.parent/'gnupg'),
                        '--batch','--pinentry-mode','loopback','--passphrase-fd','0',
                        '--symmetric','--output',str(self.encrypted),str(self.fixture.path)],
                       input=self.phrase+b'\n',capture_output=True,check=True)
        digest = hashlib.sha256(self.encrypted.read_bytes()).hexdigest()
        with self.assertRaises(UnsafeBackup):
            check_encrypted(self.encrypted, digest, self.phrase)

class OfflineSafetyTests(unittest.TestCase):
    def setUp(self):
        self.fixture = fixtures.VerifyCommercialBackupTarTests()
        self.fixture.setUp()
        self.addCleanup(self.fixture.doCleanups)
        self.fixture.build()
        self.encrypted = self.fixture.path.parent / 'fake.gpg'
        self.encrypted.write_bytes(b'simulated-ciphertext')
        self.digest = hashlib.sha256(self.encrypted.read_bytes()).hexdigest()

    def test_hash_rejection_never_launches_process(self):
        with patch('check_encrypted_backup.subprocess.run') as run:
            with self.assertRaises(UnsafeBackup):
                check_encrypted(self.encrypted, '0'*64, b'phrase')
            run.assert_not_called()

    def test_secret_is_in_stdin_not_arguments(self):
        outputs = []
        def decrypt(argv, **kwargs):
            self.assertNotIn('secret-fixture', ' '.join(argv))
            self.assertEqual(kwargs['input'], b'secret-fixture\n')
            target = Path(argv[argv.index('--output')+1])
            outputs.append(target)
            target.write_bytes(self.fixture.path.read_bytes())
            return subprocess.CompletedProcess(argv, 0, b'', b'')
        with patch('check_encrypted_backup.subprocess.run', side_effect=decrypt):
            result = check_encrypted(self.encrypted, self.digest, b'secret-fixture')
        self.assertFalse(result['full_restore_performed'])
        self.assertTrue(all(not p.exists() for p in outputs))

    def test_process_failure_never_exposes_stderr(self):
        with patch('check_encrypted_backup.subprocess.run', return_value=
                   subprocess.CompletedProcess([], 2, b'', b'private-data')):
            with self.assertRaises(UnsafeBackup) as error:
                check_encrypted(self.encrypted, self.digest, b'phrase')
        self.assertNotIn('private-data', str(error.exception))

    def test_symlink_refused(self):
        link = self.encrypted.parent / 'link.gpg'
        link.symlink_to(self.encrypted)
        with self.assertRaises(UnsafeBackup):
            check_encrypted(link, self.digest, b'phrase')

    def test_multiline_secret_refused(self):
        with self.assertRaises(UnsafeBackup):
            check_encrypted(self.encrypted, self.digest, b'one\ntwo')

if __name__ == '__main__':
    unittest.main()
