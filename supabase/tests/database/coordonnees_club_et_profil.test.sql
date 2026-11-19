begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Coordonnées du club (admin) et téléphone / date de naissance du membre
-- (visibles par lui seul). Deux clubs pour vérifier le cloisonnement.
select ok(
  not has_function_privilege(
    'anon', 'public.admin_set_club_contact(text,text,text,text,text,text)', 'EXECUTE'
  ),
  'un visiteur anonyme ne peut pas changer les coordonnées d’un club'
);
select ok(
  not has_function_privilege('anon', 'public.set_my_private_details(text,date)', 'EXECUTE'),
  'un visiteur anonyme ne peut pas écrire de coordonnées personnelles'
);
select ok(
  not has_table_privilege('authenticated', 'public.profile_private_details', 'SELECT'),
  'aucune lecture directe des coordonnées personnelles depuis l’application'
);

create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
grant select on test_clubs to authenticated;
insert into test_clubs
select 'a', id from public.create_club('Club Contact A', null, null, null, null, null);
insert into test_clubs
select 'b', id from public.create_club('Club Contact B', null, null, null, null, null);

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select v.id::uuid, v.email, jsonb_build_object('first_name', v.first_name, 'last_name', 'Tests'),
       jsonb_build_object('club_id', club.id)
from (values
  ('1f000000-0000-0000-0000-00000000000a', 'admin-a-contact@example.invalid', 'Admin', 'a'),
  ('1f000000-0000-0000-0000-00000000000c', 'joueur-a-contact@example.invalid', 'Joueur', 'a'),
  ('1f000000-0000-0000-0000-00000000000b', 'admin-b-contact@example.invalid', 'Admin', 'b')
) as v(id, email, first_name, label)
join test_clubs club on club.label = v.label;

update public.profiles
set status = 'active',
    role = case when first_name = 'Admin' then 'admin' else 'pronostiqueur' end
where id::text like '1f000000-%';

create function pg_temp.act_as(p_id text) returns void language sql as $$
  select set_config(
    'request.jwt.claims',
    format('{"sub":"%s","role":"authenticated","aud":"authenticated"}', p_id),
    true
  );
$$;

-- Administrateur du club A
select pg_temp.act_as('1f000000-0000-0000-0000-00000000000a');
set local role authenticated;

select is(
  public.admin_set_club_contact(
    '  Marie Durand ', ' Contact@Club-A.fr ', '06 12 34 56 78',
    '3 rue du Stade, 31000 Toulouse', 'https://club-a.fr', 'w123 456 789'
  ),
  jsonb_build_object(
    'contact_name', 'Marie Durand',
    'contact_email', 'contact@club-a.fr',
    'contact_phone', '06 12 34 56 78',
    'postal_address', '3 rue du Stade, 31000 Toulouse',
    'website', 'https://club-a.fr',
    'registration_number', 'W123456789'
  ),
  'l’administrateur enregistre les coordonnées, espaces et casse normalisés'
);
select throws_ok(
  $$select public.admin_set_club_contact(null, 'pas-un-mail', null, null, null, null)$$,
  '22023', null, 'un e-mail invalide est refusé'
);
select throws_ok(
  $$select public.admin_set_club_contact(null, null, 'abc', null, null, null)$$,
  '22023', null, 'un téléphone invalide est refusé'
);
select throws_ok(
  $$select public.admin_set_club_contact(null, null, null, null, null, '1234')$$,
  '22023', null, 'un numéro RNA / SIRET invalide est refusé'
);
select is(
  public.admin_set_member_private_details(
    '1f000000-0000-0000-0000-00000000000c', '07 00 00 00 01', date '2001-03-04'
  ) ->> 'phone',
  '07 00 00 00 01',
  'l’administrateur saisit le téléphone d’un membre de son club'
);
select throws_ok(
  $$select public.admin_set_member_private_details(
      '1f000000-0000-0000-0000-00000000000b', '0600000000', null)$$,
  'P0002', null, 'un administrateur ne touche pas un membre d’un autre club'
);
select is(
  public.set_my_private_details('+33 6 11 22 33 44', date '1990-05-12'),
  jsonb_build_object('phone', '+33 6 11 22 33 44', 'birth_date', '1990-05-12'),
  'l’administrateur enregistre ses propres coordonnées'
);
reset role;

-- Joueur du club A
select pg_temp.act_as('1f000000-0000-0000-0000-00000000000c');
set local role authenticated;
select is(
  (select contact_email from public.club_settings), 'contact@club-a.fr',
  'un membre voit les coordonnées de son club'
);
select throws_ok(
  $$select public.admin_set_club_contact(null, null, null, null, null, null)$$,
  '42501', null, 'un simple membre ne peut pas changer les coordonnées du club'
);
select is(
  public.get_my_private_details(),
  jsonb_build_object('phone', '07 00 00 00 01', 'birth_date', '2001-03-04'),
  'le membre relit ses propres coordonnées, saisies par l’administrateur'
);
select is(
  (select item ->> 'phone' from jsonb_array_elements(public.get_club_member_contacts()) item
   where item ->> 'profile_id' = '1f000000-0000-0000-0000-00000000000a'),
  '+33 6 11 22 33 44',
  'un membre voit le téléphone d’un autre membre dans l’Effectif'
);
select throws_ok(
  $$select public.admin_set_member_private_details(
      '1f000000-0000-0000-0000-00000000000a', '0600000000', null)$$,
  '42501', null, 'un simple membre ne modifie pas les coordonnées d’un autre'
);
select throws_ok(
  $$select public.set_my_private_details(null, current_date + 1)$$,
  '22023', null, 'une date de naissance dans le futur est refusée'
);
select is(
  public.set_my_private_details('0611223344', null) ->> 'phone', '0611223344',
  'le membre enregistre son téléphone'
);
select is(
  public.get_my_private_details() ->> 'phone', '0611223344',
  'le membre relit son téléphone'
);
select ok(
  public.export_my_data() ? 'profile_private_details',
  'le téléphone part dans l’export « Mes données »'
);
select is(
  public.set_my_private_details('', null),
  jsonb_build_object('phone', null, 'birth_date', null),
  'le membre peut tout effacer'
);
reset role;

-- Administrateur du club B : rien du club A.
select pg_temp.act_as('1f000000-0000-0000-0000-00000000000b');
set local role authenticated;
select is(
  (select contact_email from public.club_settings), null,
  'les coordonnées d’un club ne fuient pas vers un autre club'
);
select is(
  public.get_club_member_contacts(), '[]'::jsonb,
  'les téléphones des membres d’un club ne fuient pas vers un autre club'
);
reset role;

select * from finish();
rollback;
