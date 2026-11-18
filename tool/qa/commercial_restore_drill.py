#!/usr/bin/env python3
"""Exercice de restauration réelle d'une sauvegarde commerciale de Petit Filet.

À lancer UNIQUEMENT dans l'espace réseau isolé préparé par
.github/workflows/commercial_restore_drill.yml : une pile Supabase locale et
jetable, joignable sur 127.0.0.1, sans aucune sortie vers Internet. Chaque
sous-commande refait le prévol de tool/qa/restore_isolation_gate.py et refuse
de tourner sinon.

Étapes (chacune échoue au premier écart) :
  import   rôles, structure et données dans une seule transaction, tâches
           planifiées désactivées avant validation, puis comparaison des
           nombres de lignes avec la sauvegarde ;
  storage  remise des octets de chaque fichier via le Storage local, puis
           relecture et comparaison des empreintes SHA-256 du manifeste ;
  access   connexion Auth réelle (lien magique local, aucun mot de passe
           touché) d'un membre de chaque club, puis contrôle par HTTP que
           chacun ne voit aucune donnée d'un autre club, que l'anonyme ne voit
           rien et que les fichiers privés restent fermés.

Les journaux du dépôt sont publics : rien d'autre que des compteurs, des
durées et des messages fixes n'est affiché. Jamais un nom, une adresse, un
identifiant ou une valeur de ligne.
"""
from __future__ import annotations

import hashlib
import json
import os
import re
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from restore_isolation_gate import (  # noqa: E402
    UnsafeRestore,
    assert_no_remote_secrets,
    assert_url_target,
    db_counts_data_sql,
)

API = "http://127.0.0.1:54321"
IDENT = re.compile(r"^[a-z_][a-z0-9_.]*$")


def assert_no_egress(route_table: str | None = None, probe=None) -> None:
    """Aucune route par défaut et aucune connexion possible vers Internet.

    Le prévol complet (seule l'interface lo) est fait par le workflow AVANT de
    démarrer Docker. Une fois la pile locale lancée, Docker ajoute ses propres
    ponts internes : on vérifie alors qu'aucun ne mène dehors.
    """
    table = Path("/proc/net/route").read_text() if route_table is None else route_table
    for row in table.splitlines()[1:]:
        fields = row.split()
        if len(fields) > 1 and fields[1] == "00000000":
            raise UnsafeRestore("Route par défaut présente : réseau non isolé, refus.")
    connect = probe or (lambda: socket.create_connection(("1.1.1.1", 443), timeout=2).close())
    try:
        connect()
    except OSError:
        return
    raise UnsafeRestore("Sortie vers Internet possible : refus.")


def _env() -> dict[str, str]:
    environ = dict(os.environ)
    assert_url_target(environ.get("RESTORE_LOCAL_DB_URL", ""),
                      environ.get("RESTORE_LOCAL_API_URL", ""))
    assert_no_remote_secrets(environ)
    assert_no_egress()
    return environ


def post_restore_counts(counts: dict[str, int], environ: dict[str, str]) -> dict:
    """Même contrôle que restore_isolation_gate.post_restore_counts, sans
    refaire le prévol « lo seule », impossible une fois Docker démarré."""
    for name in sorted(counts):
        if not re.fullmatch(r"(?:auth|private|public)\.[a-z_][a-z_0-9]*", name):
            raise UnsafeRestore("Identifiant de table invalide.")
        if _select(f"select count(*) from {name};", environ) != str(counts[name]):
            raise UnsafeRestore("Écart de lignes PostgreSQL restaurées.")
    if _select("select count(*) from public.profiles p left join auth.users u "
               "on u.id = p.id where u.id is null;", environ) != "0":
        raise UnsafeRestore("Lien entre profils et utilisateurs Auth incomplet.")
    if _select("select to_regclass('cron.job') is not null;", environ) == "t":
        if _select("select count(*) from cron.job where active;", environ) != "0":
            raise UnsafeRestore("Tâches planifiées actives dans la cible restaurée.")
    return {"sql_tables_checked": len(counts),
            "auth_and_business_rows_checked": sum(counts.values()),
            "auth_profiles_linked": True, "cron_disabled": True}


def _sanitize_sql_error(stderr: bytes) -> str:
    """Garder la nature de l'erreur, jamais une valeur de ligne."""
    text = stderr.decode("utf-8", errors="replace")
    for line in text.splitlines():
        if "ERROR:" in line:
            message = line.split("ERROR:", 1)[1].strip()
            message = re.sub(
                r'"([^"]*)"',
                lambda m: f'"{m.group(1)}"' if IDENT.match(m.group(1)) else '"…"',
                message,
            )
            message = re.sub(r"'[^']*'", "'…'", message)
            message = re.sub(r"\([^)]*\)=\([^)]*\)", "(…)", message)
            return message[:160]
    return "erreur PostgreSQL sans message exploitable"


