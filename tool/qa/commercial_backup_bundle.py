#!/usr/bin/env python3
"""Preflight + integrity manifest for Petit Filet's OFF-SITE commercial backup.

No network or database calls in this module. The workflow supplies read-only
PostgreSQL inventory files; Storage bytes are downloaded by Supabase CLI.
Never use this module on the original AS Grinta project.
"""
from __future__ import annotations

import hashlib
import json
import os
import re
import sys
from pathlib import Path, PurePosixPath
from urllib.parse import urlsplit, unquote

PROJECT_REF = "jvxkhgdopslctpcjrhzw"
BUCKET_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,100}$")


class UnsafeBackup(ValueError):
    """A backup must stop if integrity or isolation cannot be guaranteed."""


def validate_database_url(value: str, project_ref: str = PROJECT_REF) -> None:
    try:
        url = urlsplit(value)
        host = (url.hostname or "").lower()
        user = url.username or ""
        if url.scheme not in ("postgresql", "postgres") or not url.password:
            raise UnsafeBackup("Connexion PostgreSQL invalide.")
        if url.path not in ("/postgres", "/postgres/"):
            raise UnsafeBackup("Base de données non reconnue.")
        direct = host == f"db.{project_ref}.supabase.co" and user == "postgres"
        pooler = (
            host.endswith(".pooler.supabase.com")
            and user == f"postgres.{project_ref}"
        )
        if not (direct or pooler):
            raise UnsafeBackup("L'adresse DB ne désigne pas Petit Filet commercial.")
        if url.query or url.fragment:
            raise UnsafeBackup("Options DB non autorisées dans le secret.")
    except ValueError as exc:
        if isinstance(exc, UnsafeBackup):
            raise
        raise UnsafeBackup("Connexion PostgreSQL malformée.") from None


def database_password(value: str) -> str:
    """Read the existing commercial DB URL password; never print in logs.

    The workflow only captures this value in an untraced shell assignment,
    immediately masks it and uses it to authenticate the linked CLI.
    """
    validate_database_url(value)
    password = unquote(urlsplit(value).password or "")
    if not password or any(ord(c) < 32 or ord(c) == 127 for c in password):
        raise UnsafeBackup("Mot de passe PostgreSQL invalide.")
    return password


def check_environment(environment: dict[str, str]) -> None:
    if environment.get("SUPABASE_PROJECT_REF") != PROJECT_REF:
        raise UnsafeBackup("Projet Supabase commercial incorrect.")
    database_password(environment.get("PRODUCTION_DB_URL", ""))
    if not environment.get("SUPABASE_ACCESS_TOKEN"):
        raise UnsafeBackup("Jeton Supabase commercial non configuré.")
    phrase = environment.get("BACKUP_PASSPHRASE", "")
    if len(phrase) < 48 or len(set(phrase)) < 12:
        raise UnsafeBackup("Phrase de récupération trop faible : minimum 48 caractères aléatoires.")


def valid_relpath(name: object) -> str:
    if not isinstance(name, str) or not name:
        raise UnsafeBackup("Nom de fichier Storage invalide.")
    if "\\" in name or any(ord(c) < 32 for c in name):
        raise UnsafeBackup("Chemin Storage interdit.")
    parsed = PurePosixPath(name)
    if name.startswith("/") or any(p in (".", "..", "") for p in name.split("/")):
        raise UnsafeBackup("Chemin Storage hors du répertoire prévu.")
    if parsed.is_absolute():
        raise UnsafeBackup("Chemin Storage absolu refusé.")
    return name


