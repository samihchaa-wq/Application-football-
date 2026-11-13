begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Les trois modes de liste d'attente réglables par le club.
--
-- Classement de saison : Alice n°1, Bruno n°2, Chloé n°3, Damien n°4.
-- Deux places pour quatre disponibles. Ordre d'arrivée des réponses :
-- Alice, puis Bruno, puis Chloé, puis Damien.

select vault.create_secret('test-token', 'push_internal_token')
where not exists (
  select 1 from vault.secrets secret where secret.name = 'push_internal_token'
);

insert into auth.users(id, email, raw_user_meta_data)
values
  ('f5810000-0000-0000-0000-000000000001', 'modes-admin@example.invalid', '{"first_name":"Admin"}'::jsonb),
  ('f5810000-0000-0000-0000-000000000002', 'modes-alice@example.invalid', '{"first_name":"Alice"}'::jsonb),
  ('f5810000-0000-0000-0000-000000000003', 'modes-bruno@example.invalid', '{"first_name":"Bruno"}'::jsonb),
  ('f5810000-0000-0000-0000-000000000004', 'modes-chloe@example.invalid', '{"first_name":"Chloé"}'::jsonb),
  ('f5810000-0000-0000-0000-000000000005', 'modes-damien@example.invalid', '{"first_name":"Damien"}'::jsonb);

update public.profiles
set role = case when id = 'f5810000-0000-0000-0000-000000000001' then 'admin' else 'pronostiqueur' end,
    status = 'active', updated_at = now()
where id between 'f5810000-0000-0000-0000-000000000001' and 'f5810000-0000-0000-0000-000000000005';

insert into public.seasons(id, name, status)
values ('f5820000-0000-0000-0000-000000000001', '2703-2704', 'open');
insert into public.opponents(id, name)
values ('f5830000-0000-0000-0000-000000000001', 'Modes FC');

insert into public.season_players(id, season_id, first_name, last_name, is_goalkeeper, is_active, position, profile_id)
values
  ('f5840000-0000-0000-0000-000000000001', 'f5820000-0000-0000-0000-000000000001', 'Alice', 'Mode', false, true, 1, 'f5810000-0000-0000-0000-000000000002'),
  ('f5840000-0000-0000-0000-000000000002', 'f5820000-0000-0000-0000-000000000001', 'Bruno', 'Mode', false, true, 2, 'f5810000-0000-0000-0000-000000000003'),
  ('f5840000-0000-0000-0000-000000000003', 'f5820000-0000-0000-0000-000000000001', 'Chloé', 'Mode', false, true, 3, 'f5810000-0000-0000-0000-000000000004'),
  ('f5840000-0000-0000-0000-000000000004', 'f5820000-0000-0000-0000-000000000001', 'Damien', 'Mode', false, true, 4, 'f5810000-0000-0000-0000-000000000005');

insert into public.sport_waitlist_entries(season_id, season_player_id, position, source, created_by, updated_by)
select player.season_id, player.id, player.position, 'manual',
  'f5810000-0000-0000-0000-000000000001', 'f5810000-0000-0000-0000-000000000001'
from public.season_players player
where player.season_id = 'f5820000-0000-0000-0000-000000000001';

update private.app_feature_flags
set enabled = true, updated_at = now(), updated_by = 'f5810000-0000-0000-0000-000000000001'
where key = 'sports_management';

create or replace function pg_temp.effectif(p_match uuid)
returns text language sql stable as $function$
  select string_agg(player.first_name || ' ' || participant.convocation_status::text,
    ' / ' order by player.position)
  from public.match_sport_participants participant
  join public.season_players player on player.id = participant.season_player_id
  where participant.match_id = p_match;
$function$;

create or replace function pg_temp.as_admin()
returns text language sql as $function$
  select set_config('request.jwt.claims',
    '{"sub":"f5810000-0000-0000-0000-000000000001","role":"authenticated","aud":"authenticated"}', true);
$function$;

select pg_temp.as_admin();
set local role authenticated;