def _psql_files(environ: dict[str, str], args: list[str], timeout: int) -> None:
    db = urllib.parse.urlsplit(environ["RESTORE_LOCAL_DB_URL"])
    safe_env = {"PATH": os.environ.get("PATH", ""), "PGCONNECT_TIMEOUT": "10"}
    if db.password:
        safe_env["PGPASSWORD"] = db.password
    result = subprocess.run(
        ["psql", "-X", "-q", "-v", "ON_ERROR_STOP=1", "-h", "127.0.0.1",
         "-p", "54322", "-U", "postgres", "-d", "postgres", *args],
        env=safe_env, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE, timeout=timeout, check=False,
    )
    if result.returncode:
        raise UnsafeRestore("Import SQL refusé : " + _sanitize_sql_error(result.stderr))


def _select(sql: str, environ: dict[str, str]) -> str:
    """Comme safe_psql_select, mais lit l'UTF-8 (chemins de fichiers accentués)."""
    db = urllib.parse.urlsplit(environ["RESTORE_LOCAL_DB_URL"])
    safe_env = {"PATH": os.environ.get("PATH", ""), "PGCONNECT_TIMEOUT": "10"}
    if db.password:
        safe_env["PGPASSWORD"] = db.password
    result = subprocess.run(
        ["psql", "-X", "-qAt", "-v", "ON_ERROR_STOP=1", "-h", "127.0.0.1",
         "-p", "54322", "-U", "postgres", "-d", "postgres", "-c", sql],
        env=safe_env, stdin=subprocess.DEVNULL, capture_output=True,
        timeout=120, check=False,
    )
    if result.returncode:
        raise UnsafeRestore("Contrôle local refusé : " + _sanitize_sql_error(result.stderr))
    return result.stdout.decode("utf-8").strip()


def cmd_import(payload: Path) -> dict:
    environ = _env()
    database = payload / "database"
    counts = db_counts_data_sql((database / "data.sql").read_text(encoding="utf-8"))
    started = time.monotonic()
    # Une seule transaction : en cas d'erreur, rien n'est importé. Les tâches
    # planifiées restaurées sont désactivées avant la validation, donc avant
    # que pg_cron ne puisse les voir.
    _psql_files(environ, [
        "--single-transaction",
        "-f", str(database / "roles.sql"),
        "-f", str(database / "schema.sql"),
        "-c", "SET session_replication_role = replica",
        "-f", str(database / "data.sql"),
        "-c", "RESET session_replication_role",
        "-c", ("do $$ begin if to_regclass('cron.job') is not null then "
               "update cron.job set active = false; end if; end $$"),
    ], timeout=1800)
    summary = post_restore_counts(counts, environ)
    summary["import_seconds"] = round(time.monotonic() - started, 1)
    return summary


def _request(method: str, path: str, key: str | None, *, token: str | None = None,
             body: bytes | None = None, headers: dict | None = None,
             timeout: int = 30) -> tuple[int, bytes]:
    request = urllib.request.Request(API + path, data=body, method=method)
    if key:
        request.add_header("apikey", key)
        request.add_header("Authorization", f"Bearer {token or key}")
    for name, value in (headers or {}).items():
        request.add_header(name, value)
    # Pas de proxy : la cible est la boucle locale, rien d'autre.
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    try:
        with opener.open(request, timeout=timeout) as response:
            return response.status, response.read()
    except urllib.error.HTTPError as error:
        return error.code, error.read()
    except (urllib.error.URLError, OSError) as exc:
        raise UnsafeRestore("Service local injoignable.") from exc


def _quote_path(bucket: str, name: str) -> str:
    return "/" + urllib.parse.quote(bucket, safe="") + "/" + "/".join(
        urllib.parse.quote(part, safe="") for part in name.split("/")
    )


