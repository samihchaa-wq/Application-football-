-- Abonnement des clubs et console de l'éditeur de l'application.
--
-- Modèle : 10 € par joueur et par an (montant réglable par club), avec un
-- forfait fixe facultatif pour un tarif mixte. Chaque nouveau club démarre
-- avec 30 jours d'essai gratuit.
--
-- Rien n'est bloqué automatiquement : à la fin de l'essai sans abonnement,
-- l'administrateur du club voit un rappel. Seul l'éditeur peut suspendre un
-- club, et un club suspendu voit un écran d'explication au lieu de l'appli.
--
-- Le paiement en ligne (Stripe) n'est pas encore branché : les champs
-- stripe_* sont prêts à le recevoir.

-- ---------------------------------------------------------------------------
-- 1. Abonnement d'un club
-- ---------------------------------------------------------------------------

create table public.club_subscriptions (
  club_id uuid primary key references public.clubs(id) on delete cascade,
  status text not null default 'trialing'
    constraint club_subscriptions_status_check
      check (status in ('trialing', 'active', 'past_due', 'canceled')),
  trial_ends_at timestamptz not null default (now() + interval '30 days'),
  current_period_end timestamptz,
  price_per_player_cents integer not null default 1000
    constraint club_subscriptions_price_check check (price_per_player_cents between 0 and 100000),
  base_price_cents integer not null default 0
    constraint club_subscriptions_base_price_check check (base_price_cents between 0 and 1000000),
  stripe_customer_id text,
  stripe_subscription_id text,
  notes text,
  updated_at timestamptz not null default now()
);

comment on table public.club_subscriptions is
  'Abonnement annuel d''un club : essai, tarif par joueur, état du paiement.';

alter table public.club_subscriptions enable row level security;
revoke all on public.club_subscriptions from public, anon, authenticated;
grant select on public.club_subscriptions to authenticated;
grant all on public.club_subscriptions to service_role;
grant select, insert, update, delete on public.club_subscriptions to club_scope;

-- Même cloisonnement que les autres tables de club, et lecture réservée aux
-- administrateurs du club.
create policy club_isolation on public.club_subscriptions
  as restrictive for all to public
  using (club_id = (select private.current_club_id()))
  with check (club_id = (select private.current_club_id()));
create policy active_authenticated_profile_only on public.club_subscriptions
  as restrictive for all to authenticated
  using ((select private.is_active_profile()))
  with check ((select private.is_active_profile()));
create policy club_scope_access on public.club_subscriptions
  for all to club_scope using (true) with check (true);
create policy club_subscriptions_admin_read on public.club_subscriptions
  for select to authenticated
  using ((select private.is_admin()));

-- Les clubs déjà créés démarrent leur essai maintenant.
insert into public.club_subscriptions (club_id)
select club.id from public.clubs club
on conflict (club_id) do nothing;

-- Tout nouveau club reçoit son essai gratuit à la création.
create function private.start_club_trial() returns trigger
language plpgsql security definer
set search_path to ''
as $$
begin
  perform set_config('app.club_id', new.id::text, true);
  insert into public.club_subscriptions (club_id) values (new.id)
  on conflict (club_id) do nothing;
  return new;
end;
$$;

alter function private.start_club_trial() owner to club_scope;
revoke all on function private.start_club_trial() from public;

create trigger clubs_start_trial
  after insert on public.clubs
  for each row execute function private.start_club_trial();

-- ---------------------------------------------------------------------------
-- 2. Joueurs facturés
-- ---------------------------------------------------------------------------

-- Joueurs facturés = joueurs actifs de l'effectif de la saison ouverte, hors
-- invités ponctuels. Un même joueur n'est compté qu'une fois.
create function private.club_billable_players() returns integer
language sql stable security definer
set search_path to ''
as $$
  select count(distinct season_player.player_id)::integer
  from public.season_players season_player
  join public.seasons season on season.id = season_player.season_id
  where season.status = 'open'
    and season_player.is_active;
$$;

alter function private.club_billable_players() owner to club_scope;
revoke all on function private.club_billable_players() from public;

-- État de l'abonnement tel que l'administrateur du club le voit.
create function private.club_subscription_summary() returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_sub public.club_subscriptions;
  v_players integer := private.club_billable_players();
  v_state text;
