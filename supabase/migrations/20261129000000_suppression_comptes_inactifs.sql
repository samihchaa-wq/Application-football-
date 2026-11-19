-- Comptes inactifs : avertissement un mois avant, puis suppression après
-- 3 ans sans aucune utilisation.
--
-- Promesse des textes légaux (version 2026-11-19) : « un compte sans aucune
-- connexion pendant 3 ans est supprimé ; tu es prévenu au moins un mois avant
-- par e-mail si tu en as renseigné un ; se connecter suffit à garder ton
-- compte ».
--
-- Répartition du travail :
-- - la base dit chaque nuit quels comptes prévenir et lesquels supprimer
--   (public.internal_inactive_accounts) et garde la trace des avertissements ;
-- - la fonction serveur account-email envoie les e-mails, note chaque
--   avertissement seulement une fois l'e-mail parti, puis supprime les comptes
--   arrivés au bout du délai, avec les mêmes étapes qu'une suppression
--   demandée par le membre lui-même.
--
-- « Utilisation » : la dernière ouverture de session, mais aussi le dernier
-- renouvellement automatique de session. Quelqu'un qui reste connecté des
-- années sans retaper son mot de passe n'est donc jamais considéré inactif.

-- ---------------------------------------------------------------------------
-- 1. Délais (un seul endroit à changer)
-- ---------------------------------------------------------------------------

create function private.inactive_account_delay() returns interval
language sql immutable
set search_path to ''
as $$ select interval '3 years' $$;

create function private.inactive_account_notice() returns interval
language sql immutable
set search_path to ''
as $$ select interval '30 days' $$;

revoke all on function private.inactive_account_delay() from public, anon, authenticated;
revoke all on function private.inactive_account_notice() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2. Dernière utilisation de chaque compte
-- ---------------------------------------------------------------------------

create function private.account_last_activity()
returns table (profile_id uuid, last_activity_at timestamptz)
language sql stable
set search_path to ''
as $$
  select auth_user.id,
    greatest(
      auth_user.created_at,
      auth_user.last_sign_in_at,
      (select max(session.updated_at) from auth.sessions session
        where session.user_id = auth_user.id),
      (select max(token.updated_at) from auth.refresh_tokens token
        where token.user_id = auth_user.id::text)
    )
  from auth.users auth_user
$$;

revoke all on function private.account_last_activity() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. Avertissements envoyés
-- ---------------------------------------------------------------------------

-- Un avertissement par compte et par période d'inactivité. Si la personne se
-- reconnecte, l'avertissement est effacé : une nouvelle période commence.
create table private.inactive_account_notices (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  club_id uuid references public.clubs(id) on delete cascade,
  -- Dernière utilisation connue au moment de l'avertissement.
  activity_at timestamptz not null,
  notified_at timestamptz not null default now(),
  -- false : aucune adresse e-mail, personne n'a pu être prévenu.
  emailed boolean not null
);

comment on table private.inactive_account_notices is
  'Avertissements « ton compte va être supprimé faute d''utilisation », un par compte et par période d''inactivité.';

create index inactive_account_notices_club_id_idx
  on private.inactive_account_notices (club_id);

alter table private.inactive_account_notices enable row level security;
revoke all on private.inactive_account_notices from public, anon, authenticated;
-- Même cloisonnement que les autres tables d'un club. Seules les fonctions
-- ci-dessous (propriétaire postgres) y écrivent.
create policy club_isolation on private.inactive_account_notices
  as restrictive for all to public
  using (club_id = (select private.current_club_id()))
  with check (club_id = (select private.current_club_id()));
create policy club_scope_access on private.inactive_account_notices
  for all to club_scope using (true) with check (true);

-- ---------------------------------------------------------------------------
-- 4. Liste du jour
-- ---------------------------------------------------------------------------

