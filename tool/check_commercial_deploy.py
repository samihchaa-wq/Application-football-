#!/usr/bin/env python3
"""Preflight fail-closed avant la publication de l'application multiclub.

Ce contrôle vérifie uniquement les informations PUBLIQUES du client.
Il ne contacte aucune base et n'affiche jamais de clé dans les journaux.
"""
from __future__ import annotations

import base64
import json
import os
import re
import sys
from pathlib import Path
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_PUBLIC_URL = "https://samihchaa-wq.github.io/Application-football-/"
PERSONAL_PROJECT_REFS = {
    "ovzijmqrnsgcmryinkfa",  # AS Grinta : production privée
    "yqfewxadpyulgxehhpcu",  # Carte soirée : production privée
}
PROJECT_HOST = re.compile(r"^([a-z0-9]{20})\.supabase\.co$")
# Adresse définitive (domaine propre ou *.pages.dev), fournie par le workflow
# Cloudflare via la variable d'environnement COMMERCIAL_PUBLIC_URL.
CUSTOM_URL_ENV = "COMMERCIAL_PUBLIC_URL"
FORBIDDEN_HOST_PARTS = ("grinta", "github.io")


def custom_public_url_problem(url: str) -> str | None:
    """Raison du refus d'une adresse publique définitive, ou None si elle convient."""
    parsed = urlsplit(url)
    host = (parsed.hostname or "").lower()
    if (
        parsed.scheme != "https"
        or not host
        or "." not in host
        or parsed.path != "/"
        or parsed.query
        or parsed.fragment
        or parsed.username
        or parsed.password
        or parsed.port
    ):
        return "L'adresse publique doit être https://domaine/ (racine, sans port ni paramètre)."
    if any(part in host for part in FORBIDDEN_HOST_PARTS):
        return "L'adresse publique ne doit viser ni AS Grinta ni GitHub Pages."
    return None


def _jwt_role(token: str) -> str | None:
    parts = token.split(".")
    if len(parts) != 3:
        return None
    try:
        payload = parts[1] + "=" * (-len(parts[1]) % 4)
        data = json.loads(base64.urlsafe_b64decode(payload).decode("utf-8"))
        return data.get("role") if isinstance(data, dict) else None
    except (ValueError, UnicodeDecodeError):
        return None


def check(config: object, custom_public_url: str | None = None) -> list[str]:
    """Liste des anomalies empêchant la publication. Aucun secret n'est retourné.

    custom_public_url : adresse définitive autorisée en plus de GitHub Pages
    (par défaut lue dans COMMERCIAL_PUBLIC_URL ; vide = GitHub Pages seulement).
    """
    if custom_public_url is None:
        custom_public_url = os.environ.get(CUSTOM_URL_ENV, "").strip() or None
    if not isinstance(config, dict):
        return ["La configuration de production doit être un objet JSON."]

    errors: list[str] = []

    url = config.get("SUPABASE_URL")
    if not isinstance(url, str):
        errors.append("SUPABASE_URL manquante.")
    else:
        parsed = urlsplit(url)
        match = PROJECT_HOST.fullmatch(parsed.hostname or "")
        if (
            parsed.scheme != "https"
            or not match
            or parsed.path not in ("", "/")
            or parsed.query
            or parsed.fragment
            or parsed.username
            or parsed.password
        ):
            errors.append("SUPABASE_URL doit désigner un vrai projet Supabase en HTTPS.")
        elif match.group(1) in PERSONAL_PROJECT_REFS:
            errors.append("SUPABASE_URL pointe vers une base personnelle : déploiement interdit.")

    key = config.get("SUPABASE_ANON_KEY")
    if not isinstance(key, str) or not key.strip():
        errors.append("La clé publique Supabase manque.")
    elif key.startswith("sb_publishable_") and len(key) >= 30:
        pass
    elif key.startswith("eyJ") and _jwt_role(key) == "anon":
        pass
    else:
        errors.append("Utiliser uniquement une clé publique Supabase valide, jamais une clé secrète.")

    public_url = config.get("PUBLIC_APP_URL")
    if custom_public_url:
        problem = custom_public_url_problem(custom_public_url)
        if problem:
            errors.append(problem)
        elif public_url != custom_public_url:
            errors.append("PUBLIC_APP_URL doit être l'adresse définitive configurée.")
    elif public_url != EXPECTED_PUBLIC_URL:
        errors.append("PUBLIC_APP_URL doit cibler Application-football-, pas AS Grinta.")

    domain = config.get("USERNAME_DOMAIN")
    if not isinstance(domain, str) or not domain.strip() or "A-REMPLACER" in domain:
        errors.append("USERNAME_DOMAIN doit être configuré.")

    return errors


def main() -> int:
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "config" / "production.json"
    try:
        config = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        print(f"::error::Configuration illisible : {type(exc).__name__}")
        return 1

    errors = check(config)
    if errors:
        for problem in errors:
            print(f"::error::{problem}")
        print("Publication bloquée. Aucune donnée personnelle n'a été modifiée.")
        return 1

    print("Configuration commerciale validée (URL, clé publique et destination).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
