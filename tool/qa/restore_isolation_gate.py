#!/usr/bin/env python3
"""Petit Filet #91: refuse a real-data restore unless the target is air-gapped.

Only preflight and read-only post-restore checks. Does not decrypt or import
commercial data. Run inside the same isolated network namespace as the
restored PostgreSQL and Storage services; never on the commercial server.
The procedure remains NO-GO until SQL/Auth/Storage/RLS/RPC are proven there.
"""
from __future__ import annotations

import os
import platform
import re
import socket
import subprocess
import sys
from pathlib import Path
from urllib.parse import urlsplit


class UnsafeRestore(RuntimeError):
    """Fatal precondition failure; never include confidential values."""


# A local DB URL could otherwise be a tunnel to the production project.
DB_HOST, DB_PORT, DB_NAME = "127.0.0.1", 54322, "postgres"
API_HOST, API_PORT = "127.0.0.1", 54321
# Decryption wrapper must unset these before handling cleartext.
FORBIDDEN_ENV = (
    "PRODUCTION_DB_URL", "SUPABASE_DB_PASSWORD", "SUPABASE_ACCESS_TOKEN",
    "SUPABASE_PROJECT_REF", "BACKUP_PASSPHRASE", "SUPABASE_SERVICE_ROLE_KEY",
    "RESEND_API_KEY", "SMTP_HOST", "SMTP_PASSWORD", "SMTP_USER",
    "FIREBASE_SERVER_KEY", "FIREBASE_CREDENTIALS", "ONESIGNAL_API_KEY",
    "PUSH_INTERNAL_TOKEN", "WEBHOOK_SECRET", "CLOUDFLARE_API_TOKEN",
)


def assert_url_target(db_url: str, api_url: str) -> None:
    """Exact local addresses only, never DNS localhost or nonstandard ports."""
    try:
        db, api = urlsplit(db_url), urlsplit(api_url)
        db_port, api_port = db.port, api.port
    except ValueError as exc:
        raise UnsafeRestore("URL de cible malformée.") from exc
    if (db.scheme not in {"postgres", "postgresql"}
            or db.hostname != DB_HOST or db_port != DB_PORT
            or db.username != "postgres" or db.path != "/" + DB_NAME
            or db.query or db.fragment):
        raise UnsafeRestore("Cible PostgreSQL distante ou inattendue : refus.")
    if (api.scheme != "http" or api.hostname != API_HOST
            or api_port != API_PORT or api.username or api.password
            or api.path not in ("", "/") or api.query or api.fragment):
        raise UnsafeRestore("Cible Storage/Auth distante ou inattendue : refus.")


def assert_no_remote_secrets(environ: dict[str, str]) -> None:
    if any(environ.get(key) for key in FORBIDDEN_ENV):
        raise UnsafeRestore("Des secrets ou connexions de production sont présents : refus.")
    if any(environ.get(key) for key in environ
           if re.search(r"(^|_)(SMTP|WEBHOOK|PRODUCTION|FIREBASE|ONESIGNAL)(_|$)", key)
           and key not in {"RESTORE_PRODUCTION_BACKUP_HASH"}):
        raise UnsafeRestore("Un secret de notification ou de production subsiste : refus.")


def assert_loopback_only(interfaces: list[tuple[int, str]], route_table: str,
                         ipv6_routes: str) -> None:
    """Require only 'lo', not merely the absence of a default route."""
    if {name for _, name in interfaces} != {"lo"}:
        raise UnsafeRestore("Interface réseau non isolée : refus.")
    rows = route_table.splitlines()
    if not rows or not rows[0].lstrip().startswith("Iface"):
        raise UnsafeRestore("État des routes IPv4 non vérifiable.")
    if any(row.split()[0] != "lo" for row in rows[1:] if row.split()):
        raise UnsafeRestore("Route IPv4 hors loopback : refus.")
    for line in ipv6_routes.splitlines():
        fields = line.split()
        if fields and fields[-1] != "lo":
            raise UnsafeRestore("Route IPv6 hors loopback : refus.")


def preflight(environ: dict[str, str], *, interfaces=None,
              routes_v4: str | None = None, routes_v6: str | None = None,
              system: str | None = None) -> None:
    if (system or platform.system()) != "Linux":
        raise UnsafeRestore("Restauration autorisée uniquement sous Linux isolé.")
    assert_url_target(environ.get("RESTORE_LOCAL_DB_URL", ""),
                      environ.get("RESTORE_LOCAL_API_URL", ""))
    assert_no_remote_secrets(environ)
    try:
        names = socket.if_nameindex() if interfaces is None else interfaces
        v4 = Path("/proc/net/route").read_text() if routes_v4 is None else routes_v4
        v6 = Path("/proc/net/ipv6_route").read_text() if routes_v6 is None else routes_v6
    except (OSError, ValueError) as exc:
        raise UnsafeRestore("Isolation réseau impossible à prouver.") from exc
    assert_loopback_only(names, v4, v6)


