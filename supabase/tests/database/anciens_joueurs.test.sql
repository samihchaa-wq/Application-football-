begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Anciens joueurs : le nom reste après un départ du club ; il devient
-- « Ancien joueur » partout quand le compte est supprimé, ou sur demande
-- (private.anonymize_player, éditeur SQL seulement), sans détacher le joueur
-- de ses statistiques ; deux anciens joueurs restent distincts.

insert into auth.users (id, email, raw_user_meta_data)
values
  ('7a000000-0000-0000-0000-000000000001', 'rename-admin@example.invalid',
   '{"first_name":"Admin","last_name":"Renommage"}'::jsonb),
  ('7a000000-0000-0000-0000-000000000002', 'rename-active@example.invalid',
   '{"first_name":"Actif","last_name":"Toujours"}'::jsonb);
update public.profiles set role = 'admin', status = 'active'
where id = '7a000000-0000-0000-0000-000000000001';
update public.profiles set status = 'active'
where id = '7a000000-0000-0000-0000-000000000002';

insert into public.seasons (id, name, status)
values ('7a200000-0000-0000-0000-000000000001', '2094-2095', 'archived');

insert into public.season_players (id, season_id, first_name, last_name, is_goalkeeper, is_active, position)
values
  ('7a300000-0000-0000-0000-000000000001', '7a200000-0000-0000-0000-000000000001',
   'Yves', 'Dujardin', false, false, 1),
  ('7a300000-0000-0000-0000-000000000002', '7a200000-0000-0000-0000-000000000001',
   'Paul', 'Martin', false, false, 2);
insert into public.season_players (id, season_id, first_name, last_name, is_goalkeeper, is_active, position, profile_id)
values ('7a300000-0000-0000-0000-000000000003', '7a200000-0000-0000-0000-000000000001',
   'Actif', 'Toujours', false, true, 3, '7a000000-0000-0000-0000-000000000002');

insert into public.historical_player_statistics (
  id, scope, season_name, display_rank, player_name, is_goalkeeper,
  matches_played, wins, draws, losses, goals, hdm, clean_sheets
)
values (987650000001, 'all_time', null, 998, 'Yves Dujardin', false, 12, 6, 3, 3, 7, 1, 0);

insert into public.opponents (id, name)
values ('7a600000-0000-0000-0000-000000000001', 'Adversaire renommage');
insert into public.historical_match_scores (id, opponent_id, match_date, score_as_grinta, score_adverse, is_home)
values ('7a700000-0000-0000-0000-000000000001', '7a600000-0000-0000-0000-000000000001',
        date '2094-10-01', 2, 1, true);
insert into public.historical_match_details (
  match_id, formation, field_players, bench_players, present_names, scorers, motm_names
)
values (
  '7a700000-0000-0000-0000-000000000001', 'test',
  '[{"name":"Yves Dujardin","is_gk":false,"x_pct":50,"y_pct":50},{"name":"Paul Martin","is_gk":false,"x_pct":30,"y_pct":30}]'::jsonb,
  '[]'::jsonb,
  '["Yves Dujardin","Paul Martin"]'::jsonb,
  '[{"name":"Yves Dujardin","goals":2}]'::jsonb,
  '["yves dujardin"]'::jsonb
);

create temporary table ids on commit drop as
select
  (select player_id from public.season_players where id = '7a300000-0000-0000-0000-000000000001') as yves,
  (select player_id from public.season_players where id = '7a300000-0000-0000-0000-000000000002') as paul,
  (select player_id from public.season_players where id = '7a300000-0000-0000-0000-000000000003') as active_player;
grant select on ids to authenticated;

select is(
  (select player_id from public.historical_player_statistics where id = 987650000001),
  (select yves from ids),
  'avant : les statistiques historiques sont rattachées au joueur'
);

