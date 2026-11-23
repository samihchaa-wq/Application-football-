begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Migration 20261203030000 : les tâches pilotées par les matchs ne parcourent
-- que les clubs ayant du travail.

select ok(
  to_regprocedure('private.club_has_scheduled_work(uuid)') is not null
  and to_regprocedure('private.run_for_each_busy_club(text)') is not null,
  'les deux fonctions de parcours existent'
);

select is(
  (select count(*) from pg_proc p
   where p.oid in ('private.club_has_scheduled_work(uuid)'::regprocedure,
                   'private.run_for_each_busy_club(text)'::regprocedure)
     and (has_function_privilege('anon', p.oid, 'EXECUTE')
          or has_function_privilege('authenticated', p.oid, 'EXECUTE'))),
  0::bigint,
  'ni un visiteur ni un compte connecté ne peut les appeler'
);

select is(
  (select count(*) from pg_proc p
   where p.oid in ('private.club_has_scheduled_work(uuid)'::regprocedure,
                   'private.run_for_each_busy_club(text)'::regprocedure)
     and not coalesce(p.proconfig, '{}'::text[]) @> array['search_path=""']),
  0::bigint,
  'les deux fonctions ont un search_path vide'
);

select is(
  (select count(*) from cron.job
   where jobname in ('prediction-j5-reminders','sports-availability-reminders',
                     'sports-motm-jobs','finish-due-internal-matches',
                     'live-match-notification-dispatch','match-weather-refresh')
     and command like '%run_for_each_busy_club%'),
  6::bigint,
  'les six tâches pilotées par les matchs utilisent le parcours filtré'
);

select is(
  (select count(*) from cron.job
   where jobname in ('badge-unlock-notifications','process-season-wrapped-jobs')
     and command like '%run_for_each_club%'),
  2::bigint,
  'badges et bilan de saison gardent le parcours complet'
);

select * from finish();
rollback;
