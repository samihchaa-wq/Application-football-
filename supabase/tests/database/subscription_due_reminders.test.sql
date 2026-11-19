begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- E-mail « L'abonnement arrive à échéance » aux administrateurs à J-10, et
-- suspension le jour même de l'échéance (plus de délai de grâce).

select vault.create_secret('test-token', 'push_internal_token')
where not exists (
  select 1 from vault.secrets secret where secret.name = 'push_internal_token'
);

create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
insert into test_clubs
select 'soon', (public.create_club('Club Rappel Bientôt', 'RSOON', null, null, null, null)).id;
insert into test_clubs
select 'far', (public.create_club('Club Rappel Loin', 'RFAR', null, null, null, null)).id;
insert into test_clubs
select 'year', (public.create_club('Club Rappel Année', 'RYEAR', null, null, null, null)).id;
insert into test_clubs
select 'noadmin', (public.create_club('Club Rappel Sans Mail', 'RNOMAIL', null, null, null, null)).id;
insert into test_clubs
select 'off', (public.create_club('Club Rappel Suspendu', 'ROFF', null, null, null, null)).id;

-- Deux admins pour « soon » (une adresse confirmée, une en attente), un
-- membre simple (jamais destinataire), un admin inactif (jamais destinataire).
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select v.id::uuid, v.id || '@example.invalid',
  jsonb_build_object('first_name', 'Test', 'last_name', v.label),
  jsonb_build_object('club_id', (select id from test_clubs where label = v.club))
from (values
  ('5e000000-0000-0000-0000-000000000001', 'Alpha', 'soon'),
  ('5e000000-0000-0000-0000-000000000002', 'Bravo', 'soon'),
  ('5e000000-0000-0000-0000-000000000003', 'Membre', 'soon'),
  ('5e000000-0000-0000-0000-000000000004', 'Inactif', 'soon'),
  ('5e000000-0000-0000-0000-000000000005', 'Annee', 'year'),
  ('5e000000-0000-0000-0000-000000000006', 'Sansmail', 'noadmin'),
  ('5e000000-0000-0000-0000-000000000007', 'Suspendu', 'off'),
  ('5e000000-0000-0000-0000-000000000008', 'Loin', 'far')
) as v(id, label, club);

update public.profiles set status = 'active', role = 'admin'
where id::text like '5e000000-%' and id <> '5e000000-0000-0000-0000-000000000003';
update public.profiles set status = 'active'
where id = '5e000000-0000-0000-0000-000000000003';
update public.profiles set status = 'archived'
where id = '5e000000-0000-0000-0000-000000000004';

update public.profiles set contact_email = 'admin1@club.test', contact_email_confirmed_at = now()
where id = '5e000000-0000-0000-0000-000000000001';
update public.profiles set pending_contact_email = 'admin2@club.test'
where id = '5e000000-0000-0000-0000-000000000002';
update public.profiles set contact_email = 'membre@club.test', contact_email_confirmed_at = now()
where id = '5e000000-0000-0000-0000-000000000003';
update public.profiles set contact_email = 'inactif@club.test', contact_email_confirmed_at = now()
where id = '5e000000-0000-0000-0000-000000000004';
update public.profiles set contact_email = 'annee@club.test', contact_email_confirmed_at = now()
where id = '5e000000-0000-0000-0000-000000000005';
update public.profiles set contact_email = 'suspendu@club.test', contact_email_confirmed_at = now()
where id = '5e000000-0000-0000-0000-000000000007';
update public.profiles set contact_email = 'loin@club.test', contact_email_confirmed_at = now()
where id = '5e000000-0000-0000-0000-000000000008';
-- « noadmin » : admin sans aucune adresse.

-- Échéances : essai fini dans 8 jours, dans 20 jours ; année payée finissant
-- dans 3 jours ; club suspendu à la main dont l'essai finit dans 5 jours.
update public.club_subscriptions set trial_ends_at = now() + interval '8 days'
where club_id = (select id from test_clubs where label = 'soon');
update public.club_subscriptions set trial_ends_at = now() + interval '20 days'
where club_id = (select id from test_clubs where label = 'far');
update public.club_subscriptions
set status = 'active', current_period_end = now() + interval '3 days'
where club_id = (select id from test_clubs where label = 'year');
update public.club_subscriptions set trial_ends_at = now() + interval '6 days'
where club_id = (select id from test_clubs where label = 'noadmin');
update public.club_subscriptions set trial_ends_at = now() + interval '5 days'
where club_id = (select id from test_clubs where label = 'off');
update public.clubs set status = 'suspended'
where id = (select id from test_clubs where label = 'off');

-- Les autres clubs de la base ne doivent pas fausser les comptes.
create temporary table other_due on commit drop as
select club.id from public.clubs club
where club.id not in (select id from test_clubs);
update public.club_subscriptions set status = 'active', current_period_end = now() + interval '5 years'
where club_id in (select id from other_due);

select set_config('test.marker',
  (select coalesce(max(id), 0) from net.http_request_queue)::text, true);

create function pg_temp.reminders_for(p_label text) returns jsonb
language sql as $function$
  select coalesce(jsonb_agg(convert_from(queue.body, 'UTF8')::jsonb order by queue.id), '[]')
  from net.http_request_queue queue
  where queue.id > current_setting('test.marker')::bigint
    and queue.url like '%/functions/v1/account-email'
    and convert_from(queue.body, 'UTF8')::jsonb ->> 'club_name'
      = (select name from public.clubs where id = (select id from test_clubs where label = p_label));
$function$;

