#!/usr/bin/env python3
"""Export SQL commercial avec les clients PostgreSQL du même hôte que psql.

Lecture seule. Les filtres viennent de Supabase CLI 2.111.0 (MIT, vendus dans
vendor/). Les identifiants restent en variables d'environnement, jamais dans
les scripts, les arguments, les journaux ou les fichiers exportés.
"""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

from commercial_backup_bundle import UnsafeBackup, normalize_database_url

VENDOR = Path(__file__).resolve().parent / "vendor" / "supabase_cli_2_111"


def database_environment(url: str) -> dict[str, str]:
    parsed = urlsplit(normalize_database_url(url))
    host = parsed.hostname or ""
    user = unquote(parsed.username or "")
    port = parsed.port or 5432
    password = unquote(parsed.password or "")
    if not re.fullmatch(r"[a-z0-9.-]+", host) or not re.fullmatch(r"[a-z0-9_.]+", user):
        raise UnsafeBackup("Paramètres de connexion PostgreSQL invalides.")
    if not password or any(c in password for c in "\r\n\x00"):
        raise UnsafeBackup("Mot de passe DB absent ou invalide.")
    return {
        "PATH": os.environ.get("PATH", os.defpath),
        "LC_ALL": "C.UTF-8",
        "PGHOST": host,
        "PGPORT": str(port),
        "PGUSER": user,
        "PGPASSWORD": password,
        "PGDATABASE": "postgres",
        "PGSSLMODE": "require",
        "PGCONNECT_TIMEOUT": "30",
    }


def check_clients(environment: dict[str, str]) -> None:
    for binary in ("psql", "pg_dump", "pg_dumpall", "bash", "sed", "uniq"):
        if shutil.which(binary, path=environment["PATH"]) is None:
            raise UnsafeBackup("Client PostgreSQL ou utilitaire local manquant.")
    server = subprocess.run(
        ["psql", "-X", "-At", "-v", "ON_ERROR_STOP=1", "-c", "show server_version_num"],
        env=environment, capture_output=True, timeout=60,
    )
    if server.returncode or not server.stdout.strip().isdigit():
        raise UnsafeBackup("Lecture de la version PostgreSQL impossible.")
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
            reason = "échec du client"
            diagnostic = result.stderr.lower()
            if b"password authentication" in diagnostic or b"no password supplied" in diagnostic:
                reason = "authentification refusée"
            elif b"permission denied" in diagnostic:
                reason = "permissions insuffisantes"
            elif b"connection" in diagnostic or b"could not connect" in diagnostic:
                reason = "connexion indisponible"
            raise UnsafeBackup(f"Export SQL {kind} refusé : {reason}.")


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
