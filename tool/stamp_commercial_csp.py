#!/usr/bin/env python3
"""Remplace les domaines Supabase provisoires du CSP avant le build commercial.

Le fichier source reste neutre ; seule la copie de travail du build est modifiée.
Ne jamais exécuter ce script pour AS Grinta.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path
from urllib.parse import urlsplit

from check_commercial_deploy import ROOT, check

PLACEHOLDER_HOST = "a-remplacer.supabase.co"
EXPECTED_OCCURRENCES = 4


def replace_csp_hosts(html: str, project_url: str) -> str:
    host = urlsplit(project_url).hostname
    if not host:
        raise ValueError("Domaine Supabase invalide.")
    if '<meta http-equiv="Content-Security-Policy"' not in html:
        raise ValueError("Content-Security-Policy absente.")
    if html.count(PLACEHOLDER_HOST) != EXPECTED_OCCURRENCES:
        raise ValueError("Nombre inattendu de domaines Supabase provisoires dans le CSP.")
    return html.replace(PLACEHOLDER_HOST, host)


def main() -> int:
    config_path = ROOT / "config" / "production.json"
    html_path = ROOT / "web" / "index.html"
    try:
        config = json.loads(config_path.read_text(encoding="utf-8"))
        problems = check(config)
        if problems:
            for problem in problems:
                print(f"::error::{problem}")
            return 1
        updated = replace_csp_hosts(
            html_path.read_text(encoding="utf-8"), config["SUPABASE_URL"]
        )
        html_path.write_text(updated, encoding="utf-8")
    except (OSError, ValueError, KeyError) as exc:
        print(f"::error::Préparation du CSP commercial impossible : {type(exc).__name__}")
        return 1

    print("CSP commercial préparé ; aucune destination personnelle autorisée.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