select is(
  (select count(*)::int from cron.job where jobname = 'subscription-due-reminders' and active),
  1,
  'le rappel d''échéance est planifié chaque matin'
);
select is(private.unpaid_grace_period(), interval '0 days', 'plus de délai de grâce');
select is(private.subscription_reminder_lead(), interval '10 days', 'le rappel part 10 jours avant');

select is(private.send_subscription_due_reminders(now()), 3,
  'trois clubs actifs ont une échéance dans les 10 jours (dont un sans adresse)');

select is(jsonb_array_length(pg_temp.reminders_for('soon')), 1,
  'un seul e-mail pour le club dont l''essai finit dans 8 jours');
select is(pg_temp.reminders_for('soon') -> 0 -> 'recipients',
  '["admin1@club.test", "admin2@club.test"]'::jsonb,
  'destinataires : les admins actifs, adresse confirmée ou saisie à la création ; ni membre ni admin archivé');
select is(pg_temp.reminders_for('soon') -> 0 ->> 'action', 'subscription-reminder',
  'l''e-mail est demandé à la fonction d''e-mails de compte');
select is((pg_temp.reminders_for('soon') -> 0 ->> 'trial')::boolean, true,
  'il précise qu''il s''agit d''une fin d''essai');
select is((pg_temp.reminders_for('soon') -> 0 ->> 'amount_cents')::int, 7900,
  'il donne le prix du forfait');
select is(pg_temp.reminders_for('soon') -> 0 ->> 'due_on',
  to_char((now() + interval '8 days') at time zone 'Europe/Paris', 'DD/MM/YYYY'),
  'il donne la date d''échéance, heure de Paris');
select is(
  (select count(*)::int from net.http_request_queue queue
   where queue.id > current_setting('test.marker')::bigint
     and queue.url like '%/functions/v1/account-email'
     and queue.headers ->> 'x-push-token' = 'test-token'),
  2,
  'chaque demande porte le jeton interne'
);

select is((pg_temp.reminders_for('year') -> 0 ->> 'trial')::boolean, false,
  'fin d''année payée : rappel de renouvellement');
select is(jsonb_array_length(pg_temp.reminders_for('far')), 0,
  'échéance dans 20 jours : pas encore de rappel');
select is(jsonb_array_length(pg_temp.reminders_for('off')), 0,
  'club suspendu : pas de rappel');
select is(jsonb_array_length(pg_temp.reminders_for('noadmin')), 0,
  'admin sans adresse : aucun e-mail envoyé');
select is(
  (select recipients from private.club_subscription_reminders
   where club_id = (select id from test_clubs where label = 'noadmin')),
  0,
  'le rappel sans destinataire est quand même noté, pour ne pas réessayer chaque jour'
);

-- Le lendemain : aucun doublon.
select is(private.send_subscription_due_reminders(now() + interval '1 day'), 0,
  'le lendemain, aucun club n''est prévenu une deuxième fois');
select is(jsonb_array_length(pg_temp.reminders_for('soon')), 1,
  'toujours un seul e-mail pour la même échéance');

-- 12 jours plus tard, « far » entre dans la fenêtre.
select is(private.send_subscription_due_reminders(now() + interval '12 days'), 1,
  'le club suivant est prévenu quand il arrive à J-10');
select is(jsonb_array_length(pg_temp.reminders_for('far')), 1,
  'un e-mail pour le club dont l''échéance arrive');

-- Après un paiement, la nouvelle échéance (un an plus tard) aura son propre rappel.
update public.club_subscriptions
set status = 'active', current_period_end = now() + interval '1 year 8 days'
where club_id = (select id from test_clubs where label = 'soon');
select is(private.send_subscription_due_reminders(now() + interval '1 year'), 1,
  'un an plus tard, seule la nouvelle échéance du club qui a payé est rappelée');
select is(jsonb_array_length(pg_temp.reminders_for('soon')), 2,
  'deuxième e-mail pour la nouvelle échéance seulement');

-- Envoi non configuré : rien n'est noté, le rappel partira plus tard.
delete from private.club_subscription_reminders;
delete from vault.secrets where name = 'push_internal_token';
select is(private.send_subscription_due_reminders(now()), 0,
  'sans jeton interne, aucun rappel n''est noté comme envoyé');
select is((select count(*)::int from private.club_subscription_reminders), 0,
  'les rappels restent à envoyer');

-- Suspension le jour de l'échéance.
-- « year » (échéance J+3) et « noadmin » (J+6) n'ont pas payé ; « soon » a payé.
select is(private.suspend_unpaid_clubs(now() + interval '8 days' + interval '1 minute'), 2,
  'à l''échéance, sans paiement, les clubs sont suspendus le jour même');
select is(
  (select status from public.clubs where id = (select id from test_clubs where label = 'soon')),
  'active',
  'le club qui a payé garde l''accès'
);
select is(
  (select status from public.clubs where id = (select id from test_clubs where label = 'far')),
  'active',
  'un club dont l''échéance n''est pas passée garde l''accès'
);

-- Personne ne peut déclencher les rappels depuis l'appli.
select ok(
  not has_function_privilege('authenticated', 'private.send_subscription_due_reminders(timestamptz)', 'execute')
  and not has_function_privilege('anon', 'private.send_subscription_due_reminders(timestamptz)', 'execute'),
  'les rappels ne sont pas déclenchables par un compte'
);
select ok(
  not has_table_privilege('authenticated', 'private.club_subscription_reminders', 'select'),
  'le journal des rappels n''est pas lisible depuis l''appli'
);

select * from finish();
rollback;
