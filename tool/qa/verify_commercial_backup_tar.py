#!/usr/bin/env python3
"""Vérifier localement une archive SQL + Storage déchiffrée de Petit Filet.

Ne contacte aucune API, n'écrit aucune donnée et n'extrait jamais de chemin.
Toute anomalie entraîne un échec. Ne jamais publier l'archive déchiffrée.
"""
from __future__ import annotations

import hashlib
import json
import re
import sys
import tarfile
from pathlib import Path

from commercial_backup_bundle import PROJECT_REF, UnsafeBackup, valid_relpath

DATA_PATHS = {
    "payload/database/roles.sql",
    "payload/database/schema.sql",
    "payload/database/data.sql",
}
META_PATHS = {
    "payload/database/sha256sums.txt",
    "payload/inventory-before.json",
    "payload/inventory-after.json",
    "payload/manifest.json",
    "payload/PROJECT_REF",
}
SHA_LINE = re.compile(r"^([0-9a-f]{64})  ([a-z]+\.sql)$")
MAX_META_BYTES = 64 * 1024 * 1024


def _metadata(tar: tarfile.TarFile, name: str) -> bytes:
    member = tar.getmember(name)
    if not member.isfile() or member.size > MAX_META_BYTES:
        raise UnsafeBackup("Métadonnée illisible ou trop volumineuse.")
    reader = tar.extractfile(member)
    if reader is None:
        raise UnsafeBackup("Métadonnée absente.")
    with reader:
        return reader.read(MAX_META_BYTES + 1)


