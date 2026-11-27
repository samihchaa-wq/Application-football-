begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Point 49 de l'audit : créer un match moins de 15 minutes avant le coup
-- d'envoi doit être refusé avec un message clair, et non avec « Le match est
-- verrouillé depuis l'ouverture du Live » (le match n'existe pas encore).

insert into auth.users (id, email, raw_user_meta_data)
values (
  '94100000-0000-0000-0000-000000000001',
  'too-close-admin@example.invalid',
  '{"first_name":"Admin","last_name":"Proche"}'::jsonb
);

update public.profiles
set role = 'admin', status = 'active', updated_at = now()
where id = '94100000-0000-0000-0000-000000000001';

insert into public.seasons(id, name, status)
values ('95100000-0000-0000-0000-000000000001', '2095-2096', 'open');

insert into public.opponents(id, name)
values ('96100000-0000-0000-0000-000000000001', 'Trop Proche FC');

update private.app_feature_flags
set enabled = true,
    updated_at = now(),
    updated_by = '94100000-0000-0000-0000-000000000001'
where key = 'sports_management';

-- Heures de Paris, arrondies à la minute comme dans le formulaire.
select set_config(
  'test.soon',
  to_char(date_trunc('minute', (now() + interval '10 minutes') at time zone 'Europe/Paris'), 'YYYY-MM-DD HH24:MI'),
  true
);
select set_config(
  'test.past',
  to_char(date_trunc('minute', (now() - interval '2 hours') at time zone 'Europe/Paris'), 'YYYY-MM-DD HH24:MI'),
  true
);
select set_config(
  'test.later',
  to_char(date_trunc('minute', (now() + interval '3 hours') at time zone 'Europe/Paris'), 'YYYY-MM-DD HH24:MI'),
  true
);

select set_config(
  'request.jwt.claims',
  '{"sub":"94100000-0000-0000-0000-000000000001","role":"authenticated","aud":"authenticated"}',
  true
);
set local role authenticated;

select throws_ok(
  format(
    $sql$
      select public.admin_create_match_complete_v3(
        '95100000-0000-0000-0000-000000000001',
        '96100000-0000-0000-0000-000000000001',
        %L::timestamp::date, %L::timestamp::time, 'domicile',
        2, 3, 4, 14, null, false, 'championnat', null,
        'automatic', null, null
      )
    $sql$,
    current_setting('test.soon'), current_setting('test.soon')
  ),
  '22023',
  'Impossible de créer un match qui commence dans moins de 15 minutes.',
  'un match contre un adversaire dans 10 minutes est refuse avec un message clair'
);

select throws_ok(
  format(
    $sql$
      select public.create_internal_match_v3(
        '95100000-0000-0000-0000-000000000001',
        %L::timestamp::date, %L::timestamp::time
      )
    $sql$,
    current_setting('test.soon'), current_setting('test.soon')
  ),
  '22023',
  'Impossible de créer un match qui commence dans moins de 15 minutes.',
  'un match entre nous dans 10 minutes est refuse avec le meme message'
);

select throws_ok(
  format(
    $sql$
      select public.admin_create_match_complete_v3(
        '95100000-0000-0000-0000-000000000001',
        '96100000-0000-0000-0000-000000000001',
        %L::timestamp::date, %L::timestamp::time, 'domicile',
        2, 3, 4, 14, null, false, 'amical', null,
        'automatic', null, null
      )
    $sql$,
    current_setting('test.past'), current_setting('test.past')
  ),
  '22023',
  'Impossible de créer un match dont l’heure est déjà passée.',
  'un match deja commence est refuse avec un message clair'
);

select lives_ok(
  format(
    $sql$
      select public.admin_create_match_complete_v3(
        '95100000-0000-0000-0000-000000000001',
        '96100000-0000-0000-0000-000000000001',
        %L::timestamp::date, %L::timestamp::time, 'domicile',
        2, 3, 4, 14, null, false, 'amical', null,
        'now', null, null
      )
    $sql$,
    current_setting('test.later'), current_setting('test.later')
  ),
  'un match dans 3 heures reste creable'
);

reset role;

select is(
  (
    select count(*)::integer
    from public.matches
    where season_id = '95100000-0000-0000-0000-000000000001'
  ),
  1,
  'les creations refusees ne laissent aucun match partiel'
);

select ok(
  not has_function_privilege(
    'authenticated',
    'private.assert_new_match_kickoff_open(date,time without time zone)',
    'EXECUTE'
  ),
  'la verification interne n est pas appelable directement'
);

select * from finish();
rollback;
