begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Petit Filet : plus aucun nom n'est écarté d'office des archives. Un nom
-- autrefois réservé au staff de l'ancien club doit être traité comme celui
-- de n'importe quel joueur (homonymes possibles dans d'autres clubs).
select ok(
  not private.is_known_non_player_archive_name('Paul   Staffarchive'),
  'aucun nom n''est plus considéré comme staff historique'
);

insert into public.opponents(id, name)
values ('ca600000-0000-0000-0000-000000000001', 'Adversaire test staff archive');

insert into public.historical_match_scores(
  id, opponent_id, match_date, score_as_grinta, score_adverse, is_home
)
values (
  'ca700000-0000-0000-0000-000000000001',
  'ca600000-0000-0000-0000-000000000001',
  date '2096-09-01', 1, 0, true
);

insert into public.historical_match_details(
  match_id, formation, field_players, bench_players, present_names, scorers, motm_names
)
values (
  'ca700000-0000-0000-0000-000000000001',
  'test',
  '[{"name":"Joueur Archive Test","is_gk":false,"x_pct":50,"y_pct":50}]'::jsonb,
  '[]'::jsonb,
  '["Joueur Archive Test","Paul Staffarchive"]'::jsonb,
  '[]'::jsonb,
  '["Paul Staffarchive"]'::jsonb
);

select ok(
  (
    select present_names @> '["Paul Staffarchive"]'::jsonb
       and motm_names @> '["Paul Staffarchive"]'::jsonb
    from public.historical_match_details
    where match_id = 'ca700000-0000-0000-0000-000000000001'::uuid
  ),
  'les JSON historiques d’origine sont conservés intégralement'
);

select is(
  (
    select count(*)
    from public.historical_match_players hmp
    where hmp.match_id = 'ca700000-0000-0000-0000-000000000001'::uuid
  ),
  2::bigint,
  'la projection normalisée du match contient les deux noms, sans exclusion codée en dur'
);

select * from finish();
rollback;
