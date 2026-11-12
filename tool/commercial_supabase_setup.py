#!/usr/bin/env python3
"""Mise en route de la base Supabase COMMERCIALE (jamais AS Grinta).

Lancé par le workflow « Supabase commercial : mise en route ». Utilise
l'API de gestion Supabase avec SUPABASE_ACCESS_TOKEN :

1. applique, dans l'ordre, les migrations du dépôt absentes de la base et les
   enregistre dans supabase_migrations.schema_migrations ;
2. crée dans le coffre (Vault) les secrets manquants : project_url,
   push_internal_token, push_vapid_public, push_vapid_private. Les valeurs
   sont générées ici et ne sont jamais affichées ;
3. ne touche jamais à un secret déjà présent.

Ne lance jamais supabase/seed.sql.
"""
from __future__ import annotations

import base64
import json
import os
import secrets
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COMMERCIAL_REF = "jvxkhgdopslctpcjrhzw"
PERSONAL_REFS = {"ovzijmqrnsgcmryinkfa", "yqfewxadpyulgxehhpcu"}


def query(ref: str, token: str, sql: str) -> list:
    request = urllib.request.Request(
        f"https://api.supabase.com/v1/projects/{ref}/database/query",
        data=json.dumps({"query": sql}).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "User-Agent": "commercial-setup",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=300) as response:
            body = response.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", "replace")[:2000]
        raise SystemExit(f"::error::Requête refusée ({exc.code}) : {detail}") from None
    return json.loads(body) if body else []


def dollar_quote(value: str) -> str:
    tag = "$v" + secrets.token_hex(6) + "$"
    assert tag not in value
    return f"{tag}{value}{tag}"


def vapid_keys() -> tuple[str, str]:
    from cryptography.hazmat.primitives import serialization
    from cryptography.hazmat.primitives.asymmetric import ec

    key = ec.generate_private_key(ec.SECP256R1())
    private = key.private_numbers().private_value.to_bytes(32, "big")
    public = key.public_key().public_bytes(
        serialization.Encoding.X962, serialization.PublicFormat.UncompressedPoint
    )

    def b64(raw: bytes) -> str:
        return base64.urlsafe_b64encode(raw).decode("ascii").rstrip("=")

    return b64(public), b64(private)


def apply_migrations(ref: str, token: str) -> None:
    query(
        ref,
        token,
        "create schema if not exists supabase_migrations;"
        " create table if not exists supabase_migrations.schema_migrations"
        " (version text primary key, statements text[], name text);",
    )
    done = {
        row["version"]
        for row in query(
            ref, token, "select version from supabase_migrations.schema_migrations"
        )
    }
    files = sorted((ROOT / "supabase" / "migrations").glob("*.sql"))
    pending = [f for f in files if f.name.split("_", 1)[0] not in done]
    if not pending:
        print("Base à jour : aucune migration en attente.")
        return
    for path in pending:
        version, name = path.stem.split("_", 1)
        sql = path.read_text(encoding="utf-8")
        query(
            ref,
            token,
            "begin;\n"
            + sql
            + "\n;insert into supabase_migrations.schema_migrations"
            f" (version, name, statements) values ('{version}', '{name}',"
            f" array[{dollar_quote(sql)}]);\ncommit;",
        )
        print(f"Migration appliquée : {path.name}")


def ensure_vault(ref: str, token: str) -> None:
    present = {
        row["name"]
        for row in query(ref, token, "select name from vault.secrets where name is not null")
    }
    wanted: dict[str, str] = {}
    if "project_url" not in present:
        wanted["project_url"] = f"https://{ref}.supabase.co"
    if "push_internal_token" not in present:
        wanted["push_internal_token"] = secrets.token_urlsafe(48)
    if not {"push_vapid_public", "push_vapid_private"} & present:
        public, private = vapid_keys()
        wanted["push_vapid_public"] = public
        wanted["push_vapid_private"] = private
    elif not {"push_vapid_public", "push_vapid_private"} <= present:
        raise SystemExit("::error::Une seule des deux clés VAPID existe : à corriger à la main.")
    for name, value in wanted.items():
        if name != "project_url":
            print(f"::add-mask::{value}")
        query(
            ref,
            token,
            f"select vault.create_secret({dollar_quote(value)}, '{name}');",
        )
        print(f"Secret créé dans le coffre : {name}")
    if not wanted:
        print("Coffre complet : aucun secret créé.")


def main() -> int:
    ref = os.environ.get("SUPABASE_PROJECT_REF", "")
    token = os.environ.get("SUPABASE_ACCESS_TOKEN", "")
    if ref in PERSONAL_REFS or ref != COMMERCIAL_REF:
        print("::error::Projet refusé : seule la base commerciale est autorisée.")
        return 1
    if not token:
        print("::error::Secret GitHub SUPABASE_ACCESS_TOKEN manquant.")
        return 1
    steps = sys.argv[1:] or ["migrations", "vault"]
    if "migrations" in steps:
        apply_migrations(ref, token)
    if "vault" in steps:
        ensure_vault(ref, token)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