-- Personne, depuis l'appli, ne peut renommer un ancien joueur.
select ok(
  not has_function_privilege('authenticated', 'private.anonymize_player(uuid)', 'EXECUTE')
  and not has_function_privilege('service_role', 'private.anonymize_player(uuid)', 'EXECUTE')
  and not has_function_privilege('anon', 'private.anonymize_player(uuid)', 'EXECUTE'),
  'l''anonymisation à la main n''est appelable ni depuis l''appli ni par la clé de service'
);
select ok(
  not has_function_privilege('authenticated', 'public.admin_rename_former_player(uuid,text)', 'EXECUTE')
  and not has_function_privilege('authenticated', 'public.admin_list_former_players()', 'EXECUTE'),
  'les fonctions de l''ancien écran « Anciens joueurs » sont fermées'
);

-- Règle 1 : un départ du club (fiche inactive, sans compte) ne change rien.
select is((select display_name from public.players where id = (select yves from ids)), 'Yves Dujardin',
  'un joueur parti du club garde son nom');
select is((select player_name from public.historical_player_statistics where id = 987650000001), 'Yves Dujardin',
  'y compris dans les statistiques historiques');

-- Anonymisation à la main (demande reçue par e-mail).
select is(private.anonymize_player((select yves from ids)), 'Ancien joueur',
  'le nom devient « Ancien joueur »');
select is((select display_name from public.players where id = (select yves from ids)), 'Ancien joueur',
  'identité du joueur renommée');
select is(
  (select first_name || ' ' || last_name from public.season_players where id = '7a300000-0000-0000-0000-000000000001'),
  'Ancien joueur', 'effectif de saison renommé');
select is((select player_name from public.historical_player_statistics where id = 987650000001), 'Ancien joueur',
  'statistiques historiques renommées');
select is((select player_id from public.historical_player_statistics where id = 987650000001), (select yves from ids),
  'et toujours rattachées au même joueur');
select is(
  (select matches_played || '/' || goals from public.historical_player_statistics where id = 987650000001),
  '12/7', 'les chiffres des statistiques sont intacts');
select is(
  (select present_names from public.historical_match_details where match_id = '7a700000-0000-0000-0000-000000000001'),
  '["Ancien joueur", "Paul Martin"]'::jsonb,
  'feuille de match : le nom est remplacé, les autres joueurs ne bougent pas');
select is(
  (select motm_names from public.historical_match_details where match_id = '7a700000-0000-0000-0000-000000000001'),
  '["Ancien joueur"]'::jsonb,
  'le nom est retrouvé même écrit sans majuscules');
select is(
  (select scorers -> 0 ->> 'name' from public.historical_match_details where match_id = '7a700000-0000-0000-0000-000000000001'),
  'Ancien joueur', 'liste des buteurs renommée');
select is(
  (select count(*)::int from public.historical_match_players
   where match_id = '7a700000-0000-0000-0000-000000000001' and player_id = (select yves from ids)),
  1, 'la feuille de match reste rattachée au même joueur');
select is(
  (select count(*)::int from public.player_aliases
   where player_id = (select yves from ids) and private.normalize_player_name(alias) = private.normalize_player_name('Yves Dujardin')),
  0, 'l''ancien nom ne figure plus dans les alias');
select is(
  (select count(*)::int from public.historical_player_name_links
   where player_id = (select yves from ids) and normalized_name = private.normalize_player_name('Yves Dujardin')),
  0, 'ni dans les correspondances de noms historiques');
select ok(
  (select metadata::text from private.sport_admin_audit_log
   where action = 'rename_former_player' order by id desc limit 1) not ilike '%dujardin%',
  'la trace ne contient pas l''ancien nom');

-- Règle 3 : un second ancien joueur reste distinct.
select is(private.anonymize_player((select paul from ids)), 'Ancien joueur 2',
  'un second ancien joueur reçoit un nom distinct');
select is(
  (select present_names from public.historical_match_details where match_id = '7a700000-0000-0000-0000-000000000001'),
  '["Ancien joueur", "Ancien joueur 2"]'::jsonb,
  'les deux noms sont remplacés sur la feuille de match');