-- Comptes à prévenir (action = 'notify') et à supprimer (action = 'delete').
-- Jamais concernés : le compte technique d'import historique et les comptes
-- de l'éditeur. Appelée uniquement par la fonction serveur account-email,
-- avec la clé de service.
create function public.internal_inactive_accounts(p_now timestamptz default now())
returns table (
  profile_id uuid,
  club_id uuid,
  action text,
  email text,
  first_name text,
  last_activity_at timestamptz,
  deletion_on date
)
language plpgsql security definer
set search_path to ''
as $$
begin
  -- La personne est revenue depuis l'avertissement : on repart de zéro.
  delete from private.inactive_account_notices notice
  using private.account_last_activity() activity
  where activity.profile_id = notice.profile_id
    and activity.last_activity_at > notice.activity_at;

  return query
  select profile.id,
    profile.club_id,
    case when notice.profile_id is null then 'notify' else 'delete' end,
    coalesce(profile.contact_email, profile.pending_contact_email),
    profile.first_name,
    activity.last_activity_at,
    (greatest(
      activity.last_activity_at + private.inactive_account_delay(),
      coalesce(notice.notified_at, p_now) + private.inactive_account_notice()
    ) at time zone 'Europe/Paris')::date
  from public.profiles profile
  join private.account_last_activity() activity on activity.profile_id = profile.id
  left join private.inactive_account_notices notice on notice.profile_id = profile.id
  where profile.id <> '00000000-0000-0000-0000-000000000001'
    and not exists (
      select 1 from private.platform_operators operator
      where operator.user_id = profile.id
    )
    and (
      -- À prévenir : il reste un mois ou moins avant les 3 ans.
      (notice.profile_id is null
        and activity.last_activity_at
          <= p_now - private.inactive_account_delay() + private.inactive_account_notice())
      or
      -- À supprimer : 3 ans passés, et prévenu depuis au moins un mois.
      (notice.profile_id is not null
        and activity.last_activity_at <= p_now - private.inactive_account_delay()
        and notice.notified_at <= p_now - private.inactive_account_notice())
    )
  order by activity.last_activity_at;
end;
$$;

revoke all on function public.internal_inactive_accounts(timestamptz) from public, anon, authenticated;
grant execute on function public.internal_inactive_accounts(timestamptz) to service_role;

-- Noter qu'un compte a été prévenu. Appelée après l'envoi réussi de l'e-mail
-- (ou tout de suite s'il n'y a pas d'adresse) : un e-mail qui échoue n'est pas
-- noté et repart la nuit suivante, donc personne n'est supprimé sans
-- l'avertissement promis.
create function public.internal_record_inactive_notice(
  p_profile_id uuid,
  p_activity_at timestamptz,
  p_emailed boolean,
  p_now timestamptz default now()
) returns void
language sql security definer
set search_path to ''
as $$
  insert into private.inactive_account_notices
    (profile_id, club_id, activity_at, notified_at, emailed)
  select profile.id, profile.club_id, p_activity_at, p_now, p_emailed
  from public.profiles profile
  where profile.id = p_profile_id
  on conflict (profile_id) do nothing;
$$;

revoke all on function public.internal_record_inactive_notice(uuid, timestamptz, boolean, timestamptz)
  from public, anon, authenticated;
grant execute on function public.internal_record_inactive_notice(uuid, timestamptz, boolean, timestamptz)
  to service_role;

-- ---------------------------------------------------------------------------
-- 5. Tâche de nuit
-- ---------------------------------------------------------------------------

create function private.run_inactive_accounts_cleanup() returns void
language plpgsql
set search_path to ''
as $$
declare
  v_token text;
begin
  select secret.decrypted_secret into v_token
  from private.vault_secrets() secret
  where secret.name = 'push_internal_token';
  -- Jeton interne absent : rien n'est fait (ni avertissement, ni suppression).
  if v_token is null then
    return;
  end if;

  perform private.http_post(
    url := private.edge_function_url('account-email'),
    body := jsonb_build_object('action', 'inactive-accounts'),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-push-token', v_token
    ),
    timeout_milliseconds := 60000
  );
end;
$$;

revoke all on function private.run_inactive_accounts_cleanup() from public, anon, authenticated;

-- Chaque nuit à 3 h 41 UTC (4 h 41 ou 5 h 41 à Paris).
select cron.schedule(
  'inactive-accounts-cleanup',
  '41 3 * * *',
  $cron$select private.run_inactive_accounts_cleanup();$cron$
);
