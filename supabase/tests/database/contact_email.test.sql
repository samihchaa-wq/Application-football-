begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Adresse e-mail de contact : confirmation par lien, une adresse confirmée par
-- compte, récupération réservée aux comptes actifs. Transaction annulée.
create temporary table test_club on commit drop as
select * from public.create_club('Club Mail Tests', null, null, null, null, null);

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select v.id::uuid, v.email,
       jsonb_build_object('first_name', v.first_name, 'last_name', 'Tests'),
       jsonb_build_object('club_id', (select id from test_club))
from (values
  ('1f000000-0000-0000-0000-000000000001', 'alice-mail@example.invalid', 'Alice'),
  ('1f000000-0000-0000-0000-000000000002', 'bruno-mail@example.invalid', 'Bruno')
) as v(id, email, first_name);

update public.profiles set status = 'active' where id::text like '1f000000-%';

-- Droits : réservé à la clé de service.
select ok(
  not has_function_privilege('authenticated', 'public.request_contact_email(uuid,text,text)', 'EXECUTE')
  and not has_function_privilege('authenticated', 'public.confirm_contact_email(text)', 'EXECUTE')
  and not has_function_privilege('authenticated', 'public.profile_for_recovery_email(text)', 'EXECUTE')
  and not has_function_privilege('authenticated', 'public.consume_email_rate_limit(text,text)', 'EXECUTE')
  and not has_function_privilege('anon', 'public.profile_for_recovery_email(text)', 'EXECUTE'),
  'un compte ordinaire ne peut pas appeler les fonctions d’envoi de mail'
);

-- Demande de confirmation
select is(
  public.request_contact_email(
    '1f000000-0000-0000-0000-000000000001', '  Alice@Example.invalid ', repeat('a', 64)),
  true,
  'une nouvelle adresse déclenche l’envoi d’un lien'
);
select is(
  (select pending_contact_email from public.profiles where id = '1f000000-0000-0000-0000-000000000001'),
  'alice@example.invalid',
  'l’adresse est rangée en minuscules, en attente de confirmation'
);
select is(
  (select contact_email from public.profiles where id = '1f000000-0000-0000-0000-000000000001'),
  null,
  'tant que le lien n’est pas ouvert, l’adresse n’est pas confirmée'
);
select is(
  (select count(*) from public.profile_for_recovery_email('alice@example.invalid')), 0::bigint,
  'une adresse non confirmée ne retrouve aucun compte'
);
select throws_ok(
  $$select public.request_contact_email('1f000000-0000-0000-0000-000000000001', 'pas-une-adresse', repeat('b', 64))$$,
  '22023', null, 'une adresse invalide est refusée'
);

-- Confirmation
select is(public.confirm_contact_email(repeat('f', 64)), false, 'un lien inconnu ne confirme rien');
select is(public.confirm_contact_email(repeat('a', 64)), true, 'le lien envoyé confirme l’adresse');
select is(
  (select contact_email from public.profiles where id = '1f000000-0000-0000-0000-000000000001'),
  'alice@example.invalid', 'l’adresse est maintenant celle du compte'
);
select isnt(
  (select contact_email_confirmed_at from public.profiles where id = '1f000000-0000-0000-0000-000000000001'),
  null, 'la date de confirmation est enregistrée'
);
select is(public.confirm_contact_email(repeat('a', 64)), false, 'un lien ne sert qu’une fois');

-- Récupération
select is(
  (select auth_email from public.profile_for_recovery_email('ALICE@example.invalid')),
  'alice-mail@example.invalid',
  'une adresse confirmée retrouve le compte, quelle que soit la casse'
);

-- Une adresse confirmée n'appartient qu'à un seul compte.
select is(
  public.request_contact_email(
    '1f000000-0000-0000-0000-000000000002', 'alice@example.invalid', repeat('c', 64)),
  false,
  'une adresse déjà confirmée ailleurs ne déclenche aucun envoi'
);
select is(
  (select count(*) from private.email_confirmations
   where profile_id = '1f000000-0000-0000-0000-000000000002'),
  0::bigint, 'et ne crée aucun lien'
);

-- Changer d'adresse garde l'ancienne tant que la nouvelle n'est pas confirmée.
select is(
  public.request_contact_email(
    '1f000000-0000-0000-0000-000000000001', 'alice2@example.invalid', repeat('d', 64)),
  true, 'une nouvelle adresse peut être demandée'
);
select is(
  (select contact_email from public.profiles where id = '1f000000-0000-0000-0000-000000000001'),
  'alice@example.invalid', 'l’ancienne adresse reste active en attendant'
);
select is(public.confirm_contact_email(repeat('d', 64)), true, 'la nouvelle adresse est confirmée');
select is(
  (select count(*) from public.profile_for_recovery_email('alice@example.invalid')), 0::bigint,
  'l’ancienne adresse ne retrouve plus le compte'
);

-- Un lien expiré ne confirme rien.
select public.request_contact_email(
  '1f000000-0000-0000-0000-000000000002', 'bruno@example.invalid', repeat('e', 64));
update private.email_confirmations set expires_at = now() - interval '1 minute'
where token_hash = repeat('e', 64);
select is(public.confirm_contact_email(repeat('e', 64)), false, 'un lien expiré ne confirme rien');

-- Un compte non actif n'est pas retrouvé.
select public.request_contact_email(
  '1f000000-0000-0000-0000-000000000002', 'bruno@example.invalid', repeat('1', 64));
select public.confirm_contact_email(repeat('1', 64));
update public.profiles set status = 'archived' where id = '1f000000-0000-0000-0000-000000000002';
select is(
  (select count(*) from public.profile_for_recovery_email('bruno@example.invalid')), 0::bigint,
  'un compte archivé n’est pas retrouvé'
);

-- Plafond d'envois : 3 par heure et par adresse, 10 par heure et par origine.
select is(public.consume_email_rate_limit(repeat('2', 64), repeat('3', 64)), true, 'première demande acceptée');
select is(public.consume_email_rate_limit(repeat('2', 64), repeat('3', 64)), true, 'deuxième demande acceptée');
select is(public.consume_email_rate_limit(repeat('2', 64), repeat('3', 64)), true, 'troisième demande acceptée');
select is(public.consume_email_rate_limit(repeat('2', 64), repeat('3', 64)), false, 'la quatrième pour la même adresse est refusée');
select is(public.consume_email_rate_limit(repeat('2', 64), repeat('4', 64)), true, 'une autre adresse reste possible');

-- Un administrateur de club ne voit pas l'adresse des membres dans leur liste.
update public.profiles set role = 'admin' where id = '1f000000-0000-0000-0000-000000000001';
select set_config(
  'request.jwt.claims',
  '{"sub":"1f000000-0000-0000-0000-000000000001","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select is(
  (select public.get_my_profile() ->> 'contact_email'), 'alice2@example.invalid',
  'un membre voit sa propre adresse confirmée'
);
select is(
  (select count(*) from public.staff_list_profiles() p where to_jsonb(p) ? 'contact_email'),
  0::bigint,
  'la liste des membres n’expose aucune adresse e-mail'
);
reset role;

select * from finish();
rollback;
