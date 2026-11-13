#!/usr/bin/env python3
"""Refuse un rapport pgbench faux vert malgré un code de sortie nul."""
import re
import sys
from pathlib import Path

PROCESSED = re.compile(r"^number of transactions actually processed:\s*([0-9]+)\s*$", re.M)
FAILED = re.compile(r"^number of failed transactions:\s*([0-9]+)\b", re.M)
TPS = re.compile(r"^tps\s*=\s*([0-9]+(?:\.[0-9]+)?)\b", re.M)


def check_report(content: str) -> list[str]:
    transactions = PROCESSED.findall(content)
    failed = FAILED.findall(content)
    tps = TPS.findall(content)
    errors = []
    if len(transactions) != 1 or int(transactions[0]) <= 0:
        errors.append("Rapport incomplet : aucune transaction prouvée.")
    if len(failed) > 1 or (failed and int(failed[0]) != 0):
        errors.append("Au moins une transaction a échoué pendant la charge.")
    if not tps or not any(float(value) > 0 for value in tps):
        errors.append("Débit absent ou nul.")
    return errors


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print("Usage : check_pgbench_report.py CHEMIN PHASE", file=sys.stderr)
        return 2
    try:
        content = Path(argv[1]).read_text(encoding="utf-8")
    except OSError:
        print("::error::Rapport pgbench introuvable.", file=sys.stderr)
        return 2
    errors = check_report(content)
    for error in errors:
        print(f"::error::{argv[2]} : {error}", file=sys.stderr)
    if errors:
        return 1
    print(f"{argv[2]} : transactions et débit vérifiés, aucun échec.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