def cmd_storage(payload: Path) -> dict:
    environ = _env()
    service = environ.get("LOCAL_SERVICE_KEY", "")
    if not service:
        raise UnsafeRestore("Clé de service locale absente.")
    manifest = json.loads((payload / "manifest.json").read_text(encoding="utf-8"))
    entries = manifest.get("objects") or []
    restored_rows = _select("select count(*) from storage.objects;", environ)
    if restored_rows != str(len(entries)):
        raise UnsafeRestore("Métadonnées Storage restaurées incomplètes.")
    # Le dépôt via l'API locale réécrit le propriétaire du fichier : on garde
    # celui de la sauvegarde pour le remettre ensuite (règles par club).
    _select(
        "create table if not exists public.drill_storage_owner as "
        "select bucket_id, name, owner, owner_id, metadata->>'mimetype' as mimetype "
        "from storage.objects;", environ)
    mimetypes = {
        (row["b"], row["n"]): row["m"] or "application/octet-stream"
        for row in json.loads(_select(
            "select coalesce(json_agg(json_build_object('b', bucket_id, 'n', name, "
            "'m', mimetype)), '[]') from public.drill_storage_owner;", environ))
    }
    started = time.monotonic()
    for entry in entries:
        bucket, name = entry["bucket_id"], entry["name"]
        data = (payload / "storage" / bucket / name).read_bytes()
        if hashlib.sha256(data).hexdigest() != entry["sha256"]:
            raise UnsafeRestore("Fichier de sauvegarde altéré avant remise.")
        status, _ = _request(
            "POST", "/storage/v1/object" + _quote_path(bucket, name), service,
            body=data, headers={"x-upsert": "true",
                                "Content-Type": mimetypes.get((bucket, name),
                                                              "application/octet-stream")},
            timeout=120,
        )
        if status not in (200, 201):
            raise UnsafeRestore(f"Remise d'un fichier refusée par le Storage local (HTTP {status}).")
    _select(
        "update storage.objects o set owner = s.owner, owner_id = s.owner_id, "
        "metadata = jsonb_set(coalesce(o.metadata, '{}'::jsonb), '{mimetype}', "
        "to_jsonb(coalesce(s.mimetype, o.metadata->>'mimetype'))) "
        "from public.drill_storage_owner s "
        "where s.bucket_id = o.bucket_id and s.name = o.name; "
        "drop table public.drill_storage_owner;", environ)
    verified = 0
    total_bytes = 0
    for entry in entries:
        status, body = _request(
            "GET", "/storage/v1/object/authenticated" +
            _quote_path(entry["bucket_id"], entry["name"]), service, timeout=120)
        if status != 200 or hashlib.sha256(body).hexdigest() != entry["sha256"]:
            raise UnsafeRestore("Fichier relu différent de la sauvegarde.")
        verified += 1
        total_bytes += len(body)
    if _select("select count(*) from storage.objects;", environ) != str(len(entries)):
        raise UnsafeRestore("Le Storage local contient des fichiers en trop ou en moins.")
    return {"storage_objects_verified": verified, "storage_bytes_verified": total_bytes,
            "storage_seconds": round(time.monotonic() - started, 1)}


def _club_tables(environ: dict[str, str]) -> list[str]:
    raw = _select(
        "select string_agg(c.table_name, ',' order by c.table_name) "
        "from information_schema.columns c "
        "join pg_tables t on t.schemaname = 'public' and t.tablename = c.table_name "
        "where c.table_schema = 'public' and c.column_name = 'club_id' "
        "and has_table_privilege('authenticated', format('public.%I', c.table_name), 'select');",
        environ)
    tables = [name for name in raw.split(",") if name]
    if not tables or any(not re.fullmatch(r"[a-z_][a-z0-9_]*", name) for name in tables):
        raise UnsafeRestore("Inventaire des tables par club illisible.")
    return tables


def _session_for(user_id: str, environ: dict[str, str], service: str) -> str:
    if not re.fullmatch(r"[0-9a-f-]{36}", user_id):
        raise UnsafeRestore("Identifiant de compte invalide.")
    email = _select(f"select email from auth.users where id = '{user_id}';", environ)
    if not email:
        raise UnsafeRestore("Compte restauré sans adresse de connexion.")
    status, body = _request(
        "POST", "/auth/v1/admin/generate_link", service,
        body=json.dumps({"type": "magiclink", "email": email}).encode(),
        headers={"Content-Type": "application/json"})
    if status != 200:
        raise UnsafeRestore(f"Auth local : lien de connexion refusé (HTTP {status}).")
    reply = json.loads(body)
    token_hash = reply.get("hashed_token") or (reply.get("properties") or {}).get("hashed_token")
    if not token_hash:
        raise UnsafeRestore("Auth local : réponse de lien inattendue.")
    for verify_type in ("magiclink", "email"):
        status, body = _request(
            "POST", "/auth/v1/verify", environ["LOCAL_ANON_KEY"],
            body=json.dumps({"type": verify_type, "token_hash": token_hash}).encode(),
            headers={"Content-Type": "application/json"})
        if status == 200:
            break
    if status != 200:
        raise UnsafeRestore(f"Auth local : connexion refusée (HTTP {status}).")
    token = json.loads(body).get("access_token")
    if not token:
        raise UnsafeRestore("Auth local : aucune session ouverte.")
    return token


