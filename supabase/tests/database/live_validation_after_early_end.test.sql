begin;
set local search_path = public, extensions, pg_catalog;
select plan(5);

-- Un Live lancé puis terminé avant l'heure officielle doit pouvoir être
-- validé : le garde-fou « match futur » suit la même règle que la validation
-- du compte rendu (Live terminé = match jouable comme terminé).
insert into auth.users(id,email,raw_user_meta_data) values
('4b100000-0000-0000-0000-000000000001','live-early-admin@example.invalid','{"first_name":"Live","last_name":"Early"}'::jsonb);

update public.profiles
set role='admin',status='active',updated_at=now()
where id='4b100000-0000-0000-0000-000000000001';

insert into public.seasons(id,name,status)
values('4b200000-0000-0000-0000-000000000001','2106-2107','open');

insert into public.matches(
  id,season_id,match_date,match_time,location,planned_duration_minutes,status,
  match_type,created_by
) values
(
  '4b300000-0000-0000-0000-000000000001',
  '4b200000-0000-0000-0000-000000000001',
  current_date + 1,'20:00'::time,'domicile',90,'a_venir','amical',
  '4b100000-0000-0000-0000-000000000001'
),
(
  '4b300000-0000-0000-0000-000000000002',
  '4b200000-0000-0000-0000-000000000001',
  current_date + 2,'21:00'::time,'domicile',90,'a_venir','amical',
  '4b100000-0000-0000-0000-000000000001'
);

-- Sans Live terminé : un match futur reste impossible à marquer terminé.
select throws_ok(
  $$update public.matches set status='termine'
    where id='4b300000-0000-0000-0000-000000000001'$$,
  '22023',
  null,
  'un match futur sans Live terminé ne peut pas être marqué terminé'
);

-- Live encore en cours : toujours refusé.
insert into public.match_live_sessions(
  match_id,state,planned_duration_minutes,half,elapsed_seconds,running_since,
  updated_by
) values (
  '4b300000-0000-0000-0000-000000000002','running',90,1,0,now(),
  '4b100000-0000-0000-0000-000000000001'
);
select throws_ok(
  $$update public.matches set status='termine'
    where id='4b300000-0000-0000-0000-000000000002'$$,
  '22023',
  null,
  'un Live encore en cours ne suffit pas'
);

-- Live terminé avant l'heure officielle : accepté.
insert into public.match_live_sessions(
  match_id,state,planned_duration_minutes,half,elapsed_seconds,
  finished_at,updated_by
) values (
  '4b300000-0000-0000-0000-000000000001','finished',90,2,5400,now(),
  '4b100000-0000-0000-0000-000000000001'
);
select lives_ok(
  $$update public.matches set status='termine'
    where id='4b300000-0000-0000-0000-000000000001'$$,
  'un Live terminé avant l’heure permet de marquer le match terminé'
);

-- Messages du Live et du compte rendu : plus d'anglais ni de nom de club écrit
-- en dur.
select is(
  (
    select count(*)::integer
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace,
    regexp_matches(p.prosrc, 'raise exception\s+''((?:[^'']|'''')*)''', 'g') m
    where n.nspname in ('public', 'private')
      and (p.proname ~ 'live' or p.proname in (
        'submit_match_sport_report', 'finalize_match_sport_postgame',
        'finalize_match_postgame'))
      and m[1] ~ '(required|not found|cannot|must|Invalid|already|only|Only|Unknown|Too many|The |This |Open the|End the)'
  ),
  0,
  'aucun message d’erreur en anglais dans les fonctions du Live et du compte rendu'
);

select is(
  (
    select count(*)::integer
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace,
    regexp_matches(p.prosrc, 'raise exception\s+''((?:[^'']|'''')*)''', 'g') m
    where n.nspname in ('public', 'private')
      and (p.proname ~ 'live' or p.proname in (
        'submit_match_sport_report', 'finalize_match_sport_postgame',
        'finalize_match_postgame'))
      and m[1] ilike '%grinta%'
  ),
  0,
  'aucun message du Live ne cite « AS Grinta »'
);

select * from finish();
rollback;
