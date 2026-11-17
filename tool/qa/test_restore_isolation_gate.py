"""Fail-closed tests for #91. No real backup, network or production secrets."""
import subprocess
import unittest
from unittest.mock import patch

from restore_isolation_gate import (
    UnsafeRestore, assert_url_target, assert_no_remote_secrets,
    assert_loopback_only, preflight, db_counts_data_sql, safe_psql_select,
    post_restore_counts,
)

DB = 'postgresql://postgres:local-only@127.0.0.1:54322/postgres'
API = 'http://127.0.0.1:54321'
GOOD = {"RESTORE_LOCAL_DB_URL": DB, "RESTORE_LOCAL_API_URL": API}
V4 = 'Iface\tDestination\tGateway\tFlags\tRefCnt\tUse\tMetric\tMask\tMTU\tWindow\tIRTT\nlo\t0000007F\t00000000\t0001\t0\t0\t0\t000000FF\t0\t0\t0\n'
V6 = '00000000000000000000000000000001 80 00000000000000000000000000000000 00 00000000 00000000 00000000 00000001 lo\n'


class RestoreIsolationGateTests(unittest.TestCase):
    def test_local_port_and_loopback_only(self):
        assert_url_target(DB, API)
        assert_loopback_only([(1, 'lo')], V4, V6)
        preflight(GOOD, interfaces=[(1, 'lo')], routes_v4=V4,
                  routes_v6=V6, system='Linux')

    def test_rejects_production_and_tunnels_other_ports(self):
        for db in (
            'postgresql://postgres:secret@db.jvxkhgdopslctpcjrhzw.supabase.co:5432/postgres',
            'postgresql://postgres:secret@localhost:54322/postgres',
            'postgresql://postgres:secret@127.0.0.1:5432/postgres',
            'postgresql://postgres:secret@127.0.0.1:54322/other',
            'postgresql://postgres:secret@127.0.0.1:54322/postgres?sslmode=verify-full',
        ):
            with self.subTest(db=db.split('@')[-1]):
                with self.assertRaises(UnsafeRestore):
                    assert_url_target(db, API)
        with self.assertRaises(UnsafeRestore):
            assert_url_target(DB, 'https://jvxkhgdopslctpcjrhzw.supabase.co')
        with self.assertRaises(UnsafeRestore):
            assert_url_target(DB, 'http://127.0.0.1:8080')

    def test_rejects_default_route_and_extra_interfaces(self):
        with self.assertRaises(UnsafeRestore):
            assert_loopback_only([(1, 'lo'), (2, 'eth0')], V4, V6)
        with self.assertRaises(UnsafeRestore):
            assert_loopback_only([(1, 'lo')], V4 + 'eth0\t00000000\t0100000A\n', V6)
        with self.assertRaises(UnsafeRestore):
            assert_loopback_only([(1, 'lo')], V4, V6 + '0 0 0 0 0 0 eth0\n')
        with self.assertRaises(UnsafeRestore):
            assert_loopback_only([(1, 'lo')], 'bad route table', '')

    def test_secrets_and_notifications_fail_closed(self):
        for key in ('PRODUCTION_DB_URL', 'SUPABASE_ACCESS_TOKEN',
                    'BACKUP_PASSPHRASE', 'SMTP_PASSWORD', 'PUSH_INTERNAL_TOKEN',
                    'WEBHOOK_TARGET'):
            with self.subTest(key=key):
                with self.assertRaises(UnsafeRestore):
                    assert_no_remote_secrets({key: 'redacted'})
        assert_no_remote_secrets({'RESTORE_LOCAL_DB_URL': DB})

    def test_parse_copy_dump_counts(self):
        sql = '\n'.join('COPY '+name+' (id) FROM stdin;\n'+('1\n'*n)+'\\.\n'
                        for name, n in {
                           'auth.users': 2, 'public.clubs': 2,
                           'public.profiles': 2, 'public.seasons': 1,
                           'public.matches': 4, 'public.match_predictions': 5,
                        }.items())
        counts = db_counts_data_sql(sql)
        self.assertEqual(counts['auth.users'], 2)
        self.assertEqual(counts['public.match_predictions'], 5)
        with self.assertRaises(UnsafeRestore):
            db_counts_data_sql(sql.replace('\\.\n', '', 1))
        with self.assertRaises(UnsafeRestore):
            db_counts_data_sql('COPY public.clubs (id) FROM stdin;\n1\n\\.\n')

    @patch('restore_isolation_gate.subprocess.run')
    def test_psql_never_passes_password_in_arguments_or_logs(self, run):
        run.return_value = subprocess.CompletedProcess([], 0, b'1\n', b'')
        self.assertEqual(safe_psql_select('select count(*) from auth.users;', GOOD), '1')
        argv, kwargs = run.call_args.args[0], run.call_args.kwargs
        self.assertNotIn('local-only', ' '.join(argv))
        self.assertEqual(kwargs['env']['PGPASSWORD'], 'local-only')
        run.return_value = subprocess.CompletedProcess([], 1, b'', b'PRIVATE ERROR')
        with self.assertRaises(UnsafeRestore) as ctx:
            safe_psql_select('select 1;', GOOD)
        self.assertNotIn('PRIVATE ERROR', str(ctx.exception))

    @patch('restore_isolation_gate.safe_psql_select')
    @patch('restore_isolation_gate.preflight')
    def test_postrestore_fails_if_any_table_or_cron_differs(self, gate, psql):
        psql.side_effect = ['2','2','5','4','2','1','0','f']
        counts = {'auth.users':2,'public.clubs':2,'public.profiles':2,
                  'public.seasons':1,'public.matches':4,'public.match_predictions':5}
        verified = post_restore_counts(counts, GOOD)
        self.assertFalse(verified['full_restore_proven'])
        self.assertFalse(verified['storage_bytes_checked'])
        self.assertFalse(verified['rls_rpc_jwt_checked'])
        psql.side_effect = ['2','2','99']
        with self.assertRaises(UnsafeRestore):
            post_restore_counts(counts, GOOD)
        psql.side_effect = ['2','2','5','4','2','1','0','t','1']
        with self.assertRaises(UnsafeRestore):
            post_restore_counts(counts, GOOD)


if __name__ == '__main__':
    unittest.main()