def cmd_access() -> dict:
    environ = _env()
    service, anon = environ.get("LOCAL_SERVICE_KEY", ""), environ.get("LOCAL_ANON_KEY", "")
    if not service or not anon:
        raise UnsafeRestore("Clés locales absentes.")
    tables = _club_tables(environ)
    members = _select(
        "select string_agg(id::text || ':' || club_id::text, ',') from ("
        " select distinct on (p.club_id) p.id, p.club_id from public.profiles p"
        " join auth.users u on u.id = p.id"
        " join public.clubs c on c.id = p.club_id"
        " where p.status = 'active' and u.email is not null"
        " order by p.club_id, p.role = 'admin' desc, p.created_at) s;", environ)
    pairs = [item.split(":") for item in members.split(",") if item]
    if len(pairs) < 2:
        raise UnsafeRestore("Il faut au moins deux clubs avec un membre actif.")

    # 1. Un visiteur sans compte ne lit rien.
    anonymous_leaks = 0
    for table in tables:
        status, body = _request("GET", f"/rest/v1/{table}?select=club_id&limit=1", anon)
        if status == 200 and json.loads(body or b"[]"):
            anonymous_leaks += 1
    if anonymous_leaks:
        raise UnsafeRestore("Un visiteur anonyme lit des données restaurées.")

    # 2. Un membre connecté de chaque club ne voit que son club, par HTTP.
    own_rows_total = 0
    for user_id, club_id in pairs:
        token = _session_for(user_id, environ, service)
        status, _ = _request("POST", "/rest/v1/rpc/get_my_profile", anon, token=token,
                             body=b"{}", headers={"Content-Type": "application/json"})
        if status != 200:
            raise UnsafeRestore(f"Profil illisible après connexion (HTTP {status}).")
        for table in tables:
            status, body = _request(
                "GET", f"/rest/v1/{table}?select=club_id", anon, token=token,
                headers={"Range": "0-99999"})
            if status != 200:
                continue  # table lisible seulement via fonctions : rien à comparer
            rows = json.loads(body or b"[]")
            if any(row.get("club_id") != club_id for row in rows):
                raise UnsafeRestore("Fuite entre clubs détectée après restauration.")
            own_rows_total += len(rows)

        # 3. Fichiers privés d'un autre club : jamais lisibles.
        others = _select(
            "select coalesce(string_agg(o.bucket_id || '/' || o.name, chr(10)), '') "
            "from storage.objects o join storage.buckets b on b.id = o.bucket_id "
            "join public.profiles p on p.id::text = o.owner_id "
            f"where not b.public and p.club_id <> '{club_id}';", environ)
        for path in [line for line in others.splitlines() if line]:
            bucket, name = path.split("/", 1)
            status, _ = _request(
                "GET", "/storage/v1/object/authenticated" + _quote_path(bucket, name),
                anon, token=token)
            if status == 200:
                raise UnsafeRestore("Fichier privé d'un autre club lisible.")
    if own_rows_total == 0:
        raise UnsafeRestore("Aucune donnée de son propre club visible : contrôle non probant.")

    private_objects = _select(
        "select coalesce(string_agg(o.bucket_id || '/' || o.name, chr(10)), '') "
        "from storage.objects o join storage.buckets b on b.id = o.bucket_id where not b.public;",
        environ)
    for path in [line for line in private_objects.splitlines() if line]:
        bucket, name = path.split("/", 1)
        status, _ = _request("GET", "/storage/v1/object/authenticated" +
                             _quote_path(bucket, name), anon)
        if status == 200:
            raise UnsafeRestore("Fichier privé lisible sans compte.")
    return {"clubs_checked": len(pairs), "club_tables_checked": len(tables),
            "own_club_rows_seen_over_http": own_rows_total,
            "auth_sessions_opened": len(pairs), "cross_club_leaks": 0}


def main(argv: list[str]) -> int:
    try:
        if len(argv) == 2 and argv[0] == "import":
            result = cmd_import(Path(argv[1]))
        elif len(argv) == 2 and argv[0] == "storage":
            result = cmd_storage(Path(argv[1]))
        elif argv == ["access"]:
            result = cmd_access()
        else:
            raise UnsafeRestore("Usage : commercial_restore_drill.py import|storage DOSSIER | access")
    except (UnsafeRestore, KeyError, ValueError, OSError, subprocess.TimeoutExpired) as exc:
        reason = str(exc) if isinstance(exc, UnsafeRestore) else type(exc).__name__
        print(f"::error::Exercice de restauration arrêté : {reason}")
        return 1
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