begin
  select * into v_sub
  from public.club_subscriptions sub
  where sub.club_id = private.current_club_id();

  if not found then
    return null;
  end if;

  -- trial : essai en cours ; trial_ending : moins de 7 jours d'essai ;
  -- to_pay : essai fini sans abonnement ; active ; past_due : paiement en
  -- échec ; canceled : abonnement arrêté.
  v_state := case
    when v_sub.status = 'trialing' and v_sub.trial_ends_at > now() + interval '7 days' then 'trial'
    when v_sub.status = 'trialing' and v_sub.trial_ends_at > now() then 'trial_ending'
    when v_sub.status = 'trialing' then 'to_pay'
    else v_sub.status
  end;

  return jsonb_build_object(
    'state', v_state,
    'status', v_sub.status,
    'trial_ends_at', v_sub.trial_ends_at,
    'trial_days_left', greatest(0, ceil(extract(epoch from v_sub.trial_ends_at - now()) / 86400))::integer,
    'current_period_end', v_sub.current_period_end,
    'billable_players', v_players,
    'price_per_player_cents', v_sub.price_per_player_cents,
    'base_price_cents', v_sub.base_price_cents,
    'yearly_amount_cents', v_sub.base_price_cents + v_players * v_sub.price_per_player_cents
  );
end;
$$;

alter function private.club_subscription_summary() owner to club_scope;
revoke all on function private.club_subscription_summary() from public;

create function public.admin_get_club_subscription() returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
begin
  if not (select private.is_admin()) then
    raise exception 'Réservé aux administrateurs du club.' using errcode = '42501';
  end if;
  return private.club_subscription_summary();
end;
$$;

alter function public.admin_get_club_subscription() owner to club_scope;
revoke all on function public.admin_get_club_subscription() from public, anon;
grant execute on function public.admin_get_club_subscription() to authenticated;

-- ---------------------------------------------------------------------------
-- 3. Club suspendu : plus d'accès aux données
-- ---------------------------------------------------------------------------

-- Un membre d'un club suspendu n'est plus considéré comme actif : toutes les
-- règles d'accès qui exigent un profil actif lui ferment les données.
create or replace function private.is_active_profile() returns boolean
language sql stable security definer
set search_path to ''
as $$
  select exists (
    select 1
    from public.profiles profile
    join public.clubs club on club.id = profile.club_id
    where profile.id = (select private.uid())
      and profile.status = 'active'
      and club.status = 'active'
  );
$$;

-- Ce que l'appli doit afficher au membre connecté : son club est-il ouvert ?
-- Lisible même quand le club est suspendu, pour expliquer pourquoi.
create function public.get_my_club_access() returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_status text;
begin
  if private.uid() is null then
    return jsonb_build_object('status', 'signed_out');
  end if;
  select club.status into v_status
  from public.profiles profile
  join public.clubs club on club.id = profile.club_id
  where profile.id = private.uid();
  return jsonb_build_object('status', coalesce(v_status, 'unknown'));
end;
$$;

-- Appartient à postgres : doit lire l'état du club même suspendu, quand les
-- règles d'accès du membre ne lui laissent plus rien voir.
revoke all on function public.get_my_club_access() from public, anon;
grant execute on function public.get_my_club_access() to authenticated;

-- ---------------------------------------------------------------------------
-- 4. Console de l'éditeur
-- ---------------------------------------------------------------------------