select is(
  (select count(distinct player_id)::int from public.historical_match_players
   where match_id = '7a700000-0000-0000-0000-000000000001'),
  2, 'les deux joueurs restent distincts dans les statistiques du match');
select throws_ok(
  $$select private.anonymize_player('00000000-0000-0000-0000-0000000000ff')$$,
  'P0002', null, 'un identifiant inconnu est refusé');

-- Règle 2 : suppression d'un compte.
select set_config('request.jwt.claims', '', true);
-- Sans compte technique (comme dans la base commerciale), la préparation de
-- la suppression doit réussir.
delete from public.profiles where id = '00000000-0000-0000-0000-000000000001';
insert into auth.users (id, email, raw_user_meta_data)
values ('7a000000-0000-0000-0000-000000000003', 'rename-leaving@example.invalid',
        '{"first_name":"Lea","last_name":"Partante"}'::jsonb);
update public.profiles set status = 'active' where id = '7a000000-0000-0000-0000-000000000003';
insert into public.season_players (id, season_id, first_name, last_name, is_goalkeeper, is_active, position, profile_id)
values ('7a300000-0000-0000-0000-000000000004', '7a200000-0000-0000-0000-000000000001',
   'Lea', 'Partante', false, true, 4, '7a000000-0000-0000-0000-000000000003');
update public.season_players set photo_url = 'joueurs/lea-partante.png'
where id = '7a300000-0000-0000-0000-000000000004';

insert into private.sport_admin_audit_log (actor_profile_id, action)
values ('7a000000-0000-0000-0000-000000000003', 'test_trace_partante');

select private.prepare_profile_for_hard_deletion('7a000000-0000-0000-0000-000000000003');
delete from public.profiles where id = '7a000000-0000-0000-0000-000000000003';
select is(
  (select count(*)::int from public.profiles where id = '7a000000-0000-0000-0000-000000000003'),
  0, 'le compte est effacé, même sans compte technique dans la base');
select ok(
  (select actor_profile_id is null from private.sport_admin_audit_log where action = 'test_trace_partante'),
  'ses traces d''auteur restent, vides (« compte supprimé »)');
select is(
  (select display_name from public.players
   where id = (select player_id from public.season_players where id = '7a300000-0000-0000-0000-000000000004')),
  'Ancien joueur 3',
  'à la suppression du compte, le nom de joueur devient « Ancien joueur » (distinct des autres)'
);
select is(
  (select first_name || ' ' || last_name || coalesce(photo_url, '') from public.season_players
   where id = '7a300000-0000-0000-0000-000000000004'),
  'Ancien joueur 3', 'sa fiche d''effectif n''a plus ni son nom ni sa photo');

-- Le membre actif n'a pas été touché.
select is(
  (select first_name || ' ' || last_name from public.season_players where id = '7a300000-0000-0000-0000-000000000003'),
  'Actif Toujours', 'un membre actif garde son nom');

-- Réécriture d'un instantané JSON : seuls les champs de l'objet du joueur
-- (reconnu par son identifiant) changent.
select is(
  private.rename_player_in_jsonb(
    '{"entries":[{"participant_id":"p-1","display_name":"Jean Dupont","first_name":"Jean","last_name":"Dupont","surnom":"JD","x":1},{"participant_id":"p-2","display_name":"Luc Petit"}],"title":"Composition"}'::jsonb,
    array['p-1'], array[private.normalize_player_name('Jean Dupont')], 'Jean D.', 'Jean', 'D.'
  ),
  '{"entries":[{"participant_id":"p-1","display_name":"Jean D.","first_name":"Jean","last_name":"D.","surnom":"","x":1},{"participant_id":"p-2","display_name":"Luc Petit"}],"title":"Composition"}'::jsonb,
  'instantané : seul l''objet du joueur est réécrit, le reste est identique'
);

select * from finish();
rollback;
