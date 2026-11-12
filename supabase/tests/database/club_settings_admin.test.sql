begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Réglages du club : fonctionnalités à activer ou non, nom du club. Deux
-- clubs, pour vérifier que le réglage de l'un ne touche pas l'autre.
create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
grant select on test_clubs to authenticated;
insert into test_clubs
select 'a', id from public.create_club('Club Réglages A', null, null, null, null, null);
insert into test_clubs
select 'b', id from public.create_club('Club Réglages B', null, null, null, null, null);

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select v.id::uuid, v.email, jsonb_build_object('first_name', v.first_name, 'last_name', 'Tests'),
       jsonb_build_object('club_id', club.id)
from (values
  ('1e000000-0000-0000-0000-00000000000a', 'admin-a-reglages@example.invalid', 'Admin', 'a'),
  ('1e000000-0000-0000-0000-00000000000c', 'joueur-a-reglages@example.invalid', 'Joueur', 'a'),
  ('1e000000-0000-0000-0000-00000000000b', 'admin-b-reglages@example.invalid', 'Admin', 'b')
) as v(id, email, first_name, label)
join test_clubs club on club.label = v.label;

update public.profiles
set status = 'active',
    role = case when first_name = 'Admin' then 'admin' else 'pronostiqueur' end
where id::text like '1e000000-%';

create function pg_temp.act_as(p_id text) returns void language sql as $$
  select set_config(
    'request.jwt.claims',
    format('{"sub":"%s","role":"authenticated","aud":"authenticated"}', p_id),
    true
  );
$$;

-- Administrateur du club A
select pg_temp.act_as('1e000000-0000-0000-0000-00000000000a');
set local role authenticated;

select is(
  (select count(*) from jsonb_each(public.get_club_modules()) where value = 'true'::jsonb),
  7::bigint,
  'un nouveau club démarre avec toutes les fonctionnalités activées'
);
select is(
  public.admin_set_club_module('badges', false) -> 'badges', 'false'::jsonb,
  'l’administrateur désactive une fonctionnalité'
);
select is(
  public.get_club_modules() -> 'predictions', 'true'::jsonb,
  'les autres fonctionnalités ne bougent pas'
);
select throws_ok(
  $$select public.admin_set_club_module('sports_management', false)$$,
  '22023', null,
  'une fonctionnalité hors liste ne peut pas être modifiée par ce biais'
);
select is(
  public.admin_update_club_identity('  FC   Nouveau Nom ', 'FNN') ->> 'name',
  'FC Nouveau Nom',
  'l’administrateur renomme son club'
);
select throws_ok(
  $$select public.admin_update_club_identity('X', 'FNN')$$,
  '22023', null,
  'un nom de club trop court est refusé'
);
select is(
  public.admin_update_club_colors('#aa0000', '#FFFFFF') ->> 'primary_color',
  '#AA0000',
  'l’administrateur choisit les couleurs de son club'
);
select throws_ok(
  $$select public.admin_update_club_colors('rouge', '#FFFFFF')$$,
  '22023', null,
  'une couleur invalide est refusée'
);
select is(
  public.admin_set_club_logo(
    'club-logos/' || (select id::text from public.clubs) || '/logo.png'
  ) ->> 'logo_path',
  'club-logos/' || (select id::text from public.clubs) || '/logo.png',
  'l’administrateur enregistre le logo de son club'
);
select throws_ok(
  $$select public.admin_set_club_logo('club-logos/00000000-0000-0000-0000-000000000000/logo.png')$$,
  '22023', null,
  'un chemin de logo d’un autre club est refusé'
);
select is(
  public.admin_set_club_logo(null) ->> 'logo_path', null,
  'le logo peut être retiré'
);
select is(
  public.admin_set_club_home_address('  1 rue du Stade, Toulouse  '),
  '1 rue du Stade, Toulouse',
  'l’admin fixe le terrain du club A, espaces retirés'
);
select is(
  (select home_address from public.club_settings),
  '1 rue du Stade, Toulouse',
  'le terrain du club A est enregistré sur son seul réglage'
);
select throws_ok(
  $$select public.admin_set_club_home_address(repeat('a', 201))$$,
  '22023', null,
  'une adresse de plus de 200 caractères est refusée'
);
select throws_ok(
  $$select public.admin_set_club_home_address(E'Rue\\nVille')$$,
  '22023', null,
  'une adresse multiligne est refusée'
);
reset role;

-- Simple membre du club A
select pg_temp.act_as('1e000000-0000-0000-0000-00000000000c');
set local role authenticated;
select is(
  public.get_club_modules() -> 'badges', 'false'::jsonb,
  'un membre voit le réglage posé par son administrateur'
);
select throws_ok(
  $$select public.admin_set_club_module('badges', true)$$,
  '42501', null,
  'un simple membre ne peut pas changer les fonctionnalités'
);
select throws_ok(
  $$select public.admin_update_club_identity('Piraté', 'PIR')$$,
  '42501', null,
  'un simple membre ne peut pas renommer le club'
);
select throws_ok(
  $$select public.admin_set_club_logo(null)$$,
  '42501', null,
  'un simple membre ne peut pas changer le logo'
);
select throws_ok(
  $$select public.admin_update_club_colors('#000000', '#FFFFFF')$$,
  '42501', null,
  'un simple membre ne peut pas changer les couleurs'
);
select throws_ok(
  $$select public.admin_set_club_home_address('Rue interdite')$$,
  '42501', null,
  'un membre ne peut pas changer le terrain'
);
select is(
  (select primary_color from public.clubs), '#AA0000',
  'un membre voit les couleurs choisies par son administrateur'
);
reset role;

-- Administrateur du club B : rien n'a changé chez lui.
select pg_temp.act_as('1e000000-0000-0000-0000-00000000000b');
set local role authenticated;
select is(
  public.get_club_modules() -> 'badges', 'true'::jsonb,
  'le réglage d’un club ne touche pas un autre club'
);
select is(
  (select name from public.clubs), 'Club Réglages B',
  'le renommage d’un club ne touche pas un autre club'
);
select isnt(
  (select primary_color from public.clubs), '#AA0000',
  'les couleurs d’un club ne touchent pas un autre club'
);
select is(
  (select home_address from public.club_settings), null,
  'le terrain du club B reste vide après la modification du club A'
);
select is(
  public.admin_set_club_home_address('Terrain du club B'),
  'Terrain du club B',
  'le club B configure son terrain indépendamment'
);
select is(
  public.admin_set_club_home_address(null), null,
  'le terrain du club B peut être effacé'
);
reset role;

select * from finish();
rollback;
