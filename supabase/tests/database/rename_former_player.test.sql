begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Raccourcir (« Yves D. ») ou remplacer (« Ancien joueur ») le nom d'un
-- ancien joueur partout, sans le détacher de ses statistiques.

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

select set_config(
  'request.jwt.claims',
  '{"sub":"7a000000-0000-0000-0000-000000000001","role":"authenticated","aud":"authenticated"}',
  true
);
set local role authenticated;

select ok(
  (select yves from ids) in (select player_id from public.admin_list_former_players()),
  'un ancien joueur apparaît dans la liste'
);
select ok(
  (select active_player from ids) not in (select player_id from public.admin_list_former_players()),
  'un membre actif n''apparaît pas dans la liste'
);

select is(
  public.admin_rename_former_player((select yves from ids), 'short') ->> 'display_name',
  'Yves D.',
  'le nom est raccourci en « Yves D. »'
);

reset role;

select is((select display_name from public.players where id = (select yves from ids)), 'Yves D.',
  'identité du joueur renommée');
select is(
  (select first_name || ' ' || last_name from public.season_players where id = '7a300000-0000-0000-0000-000000000001'),
  'Yves D.', 'effectif de saison renommé');
select is((select player_name from public.historical_player_statistics where id = 987650000001), 'Yves D.',
  'statistiques historiques renommées');
select is((select player_id from public.historical_player_statistics where id = 987650000001), (select yves from ids),
  'et toujours rattachées au même joueur');
select is(
  (select present_names from public.historical_match_details where match_id = '7a700000-0000-0000-0000-000000000001'),
  '["Yves D.", "Paul Martin"]'::jsonb,
  'feuille de match : le nom est remplacé, les autres joueurs ne bougent pas');
select is(
  (select motm_names from public.historical_match_details where match_id = '7a700000-0000-0000-0000-000000000001'),
  '["Yves D."]'::jsonb,
  'le nom est retrouvé même écrit sans majuscules');
select is(
  (select scorers -> 0 ->> 'name' from public.historical_match_details where match_id = '7a700000-0000-0000-0000-000000000001'),
  'Yves D.', 'liste des buteurs renommée');
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
select is(
  (select metadata from private.sport_admin_audit_log
   where action = 'rename_former_player' order by id desc limit 1) ->> 'mode',
  'short', 'l''opération est tracée');
select ok(
  (select metadata::text from private.sport_admin_audit_log
   where action = 'rename_former_player' order by id desc limit 1) not ilike '%dujardin%',
  'la trace ne contient pas l''ancien nom');

-- Ensuite « Ancien joueur », pour deux joueurs : les noms restent distincts.
set local role authenticated;
select is(public.admin_rename_former_player((select yves from ids), 'anonymous') ->> 'display_name',
  'Ancien joueur', 'remplacement par « Ancien joueur »');
select is(public.admin_rename_former_player((select paul from ids), 'anonymous') ->> 'display_name',
  'Ancien joueur 2', 'un second ancien joueur reçoit un nom distinct');
reset role;

select is(
  (select present_names from public.historical_match_details where match_id = '7a700000-0000-0000-0000-000000000001'),
  '["Ancien joueur", "Ancien joueur 2"]'::jsonb,
  'les deux noms sont remplacés sur la feuille de match');
select is(
  (select count(distinct player_id)::int from public.historical_match_players
   where match_id = '7a700000-0000-0000-0000-000000000001'),
  2, 'les deux joueurs restent distincts dans les statistiques du match');

-- Refus.
set local role authenticated;
select throws_ok(
  format($$select public.admin_rename_former_player(%L, 'short')$$, (select active_player from ids)),
  '22023',
  'un membre encore actif ne peut pas être renommé par l''administrateur'
);
select throws_ok(
  format($$select public.admin_rename_former_player(%L, 'n_importe')$$, (select yves from ids)),
  '22023',
  'un choix inconnu est refusé'
);
reset role;

select set_config(
  'request.jwt.claims',
  '{"sub":"7a000000-0000-0000-0000-000000000002","role":"authenticated","aud":"authenticated"}',
  true
);
set local role authenticated;
select throws_ok(
  format($$select public.admin_rename_former_player(%L, 'short')$$, (select yves from ids)),
  '42501',
  'un simple membre ne peut pas renommer un joueur'
);
reset role;

-- Suppression d'un compte : le nom de joueur est raccourci automatiquement.
select set_config('request.jwt.claims', '', true);
-- Compte technique qui reprend les références d'un compte supprimé (absent
-- d'une base reconstruite depuis les seules migrations).
insert into auth.users (id, email, raw_user_meta_data)
values ('00000000-0000-0000-0000-000000000001', 'rename-systeme@example.invalid',
        '{"first_name":"Systeme","last_name":"Technique"}'::jsonb)
on conflict (id) do nothing;
insert into auth.users (id, email, raw_user_meta_data)
values ('7a000000-0000-0000-0000-000000000003', 'rename-leaving@example.invalid',
        '{"first_name":"Lea","last_name":"Partante"}'::jsonb);
update public.profiles set status = 'active' where id = '7a000000-0000-0000-0000-000000000003';
insert into public.season_players (id, season_id, first_name, last_name, is_goalkeeper, is_active, position, profile_id)
values ('7a300000-0000-0000-0000-000000000004', '7a200000-0000-0000-0000-000000000001',
   'Lea', 'Partante', false, true, 4, '7a000000-0000-0000-0000-000000000003');

select private.prepare_profile_for_hard_deletion('7a000000-0000-0000-0000-000000000003');
select is(
  (select display_name from public.players
   where id = (select player_id from public.season_players where id = '7a300000-0000-0000-0000-000000000004')),
  'Lea P.',
  'à la suppression du compte, le nom de joueur devient « Lea P. »'
);

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
