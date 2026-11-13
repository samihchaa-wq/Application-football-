begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Contrat actuel : trois modes de classement, aucun crédit automatique.
-- Nom historique de test conservé pour éviter de perdre la couverture.
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


-- Simuler les conditions qui créditaient autrefois les joueurs.
-- Les changements restent dans la transaction locale de test.
update private.waitlist_auto_activation
set activated_at = now() - interval '2 days'
where singleton;

select private.recompute_match_convocations_internal(
  current_setting('test.match')::uuid, false);
select is(
  pg_temp.effectif(current_setting('test.match')::uuid),
  'Alice not_convoked / Bruno not_convoked / Chloé convoked / Damien convoked',
  'les deux premiers joueurs restent en attente'
);
select is(
  private.finalize_match_waitlist_turns_internal(
    current_setting('test.match')::uuid, true), 0,
  'aucun credit avant le coup d envoi meme en forçant'
);

update public.matches
set match_date = ((now() - interval '1 day') at time zone 'Europe/Paris')::date,
    match_time = ((now() - interval '1 day') at time zone 'Europe/Paris')::time
where id = current_setting('test.match')::uuid;
select is(
  private.finalize_match_waitlist_turns_internal(
    current_setting('test.match')::uuid, false), 0,
  'aucun credit au coup d envoi'
);
select is(
  private.finalize_match_waitlist_turns_internal(
    current_setting('test.match')::uuid, false), 0,
  'aucun credit a la deuxieme finalisation'
);
select is(
  (select string_agg(p.first_name || '=' || e.manual_waitlist_count,
                     ' / ' order by p.position)
   from public.sport_waitlist_entries e
   join public.season_players p on p.id = e.season_player_id
   where e.season_id='f5820000-0000-0000-0000-000000000001'),
  'Alice=0 / Bruno=0 / Chloé=0 / Damien=0',
  'les compteurs restent tous nuls sans administrateur'
);
select is(
  (select count(*)::integer from private.waitlist_auto_processed_matches
   where match_id=current_setting('test.match')::uuid),
  0, 'aucune trace de traitement automatique'
);
select is(
  (select count(*)::integer from private.sport_waitlist_passage_ledger
   where match_id=current_setting('test.match')::uuid
     and credited_at is not null),
  0, 'aucun point ajoute dans le journal de passage'
);

-- Deux +1 sont maintenant donnes volontairement par l'administrateur.
select pg_temp.as_admin();
set local role authenticated;
select lives_ok(
  $$select public.admin_set_waitlist_manual_count(
    'f5840000-0000-0000-0000-000000000001', 1
  )$$, 'l admin credite Alice'
);
select lives_ok(
  $$select public.admin_set_waitlist_manual_count(
    'f5840000-0000-0000-0000-000000000002', 1
  )$$, 'l admin credite Bruno'
);
reset role;
select is(
  (select string_agg(p.first_name || '=' || e.manual_waitlist_count,
                     ' / ' order by p.position)
   from public.sport_waitlist_entries e
   join public.season_players p on p.id=e.season_player_id
   where e.season_id='f5820000-0000-0000-0000-000000000001'),
  'Alice=1 / Bruno=1 / Chloé=0 / Damien=0',
  'seules les attributions admin mettent les compteurs a 1'
);
select is(
  (select count(*)::integer from private.sport_admin_audit_log
   where action='set_waitlist_manual_count'
     and actor_profile_id='f5810000-0000-0000-0000-000000000001'),
  2, 'les deux changements sont traces dans le journal admin'
);

-- Match suivant : les crédits ADMIN donnent la priorité en mode présence.
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
select is(
  pg_temp.effectif(current_setting('test.match2')::uuid),
  'Alice convoked / Bruno convoked / Chloé not_convoked / Damien not_convoked',
  'mode presence : les credits admin passent en premier'
);

-- Mode ordre d'arrivée : les credits admin restent prioritaires.
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
select is(
  pg_temp.effectif(current_setting('test.match2')::uuid),
  'Alice convoked / Bruno convoked / Chloé not_convoked / Damien not_convoked',
  'mode arrivee : les credits admin priment sur l anciennete des reponses'
);

