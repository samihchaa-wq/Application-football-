#!/usr/bin/env python3
"""Static, fail-closed security contract for deployed Edge Function sources."""

from __future__ import annotations

import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
CONFIG_PATH = ROOT / "supabase" / "config.toml"
FUNCTIONS_DIR = ROOT / "supabase" / "functions"


class ContractError(AssertionError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ContractError(message)


def source(slug: str) -> str:
    path = FUNCTIONS_DIR / slug / "index.ts"
    require(path.is_file(), f"source Edge manquante: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def function_file(slug: str, filename: str) -> str:
    path = FUNCTIONS_DIR / slug / filename
    require(path.is_file(), f"source Edge manquante: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def require_in_order(text: str, first: str, second: str, message: str) -> None:
    first_index = text.find(first)
    second_index = text.find(second)
    require(first_index >= 0, f"marqueur absent: {first!r}")
    require(second_index >= 0, f"marqueur absent: {second!r}")
    require(first_index < second_index, message)


def main() -> int:
    config = tomllib.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    functions = config.get("functions", {})

    expected_jwt = {
        "manage-user": True,
        "claim-account": True,
        "register-account": False,
        "account-email": False,
        "claim-club": True,
        "send-push": False,
        "send-prediction-reminders": True,
        "calendar-feed": False,
    }
    versioned_functions = {
        path.name
        for path in FUNCTIONS_DIR.iterdir()
        if path.is_dir() and (path / "index.ts").is_file()
    }
    require(
        versioned_functions == set(expected_jwt),
        "inventaire Edge inattendu: "
        f"présent={sorted(versioned_functions)}, "
        f"attendu={sorted(expected_jwt)}",
    )
    require(
        set(functions) == set(expected_jwt),
        "configuration Edge inattendue: "
        f"présent={sorted(functions)}, attendu={sorted(expected_jwt)}",
    )
    for slug, expected in expected_jwt.items():
        actual = functions[slug].get("verify_jwt")
        require(
            actual is expected,
            f"{slug}: verify_jwt={actual!r}, attendu {expected!r}",
        )

    manage = source("manage-user")
    for marker in (
        'req.method !== "POST"',
        'authHeader?.startsWith("Bearer ")',
        "contentLength > 16_384",
        "callerClient.auth.getUser(token)",
        'String(callerProfile?.role) !== "admin"',
        'callerProfile?.status !== "active"',
        'targetProfile.role === "admin"',
        '.eq("role", "admin")',
        '"The last active admin cannot be deleted"',
        "deleteProfileWithRetry(admin, userId)",
        # Cloisonnement entre clubs : la clé de service contourne les règles
        # d'accès, la fonction doit donc filtrer elle-même sur le club.
        '.select("role,status,club_id")',
        '"x-club-id": clubId',
    ):
        require(marker in manage, f"manage-user: garde absente: {marker}")
    require(
        manage.count('.eq("club_id", clubId)') >= 3,
        "manage-user doit borner chaque lecture de compte au club de l’administrateur",
    )
    require(
        "AS-Grinta" not in manage,
        "manage-user ne doit pas renvoyer vers l’adresse d’un club en particulier",
    )
    require(
        'String(callerProfile?.role) !== "moderateur"' not in manage,
        "manage-user ne doit plus référencer le rôle moderateur retiré",
    )
    require_in_order(
        manage,
        "callerClient.auth.getUser(token)",
        "createClient(supabaseUrl, serviceRoleKey",
        "manage-user doit valider le JWT avant de créer le client privilégié",
    )
    require_in_order(
        manage,
        'callerProfile?.status !== "active"',
        "const body = await req.json()",
        "manage-user doit vérifier l’admin actif avant de traiter le corps",
    )
    require_in_order(
        manage,
        'targetProfile.role === "admin"',
        'admin.rpc(\n        "prepare_profile_for_hard_deletion"',
        "manage-user doit protéger le dernier admin avant toute suppression",
    )

    register = source("register-account")
    for marker in (
        'req.method !== "POST"',
        "MAX_BODY_BYTES = 4_096",
        "RequestBodyTooLargeError",
        'req.headers.get("content-length")',
        "req.body.getReader()",
        "totalBytes > maxBytes",
        "await reader.cancel()",
        "readBoundedJson<Record<string, unknown>>(req, MAX_BODY_BYTES)",
        '"consume_registration_rate_limit"',
        "validatePassword(password)",
        "SUPABASE_SERVICE_ROLE_KEY",
        "admin.auth.admin.deleteUser",
        # Le club vient d'un code d'invitation valide ou d'une création, et il
        # est posé dans une zone que le compte ne peut pas modifier.
        '"club_for_invite_code"',
        "app_metadata: { club_id: club.id }",
        '"found_club"',
        '"discard_empty_club"',
    ):
        require(marker in register, f"register-account: garde absente: {marker}")
    require(
        "body = await req.json()" not in register,
        "register-account ne doit pas revenir à une lecture non bornée avec req.json()",
    )
    require_in_order(
        register,
        "readBoundedJson<Record<string, unknown>>(req, MAX_BODY_BYTES)",
        "validatePassword(password)",
        "register-account doit lire de façon bornée puis valider la demande avant la création Auth",
    )
    require_in_order(
        register,
        "validatePassword(password)",
        '"consume_registration_rate_limit"',
        "register-account doit rejeter les demandes invalides avant de consommer le quota partagé",
    )
    require_in_order(
        register,
        '"consume_registration_rate_limit"',
        "admin.auth.admin.createUser",
        "register-account doit limiter le débit avant la création Auth",
    )

    # Les deux exemplaires de l'aide d'envoi d'e-mails doivent rester identiques.
    require(
        function_file("account-email", "account_email.ts")
        == function_file("register-account", "account_email.ts"),
        "account_email.ts doit être identique dans account-email et register-account",
    )

    account_email = source("account-email")
    for marker in (
        'req.method !== "POST"',
        "MAX_BODY_BYTES = 2_048",
        "RequestBodyTooLargeError",
        "req.body.getReader()",
        '"consume_email_rate_limit"',
        '"confirm_contact_email"',
        '"request_contact_email"',
        '"profile_for_recovery_email"',
        "callerClient.auth.getUser(",
        "readMailConfig()",
    ):
        require(marker in account_email, f"account-email: garde absente: {marker}")
    require(
        "body = await req.json()" not in account_email,
        "account-email ne doit pas lire le corps sans borne",
    )
    # La demande de lien ne doit jamais partir avant le plafond de débit, ni
    # pour un compte non authentifié (confirmation).
    require_in_order(
        account_email,
        'action === "request-confirmation"',
        "callerClient.auth.getUser(",
        "account-email: la confirmation doit exiger un compte connecté",
    )
    require_in_order(
        account_email,
        '"consume_email_rate_limit"',
        '"profile_for_recovery_email"',
        "account-email doit limiter le débit avant de chercher un compte",
    )
    # La réponse à une demande de récupération ne doit pas dépendre de
    # l'existence du compte.
    require(
        account_email.count("return jsonResponse({ sent: true });") >= 2,
        "account-email doit répondre pareil que l'adresse existe ou non",
    )
    require(
        "Deno.env.get(\"MAIL_API_KEY\")" in function_file("account-email", "account_email.ts"),
        "la clé du service d'e-mail doit venir de l'environnement",
    )

    claim_club = source("claim-club")
    for marker in (
        'req.method !== "POST"',
        "MAX_BODY_BYTES = 4_096",
        "req.body.getReader()",
        "callerClient.auth.getUser(accessToken)",
        '"consume_registration_rate_limit"',
        '"club_for_invite_code"',
        '"found_club"',
        "app_metadata: { club_id: club.id }",
    ):
        require(marker in claim_club, f"claim-club: garde absente: {marker}")
    require(
        "user_metadata: { club_id" not in claim_club,
        "claim-club ne doit jamais écrire le club dans les métadonnées modifiables",
    )
    # Le compte doit être identifié avant toute écriture, et un compte qui a
    # déjà un profil ne doit pas pouvoir changer de club.
    require_in_order(
        claim_club,
        "callerClient.auth.getUser(accessToken)",
        '"consume_registration_rate_limit"',
        "claim-club doit identifier le compte avant tout le reste",
    )
    require_in_order(
        claim_club,
        "Ce compte appartient déjà à un club.",
        "app_metadata: { club_id: club.id }",
        "claim-club doit refuser un compte déjà rattaché avant d'écrire le club",
    )

    push = source("send-push")
    for marker in (
        'req.method !== "POST"',
        'req.headers.get("x-push-token")',
        '"internal_push_config"',
        "await secretsEqual(token, String(config.token))",
        "readBoundedJson<PushRequestBody>(req)",
        "RequestBodyTooLargeError",
        'return new Response("non autorisé", { status: 401 })',
        'return new Response("corps trop volumineux", { status: 413 })',
    ):
        require(marker in push, f"send-push: garde absente: {marker}")
    require(
        "token !== config.token" not in push,
        "send-push ne doit plus comparer le secret interne directement",
    )
    require_in_order(
        push,
        "await secretsEqual(token, String(config.token))",
        "readBoundedJson<PushRequestBody>(req)",
        "send-push doit valider le secret interne avant de traiter le corps",
    )
    require_in_order(
        push,
        "await secretsEqual(token, String(config.token))",
        'supabase.rpc("internal_push_dispatch"',
        "send-push doit valider le secret interne avant toute distribution",
    )

    push_security = function_file("send-push", "request_security.ts")
    for marker in (
        "MAX_BODY_BYTES = 16_384",
        'crypto.subtle.digest("SHA-256"',
        "difference |= candidateDigest[index] ^ expectedDigest[index]",
        'req.headers.get("content-length")',
        "req.body.getReader()",
        "totalBytes > maxBytes",
        "await reader.cancel()",
    ):
        require(
            marker in push_security,
            f"send-push/request_security: garde absente: {marker}",
        )

    calendar = source("calendar-feed")
    for marker in (
        'req.method !== "GET" && req.method !== "HEAD"',
        'searchParams.get("token")',
        "UUID_RE.test(token)",
        'from("calendar_subscriptions")',
        '.eq("token", token)',
        '.eq("profiles.status", "active")',
        'Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")',
        'from("matches")',
        'STATUS:CONFIRMED',
        'Cache-Control": "no-cache, no-store, must-revalidate"',
    ):
        require(marker in calendar, f"calendar-feed: garde absente: {marker}")
    # Un match annule ou supprime ne doit jamais reparaitre dans le flux : le
    # publier en evenement annule laissait une ligne barree dans l'agenda de
    # l'abonne au lieu de l'en retirer.
    require(
        'if (String(row.status ?? "") === "annule") return "";' in calendar,
        "calendar-feed doit omettre les matchs annules",
    )
    require(
        '.eq("club_id", subscription.club_id)' in calendar,
        "calendar-feed doit borner les matchs au club de l’abonné",
    )
    require(
        "CANCELLED" not in calendar,
        "calendar-feed ne doit republier aucun evenement annule",
    )
    require(
        "calendar_match_tombstones" not in calendar,
        "calendar-feed ne doit plus republier les matchs supprimes",
    )
    require_in_order(
        calendar,
        "UUID_RE.test(token)",
        'from("calendar_subscriptions")',
        "calendar-feed doit valider le token avant toute lecture privilégiée",
    )
    require_in_order(
        calendar,
        '.eq("profiles.status", "active")',
        'from("matches")',
        "calendar-feed doit vérifier le profil actif avant de charger le calendrier",
    )

    for slug in ("claim-account", "send-prediction-reminders"):
        retired = source(slug)
        require('req.method !== "POST"' in retired, f"{slug}: méthode non filtrée")
        require(
            'status: 410' in retired and '"Endpoint retired"' in retired,
            f"{slug}: l’endpoint neutralisé doit répondre 410",
        )

    print("Edge security contract: OK")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ContractError as error:
        print(f"Edge security contract: FAILED: {error}", file=sys.stderr)
        raise SystemExit(1)
