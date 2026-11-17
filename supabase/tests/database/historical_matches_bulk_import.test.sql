begin;
set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Toutes les écritures sont annulées après ce test.
insert into auth.users(id, email, raw_user_meta_data)
values
 ('ab910000-0000-0000-0000-000000000001', 'bulk-admin@example.invalid', '{"first_name":"Admin"}'::jsonb),
 ('ab910000-0000-0000-0000-000000000002', 'bulk-user@example.invalid', '{"first_name":"Joueur"}'::jsonb);
update public.profiles
set role = case when id = 'ab910000-0000-0000-0000-000000000001'
                then 'admin' else 'pronostiqueur' end,
    status = 'active'
where id in ('ab910000-0000-0000-0000-000000000001',
             'ab910000-0000-0000-0000-000000000002');

insert into public.seasons(id, name, status)
select 'ab920000-0000-0000-0000-000000000001', '2026-2027', 'open'
where not exists (select 1 from public.seasons);

select set_config('test.bulk_date',
  (private.history_entry_cutoff() - 90)::text, true);

create or replace function pg_temp.as_profile(p_profile uuid)
returns text language sql as $function$
  select set_config('request.jwt.claims',
    jsonb_build_object('sub', p_profile, 'role', 'authenticated',
      'aud', 'authenticated')::text, true);
$function$;

create or replace function pg_temp.match(p_date date, p_opponent text, p_for int)
returns jsonb language sql stable as $function$
  select jsonb_build_object('date', p_date, 'opponent', p_opponent,
    'score_for', p_for, 'score_against', 1,
    'is_home', true, 'match_type', 'championnat');
$function$;

create or replace function pg_temp.doc(p_matches jsonb)
returns jsonb language sql stable as $function$
  select jsonb_build_object('format', 'petit-filet-historique',
    'version', 1, 'matches', p_matches);
$function$;

select pg_temp.as_profile('ab910000-0000-0000-0000-000000000001');
set local role authenticated;

select is(
  (public.admin_import_historical_matches(pg_temp.doc(jsonb_build_array(
    pg_temp.match(current_setting('test.bulk_date')::date, 'Import FC A', 2),
    pg_temp.match(current_setting('test.bulk_date')::date - 7, 'Import FC B', 3)
  ))) ->> 'imported')::integer,
  2, 'l’admin importe deux matchs depuis un seul fichier'
);
select is(
  (select count(*)::integer
   from public.historical_match_scores score
   join public.opponents opponent on opponent.id = score.opponent_id
   where opponent.name like 'Import FC %'),
  2, 'les deux matchs sont enregistrés'
);

select is(
  (public.admin_import_historical_matches(pg_temp.doc(jsonb_build_array(
    pg_temp.match(current_setting('test.bulk_date')::date, 'Import FC A', 2),
    pg_temp.match(current_setting('test.bulk_date')::date, 'Import FC A', 2)
  ))) ->> 'skipped')::integer,
  2, 'le fichier réimporté et les doublons internes sont ignorés'
);

select throws_ok(
  format($$select public.admin_import_historical_matches(
    pg_temp.doc(jsonb_build_array(
      pg_temp.match(%L::date, 'Import FC C', 2),
      pg_temp.match(%L::date, 'Import FC A', 9)
    )))$$,
    current_setting('test.bulk_date')::date - 14,
    current_setting('test.bulk_date')::date),
  '22023', null, 'un conflit bloque le lot entier'
);

reset role;
select is(
  (select count(*)::integer from public.opponents
   where name = 'Import FC C'),
  0, 'une erreur annule aussi les nouvelles créations d’adversaires'
);

select pg_temp.as_profile('ab910000-0000-0000-0000-000000000002');
set local role authenticated;
select throws_ok(
  $$select public.admin_import_historical_matches(
      pg_temp.doc(jsonb_build_array(
        pg_temp.match(current_setting('test.bulk_date')::date,
          'Interdit FC', 1))))$$,
  '42501', null, 'un joueur ne peut pas importer'
);
reset role;


-- Décision métier : une saison déjà présente reste importable.
-- Les informations de domicile et de type peuvent rester inconnues.
select pg_temp.as_profile('ab910000-0000-0000-0000-000000000001');
set local role authenticated;

select is(
  (public.admin_import_historical_matches(pg_temp.doc(jsonb_build_array(
    jsonb_build_object(
      'date', current_date - 2, 'opponent', 'Sans métadonnées FC',
      'score_for', 1, 'score_against', 0
    )
  ))) ->> 'imported')::integer,
  1, 'une saison déjà suivie accepte un résultat passé sans domicile ni type'
);
reset role;
select is(
  (select is_home from public.historical_match_scores h
    join public.opponents o on o.id = h.opponent_id
    where o.name = 'Sans métadonnées FC'),
  null::boolean, 'le domicile inconnu est conservé à NULL sans invention'
);
select is(
  (select match_type from public.historical_match_scores h
    join public.opponents o on o.id = h.opponent_id
    where o.name = 'Sans métadonnées FC'),
  null::text, 'le type de rencontre inconnu est conservé à NULL'
);

-- Un match déjà saisi dans le calendrier normal ne doit jamais être doublé
-- par une archive et fausser les statistiques.
insert into public.opponents(name)
values ('Calendrier existant FC');
insert into public.matches(
  id, season_id, opponent_id, match_date, match_time, location,
  planned_duration_minutes, status, match_type, created_by
) values (
  'ab930000-0000-0000-0000-000000000001',
  (select id from public.seasons order by name limit 1),
  (select id from public.opponents where name = 'Calendrier existant FC'),
  current_date - 3, '19:30', 'domicile', 90, 'a_venir', 'championnat',
  'ab910000-0000-0000-0000-000000000001'
);
select pg_temp.as_profile('ab910000-0000-0000-0000-000000000001');
set local role authenticated;
select throws_ok(
  $select public.admin_import_historical_matches(
    pg_temp.doc(jsonb_build_array(
      pg_temp.match(current_date - 3, 'Calendrier existant FC', 2)
    )))$,
  '22023', null,
  'un match existant non validé dans Petit Filet refuse un doublon historique'
);
reset role;
select is(
  (select count(*)::integer
   from public.historical_match_scores h
   join public.opponents o on o.id = h.opponent_id
   where o.name = 'Calendrier existant FC'),
  0, 'aucune archive n’a été créée en double du calendrier'
);

select * from finish();
rollback;