-- Mode admin : tous disponibles, une mise en attente ne crédite personne.
select pg_temp.as_admin();
set local role authenticated;
select public.admin_set_club_rule('waitlist_mode', 2);
reset role;
select private.recompute_match_convocations_internal(
  current_setting('test.match2')::uuid, false);
select is(
  pg_temp.effectif(current_setting('test.match2')::uuid),
  'Alice convoked / Bruno convoked / Chloé convoked / Damien convoked',
  'mode par choix : tous les disponibles sont initialement convoques'
);
update public.match_sport_participants
set convocation_status='not_convoked', convocation_manual_override=true
where match_id=current_setting('test.match2')::uuid
  and season_player_id='f5840000-0000-0000-0000-000000000004';
select private.recompute_match_convocations_internal(
  current_setting('test.match2')::uuid, false);
update public.matches
set match_date=((now() - interval '1 minute') at time zone 'Europe/Paris')::date,
    match_time=((now() - interval '1 minute') at time zone 'Europe/Paris')::time
where id=current_setting('test.match2')::uuid;
select is(
  private.finalize_match_waitlist_turns_internal(
    current_setting('test.match2')::uuid, false), 0,
  'meme en mode par choix, aucun point automatique'
);
select is(
  (select manual_waitlist_count from public.sport_waitlist_entries
   where season_player_id='f5840000-0000-0000-0000-000000000004'),
  0, 'Damien en attente ne recoit aucun +1 sans intervention admin'
);

-- En revanche l'admin peut crediter Damien, sans effet de retrait automatique.
select pg_temp.as_admin();
set local role authenticated;
select lives_ok(
  $$select public.admin_set_waitlist_manual_count(
    'f5840000-0000-0000-0000-000000000004', 1
  )$$, 'l admin donne +1 a Damien'
);
reset role;
select is(
  private.void_match_waitlist_credits(current_setting('test.match2')::uuid), 0,
  'un retrait automatique sur annulation reste neutre'
);
select is(
  (select manual_waitlist_count from public.sport_waitlist_entries
   where season_player_id='f5840000-0000-0000-0000-000000000004'),
  1, 'le compteur manuel de Damien est conserve'
);

-- Aucune finalisation d'un match ancien ne crédite, même forcée.
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
update public.matches
set match_date=((now() - interval '3 days') at time zone 'Europe/Paris')::date,
    match_time=((now() - interval '3 days') at time zone 'Europe/Paris')::time
where id=current_setting('test.match3')::uuid;
select is(
  private.finalize_match_waitlist_turns_internal(
    current_setting('test.match3')::uuid, true), 0,
  'pas de credit retroactif sur un ancien match'
);
select ok(
  not exists (select 1 from private.waitlist_auto_processed_matches
              where match_id=current_setting('test.match3')::uuid),
  'pas de traitement automatique retroactif enregistre'
);
select is(
  private.process_due_waitlist_credits(), 0,
  'appel direct au cron historique sans effet sur les compteurs'
);
select ok(
  not exists (select 1 from cron.job where jobname='waitlist-credit'),
  'le cron n est plus planifie'
);

-- Un joueur du même club ne peut ni ajouter ni retirer de +1.
select set_config(
  'request.jwt.claims',
  '{"sub":"f5810000-0000-0000-0000-000000000002","role":"authenticated","aud":"authenticated"}',
  true);
set local role authenticated;
select throws_ok(
  $$select public.admin_set_waitlist_manual_count(
    'f5840000-0000-0000-0000-000000000001', 99
  )$$,
  '42501',
  'Active administrator role required',
  'le profil joueur ne peut pas modifier un compteur'
);
reset role;
select is(
  (select manual_waitlist_count from public.sport_waitlist_entries
   where season_player_id='f5840000-0000-0000-0000-000000000001'),
  1,
  'le refus de permission n a pas modifie le +1 admin'
);

select * from finish();
rollback;
