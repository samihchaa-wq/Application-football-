begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Comptes inactifs : avertissement un mois avant les 3 ans sans utilisation,
-- suppression seulement un mois après un avertissement noté, et retour à zéro
-- dès que la personne revient.

select vault.create_secret('test-token', 'push_internal_token')
where not exists (
  select 1 from vault.secrets secret where secret.name = 'push_internal_token'
);

create temporary table test_club on commit drop as
select (public.create_club('Club Comptes Inactifs', 'INACT', null, null, null, null)).id;

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data, created_at, last_sign_in_at)
select v.id::uuid, v.id || '@example.invalid',
  jsonb_build_object('first_name', v.label, 'last_name', 'Test'),
  jsonb_build_object('club_id', (select id from test_club)),
  now() - v.created_ago::interval,
  case when v.signed_ago is null then null else now() - v.signed_ago::interval end
from (values
  -- Utilisé récemment.
  ('1a000000-0000-0000-0000-000000000001', 'Recent', '4 years', '2 months'),
  -- Dernière connexion il y a 3 ans moins 10 jours : à prévenir.
  ('1a000000-0000-0000-0000-000000000002', 'Bientot', '5 years', '3 years -10 days'),
  -- Connexion ancienne, mais session renouvelée automatiquement la semaine
  -- dernière : jamais considéré inactif.
  ('1a000000-0000-0000-0000-000000000003', 'Connecte', '5 years', '4 years'),
  -- Jamais connecté, créé il y a 4 ans : à prévenir.
  ('1a000000-0000-0000-0000-000000000004', 'Jamais', '4 years', null),
  -- Inactif depuis 4 ans : servira au cas « prévenu puis supprimé ».
  ('1a000000-0000-0000-0000-000000000005', 'Ancien', '6 years', '4 years')
) as v(id, label, created_ago, signed_ago);

update public.profiles set status = 'active'
where id::text like '1a000000-%';
update public.profiles set contact_email = 'bientot@club.test', contact_email_confirmed_at = now()
where id = '1a000000-0000-0000-0000-000000000002';

insert into auth.refresh_tokens (token, user_id, revoked, created_at, updated_at)
values ('test-refresh-inactive', '1a000000-0000-0000-0000-000000000003', false,
  now() - interval '7 days', now() - interval '7 days');

create function pg_temp.plan_for(p_id text) returns text
language sql as $function$
  select coalesce(
    (select account.action from public.internal_inactive_accounts(now()) account
     where account.profile_id = p_id::uuid),
    'rien')
$function$;

select is(private.inactive_account_delay(), interval '3 years', 'délai d''inactivité : 3 ans');
select is(private.inactive_account_notice(), interval '30 days', 'avertissement : un mois avant');
select is(
  (select count(*)::int from cron.job where jobname = 'inactive-accounts-cleanup' and active),
  1,
  'la vérification des comptes inactifs est planifiée chaque nuit'
);

select is(pg_temp.plan_for('1a000000-0000-0000-0000-000000000001'), 'rien',
  'un compte utilisé il y a deux mois n''est pas concerné');
select is(pg_temp.plan_for('1a000000-0000-0000-0000-000000000002'), 'notify',
  'à 10 jours des 3 ans, le compte est à prévenir');
select is(
  (select account.email from public.internal_inactive_accounts(now()) account
   where account.profile_id = '1a000000-0000-0000-0000-000000000002'),
  'bientot@club.test',
  'l''avertissement part à l''adresse du compte'
);
select is(
  (select account.deletion_on from public.internal_inactive_accounts(now()) account
   where account.profile_id = '1a000000-0000-0000-0000-000000000002'),
  ((now() + interval '30 days') at time zone 'Europe/Paris')::date,
  'la date de suppression annoncée laisse au moins un mois'
);
select is(pg_temp.plan_for('1a000000-0000-0000-0000-000000000003'), 'rien',
  'une session renouvelée automatiquement compte comme une utilisation');
select is(pg_temp.plan_for('1a000000-0000-0000-0000-000000000004'), 'notify',
  'un compte jamais utilisé depuis sa création il y a 4 ans est à prévenir');
select is(pg_temp.plan_for('1a000000-0000-0000-0000-000000000005'), 'notify',
  'même après 4 ans, on prévient d''abord : jamais de suppression sans avertissement');

-- Avertissement noté aujourd'hui : pas encore de suppression.
select public.internal_record_inactive_notice(
  '1a000000-0000-0000-0000-000000000005',
  now() - interval '4 years',
  false,
  now()
);
select is(pg_temp.plan_for('1a000000-0000-0000-0000-000000000005'), 'rien',
  'prévenu aujourd''hui : ni nouvel e-mail, ni suppression avant un mois');

-- Avertissement noté il y a 31 jours : suppression.
update private.inactive_account_notices set notified_at = now() - interval '31 days'
where profile_id = '1a000000-0000-0000-0000-000000000005';
select is(pg_temp.plan_for('1a000000-0000-0000-0000-000000000005'), 'delete',
  'prévenu depuis plus d''un mois et inactif depuis 3 ans : à supprimer');

-- La personne revient : l'avertissement est effacé.
update auth.users set last_sign_in_at = now()
where id = '1a000000-0000-0000-0000-000000000005';
select is(pg_temp.plan_for('1a000000-0000-0000-0000-000000000005'), 'rien',
  'une connexion après l''avertissement garde le compte');
select is(
  (select count(*)::int from private.inactive_account_notices
   where profile_id = '1a000000-0000-0000-0000-000000000005'),
  0,
  'et efface l''avertissement : une nouvelle période de 3 ans commence'
);

-- La tâche de nuit appelle la fonction d'e-mails avec le jeton interne.
select set_config('test.marker',
  (select coalesce(max(id), 0) from net.http_request_queue)::text, true);
select private.run_inactive_accounts_cleanup();
select is(
  (select count(*)::int from net.http_request_queue queue
   where queue.id > current_setting('test.marker')::bigint
     and queue.url like '%/functions/v1/account-email'
     and convert_from(queue.body, 'UTF8')::jsonb ->> 'action' = 'inactive-accounts'
     and queue.headers ->> 'x-push-token' = 'test-token'),
  1,
  'la tâche de nuit demande le traitement avec le jeton interne'
);

-- Personne d'autre que le serveur ne peut lire la liste ni noter un avertissement.
set local role authenticated;
select throws_ok(
  $$select * from public.internal_inactive_accounts(now())$$,
  '42501',
  'un membre connecté ne peut pas lire la liste des comptes inactifs'
);
select throws_ok(
  $$select public.internal_record_inactive_notice(
    '1a000000-0000-0000-0000-000000000002', now(), true, now())$$,
  '42501',
  'un membre connecté ne peut pas noter un avertissement'
);
reset role;

select * from finish();
rollback;
