#!/usr/bin/env python3
"""Export SQL commercial avec les clients PostgreSQL du même hôte que psql.

Lecture seule. Les filtres viennent de Supabase CLI 2.111.0 (MIT, vendus dans
vendor/). La même URI libpq validée est transmise directement aux clients, comme pour
l’inventaire psql. Elle reste en mémoire du runner éphémère, sans journalisation
des arguments ni écriture dans les exports.
"""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

from commercial_backup_bundle import UnsafeBackup, normalize_database_url

VENDOR = Path(__file__).resolve().parent / "vendor" / "supabase_cli_2_111"


def database_environment(url: str) -> dict[str, str]:
    return {
        "PATH": os.environ.get("PATH", os.defpath),
        "LC_ALL": "C.UTF-8",
        "BACKUP_DATABASE_URI": normalize_database_url(url),
        "PGCONNECT_TIMEOUT": "30",
    }


def failure_reason(stderr: bytes) -> str:
    diagnostic = stderr.lower()
    if b"password authentication" in diagnostic or b"no password supplied" in diagnostic:
        return "authentification refusée"
    if b"permission denied" in diagnostic:
        return "permissions insuffisantes"
    if b"connection" in diagnostic or b"could not connect" in diagnostic:
        return "connexion indisponible"
    return "échec du client"


def check_clients(environment: dict[str, str]) -> None:
    for binary in ("psql", "pg_dump", "pg_dumpall", "bash", "sed", "uniq"):
        if shutil.which(binary, path=environment["PATH"]) is None:
            raise UnsafeBackup("Client PostgreSQL ou utilitaire local manquant.")
    server = subprocess.run(
        ["psql", environment["BACKUP_DATABASE_URI"], "-X", "-qAt", "-v",
         "ON_ERROR_STOP=1", "-c", "show server_version_num"],
        env=environment, capture_output=True, timeout=60,
    )
    if server.returncode:
        reason = failure_reason(server.stderr)
        raise UnsafeBackup(f"Lecture de la version PostgreSQL refusée : {reason}.")
    if not server.stdout.strip().isdigit():
        raise UnsafeBackup("Version PostgreSQL reçue dans un format inattendu.")
    server_major = int(server.stdout.strip()) // 10000
    for binary in ("pg_dump", "pg_dumpall"):
        client = subprocess.run(
            [binary, "--version"], env=environment, capture_output=True, timeout=30,
        )
        match = re.search(rb"PostgreSQL\)?\s+(\d+)", client.stdout)
        if client.returncode or match is None or int(match[1]) < server_major:
            raise UnsafeBackup("Client de sauvegarde plus ancien que PostgreSQL distant.")


def dump_database(url: str, destination: Path) -> None:
    environment = database_environment(url)
    check_clients(environment)
    filters = json.loads((VENDOR / "filters.json").read_text())
    destination.mkdir(parents=True, exist_ok=True, mode=0o700)
    for kind, filename in (("role", "roles.sql"), ("schema", "schema.sql"), ("data", "data.sql")):
        env = dict(environment)
        if kind == "role":
            env.update(
                RESERVED_ROLES="|".join(filters["reserved_roles"]),
                ALLOWED_CONFIGS="|".join(filters["allowed_configs"]),
                EXTRA_SED="/^--/d",
            )
        elif kind == "schema":
            env.update(EXCLUDED_SCHEMAS="|".join(filters["schema_exclusions"]), EXTRA_SED="/^--/d")
        else:
            env.update(
                INCLUDED_SCHEMAS="*",
                EXCLUDED_SCHEMAS="|".join(filters["data_exclusions"]),
                EXTRA_FLAGS="--exclude-table storage.buckets_vectors --exclude-table storage.vector_indexes",
            )
        output = destination / filename
        if output.is_symlink():
            raise UnsafeBackup("Destination SQL invalide.")
        descriptor = os.open(output, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        with os.fdopen(descriptor, "wb") as stream:
            result = subprocess.run(
                ["bash", str(VENDOR / f"dump_{kind}.sh")], env=env,
                stdout=stream, stderr=subprocess.PIPE, timeout=1800,
            )
        if result.returncode or output.stat().st_size == 0:
            output.unlink(missing_ok=True)
            # Ne jamais afficher les arguments ni le stderr brut : ils peuvent
            # contenir des informations privées venant de PostgreSQL.
            raise UnsafeBackup(f"Export SQL {kind} refusé : {failure_reason(result.stderr)}.")


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage : native_commercial_dump.py dossier-sql")
        return 2
    try:
        dump_database(os.environ.get("PRODUCTION_DB_URL", ""), Path(sys.argv[1]))
    except (UnsafeBackup, OSError, ValueError, subprocess.TimeoutExpired) as error:
        # Pas de traceback/CalledProcessError contenant une chaîne de connexion.
        message = str(error) if isinstance(error, UnsafeBackup) else type(error).__name__
        print(f"::error::Sauvegarde SQL native arrêtée : {message}")
        return 1
    print("Trois exports PostgreSQL natifs terminés avec les filtres Supabase.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
