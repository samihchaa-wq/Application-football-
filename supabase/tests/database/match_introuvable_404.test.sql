begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Un lien vers un match inexistant (ou d'un autre club) doit répondre
-- « introuvable » (PT404, HTTP 404), pas une erreur serveur (P0002, HTTP 500).
create temporary table test_club (id uuid not null) on commit drop;
insert into test_club
select (public.create_club('Club Introuvable Tests', 'INTRO', '#112233', '#FFFFFF', 'Europe/Paris', null)).id;

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select
  '1d000000-0000-0000-0000-00000000000a', 'membre-introuvable@example.invalid',
  jsonb_build_object('first_name', 'Membre', 'last_name', 'Introuvable'),
  jsonb_build_object('club_id', id)
from test_club;

update public.profiles
set status = 'active'
where id = '1d000000-0000-0000-0000-00000000000a';

select set_config(
  'request.jwt.claims',
  '{"sub":"1d000000-0000-0000-0000-00000000000a","role":"authenticated","aud":"authenticated"}',
  true
);
set local role authenticated;

select throws_ok(
  $$select public.match_prediction_participant_count('1d000000-0000-0000-0000-0000000000ff')$$,
  'PT404',
  'Match not found',
  'un match inexistant répond « introuvable » (404), pas une erreur serveur'
);

reset role;
select * from finish();
rollback;
