-- M01 : test COMPORTEMENTAL de separation des chemins Storage entre 2 clubs.
-- ATTENTION: fixtures exclusivement sur la base Supabase locale jetable de CI.
-- Tous les utilisateurs/objets fictifs sont annules par ROLLBACK.
begin;
set local search_path = public, extensions, pg_catalog;
select no_plan();

create temporary table m01_storage_clubs (
  label text primary key,
  id uuid not null
) on commit drop;

insert into m01_storage_clubs
select 'a', (public.create_club('M01 Stockage Alpha', 'M01A', null, null, null, null)).id;
insert into m01_storage_clubs
select 'b', (public.create_club('M01 Stockage Bravo', 'M01B', null, null, null, null)).id;

-- L'Auth locale cree les profils rattaches a chaque club.
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select ('a5100000-0000-0000-0000-00000000000' || label)::uuid,
       'm01-storage-' || label || '@example.invalid',
       jsonb_build_object('first_name','M01','last_name',upper(label)),
       jsonb_build_object('club_id', id)
from m01_storage_clubs;

update public.profiles
set status = 'active', role = 'admin'
where id in (
  'a5100000-0000-0000-0000-00000000000a',
  'a5100000-0000-0000-0000-00000000000b'
);

-- Deux saisons, joueurs, invites et fiches de saison, chacun dans son club.
do $fixtures$
declare
  r record;
  v_actor uuid;
  v_player uuid;
  v_season uuid;
begin
  for r in select label, id from m01_storage_clubs loop
    perform set_config('app.club_id', r.id::text, true);
    v_actor := ('a5100000-0000-0000-0000-00000000000' || r.label)::uuid;
    v_player := ('a5110000-0000-0000-0000-00000000000' || r.label)::uuid;
    v_season := ('a5120000-0000-0000-0000-00000000000' || r.label)::uuid;

    insert into public.players(id, display_name)
    values(v_player, 'M01 joueur ' || upper(r.label));

    insert into public.seasons(id, name, status)
    values(v_season, 'M01 S' || upper(r.label), 'open');

    insert into public.season_players(
      id, season_id, first_name, last_name, is_active, player_id
    ) values(
      ('a5130000-0000-0000-0000-00000000000' || r.label)::uuid,
      v_season, 'M01', upper(r.label), true, v_player
    );

    insert into public.guest_players(
      id, first_name, created_by, updated_by, player_id
    ) values(
      ('a5140000-0000-0000-0000-00000000000' || r.label)::uuid,
      'Invite M01 ' || upper(r.label), v_actor, v_actor, v_player
    );
  end loop;
end;
$fixtures$;

-- L'acteur est A mais l'en-tete de contexte technique essaie de viser B.
-- current_club_id doit continuer a deriver le club du profil Auth A.
select set_config('app.club_id', (select id::text from m01_storage_clubs where label = 'b'), true);
select set_config(
  'request.jwt.claims',
  '{"sub":"a5100000-0000-0000-0000-00000000000a","role":"authenticated","aud":"authenticated"}',
  true
);

select is(private.current_club_id(),
  (select id from m01_storage_clubs where label = 'a'),
  'l utilisateur A conserve son club meme avec un contexte technique B'
);

select ok(private.storage_path_in_current_club(
  'profile-photos', 'a5100000-0000-0000-0000-00000000000a/avatar.png'),
  'A peut viser le dossier de son propre profil'
);
select ok(not private.storage_path_in_current_club(
  'profile-photos', 'a5100000-0000-0000-0000-00000000000b/avatar.png'),
  'A ne peut pas viser le dossier du profil de B'
);

select ok(private.storage_path_in_current_club(
  'profile-photos', 'guest/a5140000-0000-0000-0000-00000000000a/photo.png'),
  'A peut viser le dossier de son invite'
);
select ok(not private.storage_path_in_current_club(
  'profile-photos', 'guest/a5140000-0000-0000-0000-00000000000b/photo.png'),
  'A ne peut pas viser le dossier de l invite de B'
);

select ok(private.storage_path_in_current_club(
  'profile-photos', 'season/a5130000-0000-0000-0000-00000000000a/photo.png'),
  'A peut viser le dossier de son joueur de saison'
);
select ok(not private.storage_path_in_current_club(
  'profile-photos', 'season/a5130000-0000-0000-0000-00000000000b/photo.png'),
  'A ne peut pas viser le dossier du joueur de saison de B'
);

select * from finish();
rollback;
