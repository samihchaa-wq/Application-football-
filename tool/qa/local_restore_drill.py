#!/usr/bin/env python3
"""Exercice de restauration PostgreSQL + objets Storage fictifs, local uniquement.

Une archive GPG locale contient des lignes COPY et les OCTETS des deux fichiers
d'un bucket privé. Les sources sont effacées puis récupérées, hash par hash.
NE CONSTITUE PAS une restauration complète d'un projet Supabase réel.
"""
from __future__ import annotations

import hashlib
import io
import json
import os
import secrets
import subprocess
import sys
import tarfile
import tempfile
import uuid
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen

API = "http://127.0.0.1:54321"
DB = "postgresql://postgres:postgres@127.0.0.1:54322/postgres"
BUCKET = "profile-photos"
PNG = bytes.fromhex(
    "89504e470d0a1a0a0000000d4948445200000001000000010804000000b51c0c02"
    "0000000b4944415478da63fcff1f0003030200efbf64bf0000000049454e44ae426082"
)


def parse_env(text: str) -> dict[str, str]:
    return {k: v.strip().strip('"').strip("'")
            for line in text.splitlines() if "=" in line and not line.startswith("#")
            for k, v in [line.split("=", 1)]}


def assert_local(url: str) -> None:
    if url.rstrip("/") != API:
        raise RuntimeError("Refus: restauration simulée exclusivement sur 127.0.0.1:54321.")


def command(argv: list[str], data: bytes | None = None) -> bytes:
    p = subprocess.run(argv, input=data, capture_output=True, timeout=60)
    if p.returncode:
        raise AssertionError("Echec d'une étape locale de sauvegarde/restauration.")
    return p.stdout


def psql(sql: str) -> str:
    return command(["psql", "-X", "-v", "ON_ERROR_STOP=1", "-At", DB, "-c", sql]).decode().strip()


def storage(api: str, key: str, method: str, path: str,
            data: bytes | None = None) -> tuple[int, bytes]:
    req = Request(api + path, data=data, method=method,
                  headers={"apikey": key, "Authorization": "Bearer " + key,
                           "Content-Type": "image/png"})
    try:
        with urlopen(req, timeout=20) as r:
            return r.status, r.read(200000)
    except HTTPError as e:
        return e.code, e.read(200000)


def check_ok(status: int, label: str) -> None:
    if not 200 <= status < 300:
        raise AssertionError(f"{label}: HTTP {status}")


def archive_bytes(entries: dict[str, bytes]) -> bytes:
    output = io.BytesIO()
    with tarfile.open(fileobj=output, mode="w:gz") as tar:
        for name, raw in sorted(entries.items()):
            meta = tarfile.TarInfo(name)
            meta.size = len(raw)
            meta.mode = 0o600
            tar.addfile(meta, io.BytesIO(raw))
    return output.getvalue()


def extract_archive(raw: bytes) -> dict[str, bytes]:
    with tarfile.open(fileobj=io.BytesIO(raw), mode="r:gz") as tar:
        expected = {"fixtures.csv", "alpha.png", "bravo.png", "manifest.json"}
        names = {member.name for member in tar.getmembers()}
        if names != expected or any(not m.isfile() for m in tar.getmembers()):
            raise AssertionError("Archive incohérente ou entrée non prévue.")
        return {m.name: tar.extractfile(m).read() for m in tar.getmembers()}