def verify_archive(path: Path) -> dict:
    if not path.is_file():
        raise UnsafeBackup("Archive de sauvegarde absente.")
    try:
        archive = tarfile.open(path, mode="r:gz")
    except (tarfile.TarError, OSError) as exc:
        raise UnsafeBackup("Archive tar/gzip invalide.") from exc
    with archive:
        actual = {}
        for member in archive:
            n = member.name
            # GNU tar, utilisé par le workflow, écrit d'abord ce dossier.
            # Seul le dossier exact est admis ; fichier/lien restent refusés.
            if n == "payload" and member.isdir():
                continue
            if not n.startswith("payload/") or "\\" in n:
                raise UnsafeBackup("Entrée d'archive hors périmètre.")
            if any(part in ("", ".", "..") for part in n.rstrip("/").split("/")):
                raise UnsafeBackup("Chemin d'archive interdit.")
            if not member.isfile() and not member.isdir():
                raise UnsafeBackup("Lien, périphérique ou entrée spéciale interdits.")
            if member.isdir():
                continue
            if n in actual:
                raise UnsafeBackup("Entrée d'archive dupliquée.")
            reader = archive.extractfile(member)
            if reader is None:
                raise UnsafeBackup("Fichier illisible.")
            digest = hashlib.sha256()
            seen_size = 0
            with reader:
                while part := reader.read(1024 * 1024):
                    digest.update(part)
                    seen_size += len(part)
            if seen_size != member.size:
                raise UnsafeBackup("Taille d'un fichier incohérente.")
            actual[n] = (digest.hexdigest(), seen_size)

        if not DATA_PATHS | META_PATHS <= actual.keys():
            raise UnsafeBackup("Archive incomplète : SQL ou métadonnées manquants.")
        project_ref = _metadata(archive, "payload/PROJECT_REF").decode("utf-8")
        if project_ref.strip() != PROJECT_REF:
            raise UnsafeBackup("Archive d'un autre projet refusée.")
        try:
            before = json.loads(_metadata(archive, "payload/inventory-before.json"))
            after = json.loads(_metadata(archive, "payload/inventory-after.json"))
            manifest = json.loads(_metadata(archive, "payload/manifest.json"))
        except (ValueError, UnicodeDecodeError) as exc:
            raise UnsafeBackup("Inventaire ou manifeste illisible.") from exc
        if before != after or not isinstance(before, dict):
            raise UnsafeBackup("Inventaires Storage différents.")
        if not isinstance(manifest, dict) or manifest.get("project_ref") != PROJECT_REF:
            raise UnsafeBackup("Manifeste sans identité commerciale.")
        objects = manifest.get("objects")
        inventory = before.get("objects")
        buckets = before.get("buckets")
        if not isinstance(objects, list) or not isinstance(inventory, list) or not isinstance(buckets, list):
            raise UnsafeBackup("Manifeste et inventaire incomplets.")
        if manifest.get("object_count") != len(objects) or manifest.get("bucket_count") != len(buckets):
            raise UnsafeBackup("Compteurs Storage incohérents.")

        ref_objects = {}
        for item in inventory:
            if not isinstance(item, dict):
                raise UnsafeBackup("Objet inventorié invalide.")
            bucket = item.get("bucket_id")
            name = valid_relpath(item.get("name"))
            if bucket not in buckets:
                raise UnsafeBackup("Objet lié à un bucket inconnu.")
            key = (bucket, name)
            if key in ref_objects:
                raise UnsafeBackup("Chemin Storage dupliqué dans l'inventaire.")
            ref_objects[key] = item
        expected_storage = set()
        for entry in objects:
            if not isinstance(entry, dict):
                raise UnsafeBackup("Entrée de manifeste invalide.")
            bucket = entry.get("bucket_id")
            name = valid_relpath(entry.get("name"))
            key = (bucket, name)
            if key not in ref_objects:
                raise UnsafeBackup("Fichier sans métadonnées Storage.")
            reference = ref_objects[key]
            if entry.get("storage_id") != reference.get("id") or entry.get("updated_at") != reference.get("updated_at"):
                raise UnsafeBackup("Métadonnées d'objet incohérentes.")
            file = f"payload/storage/{bucket}/{name}"
            if file in expected_storage:
                raise UnsafeBackup("Fichier Storage dupliqué dans le manifeste.")
            expected_storage.add(file)
            if file not in actual or actual[file] != (entry.get("sha256"), entry.get("bytes")):
                raise UnsafeBackup("Octets Storage corrompus ou manquants.")
        if len(expected_storage) != len(ref_objects):
            raise UnsafeBackup("Inventaire de fichiers incomplet.")

        sql_checksums = _metadata(
            archive, "payload/database/sha256sums.txt"
        ).decode("utf-8").splitlines()
        expected_sql = {}
        for line in sql_checksums:
            match = SHA_LINE.fullmatch(line)
            if match is None or match.group(2) in expected_sql:
                raise UnsafeBackup("Empreintes SQL malformées.")
            expected_sql[match.group(2)] = match.group(1)
        if set(expected_sql) != {"roles.sql", "schema.sql", "data.sql"}:
            raise UnsafeBackup("Liste d'exports SQL incomplète.")
        for name, digest in expected_sql.items():
            file = f"payload/database/{name}"
            if actual[file][0] != digest or actual[file][1] == 0:
                raise UnsafeBackup("Export SQL absent, vide ou modifié.")
        if set(actual) != DATA_PATHS | META_PATHS | expected_storage:
            raise UnsafeBackup("Archive contenant un fichier imprévu.")
        return {"project_ref": PROJECT_REF, "objects_checked": len(expected_storage), "sql_files_checked": 3}


def main(args: list[str]) -> int:
    if len(args) != 1:
        print("Utilisation : verify_commercial_backup_tar.py archive-déchiffrée.tar.gz")
        return 2
    try:
        summary = verify_archive(Path(args[0]))
    except (UnsafeBackup, OSError, ValueError, UnicodeError, tarfile.TarError) as exc:
        # Les messages UnsafeBackup sont fixes et ne contiennent aucun nom
        # privé ; les autres exceptions peuvent contenir un chemin du runner.
        reason = str(exc) if isinstance(exc, UnsafeBackup) else type(exc).__name__
        print(f"::error::Restauration préliminaire refusée : {reason}")
        return 1
    print(
        f"Archive commerciale cohérente : {summary['sql_files_checked']} exports SQL,"
        f" {summary['objects_checked']} objets Storage vérifiés."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
