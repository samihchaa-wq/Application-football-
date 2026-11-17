#!/usr/bin/env python3
"""Contrôle hors réseau d'une sauvegarde chiffrée ; ne restaure aucune base.
La phrase est lue sur stdin, jamais dans les arguments ou les journaux.
"""
from __future__ import annotations
import argparse
import hashlib
import re
import subprocess
import tempfile
from pathlib import Path
from commercial_backup_bundle import UnsafeBackup
from verify_commercial_backup_tar import verify_archive


def check_encrypted(path: Path, expected_sha256: str, passphrase: bytes) -> dict:
    if not re.fullmatch(r'[0-9a-f]{64}', expected_sha256):
        raise UnsafeBackup('Empreinte SHA-256 attendue invalide.')
    if not passphrase or b'\n' in passphrase or b'\r' in passphrase:
        raise UnsafeBackup('Phrase de récupération absente ou multiligne.')
    if path.is_symlink() or not path.is_file():
        raise UnsafeBackup('Archive chiffrée absente ou lien interdit.')
    # Copie stable : les octets déchiffrés sont ceux qui ont été hachés.
    with tempfile.TemporaryDirectory(prefix='pf-backup-check-') as directory:
        folder = Path(directory)
        encrypted = folder / 'archive.gpg'
        digest = hashlib.sha256()
        with path.open('rb') as source, encrypted.open('xb') as target:
            encrypted.chmod(0o600)
            for block in iter(lambda: source.read(1024 * 1024), b''):
                digest.update(block)
                target.write(block)
        if digest.hexdigest() != expected_sha256:
            raise UnsafeBackup('Empreinte de la sauvegarde chiffrée différente.')
        plain = folder / 'archive.tar.gz'
        try:
            result = subprocess.run(
                ['gpg', '--no-options', '--homedir', str(folder), '--batch',
                 '--no-tty', '--pinentry-mode', 'loopback', '--passphrase-fd', '0',
                 '--output', str(plain), '--decrypt', str(encrypted)],
                input=passphrase + b'\n', capture_output=True, timeout=1800,
            )
        except (OSError, subprocess.TimeoutExpired) as exc:
            raise UnsafeBackup('Déchiffrement indisponible ou délai dépassé.') from exc
        if result.returncode:
            raise UnsafeBackup('Déchiffrement refusé ; aucun détail privé affiché.')
        plain.chmod(0o600)
        summary = verify_archive(plain)
    return {**summary, 'encrypted_sha256': expected_sha256,
            'full_restore_performed': False}


def main() -> int:
    import sys
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('encrypted_archive', type=Path)
    parser.add_argument('--sha256', required=True,
                        help='Empreinte indépendante du fichier .gpg, pas du ZIP GitHub')
    args = parser.parse_args()
    try:
        phrase = sys.stdin.buffer.readline(16385).rstrip(b'\r\n')
        if len(phrase) > 16384:
            raise UnsafeBackup('Phrase de récupération trop longue.')
        summary = check_encrypted(args.encrypted_archive, args.sha256, phrase)
    except (UnsafeBackup, OSError, ValueError) as exc:
        reason = str(exc) if isinstance(exc, UnsafeBackup) else 'Erreur locale de lecture.'
        print('REFUS : ' + reason)
        return 1
    print(f"Archive contrôlée : {summary['sql_files_checked']} exports SQL, "
          f"{summary['objects_checked']} objets. Restauration complète NON exécutée.")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
