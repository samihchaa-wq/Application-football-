-- Audit du 26/11/2026, points 47 et 21.
-- 47 : la photo d'un profil doit être dans le dossier de ce profil.
-- 21 : un membre ne lit (ni ne liste) que les dossiers de son club.
-- Fixtures sur la base locale jetable uniquement, annulées par ROLLBACK.
begin;
set local search_path = public, extensions, pg_catalog;
select no_plan();

create temporary table h_clubs (label text primary key, id uuid not null) on commit drop;
grant select on h_clubs to authenticated;

insert into h_clubs
select 'a', (public.create_club('Lot H Alpha', 'LOTHA', null, null, null, null)).id;
insert into h_clubs
select 'b', (public.create_club('Lot H Bravo', 'LOTHB', null, null, null, null)).id;

-- a1 : admin d'Alpha ; a2 : joueur d'Alpha ; b1 : admin de Bravo.
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select u.id, u.email,
  jsonb_build_object('first_name', 'Lot', 'last_name', u.last_name),
  jsonb_build_object('club_id', c.id)
from (values
  ('4a000000-0000-0000-0000-0000000000a1'::uuid, 'loth-a1@example.invalid', 'Aun', 'a'),
  ('4a000000-0000-0000-0000-0000000000a2'::uuid, 'loth-a2@example.invalid', 'Adeux', 'a'),
  ('4a000000-0000-0000-0000-0000000000b1'::uuid, 'loth-b1@example.invalid', 'Bun', 'b')
) as u(id, email, last_name, club)
join h_clubs c on c.label = u.club;

update public.profiles set status = 'active'
where id in ('4a000000-0000-0000-0000-0000000000a1',
             '4a000000-0000-0000-0000-0000000000a2',
             '4a000000-0000-0000-0000-0000000000b1');
update public.profiles set role = 'admin'
where id in ('4a000000-0000-0000-0000-0000000000a1',
             '4a000000-0000-0000-0000-0000000000b1');

-- Un joueur de saison d'Alpha, pour le dossier season/<id>/.
do $fixtures$
begin
  perform set_config('app.club_id', (select id::text from h_clubs where label = 'a'), true);
  insert into public.players(id, display_name)
  values ('4a100000-0000-0000-0000-0000000000a1', 'Lot H joueur');
  insert into public.seasons(id, name, status)
  values ('4a200000-0000-0000-0000-0000000000a1', '2026-2027', 'open');
  insert into public.season_players(id, season_id, first_name, last_name, is_active, player_id)
  values ('4a300000-0000-0000-0000-0000000000a1', '4a200000-0000-0000-0000-0000000000a1',
          'Lot', 'Saison', true, '4a100000-0000-0000-0000-0000000000a1');
  perform set_config('app.club_id', '', true);
end;
$fixtures$;

-- Fichiers posés directement (comme un import) : les règles de dépôt ne
-- jouent pas, seules les règles de lecture sont testées.
insert into storage.objects (bucket_id, name, owner_id, metadata) values
  ('profile-photos', '4a000000-0000-0000-0000-0000000000a1/avatar.jpg',
   '4a000000-0000-0000-0000-0000000000a1', '{"size": 100}'),
  ('profile-photos', '4a000000-0000-0000-0000-0000000000a2/avatar.jpg',
   '4a000000-0000-0000-0000-0000000000a2', '{"size": 100}'),
  ('profile-photos', 'season/4a300000-0000-0000-0000-0000000000a1/avatar.jpg',
   '4a000000-0000-0000-0000-0000000000a1', '{"size": 100}'),
  ('profile-photos', '4a000000-0000-0000-0000-0000000000b1/avatar.jpg',
   '4a000000-0000-0000-0000-0000000000b1', '{"size": 100}'),
  -- Déposé par l'admin d'Alpha, mais rangé dans le dossier d'un membre de Bravo.
  ('profile-photos', '4a000000-0000-0000-0000-0000000000b1/glisse.jpg',
   '4a000000-0000-0000-0000-0000000000a1', '{"size": 100}');

-- ---------------------------------------------------------------------------
-- Point 47 : le joueur a2 ne peut viser que son dossier
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims',
  '{"sub":"4a000000-0000-0000-0000-0000000000a2","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;

select throws_ok(
  $$update public.profiles set photo_url = '4a000000-0000-0000-0000-0000000000a1/avatar.jpg'
    where id = '4a000000-0000-0000-0000-0000000000a2'$$,
  '42501', 'La photo de profil doit être déposée dans le dossier de ce profil.',
  'un membre ne peut pas prendre la photo d''un autre membre'
);

select throws_ok(
  $$update public.profiles set photo_url = '4a000000-0000-0000-0000-0000000000a2/../4a000000-0000-0000-0000-0000000000a1/avatar.jpg'
    where id = '4a000000-0000-0000-0000-0000000000a2'$$,
  '42501', 'La photo de profil doit être déposée dans le dossier de ce profil.',
  'une remontée « .. » hors de son dossier est refusée'
);

select throws_ok(
  $$update public.profiles set photo_url = 'season/4a300000-0000-0000-0000-0000000000a1/avatar.jpg'
    where id = '4a000000-0000-0000-0000-0000000000a2'$$,
  '42501', 'La photo de profil doit être déposée dans le dossier de ce profil.',
  'un membre ne peut pas prendre la photo d''un joueur de saison'
);

select throws_ok(
  $$update public.profiles set photo_url = '4a000000-0000-0000-0000-0000000000a2/'
    where id = '4a000000-0000-0000-0000-0000000000a2'$$,
  '42501', 'La photo de profil doit être déposée dans le dossier de ce profil.',
  'un dossier sans fichier est refusé'
);