-- Comptes autorisés à voir et gérer tous les clubs (l'éditeur de
-- l'application). Rempli à la main sur la base, jamais par l'appli.
create table private.platform_operators (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table private.platform_operators enable row level security;
revoke all on private.platform_operators from public, anon, authenticated;
create policy club_scope_access on private.platform_operators
  for all to club_scope using (true) with check (true);
grant select on private.platform_operators to club_scope;

create function private.is_platform_operator() returns boolean
language sql stable security definer
set search_path to ''
as $$
  select exists (
    select 1 from private.platform_operators operator
    where operator.user_id = (select private.uid())
  );
$$;

revoke all on function private.is_platform_operator() from public;
grant execute on function private.is_platform_operator() to authenticated, club_scope;

-- Vue d'ensemble de tous les clubs : taille, abonnement, activité.
-- Appartient à postgres : c'est la seule fonction qui lit au-delà d'un club,
-- et elle ne s'ouvre qu'à l'éditeur.
create function public.platform_list_clubs() returns table (
  id uuid,
  name text,
  status text,
  created_at timestamptz,
  members bigint,
  billable_players bigint,
  subscription_status text,
  trial_ends_at timestamptz,
  current_period_end timestamptz,
  yearly_amount_cents bigint,
  storage_used_bytes bigint,
  storage_quota_bytes bigint,
  last_activity_at timestamptz
)
language plpgsql stable security definer
set search_path to ''
as $$
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;

  return query
  with members as (
    select profile.club_id, count(*) as members, max(profile.updated_at) as last_profile_at
    from public.profiles profile
    where profile.status = 'active'
    group by profile.club_id
  ),
  players as (
    select season_player.club_id, count(distinct season_player.player_id) as players
    from public.season_players season_player
    join public.seasons season on season.id = season_player.season_id
    where season.status = 'open' and season_player.is_active
    group by season_player.club_id
  ),
  files as (
    select profile.club_id,
           sum(coalesce((object.metadata ->> 'size')::bigint, 0))::bigint as used
    from storage.objects object
    join public.profiles profile on profile.id::text = object.owner_id
    where object.bucket_id in ('profile-photos', 'badge-images')
    group by profile.club_id
  ),
  activity as (
    select match.club_id, max(match.updated_at) as last_match_at
    from public.matches match
    group by match.club_id
  )
  select
    club.id, club.name, club.status, club.created_at,
    coalesce(members.members, 0),
    coalesce(players.players, 0),
    sub.status, sub.trial_ends_at, sub.current_period_end,
    (coalesce(sub.base_price_cents, 0)
      + coalesce(players.players, 0) * coalesce(sub.price_per_player_cents, 0))::bigint,
    coalesce(files.used, 0),
    club.storage_quota_bytes,
    greatest(members.last_profile_at, activity.last_match_at)
  from public.clubs club
  left join public.club_subscriptions sub on sub.club_id = club.id
  left join members on members.club_id = club.id
  left join players on players.club_id = club.id
  left join files on files.club_id = club.id
  left join activity on activity.club_id = club.id
  order by club.created_at desc;
end;
$$;

revoke all on function public.platform_list_clubs() from public, anon;
grant execute on function public.platform_list_clubs() to authenticated;

-- Actions de l'éditeur sur un club : suspendre ou rouvrir, prolonger l'essai,
-- noter un paiement reçu hors ligne (virement, chèque), ajuster le tarif ou
-- le quota de fichiers.
create function public.platform_update_club(
  p_club_id uuid,
  p_status text default null,
  p_subscription_status text default null,
  p_trial_ends_at timestamptz default null,
  p_current_period_end timestamptz default null,
  p_price_per_player_cents integer default null,
  p_base_price_cents integer default null,
  p_storage_quota_bytes bigint default null,
  p_notes text default null
) returns void
language plpgsql security definer
set search_path to ''
as $$
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;
  if not exists (select 1 from public.clubs where id = p_club_id) then
    raise exception 'Club inconnu.' using errcode = 'P0002';
  end if;

  update public.clubs
  set status = coalesce(p_status, status),
      storage_quota_bytes = coalesce(p_storage_quota_bytes, storage_quota_bytes)
  where id = p_club_id;

  update public.club_subscriptions
  set status = coalesce(p_subscription_status, status),
      trial_ends_at = coalesce(p_trial_ends_at, trial_ends_at),
      current_period_end = coalesce(p_current_period_end, current_period_end),
      price_per_player_cents = coalesce(p_price_per_player_cents, price_per_player_cents),
      base_price_cents = coalesce(p_base_price_cents, base_price_cents),
      notes = coalesce(p_notes, notes),
      updated_at = now()
  where club_id = p_club_id;
end;
$$;

revoke all on function public.platform_update_club(uuid, text, text, timestamptz, timestamptz, integer, integer, bigint, text)
  from public, anon;
grant execute on function public.platform_update_club(uuid, text, text, timestamptz, timestamptz, integer, integer, bigint, text)
  to authenticated;

-- Santé de la plate-forme, pour la supervision : tâches planifiées en échec
-- et notifications en échec sur la dernière heure.
create function public.platform_health() returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
begin
  if not private.is_platform_operator() then
    raise exception 'Réservé à l''éditeur de l''application.' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'checked_at', now(),
    'clubs', (select count(*) from public.clubs),
    'active_members', (select count(*) from public.profiles where status = 'active'),
    'failed_jobs_last_hour', (
      select count(*) from cron.job_run_details run
      where run.status = 'failed' and run.start_time > now() - interval '1 hour'
    ),
    'push_sent_last_hour', (
      select count(*) from public.push_delivery_log log
      where log.success and log.created_at > now() - interval '1 hour'
    ),
    'push_failed_last_hour', (
      select count(*) from public.push_delivery_log log
      where not log.success and log.created_at > now() - interval '1 hour'
    ),
    'database_bytes', pg_database_size(current_database()),
    'storage_bytes', (
      select coalesce(sum(coalesce((object.metadata ->> 'size')::bigint, 0)), 0)
      from storage.objects object
    )
  );
end;
$$;

revoke all on function public.platform_health() from public, anon;
grant execute on function public.platform_health() to authenticated;
