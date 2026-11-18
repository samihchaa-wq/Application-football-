begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Le rappel de pronostic ne regarde d'abord que les matchs proches (voir
-- 20261124000000_rappel_pronostic_filtre_dates.sql). Ce filtre ne doit jamais
-- écarter un match pour lequel le rappel doit partir.

select like(
  pg_get_functiondef('public.push_prediction_j5_notifications()'::regprocedure),
  '%m.kickoff_at > now() - interval ''1 day''%m.kickoff_at < now() + interval ''2 days''%',
  'le rappel écarte d''abord les matchs hors de la fenêtre de dates'
);

select like(
  pg_get_functiondef('public.push_prediction_j5_notifications()'::regprocedure),
  '%m.kickoff_at < now() + interval ''2 days''%private.match_prediction_notification_at(m.kickoff_at)%',
  'le filtre de dates passe avant les calculs d''heure du rappel'
);

-- Preuve par grille : pour chaque coup d'envoi (toutes les 30 minutes, autour
-- des deux changements d'heure de 2026) et trois instants de la fenêtre
-- d'envoi (début, milieu, fin), si le rappel doit partir alors le match est
-- dans la fenêtre du filtre.
create temporary table reminder_grid on commit drop as
with kickoffs as (
  select k
  from generate_series(
         '2026-03-26 00:00:00+00'::timestamptz,
         '2026-03-31 00:00:00+00'::timestamptz,
         interval '30 minutes') as k
  union all
  select k
  from generate_series(
         '2026-10-22 00:00:00+00'::timestamptz,
         '2026-10-27 00:00:00+00'::timestamptz,
         interval '30 minutes') as k
), instants as (
  select
    kickoffs.k,
    private.match_prediction_notification_at(kickoffs.k) + offset_ as at
  from kickoffs,
       (values (interval '0 minutes'),
               (interval '5 minutes'),
               (interval '9 minutes 59 seconds')) as o(offset_)
)
select
  k,
  at,
  (
    at >= private.match_prediction_notification_at(k)
    and at < private.match_prediction_notification_at(k) + interval '10 minutes'
    and at < private.match_prediction_closes_at(k)
  ) as reminder_due,
  (k > at - interval '1 day' and k < at + interval '2 days') as inside_prefilter
from instants;

select cmp_ok(
  (select count(*) from reminder_grid where reminder_due),
  '>',
  50::bigint,
  'la grille contient de vrais cas où le rappel doit partir'
);

select is(
  (select count(*) from reminder_grid
   where reminder_due and not inside_prefilter),
  0::bigint,
  'aucun match dont le rappel doit partir n''est écarté par le filtre de dates'
);

select * from finish();
rollback;