select set_config('test.match',
  public.create_match_with_odds_and_sport_limit(
    'f5820000-0000-0000-0000-000000000001', 'f5830000-0000-0000-0000-000000000001',
    ((now() + interval '4 days') at time zone 'Europe/Paris')::date,
    ((now() + interval '4 days') at time zone 'Europe/Paris')::time,
    'domicile', 2.10, 3.20, 2.90, 2
  )::text, true);

select public.admin_override_match_availability(current_setting('test.match')::uuid,
  player.id, 'available', null, 'Test')
from (values
  ('f5840000-0000-0000-0000-000000000001'::uuid),
  ('f5840000-0000-0000-0000-000000000002'::uuid),
  ('f5840000-0000-0000-0000-000000000003'::uuid),
  ('f5840000-0000-0000-0000-000000000004'::uuid)) as player(id);

reset role;

-- Une seule transaction : on fixe nous-mêmes l'heure de chaque réponse.
update public.match_sport_participants participant
set availability_updated_at = now() - make_interval(hours => 10 - player.position)
from public.season_players player
where player.id = participant.season_player_id
  and participant.match_id = current_setting('test.match')::uuid;


-- Les tests peuvent uniquement modifier leur transaction : simulation d'un
-- coup d'envoi apres activation, sans toucher a la base commerciale.
update private.waitlist_auto_activation
set activated_at = now() - interval '2 hours'
where singleton;

select private.recompute_match_convocations_internal(
  current_setting('test.match')::uuid, false
);
select is(pg_temp.effectif(current_setting('test.match')::uuid),
  'Alice not_convoked / Bruno not_convoked / Chloé convoked / Damien convoked',
  'initialement les deux joueurs les moins prioritaires attendent');

select is(
  private.finalize_match_waitlist_turns_internal(
    current_setting('test.match')::uuid, true), 0,
  'meme avec force=true, jamais de credit avant le coup d envoi');

update public.matches
set kickoff_at = now() - interval '1 minute'
where id = current_setting('test.match')::uuid;

select is(
  private.finalize_match_waitlist_turns_internal(
    current_setting('test.match')::uuid, false), 2,
  'deux joueurs disponibles en attente gagnent chacun +1 au coup d envoi');
select is(
  (select string_agg(p.first_name || '=' || e.manual_waitlist_count,
                     ' / ' order by p.position)
   from public.sport_waitlist_entries e
   join public.season_players p on p.id=e.season_player_id
   where e.season_id='f5820000-0000-0000-0000-000000000001'),
  'Alice=1 / Bruno=1 / Chloé=0 / Damien=0',
  'les credits sont uniquement attribues aux joueurs presents en attente');
select is(
  private.finalize_match_waitlist_turns_internal(
    current_setting('test.match')::uuid, false), 0,
  'deux executions du meme match ne creditent jamais deux fois');
select is(
  (select credited_count from private.waitlist_auto_processed_matches
   where match_id=current_setting('test.match')::uuid),
  2, 'un seul traitement enregistre deux credits');
select is(
  (select count(*)::integer from private.sport_waitlist_passage_ledger
   where match_id=current_setting('test.match')::uuid
     and credited_at is not null), 2,
  'deux traces individuelles permettent un audit par match');

-- Match suivant : les +1 permanents priment sur les presences precedentes.
select pg_temp.as_admin();
set local role authenticated;
select set_config('test.match2',
  public.create_match_with_odds_and_sport_limit(
    'f5820000-0000-0000-0000-000000000001',
    'f5830000-0000-0000-0000-000000000001',
    ((now()+interval '6 days') at time zone 'Europe/Paris')::date,
    ((now()+interval '6 days') at time zone 'Europe/Paris')::time,
    'domicile', 2.10, 3.20, 2.90, 2
  )::text, true);
select public.admin_override_match_availability(
  current_setting('test.match2')::uuid, player.id, 'available', null, 'Test'
) from (values
  ('f5840000-0000-0000-0000-000000000001'::uuid),
  ('f5840000-0000-0000-0000-000000000002'::uuid),
  ('f5840000-0000-0000-0000-000000000003'::uuid),
  ('f5840000-0000-0000-0000-000000000004'::uuid)
) player(id);
reset role;

select private.recompute_match_convocations_internal(
  current_setting('test.match2')::uuid, false);
