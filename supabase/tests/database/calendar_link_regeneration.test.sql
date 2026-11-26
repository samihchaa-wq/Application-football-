begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Le lien d'abonnement au calendrier peut être remplacé par son titulaire
-- (20261208010000_lien_agenda_regenerable.sql) : l'ancien lien cesse de
-- fonctionner, celui des autres membres ne change pas.
create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
grant select on test_clubs to authenticated;

insert into test_clubs
select 'a', (public.create_club('Club Agenda Alpha', 'AGALPHA', null, null, null, null)).id;

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '3d000000-0000-0000-0000-00000000000a', 'agenda-a@example.invalid',
  jsonb_build_object('first_name', 'Joueur', 'last_name', 'Un'),
  jsonb_build_object('club_id', id)
from test_clubs where label = 'a';
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '3d000000-0000-0000-0000-00000000000b', 'agenda-b@example.invalid',
  jsonb_build_object('first_name', 'Joueur', 'last_name', 'Deux'),
  jsonb_build_object('club_id', id)
from test_clubs where label = 'a';

update public.profiles set status = 'active'
where id in ('3d000000-0000-0000-0000-00000000000a', '3d000000-0000-0000-0000-00000000000b');

create temporary table tokens (label text primary key, token uuid) on commit drop;
grant select, insert on tokens to authenticated;

-- Le second joueur a déjà un lien.
select set_config('request.jwt.claims',
  '{"sub":"3d000000-0000-0000-0000-00000000000b","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
insert into tokens values ('other', public.get_or_create_calendar_subscription_token());

-- Le premier joueur crée son lien, puis le remplace.
select set_config('request.jwt.claims',
  '{"sub":"3d000000-0000-0000-0000-00000000000a","role":"authenticated","aud":"authenticated"}', true);
insert into tokens values ('before', public.get_or_create_calendar_subscription_token());
insert into tokens values ('after', public.regenerate_calendar_subscription_token());

select isnt(
  (select token from tokens where label = 'after'),
  (select token from tokens where label = 'before'),
  'régénérer donne un nouveau lien'
);

select is(
  public.get_or_create_calendar_subscription_token(),
  (select token from tokens where label = 'after'),
  'le nouveau lien remplace l''ancien'
);

reset role;

select ok(
  not exists (
    select 1 from public.calendar_subscriptions
    where token = (select token from tokens where label = 'before')
  ),
  'l''ancien lien ne mène plus à aucun abonnement'
);

select is(
  (select token from public.calendar_subscriptions
   where profile_id = '3d000000-0000-0000-0000-00000000000b'),
  (select token from tokens where label = 'other'),
  'le lien d''un autre membre ne change pas'
);

-- Sans compte, rien n'est possible.
select set_config('request.jwt.claims', '', true);
set local role anon;
select throws_ok(
  'select public.regenerate_calendar_subscription_token()',
  '42501',
  null,
  'un visiteur sans compte ne peut pas régénérer de lien'
);
reset role;

select * from finish();
rollback;
