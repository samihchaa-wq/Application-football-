#!/usr/bin/env python3
"""Vrais tokens Auth et requêtes HTTP RLS/RPC/Storage, sur Supabase LOCAL.

Refuse tout host/port non local. N'utilise aucune clé de production.
"""
from __future__ import annotations
import base64
import json
import subprocess
import sys
import uuid
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen
from urllib.parse import urlsplit

API = "http://127.0.0.1:54321"
DB = "postgresql://postgres:postgres@127.0.0.1:54322/postgres"
PNG = base64.b64decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/ZL8AAAAASUVORK5CYII=")


def parse_status(raw: str) -> dict[str, str]:
    return {key: val.strip().strip('"').strip("'")
            for line in raw.splitlines() if "=" in line and not line.startswith("#")
            for key, val in [line.split("=", 1)]}


def assert_local(api: str, db: str) -> None:
    url = urlsplit(db)
    if api.rstrip("/") != API or url.hostname != "127.0.0.1" or url.port != 54322 or url.path != "/postgres":
        raise RuntimeError("Refus : ce test ne doit jamais toucher une base distante.")


def sql(statement: str) -> str:
    out = subprocess.run(
        ["psql", "-X", "-v", "ON_ERROR_STOP=1", "-At", DB, "-c", statement],
        capture_output=True, text=True, timeout=45,
    )
    if out.returncode:
        raise AssertionError("Echec SQL dans l'instance de test locale.")
    return out.stdout.strip()


def request(api: str, api_key: str, token: str, method: str,
            path: str, payload=None, binary: bytes | None = None, headers=None):
    data = binary if binary is not None else (json.dumps(payload).encode() if payload is not None else None)
    h = {"apikey": api_key, "Authorization": "Bearer " + token}
    if payload is not None:
        h["Content-Type"] = "application/json"
    h.update(headers or {})
    req = Request(api + path, data=data, headers=h, method=method)
    try:
        with urlopen(req, timeout=30) as resp:
            return resp.status, resp.read(200000)
    except HTTPError as e:
        return e.code, e.read(200000)


def ok(status, label):
    if not 200 <= status < 300:
        raise AssertionError(f"{label} : HTTP {status} au lieu de succès")


def denied(status, label):
    if status not in (400, 401, 403, 404, 409):
        raise AssertionError(f"{label} : HTTP {status} au lieu de refus")


def mk_user(api, service, anon, club, label):
    email = "qa-" + label + "-" + uuid.uuid4().hex[:12] + "@example.invalid"
    password = "Qa_" + uuid.uuid4().hex + "_Z1!"
    code, body = request(api, service, service, "POST", "/auth/v1/admin/users",
                         {"email": email, "password": password, "email_confirm": True,
                          "app_metadata": {"club_id": club},
                          "user_metadata": {"first_name": "QA", "last_name": label}})
    ok(code, "Création GoTrue")
    uid = str(uuid.UUID(json.loads(body)["id"]))
    # Le service Auth peut d'abord insérer le compte, puis associer le club
    # dans raw_app_meta_data. Forcer ici cette étape SERVEUR en local afin
    # de reproduire le parcours de register-account (jamais depuis le client).
    sql(f"update auth.users set raw_app_meta_data = "
        f"coalesce(raw_app_meta_data, '{{}}'::jsonb) || "
        f"jsonb_build_object('club_id', '{club}') where id='{uid}'")
    sql(f"update public.profiles set role='admin',status='active' where id='{uid}'")
    if sql(f"select count(*) from public.profiles where id='{uid}' and club_id='{club}' and status='active' and role='admin'") != "1":
        raise AssertionError("Profil ou rattachement du compte Auth incorrect.")
    code, body = request(api, anon, anon, "POST", "/auth/v1/token?grant_type=password",
                         {"email": email, "password": password})
    ok(code, "Connexion Auth locale")
    jwt = json.loads(body).get("access_token", "")
    if jwt.count(".") != 2:
        raise AssertionError("Le test n'a pas obtenu de JWT Auth.")
    return uid, jwt


