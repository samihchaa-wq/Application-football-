begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Maillots propres à chaque club : deux clubs, pour vérifier que les maillots
-- de l'un ne touchent pas l'autre.
create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
grant select on test_clubs to authenticated;
insert into test_clubs
select 'a', id from public.create_club('Club Maillots A', null, null, null, null, null);
insert into test_clubs
select 'b', id from public.create_club('Club Maillots B', null, null, null, null, null);
insert into test_clubs
select 'c', id from public.create_club('Club Maillots C', null, null, null, null, null);

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select v.id::uuid, v.email, jsonb_build_object('first_name', v.first_name, 'last_name', 'Tests'),
       jsonb_build_object('club_id', club.id)
from (values
  ('1f000000-0000-0000-0000-00000000000a', 'admin-a-maillots@example.invalid', 'Admin', 'a'),
  ('1f000000-0000-0000-0000-00000000000c', 'joueur-a-maillots@example.invalid', 'Joueur', 'a'),
  ('1f000000-0000-0000-0000-00000000000b', 'admin-b-maillots@example.invalid', 'Admin', 'b'),
  ('1f000000-0000-0000-0000-00000000000d', 'admin-d-maillots@example.invalid', 'Admin', 'a'),
  ('1f000000-0000-0000-0000-0000000000c0', 'admin-c-maillots@example.invalid', 'Admin', 'c')
) as v(id, email, first_name, label)
join test_clubs club on club.label = v.label;

update public.profiles
set status = 'active',
    role = case when first_name = 'Admin' then 'admin' else 'pronostiqueur' end
where id::text like '1f000000-%';

-- Un administrateur du club A dont le compte est désactivé (archivé), et un club C
-- suspendu par l'éditeur.
update public.profiles set status = 'archived'
where id = '1f000000-0000-0000-0000-00000000000d';
update public.clubs set status = 'suspended'
where id = (select id from test_clubs where label = 'c');

create function pg_temp.act_as(p_id text) returns void language sql as $$
  select set_config(
    'request.jwt.claims',
    format('{"sub":"%s","role":"authenticated","aud":"authenticated"}', p_id),
    true
  );
$$;

create function pg_temp.kits(p_second_enabled boolean default true) returns jsonb
language sql as $$
  select jsonb_build_array(
    jsonb_build_object('slot', 'france', 'label', '  Domicile  ', 'body', '#aa0000', 'trim', '#FFFFFF', 'enabled', true),
    jsonb_build_object('slot', 'orange', 'label', 'Extérieur', 'body', '#FFFFFF', 'trim', '#AA0000', 'enabled', p_second_enabled),
    jsonb_build_object('slot', 'blue', 'label', 'Troisième', 'body', '#111111', 'trim', '#AA0000', 'enabled', false)
  );
$$;

-- Administrateur du club A
select pg_temp.act_as('1f000000-0000-0000-0000-00000000000a');
set local role authenticated;

select is(
  (select kits from public.clubs), null,
  'un nouveau club n’a pas de maillots enregistrés (maillots par défaut)'
);
select is(
  public.admin_update_club_kits(pg_temp.kits()) -> 0 ->> 'label',
  'Domicile',
  'l’administrateur enregistre ses maillots (nom nettoyé)'
);
select is(
  (select kits -> 0 ->> 'body' from public.clubs), '#AA0000',
  'les couleurs sont enregistrées en majuscules'
);
select is(
  (select kits -> 0 ->> 'goalkeeper_body' from public.clubs), '#168A52',
  'les anciens clients gardent une couleur de gardien par défaut'
);
select is(
  public.admin_update_club_kits(
    jsonb_set(
      jsonb_set(pg_temp.kits(), '{0,goalkeeper_body}', '"#111111"'),
      '{0,goalkeeper_trim}', '"#fbe80c"'
    )
  ) -> 0 ->> 'goalkeeper_trim',
  '#FBE80C',
  'l’administrateur peut choisir une couleur distincte de gardien'
);
select is(
  (select kits -> 0 ->> 'goalkeeper_body' from public.clubs),
  '#111111',
  'la couleur gardien du club A est persistée'
);
select is(
  public.admin_update_club_kits(pg_temp.kits()) -> 0 ->> 'goalkeeper_body',
  '#111111',
  'un ancien client conserve la personnalisation du gardien'
);
select throws_ok(
  $$select public.admin_update_club_kits(
      jsonb_set(pg_temp.kits(), '{0,goalkeeper_body}', '"noir"')
  )$$,
  '22023', null,
  'le serveur refuse une couleur gardien non hexadécimale'
);
select throws_ok(
  $$select public.admin_update_club_kits(jsonb_build_array(pg_temp.kits() -> 0, pg_temp.kits() -> 1))$$,
  '22023', null,
  'il faut exactement trois maillots'
);
select throws_ok(
  $$select public.admin_update_club_kits(jsonb_build_array(pg_temp.kits() -> 0, pg_temp.kits() -> 0, pg_temp.kits() -> 2))$$,
  '22023', null,
  'un emplacement en double est refusé'
);
select throws_ok(
  $$select public.admin_update_club_kits(jsonb_set(pg_temp.kits(), '{0,slot}', '"autre"'))$$,
  '22023', null,
  'un emplacement inconnu est refusé'
);
select throws_ok(
  $$select public.admin_update_club_kits(jsonb_set(pg_temp.kits(), '{0,body}', '"rouge"'))$$,
  '22023', null,
  'une couleur invalide est refusée'
);
select throws_ok(
  $$select public.admin_update_club_kits(jsonb_set(pg_temp.kits(), '{0,label}', '"   "'))$$,
  '22023', null,
  'un nom vide est refusé'
);
select throws_ok(
  $$select public.admin_update_club_kits(jsonb_set(pg_temp.kits(), '{0,label}', to_jsonb(repeat('x', 21))))$$,
  '22023', null,
  'un nom trop long est refusé'
);
select throws_ok(
  $$select public.admin_update_club_kits(jsonb_set(pg_temp.kits(false), '{0,enabled}', 'false'))$$,
  '22023', null,
  'au moins un maillot doit rester proposé'
);
select throws_ok(
  $$select public.admin_update_club_kits(jsonb_set(pg_temp.kits(), '{0,enabled}', '"oui"'))$$,
  '22023', null,
  'un état de maillot non booléen est refusé'
);
reset role;

