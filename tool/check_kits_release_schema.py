#!/usr/bin/env python3
"""Contrôle en lecture seule de la compatibilité maillots avant livraison Web.

Ce contrôle ne déploie rien : il refuse qu'un client contenant le support des
tenues illimitées soit publié tant que la migration commerciale requise n'est
pas enregistrée ET que la forme du schéma correspondant n'est pas présente.

Les commits historiques dépourvus de cette migration restent publiables pour
un retour arrière contrôlé. Le projet AS Grinta original est toujours refusé.
"""
from __future__ import annotations

import os
from pathlib import Path

from commercial_supabase_setup import COMMERCIAL_REF, ROOT, query

MIGRATION_VERSION = "20261120000000"
MIGRATION_PATH = ROOT / "supabase" / "migrations" / (
    MIGRATION_VERSION + "_kits_illimites_par_club.sql"
)

# SELECT uniquement. Ne lit aucun joueur, maillot, secret ou contenu de club.
READINESS_SQL = """
select
  exists (
    select 1 from supabase_migrations.schema_migrations
    where version = '20261120000000'
  ) as migration_registered,
  exists (
    select 1 from pg_constraint
    where conrelid = 'public.clubs'::regclass
      and conname = 'clubs_kits_shape'
      and pg_get_constraintdef(oid)
          like '%jsonb_array_length(kits) >= 1%'
  ) as club_kits_shape_ready,
  exists (
    select 1 from pg_constraint
    where conrelid = 'public.match_kit_snapshots'::regclass
      and conname = 'match_kit_snapshots_kits_check'
      and pg_get_constraintdef(oid)
          like '%jsonb_array_length(kits) >= 1%'
  ) as snapshots_ready,
  exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'admin_update_club_kits'
      and pg_get_functiondef(p.oid)
          like '%Au moins un maillot est nécessaire.%'
  ) as admin_rpc_ready;
"""

REQUIRED_FIELDS = (
    "migration_registered",
    "club_kits_shape_ready",
    "snapshots_ready",
    "admin_rpc_ready",
)


def run(ref: str, token: str, migration_path: Path = MIGRATION_PATH) -> int:
    # Ne pas bloquer les anciens commits sans le nouveau contrat client.
    if not migration_path.is_file():
        print("Garde maillots illimités : version antérieure, contrôle non requis.")
        return 0

    if ref != COMMERCIAL_REF or not token:
        print(
            "::error::Contrôle maillots refusé : projet commercial ou jeton "
            "SUPABASE_ACCESS_TOKEN manquant. Aucune publication."
        )
        return 2

    try:
        result = query(ref, token, READINESS_SQL)
    except Exception as exc:
        print(
            "::error::Schéma maillots illisible : "
            f"{type(exc).__name__}. Aucune publication."
        )
        return 2

    if not isinstance(result, list) or len(result) != 1 or not isinstance(
        result[0], dict
    ):
        print("::error::Réponse Supabase inattendue. Aucune publication.")
        return 2

    missing = [name for name in REQUIRED_FIELDS if result[0].get(name) is not True]
    if missing:
        print(
            "::error::La version Flutter attend la migration maillots "
            f"{MIGRATION_VERSION} et son schéma : vérifications manquantes : "
            + ", ".join(missing)
            + ". Aucune publication."
        )
        return 1

    print(
        "Migration et schéma des maillots illimités compatibles : "
        "publication Web autorisable après les autres contrôles."
    )
    return 0


def main() -> int:
    return run(
        os.environ.get("SUPABASE_PROJECT_REF", ""),
        os.environ.get("SUPABASE_ACCESS_TOKEN", ""),
    )


if __name__ == "__main__":
    raise SystemExit(main())