def main(env_file: Path) -> None:
    env = parse_env(env_file.read_text())
    api = env.get("API_URL", "")
    assert_local(api)
    key = env.get("SERVICE_ROLE_KEY", "")
    if not key:
        raise RuntimeError("Clé de service de la pile locale manquante.")

    alpha, bravo = str(uuid.uuid4()), str(uuid.uuid4())
    paths = {
        "alpha": f"/storage/v1/object/{BUCKET}/{alpha}/fixture.png",
        "bravo": f"/storage/v1/object/{BUCKET}/{bravo}/fixture.png",
    }
    private_paths = {
        label: path.replace("/storage/v1/object/",
                            "/storage/v1/object/authenticated/", 1)
        for label, path in paths.items()
    }

    # Seuls deux objets fictifs sont créés ; aucun chemin d'un club réel.
    for label, path in paths.items():
        status, _ = storage(api, key, "POST", path, PNG)
        check_ok(status, "Création Storage " + label)

    files = {}
    for label, path in private_paths.items():
        status, body = storage(api, key, "GET", path)
        check_ok(status, "Lecture avant sauvegarde " + label)
        if body != PNG:
            raise AssertionError("Source Storage inattendue.")
        files[label] = body

    psql("create schema if not exists qa_restore; "
         "create table qa_restore.fixtures "
         "(label text primary key, actor_id uuid not null, path text not null, digest text not null)")
    for label, uid in (("alpha", alpha), ("bravo", bravo)):
        digest = hashlib.sha256(files[label]).hexdigest()
        psql(f"insert into qa_restore.fixtures values "
             f"('{label}', '{uid}'::uuid, '{paths[label]}', '{digest}')")
    rows = command(["psql", "-X", "-v", "ON_ERROR_STOP=1", "-q", "-At",
                    DB, "-c", "COPY (select label,actor_id,path,digest from qa_restore.fixtures order by label) TO STDOUT WITH (FORMAT csv, HEADER true)"])
    if b"alpha" not in rows or b"bravo" not in rows:
        raise AssertionError("Export PostgreSQL partiel.")

    manifest = {label: hashlib.sha256(data).hexdigest()
                for label, data in files.items()}
    entries = {
        "fixtures.csv": rows,
        "alpha.png": files["alpha"],
        "bravo.png": files["bravo"],
        "manifest.json": json.dumps(manifest, sort_keys=True).encode(),
    }
    with tempfile.TemporaryDirectory(prefix="petit-filet-restore-") as tmp:
        encrypted = str(Path(tmp) / "backup.tar.gz.gpg")
        password = Path(tmp) / "passphrase"
        password.write_text(secrets.token_urlsafe(48))
        os.chmod(password, 0o600)
        command(["gpg", "--batch", "--yes", "--pinentry-mode", "loopback",
                 "--passphrase-file", str(password), "--symmetric",
                 "--cipher-algo", "AES256", "--output", encrypted], archive_bytes(entries))

        # Détruire LES DONNEES FICTIVES pour prouver la vraie restauration.
        for label, path in paths.items():
            status, _ = storage(api, key, "DELETE", path)
            check_ok(status, "Effacement objet " + label)
        psql("drop schema qa_restore cascade")
        if psql("select count(*) from information_schema.tables "
                "where table_schema='qa_restore'") != "0":
            raise AssertionError("L'objet DB n'a pas été supprimé.")
        for label, path in private_paths.items():
            status, _ = storage(api, key, "GET", path)
            if status < 400:
                raise AssertionError("L'objet Storage n'a pas été supprimé.")

        decrypted = command(["gpg", "--batch", "--yes", "--pinentry-mode", "loopback",
                             "--passphrase-file", str(password),
                             "--decrypt", encrypted])
        restored = extract_archive(decrypted)
        if restored["fixtures.csv"] != rows:
            raise AssertionError("Export SQL altéré dans l'archive.")
        expected = json.loads(restored["manifest.json"])
        psql("create schema qa_restore; "
             "create table qa_restore.fixtures "
             "(label text primary key, actor_id uuid not null, path text not null, digest text not null)")
        copy_script = (
            "COPY qa_restore.fixtures(label,actor_id,path,digest) FROM STDIN "
            "WITH (FORMAT csv, HEADER true);\n"
        ).encode() + restored["fixtures.csv"] + b"\\.\n"
        command(["psql", "-X", "-v", "ON_ERROR_STOP=1", "-q", DB, "-f", "-"], copy_script)
        if psql("select count(*) from qa_restore.fixtures") != "2":
            raise AssertionError("Restauration incomplète des deux lignes DB.")
        for label, path in paths.items():
            original = restored[label + ".png"]
            if hashlib.sha256(original).hexdigest() != expected[label]:
                raise AssertionError("Empreinte du fichier dans la sauvegarde invalide.")
            status, _ = storage(api, key, "POST", path, original)
            check_ok(status, "Réimport Storage " + label)
            status, current = storage(api, key, "GET", private_paths[label])
            check_ok(status, "Relire après restauration " + label)
            if hashlib.sha256(current).hexdigest() != expected[label]:
                raise AssertionError("Octets restaurés divergents.")
            if psql(f"select digest from qa_restore.fixtures where label='{label}'") != expected[label]:
                raise AssertionError("Restauration PostgreSQL et Storage désynchronisée.")

    print("PASS : archive AES256 chiffrée et déchiffrée (données fictives).")
    print("PASS : lignes PostgreSQL exportées, effacées puis restaurées.")
    print("PASS : fichiers Storage privés effacés, restaurés et SHA-256 vérifiés.")
    print("LIMITATION : ne constitue PAS une restauration complète d'un projet Supabase.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage : local_restore_drill.py STATUS_LOCAL")
    main(Path(sys.argv[1]))
