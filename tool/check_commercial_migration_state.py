#!/usr/bin/env python3
"""Audit NON DESTRUCTIF des migrations Supabase sur le projet commercial.

Échoue sur migrations inconnues de GitHub ou manifestes incohérents, mais
affiche simplement les migrations en attente : le déploiement est un choix
manuel et distinct. Aucun SQL d'écriture ne doit être ajouté à cet outil.
"""
from __future__ import annotations

import os
import re
from pathlib import Path

from commercial_supabase_setup import COMMERCIAL_REF, ROOT, query

MIGRATION = re.compile(r"^([0-9]{14})_([a-z0-9_]+)\.sql$")


def compare_migrations(local_names: list[str], remote_versions: list[str]) -> dict[str, list[str]]:
    """Comparaison déterministe et testable sans réseau ni base de données."""
    local: dict[str, str] = {}
    invalid: list[str] = []
    for name in local_names:
        match = MIGRATION.fullmatch(name)
        if match is None:
            invalid.append(name)
            continue
        version = match.group(1)
        if version in local:
            invalid.extend([local[version], name])
        local[version] = name
    duplicates = sorted({
        version for version in remote_versions if remote_versions.count(version) > 1
    })
    remote = set(remote_versions)
    pending = sorted(name for version, name in local.items() if version not in remote)
    unknown = sorted(version for version in remote if version not in local)
    backfilled = sorted(
        name for name in pending if remote and name[:14] < max(remote)
    )
    return {
        "pending": pending,
        "unknown": unknown,
        "backfilled": backfilled,
        "invalid": sorted(set(invalid)),
        "duplicates": duplicates,
    }


def run(ref: str, token: str, directory: Path) -> int:
    if ref != COMMERCIAL_REF or not token:
        print("::error::Projet commercial ou jeton absent : audit refusé.")
        return 2
    if not directory.is_dir():
        print("::error::Répertoire des migrations absent.")
        return 2
    # Uniquement une lecture du registre officiel : aucune RPC métier,
    # aucun secret ni contenu personnel récupéré ou affiché.
    rows = query(
        ref, token,
        "select version from supabase_migrations.schema_migrations order by version",
    )
    if not isinstance(rows, list) or any(
        not isinstance(row, dict) or not isinstance(row.get("version"), str)
        for row in rows
    ):
        print("::error::Registre des migrations Supabase illisible.")
        return 2
    state = compare_migrations(
        [p.name for p in directory.glob("*.sql")],
        [row["version"] for row in rows],
    )
    print(f"Migrations enregistrées dans Supabase : {len(rows)}")
    print(f"Migrations du dépôt GitHub : {len(list(directory.glob('*.sql')))}")
    for name in state["pending"]:
        print(f"À appliquer uniquement sur autorisation : {name}")
    for name in state["backfilled"]:
        print(f"::warning::Migration rétrospective à revoir : {name}")
    if any(state[key] for key in ("unknown", "invalid", "duplicates")):
        for name in state["unknown"]:
            print(f"::error::Version distante absente du dépôt : {name}")
        for name in state["invalid"]:
            print(f"::error::Fichier local incorrect ou en double : {name}")
        for name in state["duplicates"]:
            print(f"::error::Version distante dupliquée : {name}")
        return 1
    print("Registres compatibles ; aucun déploiement ni changement de base.")
    return 0


def main() -> int:
    return run(
        os.environ.get("SUPABASE_PROJECT_REF", ""),
        os.environ.get("SUPABASE_ACCESS_TOKEN", ""),
        ROOT / "supabase" / "migrations",
    )


if __name__ == "__main__":
    raise SystemExit(main())
