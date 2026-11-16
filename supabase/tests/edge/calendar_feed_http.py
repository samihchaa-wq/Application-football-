#!/usr/bin/env python3
"""Calendar Edge + PostgREST integration on the disposable LOCAL CI stack only."""
from __future__ import annotations

import subprocess
import sys
import tempfile
import time
import uuid
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import HTTPRedirectHandler, Request, build_opener

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tool" / "qa"))
from tenant_http_smoke import API, DB, assert_local, mk_user, parse_status, sql


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def main() -> None:
    # Do not accept a target URL, DB credential, or production token argument.
    status = subprocess.run(
        ["supabase", "status", "-o", "env"], capture_output=True,
        text=True, check=True, timeout=30, cwd=ROOT,
    )
    env = parse_status(status.stdout)
    assert_local(env.get("API_URL", ""), DB)
    anon, service = env.get("ANON_KEY", ""), env.get("SERVICE_ROLE_KEY", "")
    if not anon or not service:
        raise RuntimeError("Ephemeral local keys missing")

    # Redirects are inspected, never followed to an app or any external URL.
    opener = build_opener(NoRedirect())

    def request(token: str, method="GET", navigate=False):
        token = str(uuid.UUID(token))
        headers = {"apikey": anon, "Authorization": "Bearer " + anon}
        if navigate:
            headers["Sec-Fetch-Mode"] = "navigate"
        req = Request(
            API + "/functions/v1/calendar-feed?token=" + token,
            headers=headers, method=method,
        )
        try:
            with opener.open(req, timeout=20) as response:
                return response.status, response.read(200000), response.headers
        except HTTPError as error:
            return error.code, error.read(200000), error.headers

    with tempfile.TemporaryFile(mode="w+") as logs:
        process = subprocess.Popen(
            ["supabase", "functions", "serve", "calendar-feed"],
            cwd=ROOT, stdout=logs, stderr=subprocess.STDOUT,
        )
        try:
            missing = str(uuid.uuid4())
            # An exact response from this handler, not a gateway 404, is needed.
            deadline = time.monotonic() + 90
            while True:
                if process.poll() is not None:
                    raise AssertionError("Local Edge server stopped before readiness")
                try:
                    code, body, _ = request(missing)
                    if code == 404 and body == b"Not found":
                        break
                except (URLError, TimeoutError):
                    pass
                if time.monotonic() >= deadline:
                    raise AssertionError("Local calendar handler did not become ready")
                time.sleep(1)

            alpha = str(uuid.UUID(sql(
                "select (public.create_club('QA Calendar Alpha', 'QCA')).id"
            )))
            bravo = str(uuid.UUID(sql(
                "select (public.create_club('QA Calendar Bravo', 'QCB')).id"
            )))
            sql("delete from private.local_default_club")
            user_a, _ = mk_user(API, service, anon, alpha, "calendar-alpha")
            user_b, _ = mk_user(API, service, anon, bravo, "calendar-bravo")

            def subscribe(user, club):
                # Real token and club assignment from the canonical table.
                return str(uuid.UUID(sql(
                    "insert into public.calendar_subscriptions(profile_id,club_id) "
                    f"values ('{user}','{club}') on conflict(profile_id) "
                    "do update set club_id=excluded.club_id returning token"
                ).splitlines()[0]))

            token_a = subscribe(user_a, alpha)
            token_b = subscribe(user_b, bravo)
            code, body, _ = request(token_a)
            assert code == 200 and b"BEGIN:VCALENDAR" in body, "Active club must have a valid feed"
            assert b"QA Calendar Alpha" in body and b"QA Calendar Bravo" not in body
            assert request(token_a, method="HEAD")[0] == 200
            assert request(token_a, navigate=True)[0] == 302
            print("PASS real Edge and PostgREST: active GET, HEAD and redirect")

            sql(f"update public.clubs set status='suspended' where id='{alpha}'")
            for method, navigate in [("GET", False), ("HEAD", False), ("GET", True)]:
                code, _, headers = request(token_a, method=method, navigate=navigate)
                assert code == 404, "Suspended club must be refused"
                assert not headers.get("Location"), "Suspended club must not redirect"
            code, body, _ = request(token_b)
            assert code == 200 and b"QA Calendar Bravo" in body, "Other club must keep access"
            assert b"QA Calendar Alpha" not in body
            print("PASS suspension on the same token; other club unaffected")

            sql(f"update public.clubs set status='active' where id='{alpha}'")
            assert request(token_a)[0] == 200, "Reactivated club must recover its feed"
            sql(f"update public.profiles set status='pending' where id='{user_a}'")
            assert request(token_a)[0] == 404, "Inactive profile must be refused"
            sql(f"update public.profiles set status='active' where id='{user_a}'")
            sql(f"delete from public.calendar_subscriptions where profile_id='{user_a}'")
            assert request(token_a)[0] == 404, "Revoked token must be refused"
            print("PASS reactivation, inactive profile and revoked token")
            print("PASS local calendar HTTP integration; no production target")
        finally:
            process.terminate()
            try:
                process.wait(timeout=15)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)
            # Logs may contain ephemeral credentials. Never print or upload them.


if __name__ == "__main__":
    if len(sys.argv) != 1:
        raise SystemExit("No target or credential arguments are accepted")
    main()
