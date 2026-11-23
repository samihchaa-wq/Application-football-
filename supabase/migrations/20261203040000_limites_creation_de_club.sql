-- Limites anti-abus pour la création de club. La création RESTE OUVERTE à tous
-- (décision du propriétaire, 23/11/2026) : on borne l'abus, on ne ferme rien.
--
-- Pourquoi : chaque club créé ajoute du travail planifié à toute la
-- plate-forme. Aujourd'hui seul un quota par adresse réseau existe (5/h, 15/j).
--
-- Ce que fait la migration (aucune création de club n'est modifiée ici) :
--   * private.club_creation_log : journal de chaque demande (autorisée ou
--     refusée), avec adresse réseau hachée et e-mail haché. Aucune donnée
--     lisible : pas d'e-mail en clair, pas d'adresse IP ;
--   * private.disposable_email_domains : liste de domaines d'e-mail jetables,
--     modifiable par l'éditeur (insertion SQL), amorcée avec quelques noms ;
--   * public.check_club_creation_limits(origine_hachée, e-mail) : renvoie
--     { allowed, reason } et journalise. Règles :
--       - e-mail jetable : refus (reason = 'disposable_email') ;
--       - délai de 60 s entre deux demandes depuis la même adresse
--         ('too_soon') ;
--       - 3 créations par jour et par adresse réseau ('origin_daily') ;
--       - 2 créations par jour et par e-mail normalisé (points et +étiquette
--         ignorés pour gmail) ('email_daily') ;
--       - 20 créations par heure pour toute la plate-forme, garde-fou contre
--         une attaque répartie ('global_hourly').
--     Seules les demandes autorisées comptent dans les plafonds ; les refus
--     sont journalisés pour l'éditeur.
--   * réservée à service_role (fonctions Edge). Le câblage dans claim-club et
--     register-account n'est PAS fait ici : il demande un redéploiement des
--     fonctions Edge, donc l'accord du propriétaire.
--
-- Les chiffres sont des valeurs de départ, à ajuster selon l'usage réel.
-- NON APPLIQUÉE : à appliquer seulement avec l'accord du propriétaire.

create table if not exists private.club_creation_log (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  origin_hash text not null,
  email_hash text not null,
  allowed boolean not null,
  reason text not null
);
create index if not exists club_creation_log_origin_idx
  on private.club_creation_log (origin_hash, created_at);
create index if not exists club_creation_log_email_idx
  on private.club_creation_log (email_hash, created_at);
create index if not exists club_creation_log_time_idx
  on private.club_creation_log (created_at);
alter table private.club_creation_log enable row level security;
revoke all on private.club_creation_log from public, anon, authenticated;
grant select, insert, delete on private.club_creation_log to club_scope;

create table if not exists private.disposable_email_domains (
  domain text primary key check (domain = lower(domain))
);
alter table private.disposable_email_domains enable row level security;
revoke all on private.disposable_email_domains from public, anon, authenticated;
grant select on private.disposable_email_domains to club_scope;

insert into private.disposable_email_domains (domain) values
  ('mailinator.com'), ('guerrillamail.com'), ('10minutemail.com'),
  ('tempmail.com'), ('temp-mail.org'), ('yopmail.com'), ('trashmail.com'),
  ('sharklasers.com'), ('getnada.com'), ('throwawaymail.com'),
  ('maildrop.cc'), ('dispostable.com'), ('fakeinbox.com')
on conflict do nothing;

create or replace function public.check_club_creation_limits(
  p_origin_hash text,
  p_email text
) returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_local text;
  v_domain text;
  v_norm text;
  v_email_hash text;
  v_reason text := null;
begin
  if p_origin_hash is null or p_origin_hash !~ '^[0-9a-f]{64}$' then
    raise exception 'Invalid origin hash' using errcode = '22023';
  end if;
  if v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'Invalid email' using errcode = '22023';
  end if;

  v_local := split_part(v_email, '@', 1);
  v_domain := split_part(v_email, '@', 2);
  -- Normalisation : étiquette « +x » ignorée ; points ignorés pour gmail.
  v_local := split_part(v_local, '+', 1);
  if v_domain in ('gmail.com', 'googlemail.com') then
    v_local := replace(v_local, '.', '');
    v_domain := 'gmail.com';
  end if;
  v_norm := v_local || '@' || v_domain;
  v_email_hash := encode(pg_catalog.sha256(pg_catalog.convert_to(v_norm, 'UTF8')), 'hex');

  -- Un seul passage à la fois par adresse réseau : pas de course entre deux
  -- demandes simultanées.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('club_creation:' || p_origin_hash, 0)
  );

  if exists (
    select 1 from private.disposable_email_domains d where d.domain = v_domain
  ) then
    v_reason := 'disposable_email';
  elsif exists (
    select 1 from private.club_creation_log l
    where l.origin_hash = p_origin_hash and l.allowed
      and l.created_at >= now() - interval '60 seconds'
  ) then
    v_reason := 'too_soon';
  elsif (
    select count(*) from private.club_creation_log l
    where l.origin_hash = p_origin_hash and l.allowed
      and l.created_at >= now() - interval '24 hours'
  ) >= 3 then
    v_reason := 'origin_daily';
  elsif (
    select count(*) from private.club_creation_log l
    where l.email_hash = v_email_hash and l.allowed
      and l.created_at >= now() - interval '24 hours'
  ) >= 2 then
    v_reason := 'email_daily';
  elsif (
    select count(*) from private.club_creation_log l
    where l.allowed and l.created_at >= now() - interval '1 hour'
  ) >= 20 then
    v_reason := 'global_hourly';
  end if;

  insert into private.club_creation_log (origin_hash, email_hash, allowed, reason)
  values (p_origin_hash, v_email_hash, v_reason is null, coalesce(v_reason, 'ok'));

  -- Journal borné : 90 jours.
  delete from private.club_creation_log
  where created_at < now() - interval '90 days';

  return jsonb_build_object('allowed', v_reason is null,
                            'reason', coalesce(v_reason, 'ok'));
end;
$$;

-- Même propriétaire que le quota d'inscription : rôle sans contournement des
-- règles d'accès (club_isolation.test.sql).
alter function public.check_club_creation_limits(text, text) owner to club_scope;
revoke all on function public.check_club_creation_limits(text, text) from public, anon, authenticated;
grant execute on function public.check_club_creation_limits(text, text) to service_role;

comment on function public.check_club_creation_limits(text, text) is
  'Limites anti-abus de création de club (création ouverte à tous) : e-mail jetable, 60 s entre deux demandes, 3/j par adresse réseau, 2/j par e-mail, 20/h global. Journalise. Réservée aux fonctions Edge (service_role).';