def db_counts_data_sql(source: str) -> dict[str, int]:
    """Read pg_dump COPY row counts, never log personal information."""
    pattern = re.compile(r'^COPY\s+(?:"?(auth|public|private)"?)\.(?:"?([a-z_][a-z_0-9]*)"?)\s*\([^\n]*\)\s+FROM stdin;$')
    counts: dict[str, int] = {}
    active: str | None = None
    for line in source.splitlines():
        if active is not None:
            if line == r"\.":
                active = None
            else:
                counts[active] += 1
            continue
        if line.startswith("COPY "):
            match = pattern.fullmatch(line)
            if match:
                key = f"{match.group(1)}.{match.group(2)}"
                if key in counts:
                    raise UnsafeRestore("Table SQL dupliquée dans le dump.")
                counts[key] = 0
                active = key
    if active is not None:
        raise UnsafeRestore("Bloc COPY SQL non terminé.")
    required = {"auth.users", "public.clubs", "public.profiles",
                "public.seasons", "public.matches", "public.match_predictions"}
    if not required.issubset(counts):
        raise UnsafeRestore("Tables métier ou Auth absentes du dump SQL.")
    return counts


def safe_psql_select(sql: str, environ: dict[str, str], *, timeout=30) -> str:
    """Fixed SQL on local Postgres; no password in arguments or logs."""
    db = urlsplit(environ["RESTORE_LOCAL_DB_URL"])
    safe_env = {"PATH": os.environ.get("PATH", ""), "PGCONNECT_TIMEOUT": "5"}
    if db.password:
        safe_env["PGPASSWORD"] = db.password
    try:
        result = subprocess.run(
            ["psql", "-X", "-qAt", "-v", "ON_ERROR_STOP=1",
             "-h", DB_HOST, "-p", str(DB_PORT), "-U", "postgres",
             "-d", DB_NAME, "-c", sql],
            env=safe_env, stdin=subprocess.DEVNULL,
            capture_output=True, timeout=timeout, check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise UnsafeRestore("Interrogation PostgreSQL locale impossible.") from exc
    if result.returncode:
        raise UnsafeRestore("Contrôle de base locale échoué.")
    return result.stdout.decode("ascii", errors="strict").strip()


def post_restore_counts(counts: dict[str, int], environ: dict[str, str]) -> dict:
    """Read-only comparison after a separately executed real import."""
    preflight(environ)
    observed = {}
    for name in sorted(counts):
        if not re.fullmatch(r"(?:auth|private|public)\.[a-z_][a-z_0-9]*", name):
            raise UnsafeRestore("Identifiant de table invalide.")
        value = safe_psql_select(f"select count(*) from {name};", environ)
        if not value.isdecimal():
            raise UnsafeRestore("Compteur local illisible.")
        observed[name] = int(value)
        if observed[name] != counts[name]:
            raise UnsafeRestore("Écart de lignes PostgreSQL restaurées.")
    orphan_profiles = safe_psql_select(
        "select count(*) from public.profiles p "
        "left join auth.users u on u.id=p.id where u.id is null;", environ)
    if orphan_profiles != "0":
        raise UnsafeRestore("Lien entre profils et utilisateurs Auth incomplet.")
    cron_table = safe_psql_select("select to_regclass('cron.job') is not null;", environ)
    if cron_table not in {"t", "f"}:
        raise UnsafeRestore("État des tâches planifiées inconnu.")
    if cron_table == "t":
        active_cron = safe_psql_select(
            "select count(*) from cron.job where active;", environ)
        if active_cron != "0":
            raise UnsafeRestore("Tâches planifiées actives dans la cible restaurée.")
    return {"sql_tables_checked": len(observed),
            "auth_and_business_rows_checked": sum(observed.values()),
            "auth_profiles_fk": True, "cron_disabled": True,
            "storage_bytes_checked": False, "rls_rpc_jwt_checked": False,
            "full_restore_proven": False}


def main(argv: list[str]) -> int:
    try:
        if argv == ["preflight"]:
            preflight(dict(os.environ))
            print("PASS : adresse locale et réseau isolé sans sortie. Aucun import effectué.")
        else:
            raise UnsafeRestore("Usage : restore_isolation_gate.py preflight")
    except (UnsafeRestore, ValueError, UnicodeError) as exc:
        print(f"REFUS : {exc}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