def smoke(status_file: Path):
    env = parse_status(status_file.read_text())
    api, anon, service = env.get("API_URL", ""), env.get("ANON_KEY", ""), env.get("SERVICE_ROLE_KEY", "")
    assert_local(api, DB)
    if not anon or not service:
        raise RuntimeError("Clés éphémères locales non trouvées.")
    alpha = str(uuid.UUID(sql("select (public.create_club('QA Alpha HTTP', 'QAA')).id")))
    bravo = str(uuid.UUID(sql("select (public.create_club('QA Bravo HTTP', 'QAB')).id")))
    # Supabase seed a un club local par défaut : le désactiver pour les
    # comptes QA, afin qu'aucun profil ne soit créé dans le mauvais club.
    sql("delete from private.local_default_club")
    ua, ta = mk_user(api, service, anon, alpha, "alpha")
    ub, tb = mk_user(api, service, anon, bravo, "bravo")

    def get(token, path, headers=None):
        code, body = request(api, anon, token, "GET", path, headers=headers)
        ok(code, "GET " + path.split("?")[0])
        return json.loads(body)

    def visible(token, headers=None):
        return [r["id"] for r in get(token, "/rest/v1/clubs?select=id", headers)]

    if visible(ta) != [alpha] or visible(tb) != [bravo] or visible(tb, {"x-club-id": alpha}) != [bravo]:
        raise AssertionError("Fuite RLS / en-tête x-club-id exploitable.")
    if get(ta, "/rest/v1/rpc/is_admin") is not True:
        raise AssertionError("Admin A refusé avant suspension.")
    print("PASS Auth + deux vrais JWT + RLS clubs + en-tête falsifié")

    for token, color, label, extra in [
        (ta, "#AA1100", "Alpha", {}),
        (tb, "#0011BB", "Bravo", {"x-club-id": alpha}),
    ]:
        code, _ = request(api, anon, token, "POST",
                          "/rest/v1/rpc/admin_update_club_colors",
                          {"p_primary": color, "p_secondary": "#FFFFFF"}, headers=extra)
        ok(code, "RPC " + label)
    if sql(f"select primary_color from public.clubs where id='{alpha}'") != "#AA1100":
        raise AssertionError("Le club A a été modifié par un autre compte.")
    if sql(f"select primary_color from public.clubs where id='{bravo}'") != "#0011BB":
        raise AssertionError("RPC B non fonctionnelle.")
    code, _ = request(api, anon, tb, "POST", "/rest/v1/rpc/staff_validate_profile", {"p_profile_id": ua})
    denied(code, "Validation interclub")
    print("PASS RPC administrateur, modifications isolées, cible A refusée par B")

    pa = "/storage/v1/object/profile-photos/" + ua + "/qa-alpha.png"
    pb = "/storage/v1/object/profile-photos/" + ub + "/qa-bravo.png"
    for token, path in [(ta, pa), (tb, pb)]:
        code, _ = request(api, anon, token, "POST", path, binary=PNG,
                          headers={"Content-Type": "image/png"})
        ok(code, "Téléversement Storage légitime")
    auth_path = pa.replace("/storage/v1/object/", "/storage/v1/object/authenticated/", 1)
    code, body = request(api, anon, ta, "GET", auth_path)
    ok(code, "Photo A privée")
    if body != PNG:
        raise AssertionError("Les octets de l'image ont changé.")
    code, _ = request(api, anon, tb, "GET", auth_path)
    denied(code, "Lecture interclub Storage")
    code, _ = request(api, anon, tb, "POST",
                      "/storage/v1/object/profile-photos/" + ua + "/forged.png",
                      binary=PNG, headers={"Content-Type": "image/png"})
    denied(code, "Dépôt Storage dans le dossier du club A")
    print("PASS Storage upload + téléchargement + refus lecture/écriture entre clubs")

    sql(f"update public.clubs set status='suspended' where id='{alpha}'")
    if get(ta, "/rest/v1/rpc/is_admin") is not False:
        raise AssertionError("Un club suspendu garde ses droits admin.")
    code, _ = request(api, anon, ta, "POST", "/rest/v1/rpc/admin_update_club_colors",
                      {"p_primary": "#CC0000", "p_secondary": "#FFFFFF"})
    denied(code, "RPC admin d'un club suspendu")
    if get(tb, "/rest/v1/rpc/is_admin") is not True:
        raise AssertionError("La suspension du club A a impacté B.")
    sql(f"update public.clubs set status='active' where id='{alpha}'")
    if get(ta, "/rest/v1/rpc/is_admin") is not True:
        raise AssertionError("La réactivation n'a pas rendu les droits.")
    print("PASS suspension/réactivation avec les mêmes JWT et maintien des droits du club B")
    print("SUCCÈS : preuve HTTP Auth/RLS/RPC/Storage sur Supabase local uniquement.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage : tenant_http_smoke.py FICHIER_STATUS_LOCAL")
    smoke(Path(sys.argv[1]))