-- Simple membre du club A
select pg_temp.act_as('1f000000-0000-0000-0000-00000000000c');
set local role authenticated;
select is(
  (select kits -> 1 ->> 'label' from public.clubs), 'Extérieur',
  'un membre voit les maillots choisis par son administrateur'
);
select throws_ok(
  $$select public.admin_update_club_kits(pg_temp.kits())$$,
  '42501', null,
  'un simple membre ne peut pas changer les maillots'
);
reset role;

-- Compte administrateur désactivé (club A).
select pg_temp.act_as('1f000000-0000-0000-0000-00000000000d');
set local role authenticated;
select throws_ok(
  $$select public.admin_update_club_kits(pg_temp.kits())$$,
  '42501', null,
  'un administrateur désactivé ne peut pas changer les maillots'
);
reset role;

-- Administrateur d'un club suspendu.
select pg_temp.act_as('1f000000-0000-0000-0000-0000000000c0');
set local role authenticated;
select throws_ok(
  $$select public.admin_update_club_kits(pg_temp.kits())$$,
  '42501', null,
  'l’administrateur d’un club suspendu ne peut pas changer les maillots'
);
reset role;

-- Compte connecté sans club (aucun profil).
select pg_temp.act_as('1f000000-0000-0000-0000-0000000000ff');
set local role authenticated;
select throws_ok(
  $$select public.admin_update_club_kits(pg_temp.kits())$$,
  '42501', null,
  'un compte sans club ne peut pas changer de maillots'
);
reset role;

-- Administrateur A avec un jeton trafiqué qui désigne le club B : seul son
-- propre club (celui de son profil) est modifié.
select set_config(
  'request.jwt.claims',
  format(
    '{"sub":"1f000000-0000-0000-0000-00000000000a","role":"authenticated","aud":"authenticated","club_id":"%1$s","app_metadata":{"club_id":"%1$s"}}',
    (select id from test_clubs where label = 'b')
  ),
  true
);
select set_config('app.club_id', (select id::text from test_clubs where label = 'b'), true);
select set_config(
  'request.headers',
  format('{"x-club-id":"%s"}', (select id from test_clubs where label = 'b')),
  true
);
set local role authenticated;
select is(
  public.admin_update_club_kits(jsonb_set(pg_temp.kits(), '{0,label}', '"Forcé"')) -> 0 ->> 'label',
  'Forcé',
  'l’administrateur A modifie ses maillots même avec un jeton trafiqué'
);
reset role;
select set_config('app.club_id', '', true);
select set_config('request.headers', '', true);
select is(
  (select kits -> 0 ->> 'label' from public.clubs where id = (select id from test_clubs where label = 'a')),
  'Forcé',
  'le changement est allé au club A'
);
select is(
  (select kits from public.clubs where id = (select id from test_clubs where label = 'b')),
  null,
  'le club B désigné par le jeton trafiqué reste inchangé'
);
select is(
  (select kits from public.clubs where id = (select id from test_clubs where label = 'c')),
  null,
  'le club suspendu reste inchangé'
);

-- Contrat de la fonction : propriétaire, chemin de recherche, droits.
select is(
  (select pg_get_userbyid(proowner)::text from pg_proc
   where oid = 'public.admin_update_club_kits(jsonb)'::regprocedure),
  'club_scope',
  'la fonction appartient au rôle cloisonné club_scope'
);
select ok(
  (select prosecdef and proconfig @> array['search_path=""'] from pg_proc
   where oid = 'public.admin_update_club_kits(jsonb)'::regprocedure),
  'la fonction a un chemin de recherche vide'
);
select ok(
  not has_function_privilege('anon', 'public.admin_update_club_kits(jsonb)', 'execute'),
  'un visiteur non connecté ne peut pas appeler la fonction'
);
select ok(
  has_function_privilege('authenticated', 'public.admin_update_club_kits(jsonb)', 'execute'),
  'un compte connecté peut appeler la fonction (qui vérifie le rôle)'
);

-- Administrateur du club B : rien n'a changé chez lui.
select pg_temp.act_as('1f000000-0000-0000-0000-00000000000b');
set local role authenticated;
select is(
  (select kits from public.clubs), null,
  'les maillots d’un club ne touchent pas un autre club'
);
reset role;

select * from finish();
rollback;
