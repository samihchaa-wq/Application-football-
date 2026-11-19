begin;

set local search_path = public, extensions, pg_catalog;
select plan(7);

-- Un club et deux comptes : un compte de démo (identifiant fixe) et un compte
-- ordinaire. Tout est annulé au rollback.
create temporary table test_club on commit drop as
select id from public.create_club('Club Démo Protégé', 'DEMOP', null, null, null, null);

insert into auth.users (id, email, encrypted_password, raw_user_meta_data, raw_app_meta_data)
select account.id, account.id::text || '@example.invalid', 'ancien-hash',
       jsonb_build_object('first_name', 'Démo', 'last_name', 'Compte'),
       jsonb_build_object('club_id', (select id from test_club))
from (values
  ('de000000-0000-4000-8000-0000000000aa'::uuid),
  ('7c000000-0000-4000-8000-0000000000aa'::uuid)
) as account(id);

select throws_ok(
  $$update auth.users set encrypted_password = 'nouveau-hash'
    where id = 'de000000-0000-4000-8000-0000000000aa'$$,
  '42501',
  null,
  'le mot de passe d''un compte de démo ne peut pas être changé'
);

select throws_ok(
  $$delete from auth.users where id = 'de000000-0000-4000-8000-0000000000aa'$$,
  '42501',
  null,
  'un compte de démo ne peut pas être supprimé'
);

select throws_ok(
  $$select private.prepare_profile_for_hard_deletion('de000000-0000-4000-8000-0000000000aa')$$,
  '42501',
  null,
  'la préparation de suppression refuse un compte de démo avant toute modification'
);

select lives_ok(
  $$update auth.users set encrypted_password = 'nouveau-hash'
    where id = '7c000000-0000-4000-8000-0000000000aa'$$,
  'un compte ordinaire change son mot de passe normalement'
);

select lives_ok(
  $$update auth.users set raw_user_meta_data = raw_user_meta_data || '{"surnom":"Démo"}'
    where id = 'de000000-0000-4000-8000-0000000000aa'$$,
  'les autres modifications du compte de démo restent possibles'
);

-- Le script de démo lève le verrou pour sa propre transaction.
select set_config('pf.demo_reset', 'on', true);
select lives_ok(
  $$update auth.users set encrypted_password = 'remis-a-neuf'
    where id = 'de000000-0000-4000-8000-0000000000aa'$$,
  'le script de démo peut remettre le mot de passe à neuf'
);
select lives_ok(
  $$delete from auth.users where id = 'de000000-0000-4000-8000-0000000000aa'$$,
  'le script de démo peut recréer les comptes'
);

select * from finish();
rollback;