select is(pg_temp.effectif(current_setting('test.match2')::uuid),
  'Alice convoked / Bruno convoked / Chloé not_convoked / Damien not_convoked',
  'en mode presence an dernier les +1 priment pour le match suivant');

-- Ordre d'arrivee : Chloé et Damien ont repondu les premiers, mais
-- Alice et Bruno ont un +1 et restent prioritaires.
select pg_temp.as_admin();
set local role authenticated;
select public.admin_set_club_rule('waitlist_mode', 1);
reset role;
update public.match_sport_participants
set availability_updated_at =
  case when season_player_id in (
    'f5840000-0000-0000-0000-000000000001',
    'f5840000-0000-0000-0000-000000000002'
  ) then now() - interval '1 hour'
  else now() - interval '4 hours' end
where match_id=current_setting('test.match2')::uuid;

select private.recompute_match_convocations_internal(
  current_setting('test.match2')::uuid, false);
select is(pg_temp.effectif(current_setting('test.match2')::uuid),
  'Alice convoked / Bruno convoked / Chloé not_convoked / Damien not_convoked',
  'ordre arrivee : +1 l emporte sur une reponse plus ancienne');

-- Par choix : les quatre presents sont convoques initialement, mais l'admin
-- peut placer Damien en attente et lui donner ainsi +1 au coup d'envoi.
select pg_temp.as_admin();
set local role authenticated;
select public.admin_set_club_rule('waitlist_mode', 2);
reset role;
select private.recompute_match_convocations_internal(
  current_setting('test.match2')::uuid, false);
select is(pg_temp.effectif(current_setting('test.match2')::uuid),
  'Alice convoked / Bruno convoked / Chloé convoked / Damien convoked',
  'par choix : tout le monde est initialement convoque');

update public.match_sport_participants
set convocation_status='not_convoked',
    convocation_manual_override=true
where match_id=current_setting('test.match2')::uuid
  and season_player_id='f5840000-0000-0000-0000-000000000004';
select private.recompute_match_convocations_internal(
  current_setting('test.match2')::uuid, false);
update public.matches
set kickoff_at=now() - interval '1 minute'
where id=current_setting('test.match2')::uuid;
select is(
  private.finalize_match_waitlist_turns_internal(
    current_setting('test.match2')::uuid, false), 1,
  'par choix, le joueur place en attente par admin recoit +1');
select is(
  (select manual_waitlist_count from public.sport_waitlist_entries
   where season_player_id='f5840000-0000-0000-0000-000000000004'), 1,
  'le credit en attente est ajoute sans consommation des autres credits');

update public.matches set status='annule'
where id=current_setting('test.match2')::uuid;
select is(
  (select manual_waitlist_count from public.sport_waitlist_entries
   where season_player_id='f5840000-0000-0000-0000-000000000004'), 1,
  'annuler apres le coup d envoi ne retire pas le +1 permanent');
select is(
  private.void_match_waitlist_credits(current_setting('test.match2')::uuid), 0,
  'ancienne fonction de retrait neutralisee');

-- Aucun rattrapage retroactif de matchs passes avant installation.
select pg_temp.as_admin();
set local role authenticated;
select set_config('test.match3',
  public.create_match_with_odds_and_sport_limit(
    'f5820000-0000-0000-0000-000000000001',
    'f5830000-0000-0000-0000-000000000001',
    ((now()+interval '8 days') at time zone 'Europe/Paris')::date,
    ((now()+interval '8 days') at time zone 'Europe/Paris')::time,
    'domicile', 2.10, 3.20, 2.90, 2
  )::text, true);
reset role;
update public.matches set kickoff_at=now() - interval '3 hours'
where id=current_setting('test.match3')::uuid;
select is(
  private.finalize_match_waitlist_turns_internal(
    current_setting('test.match3')::uuid, true), 0,
  'match anterieur a l activation jamais credite retroactivement');
select ok(
  not exists (select 1 from private.waitlist_auto_processed_matches
              where match_id=current_setting('test.match3')::uuid),
  'aucune trace de traitement retroactif');
select is(private.process_due_waitlist_credits(), 0,
  'cron idempotent : aucun match passe ou deja traite ne recrédite');

select * from finish();
rollback;
