#!/usr/bin/env python3
"""Local contract guard reused from AS Grinta, adapted for Petit Filet.

Checks the Flutter/Edge password policy and the commercial Auth endpoint
without contacting Supabase or mutating a database.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from urllib.parse import urlparse


class ContractError(ValueError):
    """Password contract drift or incorrect commercial configuration."""


def _unique_number(source: str, expression: str, label: str) -> int:
    values = re.findall(expression, source)
    if len(values) != 1:
        raise ContractError(f"{label}: expected exactly one constant, found {len(values)}")
    return int(values[0])


def validate(root: Path) -> tuple[int, int]:
    dart = (root / "lib/core/security/password_policy.dart").read_text(
        encoding="utf-8"
    )
    edge = (
        root / "supabase/functions/register-account/password_policy.ts"
    ).read_text(encoding="utf-8")
    registration = (
        root / "supabase/functions/register-account/index.ts"
    ).read_text(encoding="utf-8")
    config = json.loads(
        (root / "config/production.json").read_text(encoding="utf-8")
    )

    bounds = {}
    for key, expected_dart, expected_edge in (
        (
            "minimum",
            r"static\s+const\s+int\s+minLength\s*=\s*(\d+)\s*;",
            r"export\s+const\s+MIN_PASSWORD_LENGTH\s*=\s*(\d+)\s*;",
        ),
        (
            "maximum",
            r"static\s+const\s+int\s+maxLength\s*=\s*(\d+)\s*;",
            r"export\s+const\s+MAX_PASSWORD_LENGTH\s*=\s*(\d+)\s*;",
        ),
    ):
        left = _unique_number(dart, expected_dart, f"Flutter {key}")
        right = _unique_number(edge, expected_edge, f"Edge {key}")
        if left != right:
            raise ContractError(
                f"{key}: Flutter ({left}) and Edge ({right}) disagree"
            )
        bounds[key] = left

    if bounds["minimum"] < 12 or bounds["maximum"] > 72:
        raise ContractError("Commercial password length left the 12-72 policy")
    if bounds["minimum"] > bounds["maximum"]:
        raise ContractError("Minimum password length exceeds maximum")

    # Keep client/server checks aligned. Tests of their runtime behaviour are
    # maintained separately in Flutter and Deno.
    for category in ("a-z", "A-Z", "0-9"):
        if not re.search(
            r"RegExp\(\s*r['\"]\[" + category + r"\]['\"]\s*\)",
            dart,
        ):
            raise ContractError(f"Flutter is missing password category [{category}]")
        if f"/[{category}]/" not in edge:
            raise ContractError(f"Edge is missing password category [{category}]")

    if not re.search(
        r'import\s*\{\s*validatePassword\s*\}\s*from\s*'
        r'["\']\./password_policy\.ts["\']\s*;',
        registration,
    ):
        raise ContractError("Account registration no longer imports the validator")
    if not re.search(r"\bvalidatePassword\s*\(\s*password\s*\)", registration):
        raise ContractError("Account registration no longer invokes the validator")

    endpoint = urlparse(config.get("SUPABASE_URL", ""))
    if endpoint.scheme != "https" or endpoint.hostname != (
        "jvxkhgdopslctpcjrhzw.supabase.co"
    ):
        raise ContractError("Production configuration does not target Petit Filet")

    username_domain = config.get("USERNAME_DOMAIN", "")
    if not isinstance(username_domain, str) or not username_domain.strip():
        raise ContractError("The username domain is absent")
    if "as-grinta" in username_domain.lower():
        raise ContractError("The old club's username domain must not be reused")

    return bounds["minimum"], bounds["maximum"]


if __name__ == "__main__":
    try:
        minimum, maximum = validate(Path(__file__).resolve().parents[1])
    except (ContractError, OSError, ValueError, KeyError) as error:
        print(f"Auth contract check failed: {error}", file=sys.stderr)
        raise SystemExit(1) from error
    print(f"Auth contract OK: Flutter + Edge agree on {minimum}-{maximum} characters")
