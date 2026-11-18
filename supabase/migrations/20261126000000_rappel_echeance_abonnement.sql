-- Échéance d'abonnement : e-mail aux administrateurs à J-10, blocage le jour
-- même.
--
-- Décision de l'éditeur (18/11/2026) : plus de délai de grâce de 15 jours
-- après l'échéance. À la place, les administrateurs du club reçoivent un
-- e-mail « L'abonnement arrive à échéance » 10 jours avant. Sans paiement
-- noté, le club est suspendu à l'échéance (tâche de nuit existante). Les
-- données restent conservées et un paiement rouvre aussitôt le club.

-- ---------------------------------------------------------------------------
-- 1. Plus de délai de grâce
-- ---------------------------------------------------------------------------

-- Même signature que dans 20261124020000 : toutes les fonctions qui
-- calculent la date de suspension (tâche de nuit, résumé de l'administrateur,
-- fiche de facturation de l'éditeur) suivent automatiquement.
create or replace function private.unpaid_grace_period() returns interval
language sql immutable
set search_path to ''
as $$ select interval '0 days' $$;

-- ---------------------------------------------------------------------------
-- 2. Rappel par e-mail à J-10
-- ---------------------------------------------------------------------------

-- Délai entre l'e-mail de rappel et l'échéance. Un seul endroit à changer.
create function private.subscription_reminder_lead() returns interval
language sql immutable
set search_path to ''
as $$ select interval '10 days' $$;

revoke all on function private.subscription_reminder_lead() from public, anon, authenticated;

-- Un rappel par club et par échéance : jamais deux e-mails pour la même date,
-- et une nouvelle échéance (après un paiement) aura son propre rappel.
create table private.club_subscription_reminders (
  club_id uuid not null references public.clubs(id) on delete cascade,
  due_at timestamptz not null,
  recipients integer not null check (recipients >= 0),
  sent_at timestamptz not null default now(),
  primary key (club_id, due_at)
);

comment on table private.club_subscription_reminders is
  'Rappels « l''abonnement arrive à échéance » déjà envoyés aux administrateurs, un par club et par échéance.';

alter table private.club_subscription_reminders enable row level security;
revoke all on private.club_subscription_reminders from public, anon, authenticated;
-- Même cloisonnement que les autres tables d'un club. Seule la tâche
-- planifiée (rôle postgres, propriétaire) y écrit.
create policy club_isolation on private.club_subscription_reminders
  as restrictive for all to public
  using (club_id = (select private.current_club_id()))
  with check (club_id = (select private.current_club_id()));
create policy club_scope_access on private.club_subscription_reminders
  for all to club_scope using (true) with check (true);

-- Adresses des administrateurs actifs d'un club : l'adresse confirmée, sinon
-- celle saisie à la création du club et pas encore confirmée.
create function private.club_admin_billing_emails(p_club_id uuid)
returns text[]
language sql stable
set search_path to ''
as $$
  select coalesce(array_agg(distinct email order by email), '{}')
  from (
    select coalesce(profile.contact_email, profile.pending_contact_email) as email
    from public.profiles profile
    where profile.club_id = p_club_id
      and profile.role = 'admin'
      and profile.status = 'active'
  ) admins
  where email is not null
$$;

revoke all on function private.club_admin_billing_emails(uuid) from public, anon, authenticated;

-- Lancée chaque matin par la tâche planifiée (rôle postgres), jamais par un
-- compte. Renvoie le nombre de clubs prévenus.
create function private.send_subscription_due_reminders(p_now timestamptz default now())
returns integer
language plpgsql
set search_path to ''
as $$
declare
  v_token text;
  v_club record;
  v_emails text[];
  v_count integer := 0;
begin
  select secret.decrypted_secret into v_token
  from private.vault_secrets() secret
  where secret.name = 'push_internal_token';
  -- Envoi non configuré : rien n'est noté, le rappel partira dès qu'il le sera.
  if v_token is null then
    return 0;
  end if;

  for v_club in
    select club.id, club.name, sub.status, sub.base_price_cents,
      private.club_suspension_due_at(
        sub.status, sub.trial_ends_at, sub.current_period_end) as due_at
    from public.clubs club
    join public.club_subscriptions sub on sub.club_id = club.id
    where club.status = 'active'
  loop
    continue when v_club.due_at is null
      or v_club.due_at <= p_now
      or v_club.due_at > p_now + private.subscription_reminder_lead();
    continue when exists (
      select 1 from private.club_subscription_reminders reminder
      where reminder.club_id = v_club.id and reminder.due_at = v_club.due_at
    );

    v_emails := private.club_admin_billing_emails(v_club.id);
    insert into private.club_subscription_reminders (club_id, due_at, recipients, sent_at)
    values (v_club.id, v_club.due_at, coalesce(array_length(v_emails, 1), 0), p_now);

    if coalesce(array_length(v_emails, 1), 0) > 0 then
      perform private.http_post(
        url := private.edge_function_url('account-email'),
        body := jsonb_build_object(
          'action', 'subscription-reminder',
          'recipients', to_jsonb(v_emails),
          'club_name', v_club.name,
          'trial', v_club.status = 'trialing',
          'due_on', to_char(v_club.due_at at time zone 'Europe/Paris', 'DD/MM/YYYY'),
          'amount_cents', v_club.base_price_cents
        ),
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'x-push-token', v_token,
          'x-club-id', v_club.id::text
        ),
        timeout_milliseconds := 10000
      );
    end if;
    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

revoke all on function private.send_subscription_due_reminders(timestamptz) from public, anon, authenticated;

-- Chaque matin à 8 h 17 UTC (9 h 17 ou 10 h 17 à Paris).
select cron.schedule(
  'subscription-due-reminders',
  '17 8 * * *',
  $cron$select private.send_subscription_due_reminders(now());$cron$
);