def read_inventory(file: Path) -> dict:
    data = json.loads(file.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise UnsafeBackup("Inventaire DB absent ou invalide.")
    buckets, objects = data.get("buckets"), data.get("objects")
    if not isinstance(buckets, list) or not isinstance(objects, list):
        raise UnsafeBackup("Inventaire DB incomplet.")
    if len(set(buckets)) != len(buckets):
        raise UnsafeBackup("Buckets dupliqués.")
    for bucket in buckets:
        if not isinstance(bucket, str) or not BUCKET_RE.fullmatch(bucket):
            raise UnsafeBackup("Nom de bucket invalide.")
    seen = set()
    for item in objects:
        if not isinstance(item, dict):
            raise UnsafeBackup("Objet Storage invalide.")
        bucket = item.get("bucket_id")
        name = valid_relpath(item.get("name"))
        if bucket not in buckets:
            raise UnsafeBackup("Objet d'un bucket absent.")
        if not isinstance(item.get("id"), str) or not item["id"]:
            raise UnsafeBackup("Identifiant Storage absent.")
        if not isinstance(item.get("updated_at"), str):
            raise UnsafeBackup("Horodatage Storage absent.")
        if (bucket, name) in seen:
            raise UnsafeBackup("Objet Storage dupliqué.")
        seen.add((bucket, name))
    return data


def write_bucket_list(inventory: Path, destination: Path) -> int:
    data = read_inventory(inventory)
    used = {item["bucket_id"] for item in data["objects"]}
    destination.write_text(
        "".join(f"{bucket}\n" for bucket in sorted(used)), encoding="utf-8"
    )
    return len(used)


def verify_and_manifest(
    before: Path, after: Path, root: Path, destination: Path
) -> dict:
    a = read_inventory(before)
    b = read_inventory(after)
    # Fails closed if an object was uploaded, removed or replaced mid-backup.
    if a != b:
        raise UnsafeBackup("Storage modifié pendant la copie : nouvelle sauvegarde nécessaire.")
    if not root.is_dir() or root.is_symlink():
        raise UnsafeBackup("Répertoire Storage manquant.")
    expected = {
        (o["bucket_id"], o["name"]): o for o in a["objects"]
    }
    captured: dict[tuple[str, str], Path] = {}
    for file in root.rglob("*"):
        if file.is_symlink():
            raise UnsafeBackup("Lien symbolique interdit dans la sauvegarde.")
        if file.is_file():
            relative = file.relative_to(root).parts
            if len(relative) < 2:
                raise UnsafeBackup("Objet téléchargé sans bucket.")
            key = (relative[0], "/".join(relative[1:]))
            if key in captured:
                raise UnsafeBackup("Fichier dupliqué.")
            captured[key] = file
    if set(captured) != set(expected):
        raise UnsafeBackup(
            "Copie Storage incomplète ou fichiers supplémentaires : "
            f"{len(expected)} attendus, {len(captured)} téléchargés."
        )
    entries = []
    for bucket, name in sorted(expected):
        file = captured[(bucket, name)]
        digest = hashlib.sha256()
        with file.open("rb") as stream:
            while chunk := stream.read(1024 * 1024):
                digest.update(chunk)
        entries.append({
            "bucket_id": bucket, "name": name,
            "storage_id": expected[(bucket, name)]["id"],
            "updated_at": expected[(bucket, name)]["updated_at"],
            "sha256": digest.hexdigest(), "bytes": file.stat().st_size,
        })
    manifest = {
        "version": 1, "project_ref": PROJECT_REF,
        "bucket_count": len(a["buckets"]),
        "object_count": len(entries),
        "objects": entries,
    }
    destination.write_text(
        json.dumps(manifest, ensure_ascii=False, sort_keys=True, indent=2) + "\n",
        encoding="utf-8",
    )
    return manifest


def main(arguments: list[str]) -> int:
    try:
        if arguments == ["preflight"]:
            check_environment(dict(os.environ))
            print("Prévol sauvegarde commercial validé.")
        elif arguments == ["db-password"]:
            # Sensible : cette sortie est capturée, JAMAIS envoyée dans les logs.
            print(database_password(os.environ.get("PRODUCTION_DB_URL", "")))
        elif len(arguments) == 3 and arguments[0] == "buckets":
            count = write_bucket_list(Path(arguments[1]), Path(arguments[2]))
            print(f"Buckets avec objets à copier : {count}")
        elif len(arguments) == 5 and arguments[0] == "verify":
            manifest = verify_and_manifest(*(Path(path) for path in arguments[1:]))
            print(
                f"Copie DB + Storage : {manifest['object_count']} "
                "objets Storage contrôlés et manifestés."
            )
        else:
            raise UnsafeBackup("Commande de sauvegarde non reconnue.")
        return 0
    except (UnsafeBackup, OSError, ValueError, TypeError) as exc:
        print(f"::error::Sauvegarde refusée ({type(exc).__name__}) : {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
