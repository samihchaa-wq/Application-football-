"""Real concurrent sessions against the disposable CI stack only.

No production URL or credentials are accepted. All identities are synthetic.
"""

from concurrent.futures import ThreadPoolExecutor
import json
import subprocess
import threading
import unittest
import uuid


LOCAL_DB = "postgresql://postgres:postgres@127.0.0.1:54322/postgres"
ADMIN_A = "a2500000-0000-4000-8000-000000000001"
ADMIN_B = "a2500000-0000-4000-8000-000000000002"
OTHER_ADMIN = "a2500000-0000-4000-8000-000000000003"
SEASON = "a2510000-0000-4000-8000-000000000001"
PLAYER_A = "a2520000-0000-4000-8000-000000000001"
PLAYER_B = "a2520000-0000-4000-8000-000000000002"


class LocalSqlError(subprocess.CalledProcessError):
    def __str__(self):
        return f"Disposable local SQL test failed: {self.stderr.strip()}"


def query(sql):
    result = subprocess.run(
        ["psql", LOCAL_DB, "-XAtq", "-v", "ON_ERROR_STOP=1"],
        input="set statement_timeout = '10s';\n" + sql,
        text=True, capture_output=True, timeout=20, check=False,
    )
    if result.returncode:
        raise LocalSqlError(result.returncode, ["psql", "disposable-local-db"],
                            output=result.stdout, stderr=result.stderr)
    return result.stdout.strip()


def as_admin(actor, sql, hold_lock=False):
    claims = json.dumps({"sub": actor, "role": "authenticated"})
    pause = "select pg_sleep(0.2);" if hold_lock else ""
    return query(
        f"begin; set local role authenticated; "
        f"set local request.jwt.claims = '{claims}'; "
        f"{sql} {pause} commit;"
    )


class WaitlistConcurrencyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.club = query("select (public.create_club('Concurrent Test', 'WLC')).id;")
        cls.other_club = query("select (public.create_club('Other Test', 'WLO')).id;")
        # Validate before interpolating generated fixture identifiers.
        uuid.UUID(cls.club)
        uuid.UUID(cls.other_club)
        cls.addClassCleanup(cls.cleanup)
        users = ",".join(
            f"('{actor}', 'waitlist-{i}@example.invalid', "
            f"'{{\"first_name\":\"Admin{chr(65 + i)}\"}}'::jsonb, "
            f"'{{\"club_id\":\"{club}\"}}'::jsonb)"
            for i, (actor, club) in enumerate([
                (ADMIN_A, cls.club), (ADMIN_B, cls.club),
                (OTHER_ADMIN, cls.other_club),
            ])
        )
        query(f"""
          begin;
          insert into auth.users(id,email,raw_user_meta_data,raw_app_meta_data)
          values {users};
          update public.profiles set role='admin', status='active'
          where id in ('{ADMIN_A}','{ADMIN_B}','{OTHER_ADMIN}');
          set local app.club_id = '{cls.club}';
          insert into public.seasons(id,name,status) values ('{SEASON}','2088-2089','open');
          insert into public.season_players(
            id,season_id,first_name,last_name,is_active,position,profile_id
          ) values
            ('{PLAYER_A}','{SEASON}','One','Synthetic',true,1,'{ADMIN_A}'),
            ('{PLAYER_B}','{SEASON}','Two','Synthetic',true,2,'{ADMIN_B}');
          insert into public.sport_waitlist_entries(
            season_id,season_player_id,position,source,created_by,updated_by
          ) values
            ('{SEASON}','{PLAYER_A}',1,'manual','{ADMIN_A}','{ADMIN_A}'),
            ('{SEASON}','{PLAYER_B}',2,'manual','{ADMIN_A}','{ADMIN_A}');
          commit;
        """)

    @classmethod
    def cleanup(cls):
        query(f"""
          delete from private.sport_admin_audit_log
            where club_id in ('{cls.club}','{cls.other_club}');
          delete from public.clubs where id in ('{cls.club}','{cls.other_club}');
          delete from auth.users where id in ('{ADMIN_A}','{ADMIN_B}','{OTHER_ADMIN}');
        """)

    def setUp(self):
        for player in (PLAYER_A, PLAYER_B):
            as_admin(ADMIN_A, f"select public.admin_set_waitlist_manual_count('{player}',0);")

    def count(self, player=PLAYER_A):
        return int(query(f"select manual_waitlist_count from public.sport_waitlist_entries "
                         f"where season_player_id='{player}';"))

    def parallel(self, operations):
        barrier = threading.Barrier(len(operations))

        def apply(operation):
            actor, player, delta, request = operation
            barrier.wait(timeout=5)
            return as_admin(actor, f"select public.admin_adjust_waitlist_manual_count("
                            f"'{player}',{delta},'{request}')->>'season_id';", hold_lock=True)

        with ThreadPoolExecutor(max_workers=len(operations)) as pool:
            # Consume every future so a deadlock or permission failure fails CI.
            results = list(pool.map(apply, operations))
        self.assertTrue(all(SEASON in result for result in results))

    def test_two_admins_add_two_credits(self):
        self.parallel([
            (ADMIN_A, PLAYER_A, 1, uuid.uuid4()),
            (ADMIN_B, PLAYER_A, 1, uuid.uuid4()),
        ])
        self.assertEqual(self.count(), 2)

    def test_duplicate_in_flight_gesture_counts_once(self):
        request = uuid.uuid4()
        operation = (ADMIN_A, PLAYER_A, 1, request)
        self.parallel([operation, operation])
        self.assertEqual(self.count(), 1)
        self.assertEqual(int(query("select count(*) from private.sport_admin_audit_log "
                                   f"where metadata->>'request_id'='{request}';")), 1)

    def test_different_players_do_not_deadlock_during_reorder(self):
        self.parallel([
            (ADMIN_A, PLAYER_A, 1, uuid.uuid4()),
            (ADMIN_B, PLAYER_B, 1, uuid.uuid4()),
        ])
        self.assertEqual((self.count(PLAYER_A), self.count(PLAYER_B)), (1, 1))

    def test_add_and_remove_both_apply(self):
        as_admin(ADMIN_A, f"select public.admin_set_waitlist_manual_count('{PLAYER_A}',3);")
        self.parallel([
            (ADMIN_A, PLAYER_A, 1, uuid.uuid4()),
            (ADMIN_B, PLAYER_A, -1, uuid.uuid4()),
        ])
        self.assertEqual(self.count(), 3)

    def test_other_club_cannot_adjust(self):
        with self.assertRaises(subprocess.CalledProcessError) as error:
            as_admin(OTHER_ADMIN, f"select public.admin_adjust_waitlist_manual_count("
                     f"'{PLAYER_A}',1,'{uuid.uuid4()}');")
        self.assertIn("Waitlist entry not found", error.exception.stderr)
        self.assertEqual(self.count(), 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
