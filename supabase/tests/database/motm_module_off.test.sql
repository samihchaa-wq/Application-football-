begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Homme du match coupé par le club : la validation du compte rendu n'ouvre
-- aucun vote et n'envoie aucun « Pense à voter », même en rouvrant l'écran
-- de vote. Même match et mêmes joueurs que
-- sports_management_motm_notifications, où le vote s'ouvre bien quand la
-- fonction est activée.

insert into auth.users(id, email, raw_user_meta_data)
values
  (
    'e7100000-0000-0000-0000-000000000001',
    'motm-off-admin@example.invalid',
    '{"first_name":"Admin"}'::jsonb
  ),
  (
    'e7100000-0000-0000-0000-000000000002',
    'motm-off-one@example.invalid',
    '{"first_name":"Votant Un"}'::jsonb
  ),
  (
    'e7100000-0000-0000-0000-000000000003',
    'motm-off-two@example.invalid',
    '{"first_name":"Votant Deux"}'::jsonb
  );

update public.profiles
set role = case
      when id = 'e7100000-0000-0000-0000-000000000001' then 'admin'
      else 'pronostiqueur'
    end,
    status = 'active',
    notify_motm_vote = true,
    updated_at = now()
where id in (
  'e7100000-0000-0000-0000-000000000001',
  'e7100000-0000-0000-0000-000000000002',
  'e7100000-0000-0000-0000-000000000003'
);

insert into public.seasons(id, name, status)
values ('e7200000-0000-0000-0000-000000000001', '2095-2096', 'open');

insert into public.opponents(id, name)
values ('e7300000-0000-0000-0000-000000000001', 'Coupé FC');

insert into public.season_players(
  id,
  season_id,
  first_name,
  last_name,
  is_goalkeeper,
  is_active,
  position,
  profile_id
) values
  (
    'e7400000-0000-0000-0000-000000000001',
    'e7200000-0000-0000-0000-000000000001',
    'Votant',
    'Un',
    false,
    true,
    1,
    'e7100000-0000-0000-0000-000000000002'
  ),
  (
    'e7400000-0000-0000-0000-000000000002',
    'e7200000-0000-0000-0000-000000000001',
    'Votant',
    'Deux',
    false,
    true,
    2,
    'e7100000-0000-0000-0000-000000000003'
  );

insert into public.push_subscriptions(
  profile_id,
  endpoint,
  p256dh,
  auth,
  user_agent
) values
  (
    'e7100000-0000-0000-0000-000000000002',
    'https://push.example.invalid/motm-off-one',
    'p256dh-one',
    'auth-one',
    'pgTAP'
  ),
  (
    'e7100000-0000-0000-0000-000000000003',
    'https://push.example.invalid/motm-off-two',
    'p256dh-two',
    'auth-two',
    'pgTAP'
  );

update private.app_feature_flags
set enabled = true,
    updated_at = now(),
    updated_by = 'e7100000-0000-0000-0000-000000000001'
where key = 'sports_management';

select set_config(
  'request.jwt.claims',
  '{"sub":"e7100000-0000-0000-0000-000000000001","role":"authenticated","aud":"authenticated"}',
  true
);
set local role authenticated;

select set_config(
  'test.motm_off_match',
  public.create_match_with_odds_and_sport_limit(
    'e7200000-0000-0000-0000-000000000001',
    'e7300000-0000-0000-0000-000000000001',
    ((now() + interval '5 days') at time zone 'Europe/Paris')::date,
    ((now() + interval '5 days') at time zone 'Europe/Paris')::time,
    'domicile',
    2.10,
    3.20,
    2.90,
    14
  )::text,
  true
);

reset role;
update public.matches
set kickoff_at = now() - interval '2 hours',
    match_date = ((now() - interval '2 hours') at time zone 'Europe/Paris')::date,
    match_time = ((now() - interval '2 hours') at time zone 'Europe/Paris')::time
where id = current_setting('test.motm_off_match')::uuid;

select set_config(
  'test.motm_off_player_one_participant',
  (
    select participant.id::text
    from public.match_sport_participants participant
    where participant.match_id = current_setting('test.motm_off_match')::uuid
      and participant.season_player_id =
        'e7400000-0000-0000-0000-000000000001'::uuid
  ),
  true
);

select set_config(
  'test.motm_off_player_two_participant',
  (
    select participant.id::text
    from public.match_sport_participants participant
    where participant.match_id = current_setting('test.motm_off_match')::uuid
      and participant.season_player_id =
        'e7400000-0000-0000-0000-000000000002'::uuid
  ),
  true
);

create or replace function pg_temp.motm_off_final_payload()
returns jsonb
language sql
stable
as $function$
  select jsonb_agg(
    jsonb_build_object(
      'participant_id', participant.id,
      'present', true,
      'final_selection_status', case
        when participant.season_player_id =
          'e7400000-0000-0000-0000-000000000001'::uuid then 'starter'
        else 'substitute'
      end,
      'goals', 0,
      'clean_sheet', false
    ) order by participant.id
  )
  from public.match_sport_participants participant
  where participant.match_id = current_setting('test.motm_off_match')::uuid;
$function$;

-- Le club coupe l'homme du match avant la validation.
insert into private.app_feature_flags (key, enabled, config, updated_at)
values ('man_of_the_match', false, '{}'::jsonb, now())
on conflict (club_id, key) do update set enabled = false;

select set_config(
  'request.jwt.claims',
  '{"sub":"e7100000-0000-0000-0000-000000000001","role":"authenticated","aud":"authenticated"}',
  true
);
set local role authenticated;
select lives_ok(
  $$select public.admin_finalize_match_sport_postgame(
    current_setting('test.motm_off_match')::uuid,
    1,
    0,
    pg_temp.motm_off_final_payload(),
    'Validation avec l’homme du match coupé'
  )$$,
  'le compte rendu se valide normalement quand l’homme du match est coupé'
);
reset role;

select is(
  (select count(*) from public.match_sport_motm_elections
   where match_id = current_setting('test.motm_off_match')::uuid),
  0::bigint,
  'aucun vote n’est ouvert'
);
select is(
  (select count(*) from public.push_notification_log
   where match_id = current_setting('test.motm_off_match')::uuid
     and kind like 'motm%'),
  0::bigint,
  'aucune notification d’homme du match n’est préparée'
);

select private.ensure_match_motm_election(current_setting('test.motm_off_match')::uuid);
select is(
  (select count(*) from public.match_sport_motm_elections
   where match_id = current_setting('test.motm_off_match')::uuid),
  0::bigint,
  'redemander le vote (ouverture de l’écran) n’en crée pas non plus'
);

select is(
  private.push_due_motm_open_notifications(now()),
  0,
  'la tâche planifiée n’envoie aucun « Pense à voter »'
);

-- Réactivée : le comportement normal revient.
update private.app_feature_flags set enabled = true where key = 'man_of_the_match';
select private.ensure_match_motm_election(current_setting('test.motm_off_match')::uuid);
select is(
  (select count(*) from public.match_sport_motm_elections
   where match_id = current_setting('test.motm_off_match')::uuid),
  1::bigint,
  'réactivé dans le délai du vote, le vote peut de nouveau s’ouvrir'
);

select * from finish();
rollback;