select throws_ok(
  $$update public.profiles set photo_url = 'https://exemple.invalid/storage/v1/object/public/profile-photos/4a000000-0000-0000-0000-0000000000a1/avatar.jpg'
    where id = '4a000000-0000-0000-0000-0000000000a2'$$,
  '42501', 'La photo de profil doit être déposée dans le dossier de ce profil.',
  'une adresse complète vers le dossier d''un autre membre est refusée'
);

select lives_ok(
  $$update public.profiles set photo_url = '4a000000-0000-0000-0000-0000000000a2/avatar.jpg'
    where id = '4a000000-0000-0000-0000-0000000000a2'$$,
  'un membre peut poser une photo de son propre dossier'
);

select lives_ok(
  $$update public.profiles set photo_url = 'https://exemple.invalid/storage/v1/object/sign/profile-photos/4a000000-0000-0000-0000-0000000000a2/avatar.jpg?token=x'
    where id = '4a000000-0000-0000-0000-0000000000a2'$$,
  'une ancienne adresse complète vers son propre dossier reste acceptée'
);

select lives_ok(
  $$update public.profiles set photo_url = null
    where id = '4a000000-0000-0000-0000-0000000000a2'$$,
  'un membre peut retirer sa photo'
);

reset role;

-- L'admin d'Alpha change la photo du joueur a2 : même règle.
select set_config('request.jwt.claims',
  '{"sub":"4a000000-0000-0000-0000-0000000000a1","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;

select throws_ok(
  $$update public.profiles set photo_url = '4a000000-0000-0000-0000-0000000000a1/avatar.jpg'
    where id = '4a000000-0000-0000-0000-0000000000a2'$$,
  '42501', 'La photo de profil doit être déposée dans le dossier de ce profil.',
  'un admin ne peut pas donner à un joueur la photo d''un autre dossier'
);

select lives_ok(
  $$update public.profiles set photo_url = '4a000000-0000-0000-0000-0000000000a2/avatar.jpg'
    where id = '4a000000-0000-0000-0000-0000000000a2'$$,
  'un admin peut poser la photo d''un joueur rangée dans le dossier du joueur'
);

reset role;

-- Une valeur déjà enregistrée hors dossier (avant ce contrôle) n'empêche pas
-- de modifier le reste du profil.
set local session_replication_role = replica;
update public.profiles set photo_url = '4a000000-0000-0000-0000-0000000000a1/avatar.jpg'
where id = '4a000000-0000-0000-0000-0000000000a2';
set local session_replication_role = origin;

-- Retirer la photo plus haut a effacé le fichier de a2 (nettoyage
-- automatique) : on le remet pour la partie lecture.
insert into storage.objects (bucket_id, name, owner_id, metadata) values
  ('profile-photos', '4a000000-0000-0000-0000-0000000000a2/avatar.jpg',
   '4a000000-0000-0000-0000-0000000000a2', '{"size": 100}');

select set_config('request.jwt.claims',
  '{"sub":"4a000000-0000-0000-0000-0000000000a2","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;

select lives_ok(
  $$update public.profiles set surnom = 'Lot H'
    where id = '4a000000-0000-0000-0000-0000000000a2'$$,
  'une photo existante n''est pas relue quand on change autre chose'
);

-- ---------------------------------------------------------------------------
-- Point 21 : lecture et liste limitées aux dossiers du club
-- ---------------------------------------------------------------------------

select is(
  (select array_agg(name order by name)::text[] from storage.objects
   where bucket_id = 'profile-photos' and name like '%/avatar.jpg'
     and (name like '4a%' or name like 'season/4a%')),
  array[
    '4a000000-0000-0000-0000-0000000000a1/avatar.jpg',
    '4a000000-0000-0000-0000-0000000000a2/avatar.jpg',
    'season/4a300000-0000-0000-0000-0000000000a1/avatar.jpg'
  ]::text[],
  'un membre voit les photos de son club (profils et joueurs de saison)'
);

select is(
  (select count(*) from storage.objects
   where bucket_id = 'profile-photos'
     and name like '4a000000-0000-0000-0000-0000000000b1/%'),
  0::bigint,
  'un membre ne voit rien du dossier d''un autre club, même déposé par son admin'
);

select ok(
  not exists (
    select 1 from storage.search('', 'profile-photos', 1000, 1, 0)
    where name = '4a000000-0000-0000-0000-0000000000b1'
  ),
  'la liste de la racine ne montre pas les dossiers d''un autre club'
);

select ok(
  exists (
    select 1 from storage.search('', 'profile-photos', 1000, 1, 0)
    where name = '4a000000-0000-0000-0000-0000000000a2'
  ),
  'la liste de la racine montre toujours les dossiers de son club'
);

select is(
  (select count(*) from storage.search(
     '4a000000-0000-0000-0000-0000000000b1/', 'profile-photos', 1000, 1, 0)),
  0::bigint,
  'le contenu du dossier d''un autre club ne se liste pas'
);

reset role;

select set_config('request.jwt.claims',
  '{"sub":"4a000000-0000-0000-0000-0000000000b1","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;

select is(
  (select array_agg(name order by name)::text[] from storage.objects
   where bucket_id = 'profile-photos' and (name like '4a%' or name like 'season/4a%')),
  array['4a000000-0000-0000-0000-0000000000b1/avatar.jpg']::text[],
  'Bravo ne voit que sa photo, ni celles d''Alpha ni le fichier glissé par Alpha'
);

reset role;

select * from finish();
rollback;
