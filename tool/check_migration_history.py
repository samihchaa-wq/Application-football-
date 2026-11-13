#!/usr/bin/env python3
"""Refuse les modifications destructrices des migrations SQL déjà versionnées.

Compare l'état de la base Git de la PR à la tête à valider. N'écrit rien et
ne se connecte pas à Supabase. Une nouvelle migration datée est autorisée.
"""
from __future__ import annotations

import re
import subprocess
import sys

PREFIX = "supabase/migrations/"
MIGRATION_NAME = re.compile(r"^supabase/migrations/[0-9]{14}_[a-z0-9_]+\.sql$")


def violations(name_status: str) -> list[str]:
    errors: list[str] = []
    for line in name_status.splitlines():
        columns = line.split("\t")
        if len(columns) < 2:
            errors.append(f"Statut Git illisible : {line!r}")
            continue
        status, *paths = columns
        if not any(path.startswith(PREFIX) and path.endswith(".sql") for path in paths):
            continue
        if status == "A" and len(paths) == 1:
            if not MIGRATION_NAME.fullmatch(paths[0]):
                errors.append(f"Nom de migration non conforme : {paths[0]}")
            continue
        errors.append(
            f"Migration historique modifiée, renommée ou supprimée ({status}): "
            + " → ".join(paths)
        )
    return errors


def main(argv: list[str]) -> int:
    if len(argv) != 3 or not all(argv[1:]):
        print("Usage: check_migration_history.py BASE_SHA HEAD_SHA", file=sys.stderr)
        return 2
    base, head = argv[1:]
    result = subprocess.run(
        ["git", "diff", "--name-status", "--find-renames", "--find-copies",
         base, head, "--", PREFIX],
        capture_output=True, text=True, check=False,
    )
    if result.returncode != 0:
        print("Impossible de vérifier l'historique Git : " + result.stderr, file=sys.stderr)
        return 2
    problems = violations(result.stdout)
    for problem in problems:
        print("ERREUR : " + problem, file=sys.stderr)
    if problems:
        print("Créer une nouvelle migration datée ; ne jamais réécrire l'historique.", file=sys.stderr)
        return 1
    print("Historique des migrations intact ; nouvelles migrations conformes.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
