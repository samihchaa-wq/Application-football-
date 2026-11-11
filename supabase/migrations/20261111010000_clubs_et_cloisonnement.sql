-- Plusieurs clubs dans une même base, chacun ne voyant que ses données.
--
-- Principe :
--   1. chaque ligne de donnée porte le club auquel elle appartient (club_id),
--      rempli tout seul à l'écriture ;
--   2. une règle d'accès, posée sur chaque table, ne laisse voir et écrire
--      que les lignes du club courant ;
--   3. les fonctions serveur ne tournent plus avec un compte qui contourne
--      ces règles : elles appartiennent au rôle `club_scope`, soumis aux
--      mêmes règles. Une fonction ne peut donc pas, même par oubli, lire ou
--      modifier les données d'un autre club.
--
-- Le club courant est celui du compte connecté. Pour les traitements sans
-- utilisateur (tâches planifiées, fonctions Edge), il est fixé explicitement
-- avant le traitement.

-- ---------------------------------------------------------------------------
-- 1. Les clubs
-- ---------------------------------------------------------------------------

create table public.clubs (
  id uuid primary key default gen_random_uuid(),
  name text not null
    constraint clubs_name_check
      check (char_length(btrim(name)) between 2 and 80 and name = btrim(name)),
  short_name text not null
    constraint clubs_short_name_check
      check (char_length(btrim(short_name)) between 2 and 12
             and short_name = btrim(short_name)),
  primary_color text not null default '#1F6FEB'
    constraint clubs_primary_color_check check (primary_color ~ '^#[0-9A-Fa-f]{6}$'),
  secondary_color text not null default '#FFFFFF'
    constraint clubs_secondary_color_check check (secondary_color ~ '^#[0-9A-Fa-f]{6}$'),
  logo_path text,
  timezone text not null default 'Europe/Paris',
  invite_code text not null unique
    constraint clubs_invite_code_check check (invite_code ~ '^[A-Z2-9]{8}$'),
  status text not null default 'active'
    constraint clubs_status_check check (status in ('active', 'suspended')),
  created_at timestamptz not null default now(),
  created_by uuid
);

comment on table public.clubs is
  'Un club utilisateur de l''application. Racine du cloisonnement des données.';

alter table public.clubs enable row level security;
revoke all on public.clubs from public, anon, authenticated;
grant select on public.clubs to authenticated;
grant all on public.clubs to service_role;

-- ---------------------------------------------------------------------------
-- 2. Le club courant
-- ---------------------------------------------------------------------------

-- Club par défaut des sessions techniques, pour les installations locales et
-- les tests uniquement : rempli par supabase/seed.sql, jamais sur une base
-- réelle.
create table private.local_default_club (
  singleton boolean primary key default true check (singleton),
  club_id uuid not null references public.clubs(id) on delete cascade
);
create index local_default_club_club_id_idx on private.local_default_club (club_id);
alter table private.local_default_club enable row level security;
revoke all on private.local_default_club from public, anon, authenticated;

-- Appartient à postgres : doit lire le profil sans passer par les règles
-- d'accès, qui elles-mêmes appellent cette fonction.
create function private.current_club_id() returns uuid
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_user uuid := private.uid();
  v_club uuid;
  v_setting text;
  v_claim_role text;
begin
  -- Un utilisateur connecté n'a qu'un club : celui de son profil. Aucun
  -- réglage ni en-tête ne peut le faire changer de club.
  if v_user is not null then
    select profile.club_id into v_club
    from public.profiles profile
    where profile.id = v_user;
    return v_club;
  end if;

  -- Traitement sans utilisateur : club fixé pour la transaction ou la session.
  v_setting := nullif(current_setting('app.club_id', true), '');
  if v_setting is not null then
    return v_setting::uuid;
  end if;

  -- Fonction Edge authentifiée par la clé de service : club passé en en-tête.
  v_claim_role := nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role';
  if v_claim_role = 'service_role' then
    v_setting := nullif(
      nullif(current_setting('request.headers', true), '')::jsonb ->> 'x-club-id',
      ''
    );
    if v_setting is not null then
      return v_setting::uuid;
    end if;
  end if;

  -- Installation locale ou de test : club par défaut des sessions techniques.
  -- Cette table reste vide sur une base réelle.
  select fallback.club_id into v_club from private.local_default_club fallback;
  return v_club;
exception
  when invalid_text_representation then
    return null;
end;
$$;

revoke all on function private.current_club_id() from public;
grant execute on function private.current_club_id() to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 3. Le rôle des fonctions serveur
-- ---------------------------------------------------------------------------

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'club_scope') then
    create role club_scope nologin noinherit;
  end if;
end;
$$;

grant club_scope to postgres;
grant usage, create on schema public, private to club_scope;
grant usage on schema extensions, vault, storage to club_scope;

-- Le coffre n'est pas délégable non plus : une fonction relais appartenant à
-- postgres, réservée aux fonctions serveur.
create function private.vault_secrets()
returns table (name text, decrypted_secret text)
language sql stable security definer
set search_path to ''
as $$
  select secret.name, secret.decrypted_secret
  from vault.decrypted_secrets secret;
$$;
revoke all on function private.vault_secrets() from public;

-- Les objets créés plus tard restent utilisables par les fonctions serveur.
alter default privileges for role postgres in schema public, private
  grant execute on functions to club_scope;
alter default privileges for role postgres in schema public, private
  grant select, insert, update, delete on tables to club_scope;
alter default privileges for role postgres in schema public, private
  grant usage, select, update on sequences to club_scope;
grant select, delete on storage.objects to club_scope;

-- pg_net n'est pas délégable : un relais appartenant à postgres.
create function private.http_post(
  url text,
  body jsonb default '{}'::jsonb,
  params jsonb default '{}'::jsonb,
  headers jsonb default '{"Content-Type": "application/json"}'::jsonb,
  timeout_milliseconds integer default 5000
) returns bigint
language sql security definer
set search_path to ''
as $$
  select net.http_post(
    url := url,
    body := body,
    params := params,
    headers := headers,
    timeout_milliseconds := timeout_milliseconds
  );
$$;

revoke all on function private.http_post(text, jsonb, jsonb, jsonb, integer) from public;

-- ---------------------------------------------------------------------------
-- 4. Données de référence : elles deviennent propres à chaque club
-- ---------------------------------------------------------------------------

-- Le catalogue de badges livré avec le produit devient un modèle, copié dans
-- chaque club à sa création.
create table private.badge_templates (like public.badges including defaults);
alter table private.badge_templates add primary key (code);
alter table private.badge_templates enable row level security;
revoke all on private.badge_templates from public, anon, authenticated;
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('879af1f7-477c-4d48-986d-f7051d89e033', 'role_goalkeeper', 'Gardien', 'Exercer officiellement la fonction de gardien du club.', '🧤', 'joueur', false, NULL, NULL, 911, '2026-11-11 00:17:29.945328+00', 'custom', 'palmares', NULL, '#1C1C24', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('bc8e027e-8d01-45c1-9b46-23ef4d2abb30', 'assists__10', 'Faiseur de jeu', 'Atteindre 10 passes décisives avec le club.', '🎯', 'joueur', true, 'assists', 10, 144, '2026-11-11 00:17:31.007828+00', 'tier', 'joueur_all_time', NULL, '#4FA9E8', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('cb153e9a-9d6c-4baf-93cb-ea395b2344d6', 'assists__25', 'Passeur confirmé', 'Atteindre 25 passes décisives avec le club.', '🎯', 'joueur', true, 'assists', 25, 145, '2026-11-11 00:17:31.007828+00', 'tier', 'joueur_all_time', NULL, '#1E3A8A', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('f243e7ed-4641-4e05-a363-265d446099f7', 'assists__50', 'Maestro', 'Atteindre 50 passes décisives avec le club.', '🎯', 'joueur', true, 'assists', 50, 146, '2026-11-11 00:17:31.007828+00', 'tier', 'joueur_all_time', NULL, '#7C3AED', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('76e6a367-23a4-4097-bd94-a26a516100b3', 'assists__100', 'Architecte du jeu', 'Atteindre 100 passes décisives avec le club.', '🎯', 'joueur', true, 'assists', 100, 147, '2026-11-11 00:17:31.007828+00', 'tier', 'joueur_all_time', NULL, '#1C1C24', true, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('68952857-4316-46e3-92ae-7de853833d91', 'max_match_assists__3', 'Triple passe', 'Délivrer trois passes décisives au cours d’un même match.', '🪄', 'joueur', true, 'max_match_assists', 3, 163, '2026-11-11 00:17:31.007828+00', 'tier', 'joueur_all_time', NULL, '#F1706E', false, true, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('5d352209-9592-4e08-81f6-760ab26ca3b8', 'assists_season__5', 'Passeur', 'Délivrer 10 passes décisives au cours d’une même saison.', '🎯', 'joueur', true, 'assists_season', 10, 141, '2026-11-11 00:17:31.007828+00', 'tier', 'joueur_saison', NULL, '#CD7F32', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('f2d6b6ee-5773-4b7e-92e8-0b6b1339e6dc', 'assists_season__10', 'Créateur', 'Délivrer 15 passes décisives au cours d’une même saison.', '🎯', 'joueur', true, 'assists_season', 15, 142, '2026-11-11 00:17:31.007828+00', 'tier', 'joueur_saison', NULL, '#C0C0C0', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('12540099-12a1-4ce2-900f-040bb29749f7', 'assists_season__15', 'Chef d’orchestre', 'Délivrer 20 passes décisives au cours d’une même saison.', '🎯', 'joueur', true, 'assists_season', 20, 143, '2026-11-11 00:17:31.007828+00', 'tier', 'joueur_saison', NULL, '#D4AF37', true, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('5c870da8-8a7d-4cf1-a433-2e39fc0cfa64', 'assists_season__3', 'Passeur en herbe', 'Délivrer 5 passes décisives au cours d’une même saison.', '🎯', 'joueur', true, 'assists_season', 5, 140, '2026-11-11 00:17:31.007828+00', 'tier', 'joueur_saison', NULL, '#7A858D', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('7cd3187e-c8e7-4e28-a4a2-c6de87043dd3', 'title_top_assists__1', 'Passe d’or', 'Terminer une saison en étant le joueur ayant délivré le plus grand nombre de passes décisives.', '🎯', 'joueur', true, 'title_top_assists', 1, 195, '2026-11-11 00:17:31.04908+00', 'tier', 'palmares', NULL, '#B9F2FF', true, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('56c72984-4d4b-46dc-ae6e-b784222e7f02', 'matches_played_season__15', 'Habitué', 'Participer à 15 matchs au cours d’une même saison.', '📅', 'joueur', true, 'matches_played_season', 15, 100, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_saison', NULL, '#6E7A86', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('198f0bd9-6643-494b-a95b-2e2472c9c1c4', 'matches_played_season__20', 'Assidu', 'Participer à 20 matchs au cours d’une même saison.', '📅', 'joueur', true, 'matches_played_season', 20, 101, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_saison', NULL, '#B87333', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('667cfdf7-5915-4c7f-bd2e-9c2abf6b4b59', 'matches_played_season__25', 'Pilier', 'Participer à 25 matchs au cours d’une même saison.', '📅', 'joueur', true, 'matches_played_season', 25, 102, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_saison', NULL, '#C4CBD4', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('4eb3cb1f-46be-484b-9767-e1a0c4b0d358', 'matches_played_season__30', 'Incontournable', 'Participer à 30 matchs au cours d’une même saison.', '📅', 'joueur', true, 'matches_played_season', 30, 103, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_saison', NULL, '#E3B23C', true, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('370fd099-e77c-4ec5-ba55-74308ae215f0', 'matches_played__50', 'Fidèle', 'Atteindre 50 matchs joués avec le club.', '📅', 'joueur', true, 'matches_played', 50, 104, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_all_time', NULL, '#4FA9E8', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('8d30e9be-1b15-443d-b852-ed597e7d0f05', 'matches_played__100', 'Vétéran', 'Atteindre 100 matchs joués avec le club.', '📅', 'joueur', true, 'matches_played', 100, 105, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_all_time', NULL, '#1E3A8A', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('7ebba7be-d546-4678-8ba8-a428c8c52b09', 'matches_played__150', 'Cadre du club', 'Atteindre 150 matchs joués avec le club.', '📅', 'joueur', true, 'matches_played', 150, 106, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_all_time', NULL, '#7C3AED', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('22f43a6b-031d-4842-bd26-35d79989bf7e', 'matches_played__200', 'Légende du club', 'Atteindre 200 matchs joués avec le club.', '📅', 'joueur', true, 'matches_played', 200, 107, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_all_time', NULL, '#1C1C24', true, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('c9025d71-e56f-44b9-a803-386199317cb0', 'goals_season__5', 'Première gâchette', 'Marquer 5 buts au cours d’une même saison.', '⚽', 'joueur', true, 'goals_season', 5, 110, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_saison', NULL, '#6E7A86', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('fcdd784f-1cb5-48f8-acd6-3238768e88f9', 'goals_season__10', 'Finisseur', 'Marquer 10 buts au cours d’une même saison.', '⚽', 'joueur', true, 'goals_season', 10, 111, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_saison', NULL, '#B87333', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('259fcfff-51db-4279-a784-236de602127a', 'goals_season__20', 'Artilleur', 'Marquer 20 buts au cours d’une même saison.', '⚽', 'joueur', true, 'goals_season', 20, 112, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_saison', NULL, '#C4CBD4', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('9e5506bc-7d65-4ba2-94f8-da42ab8ff8a4', 'goals_season__30', 'Goleador', 'Marquer 30 buts au cours d’une même saison.', '⚽', 'joueur', true, 'goals_season', 30, 113, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_saison', NULL, '#E3B23C', true, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('75c5c90a-babe-46a9-a5d8-e95992faa8ab', 'goals__25', 'Buteur confirmé', 'Atteindre 25 buts marqués avec le club.', '⚽', 'joueur', true, 'goals', 25, 114, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_all_time', NULL, '#4FA9E8', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('ad76eebb-46d5-494d-bbe7-623e0ff80f80', 'goals__50', 'Canonnier', 'Atteindre 50 buts marqués avec le club.', '⚽', 'joueur', true, 'goals', 50, 115, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_all_time', NULL, '#1E3A8A', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('a12ebbe7-7395-4733-a2c7-f21b870029df', 'goals__75', 'Chasseur de records', 'Atteindre 75 buts marqués avec le club.', '⚽', 'joueur', true, 'goals', 75, 116, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_all_time', NULL, '#7C3AED', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('3dff4b28-780a-4508-ba53-4a4ce68cd11b', 'goals__100', 'Centurion', 'Atteindre la barre mythique des 100 buts avec le club.', '⚽', 'joueur', true, 'goals', 100, 117, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_all_time', NULL, '#1C1C24', true, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('1309001d-f711-4c1f-a35c-9a0daa39b0a5', 'wins_season__10', 'Compétiteur', 'Remporter 10 matchs au cours d’une même saison.', '🏆', 'joueur', true, 'wins_season', 10, 120, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_saison', NULL, '#6E7A86', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('da4cbd56-518e-4be2-8562-b1b82b3c7d34', 'wins_season__15', 'Gagnant', 'Remporter 15 matchs au cours d’une même saison.', '🏆', 'joueur', true, 'wins_season', 15, 121, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_saison', NULL, '#B87333', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('801008b9-a458-4437-a333-df66971e101e', 'wins_season__20', 'Serial winner', 'Remporter 20 matchs au cours d’une même saison.', '🏆', 'joueur', true, 'wins_season', 20, 122, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_saison', NULL, '#C4CBD4', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('1aa3fc31-600d-4f0c-82b2-18e3634648a3', 'wins_season__25', 'Invincible', 'Remporter 25 matchs au cours d’une même saison.', '🏆', 'joueur', true, 'wins_season', 25, 123, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_saison', NULL, '#E3B23C', true, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('a91f7e80-d426-4453-9358-057d1b312b57', 'wins__50', 'Habitué de la victoire', 'Atteindre 50 victoires avec le club.', '🏆', 'joueur', true, 'wins', 50, 124, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_all_time', NULL, '#4FA9E8', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('c813c5da-73d7-42d3-943f-d45e7b639003', 'wins__100', 'Centurion victorieux', 'Atteindre 100 victoires avec le club.', '🏆', 'joueur', true, 'wins', 100, 125, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_all_time', NULL, '#1E3A8A', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('aa5fb09b-dc93-44e8-8517-3be7d0f73bbb', 'wins__150', 'Maître de la gagne', 'Atteindre 150 victoires avec le club.', '🏆', 'joueur', true, 'wins', 150, 126, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_all_time', NULL, '#7C3AED', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('b3a55a70-15f8-4565-8f6d-2cfd8ae8a523', 'wins__200', 'Légende victorieuse', 'Atteindre 200 victoires avec le club.', '🏆', 'joueur', true, 'wins', 200, 127, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_all_time', NULL, '#1C1C24', true, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('5e9743c4-56ad-4ac2-a246-b07a74e6b156', 'clean_sheets_season__3', 'Premier verrou', 'Terminer 3 matchs sans encaisser de but au cours d’une même saison.', '🧱', 'joueur', true, 'clean_sheets_season', 3, 130, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_saison', NULL, '#6E7A86', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('29a4fc42-1d4f-43b7-b8fb-3bce4b4caa8a', 'clean_sheets_season__5', 'Dernier rempart', 'Terminer 5 matchs sans encaisser de but au cours d’une même saison.', '🧱', 'joueur', true, 'clean_sheets_season', 5, 131, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_saison', NULL, '#B87333', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('d104a6a7-423f-4de6-a16c-18f5797bc189', 'clean_sheets_season__7', 'Muraille', 'Terminer 7 matchs sans encaisser de but au cours d’une même saison.', '🧱', 'joueur', true, 'clean_sheets_season', 7, 132, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_saison', NULL, '#C4CBD4', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('98a25610-7187-440e-81b5-0821ec3b5acf', 'clean_sheets_season__10', 'Forteresse imprenable', 'Terminer 10 matchs sans encaisser de but au cours d’une même saison.', '🧱', 'joueur', true, 'clean_sheets_season', 10, 133, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_saison', NULL, '#E3B23C', true, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('da9417fc-63a2-4498-9c2b-9c1a3dd81b67', 'clean_sheets__10', 'Verrou confirmé', 'Atteindre 10 matchs sans encaisser de but avec le club.', '🧱', 'joueur', true, 'clean_sheets', 10, 134, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_all_time', NULL, '#4FA9E8', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('344513be-89dc-4ae4-9261-9ac4819b1b18', 'clean_sheets__20', 'Gardien du temple', 'Atteindre 20 matchs sans encaisser de but avec le club.', '🧱', 'joueur', true, 'clean_sheets', 20, 135, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_all_time', NULL, '#1E3A8A', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('2de5abb3-8ea8-4d26-83a0-1e612d35e15d', 'clean_sheets__30', 'Mur infranchissable', 'Atteindre 30 matchs sans encaisser de but avec le club.', '🧱', 'joueur', true, 'clean_sheets', 30, 136, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_all_time', NULL, '#7C3AED', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('18574ecf-7da8-4d40-8a7f-73e841f225e7', 'clean_sheets__50', 'Bastion', 'Atteindre 50 matchs sans encaisser de but avec le club.', '🧱', 'joueur', true, 'clean_sheets', 50, 137, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_all_time', NULL, '#1C1C24', true, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('ee4724a8-fe5a-479d-bdaf-efc153dbc79c', 'mvp__10', 'Homme fort', 'Obtenir 10 distinctions d’Homme du match avec le club.', '👑', 'joueur', true, 'mvp', 10, 150, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_all_time', NULL, '#4FA9E8', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('667478bb-c25d-4ff5-b916-220ac2665335', 'mvp__20', 'Joueur décisif', 'Obtenir 20 distinctions d’Homme du match avec le club.', '👑', 'joueur', true, 'mvp', 20, 151, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_all_time', NULL, '#1E3A8A', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('7025b877-9204-4629-ac98-c7d63bce49f6', 'mvp__30', 'Roi du match', 'Obtenir 30 distinctions d’Homme du match avec le club.', '👑', 'joueur', true, 'mvp', 30, 152, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_all_time', NULL, '#7C3AED', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('cfb3b1b2-907f-4792-a279-645bb884286c', 'mvp__50', 'Mobutu', 'Obtenir 50 distinctions d’Homme du match avec le club.', '👑', 'joueur', true, 'mvp', 50, 153, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_all_time', NULL, '#1C1C24', true, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('2d3798da-45ac-4e75-b8fa-3df32dacb71f', 'max_match_goals__3', 'Triplé', 'Marquer exactement trois buts au cours d’un même match.', '🎩', 'joueur', true, 'max_match_goals', 3, 160, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_all_time', NULL, '#F1706E', false, true, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('d6c63942-918f-49c2-bf9c-c684f986e7be', 'max_match_goals__4', 'Quadruplé', 'Marquer exactement quatre buts au cours d’un même match.', '🃏', 'joueur', true, 'max_match_goals', 4, 161, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_all_time', NULL, '#E23B36', false, true, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('9719ea9a-464a-4983-906d-fd84816118b9', 'max_match_goals__5', 'Quintuplé', 'Marquer cinq buts ou plus au cours d’un même match.', '🖐️', 'joueur', true, 'max_match_goals', 5, 162, '2026-11-11 00:17:33.382469+00', 'tier', 'joueur_all_time', NULL, '#9E1B1B', false, true, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('119f1252-2551-46d0-bb1f-c2f053fd0561', 'title_most_present__1', 'Monsieur Présent', 'Terminer une saison en étant le joueur ayant participé au plus grand nombre de matchs.', '🙋', 'joueur', true, 'title_most_present', 1, 191, '2026-11-11 00:17:33.382469+00', 'tier', 'palmares', NULL, '#5FC9D9', true, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('930ac4a3-015f-45e2-80e3-a77a3326036c', 'title_top_scorer__1', 'Soulier d’or', 'Terminer une saison en étant le joueur ayant marqué le plus grand nombre de buts.', '🥇', 'joueur', true, 'title_top_scorer', 1, 192, '2026-11-11 00:17:33.382469+00', 'tier', 'palmares', NULL, '#5FC9D9', true, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('04e1f098-9ff8-471e-b57b-0b86a23cee88', 'title_best_winrate__1', 'Monsieur Victoire', 'Terminer une saison avec le meilleur taux de victoire parmi les joueurs éligibles.', '📈', 'joueur', true, 'title_best_winrate', 1, 193, '2026-11-11 00:17:33.382469+00', 'tier', 'palmares', NULL, '#5FC9D9', true, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('160e397f-be4b-40e2-b208-c1b93c6b44a2', 'title_mvp_king__1', 'Ballon d’or', 'Terminer une saison en étant le joueur ayant obtenu le plus de distinctions d’Homme du match.', '🌟', 'joueur', true, 'title_mvp_king', 1, 194, '2026-11-11 00:17:33.382469+00', 'tier', 'palmares', NULL, '#5FC9D9', true, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('2a6557eb-2cbc-4c85-9a72-1f4bc494cf6a', 'title_best_pred_player__1', 'L’Analyste', 'Terminer une saison avec le meilleur total de points sur les pronostics liés aux statistiques des joueurs.', '📊', 'pronostiqueur', true, 'title_best_pred_player', 1, 200, '2026-11-11 00:17:33.382469+00', 'tier', 'palmares', NULL, '#5FC9D9', true, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('8f60d5d5-7a1a-40df-ab18-968c8698f0e6', 'title_best_pred_match__1', 'Le Visionnaire', 'Terminer une saison avec le meilleur total de points sur les pronostics de résultats et de scores des matchs.', '🔮', 'pronostiqueur', true, 'title_best_pred_match', 1, 201, '2026-11-11 00:17:33.382469+00', 'tier', 'palmares', NULL, '#5FC9D9', true, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('cab7083e-dc5e-4f47-ab63-f62f218076ca', 'title_best_pred_overall__1', 'Le Cerveau', 'Terminer une saison avec le meilleur total cumulé sur l’ensemble des catégories de pronostics.', '🧠', 'pronostiqueur', true, 'title_best_pred_overall', 1, 202, '2026-11-11 00:17:33.382469+00', 'tier', 'palmares', NULL, '#5FC9D9', true, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('c7ff4546-10fc-4f51-a1f8-7fa7bd448b4a', 'bet_against_grinta__1', 'Traître', 'Pronostiquer contre l’AS Grinta… et avoir raison. Honte à toi.', '🐍', 'pronostiqueur', true, 'bet_against_grinta', 1, 900, '2026-11-11 00:17:33.382469+00', 'tier', 'pronos_all_time', NULL, '#F97316', false, true, true, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('24007ec9-ecb1-45bd-9afc-38a3ef4a0530', 'exploit_remplace_gardien', 'Gardien d’un soir', 'Prendre la place du gardien pendant un match alors que ce n’est pas son poste habituel.', '🧤', 'joueur', false, NULL, NULL, 900, '2026-11-11 00:17:33.382469+00', 'custom', 'faits_de_jeu', NULL, '#F2811D', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('ba9a19c7-89e6-4a76-aefa-545fb49e875a', 'exploit_penalty_provoque', 'Le Boucher', 'Commettre une faute entraînant un penalty pour l’équipe adverse.', '🔪', 'joueur', false, NULL, NULL, 902, '2026-11-11 00:17:33.382469+00', 'custom', 'faits_de_jeu', NULL, '#F2811D', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('e16645f6-2d93-48ff-bd4f-2c885bb1720b', 'exploit_penalty_subi', 'Le Plongeur', 'Subir une faute dans la surface permettant à son équipe d’obtenir un penalty.', '🤿', 'joueur', false, NULL, NULL, 903, '2026-11-11 00:17:33.382469+00', 'custom', 'faits_de_jeu', NULL, '#F2811D', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('f3095d2e-9869-4bc0-8acb-9f6594764292', 'exploit_but_vainqueur_tardif', 'Clutch', 'Marquer dans les dernières minutes le but qui offre définitivement la victoire à son équipe.', '🥵', 'joueur', false, NULL, NULL, 905, '2026-11-11 00:17:33.382469+00', 'custom', 'faits_de_jeu', NULL, '#F2811D', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('65463724-2fe5-460d-9935-4677d15a8c64', 'exploit_csc', 'La Boulette', 'Envoyer involontairement le ballon dans les cages de sa propre équipe.', '🫣', 'joueur', false, NULL, NULL, 906, '2026-11-11 00:17:33.382469+00', 'custom', 'faits_de_jeu', NULL, '#F2811D', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('c6feebf1-8147-49db-ab9e-556749eed0c6', 'role_president', 'El Presidente', 'Exercer officiellement la fonction de président du club.', '🤵', 'joueur', false, NULL, NULL, 909, '2026-11-11 00:17:33.382469+00', 'custom', 'palmares', NULL, '#1C1C24', false, false, false, NULL);
insert into private.badge_templates (id, code, name, description, emoji, family, auto, metric, threshold, sort_order, created_at, kind, category, image_url, color, has_star, standalone, secret, auto_rule) VALUES ('718dcd9f-9400-4f0a-9dd4-e06feea0a614', 'role_coach', 'Coach', 'Exercer officiellement la fonction de coach du club.', '👨‍🦲', 'joueur', false, NULL, NULL, 910, '2026-11-11 00:17:33.382469+00', 'custom', 'palmares', NULL, '#1C1C24', false, false, false, NULL);

-- ---------------------------------------------------------------------------
-- 5. club_id sur chaque table de données
-- ---------------------------------------------------------------------------

do $$
declare
  v_table record;
  -- Tables communes à tous les clubs.
  v_global text[] := array[
    'public.clubs',
    'private.badge_templates',
    'private.local_default_club',
    'private.registration_attempts',
    'private.prediction_reminder_cron_config',
    'private.sport_waitlist_engine_activation',
    'private.client_incident_log'
  ];
begin
  for v_table in
    select n.nspname as schema_name, c.relname as table_name
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname in ('public', 'private')
      and c.relkind = 'r'
    order by 1, 2
  loop
    execute format(
      'grant select, insert, update, delete on %I.%I to club_scope',
      v_table.schema_name, v_table.table_name
    );
    execute format(
      'alter table %I.%I enable row level security',
      v_table.schema_name, v_table.table_name
    );

    if format('%s.%s', v_table.schema_name, v_table.table_name) = any (v_global) then
      if v_table.table_name <> 'clubs' then
        execute format(
          'create policy club_scope_access on %I.%I for all to club_scope using (true) with check (true)',
          v_table.schema_name, v_table.table_name
        );
      end if;
      continue;
    end if;

    execute format(
      'alter table %I.%I add column club_id uuid not null default private.current_club_id() references public.clubs(id) on delete cascade',
      v_table.schema_name, v_table.table_name
    );
    execute format(
      'create index %I on %I.%I (club_id)',
      v_table.table_name || '_club_id_idx', v_table.schema_name, v_table.table_name
    );
    -- Règle restrictive : s'ajoute à toutes les autres, pour tous les rôles.
    execute format(
      'create policy club_isolation on %I.%I as restrictive for all to public '
      'using (club_id = (select private.current_club_id())) '
      'with check (club_id = (select private.current_club_id()))',
      v_table.schema_name, v_table.table_name
    );
    -- Les fonctions serveur accèdent à tout… dans la limite de la règle
    -- restrictive ci-dessus.
    execute format(
      'create policy club_scope_access on %I.%I for all to club_scope using (true) with check (true)',
      v_table.schema_name, v_table.table_name
    );
  end loop;
end;
$$;

grant usage, select, update on all sequences in schema public, private to club_scope;

-- Un membre voit son club, et seulement le sien.
create policy clubs_member_read on public.clubs
  for select to authenticated
  using (id = (select private.current_club_id()));
create policy active_authenticated_profile_only on public.clubs
  as restrictive for all to authenticated
  using ((select private.is_active_profile()))
  with check ((select private.is_active_profile()));
create policy club_scope_access on public.clubs
  for all to club_scope
  using (id = (select private.current_club_id()))
  with check (id = (select private.current_club_id()));

-- Fichiers : les fonctions serveur ne touchent qu'aux espaces de l'application.
create policy club_scope_files on storage.objects
  for all to club_scope
  using (bucket_id in ('profile-photos', 'badge-images', 'app-assets'))
  with check (bucket_id in ('profile-photos', 'badge-images', 'app-assets'));

-- ---------------------------------------------------------------------------
-- 6. Unicités qui valaient pour « le » club : elles valent par club
-- ---------------------------------------------------------------------------

alter table private.app_feature_flags drop constraint app_feature_flags_pkey cascade;
alter table private.app_feature_flags add primary key (club_id, key);

alter table public.feature_flag_change_signals drop constraint feature_flag_change_signals_pkey;
alter table public.feature_flag_change_signals add primary key (club_id, key);

alter table public.shared_data_change_signals drop constraint shared_data_change_signals_pkey;
alter table public.shared_data_change_signals add primary key (club_id, key);

alter table public.club_settings drop constraint club_settings_pkey;
alter table public.club_settings add primary key (club_id);

alter table public.badges drop constraint badges_code_key;
alter table public.badges add constraint badges_club_code_key unique (club_id, code);

alter table public.seasons drop constraint seasons_name_key;
alter table public.seasons add constraint seasons_club_name_key unique (club_id, name);
drop index public.idx_seasons_open;
create unique index idx_seasons_open on public.seasons (club_id) where (status = 'open');

drop index public.matches_match_date_uidx;
create unique index matches_match_date_uidx on public.matches (club_id, match_date);

drop index public.guest_players_reusable_identity_unique_idx;
create unique index guest_players_reusable_identity_unique_idx
  on public.guest_players (
    club_id,
    lower(btrim(first_name)),
    lower(coalesce(btrim(last_name), '')),
    is_goalkeeper
  ) where is_reusable;

alter table public.historical_player_name_links drop constraint historical_player_name_links_pkey;
alter table public.historical_player_name_links add primary key (club_id, normalized_name);

alter table public.historical_player_statistics
  drop constraint historical_player_statistics_scope_player_name_key;
alter table public.historical_player_statistics
  add constraint historical_player_statistics_scope_player_name_key
  unique (club_id, scope, player_name);

alter table public.historical_team_statistics drop constraint historical_team_statistics_pkey;
alter table public.historical_team_statistics add primary key (club_id, scope);

-- ---------------------------------------------------------------------------
-- 7. Les fonctions et les vues passent sous les règles d'accès
-- ---------------------------------------------------------------------------

do $$
declare
  v_object record;
  -- Restent à postgres : elles doivent agir hors du cloisonnement.
  v_keep text[] := array[
    'private.current_club_id()',
    'private.http_post(text,jsonb,jsonb,jsonb,integer)',
    'private.edge_function_url(text)',
    'private.vault_secrets()',
    'public.handle_new_auth_user()'
  ];
begin
  for v_object in
    select p.oid::regprocedure::text as signature,
           format('%s.%s(%s)', n.nspname, p.proname,
                  pg_get_function_identity_arguments(p.oid)) as identity,
           format('%s.%s(%s)', n.nspname, p.proname,
                  oidvectortypes(p.proargtypes)) as plain
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('public', 'private')
      and p.proowner = 'postgres'::regrole
      and p.prokind in ('f', 'p')
  loop
    if replace(v_object.plain, ', ', ',') = any (v_keep) then
      continue;
    end if;
    execute format('alter routine %s owner to club_scope', v_object.signature);
  end loop;

  for v_object in
    select format('%I.%I', schemaname, viewname) as name
    from pg_views
    where schemaname in ('public', 'private')
  loop
    execute format('alter view %s owner to club_scope', v_object.name);
  end loop;
end;
$$;

grant execute on all functions in schema public, private to club_scope;
grant execute on function private.http_post(text, jsonb, jsonb, jsonb, integer) to club_scope;
grant execute on function private.vault_secrets() to club_scope;

-- ---------------------------------------------------------------------------
-- 8. Mise en place d'un club
-- ---------------------------------------------------------------------------

create function private.generate_invite_code() returns text
language plpgsql volatile
set search_path to ''
as $$
declare
  -- Sans 0, 1, I, O : pas de confusion à la lecture.
  v_alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_code text;
begin
  loop
    select string_agg(
      substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1), ''
    )
    into v_code
    from generate_series(1, 8);
    exit when not exists (select 1 from public.clubs where invite_code = v_code);
  end loop;
  return v_code;
end;
$$;

revoke all on function private.generate_invite_code() from public;

-- Pose les données de départ d'un club : réglages, signaux, badges.
create function private.provision_club(p_club_id uuid) returns void
language plpgsql security definer
set search_path to ''
as $$
begin
  perform set_config('app.club_id', p_club_id::text, true);

  insert into public.club_settings (club_id, id, home_address)
  values (p_club_id, true, null)
  on conflict (club_id) do nothing;

  insert into private.app_feature_flags (club_id, key, enabled, config, updated_at, updated_by)
  values
    (p_club_id, 'sports_management', true,
     jsonb_build_object(
       'availability_open_hours_before', 144,
       'reminder_hours_before', jsonb_build_array(72, 24),
       'usual_squad_size', 14,
       'vote_duration_hours', 24,
       'timezone', 'Europe/Paris'
     ), now(), null),
    (p_club_id, 'notifications_paused', false, '{}'::jsonb, now(), null)
  on conflict (club_id, key) do nothing;

  insert into public.feature_flag_change_signals (club_id, key, revision, updated_at)
  select p_club_id, flag.key, 1, flag.updated_at
  from private.app_feature_flags flag
  where flag.club_id = p_club_id
  on conflict (club_id, key) do nothing;

  insert into public.shared_data_change_signals (
    club_id, key, revision, profile_revision, sports_revision, updated_at
  )
  values (p_club_id, 'global', 1, 1, 1, now())
  on conflict (club_id, key) do nothing;

  insert into public.badges (
    club_id, code, name, description, emoji, family, auto, metric, threshold,
    sort_order, kind, category, image_url, color, has_star, standalone,
    secret, auto_rule
  )
  select
    p_club_id, template.code, template.name, template.description,
    template.emoji, template.family, template.auto, template.metric,
    template.threshold, template.sort_order, template.kind, template.category,
    template.image_url, template.color, template.has_star, template.standalone,
    template.secret, template.auto_rule
  from private.badge_templates template
  on conflict (club_id, code) do nothing;
end;
$$;

revoke all on function private.provision_club(uuid) from public;

-- Création d'un club. Réservée à la clé de service (fonctions Edge) : le
-- parcours d'inscription l'appelle, jamais un client directement.
create function public.create_club(
  p_name text,
  p_short_name text default null,
  p_primary_color text default null,
  p_secondary_color text default null,
  p_timezone text default null,
  p_created_by uuid default null
) returns public.clubs
language plpgsql security definer
set search_path to ''
as $$
declare
  v_name text := btrim(coalesce(p_name, ''));
  v_short text := btrim(coalesce(p_short_name, ''));
  v_club public.clubs;
begin
  if char_length(v_name) < 2 or char_length(v_name) > 80 then
    raise exception 'Le nom du club doit compter entre 2 et 80 caractères.'
      using errcode = '22023';
  end if;

  if v_short = '' then
    -- Initiales du nom, à défaut ses premières lettres.
    select upper(string_agg(substr(word, 1, 1), ''))
    into v_short
    from regexp_split_to_table(v_name, '\s+') as word
    where word <> '';
    if char_length(v_short) < 2 then
      v_short := upper(substr(regexp_replace(v_name, '\s+', '', 'g'), 1, 3));
    end if;
    v_short := substr(v_short, 1, 12);
  end if;

  insert into public.clubs (
    name, short_name, primary_color, secondary_color, timezone,
    invite_code, created_by
  )
  values (
    v_name,
    v_short,
    coalesce(nullif(btrim(p_primary_color), ''), '#1F6FEB'),
    coalesce(nullif(btrim(p_secondary_color), ''), '#FFFFFF'),
    coalesce(nullif(btrim(p_timezone), ''), 'Europe/Paris'),
    private.generate_invite_code(),
    p_created_by
  )
  returning * into v_club;

  perform private.provision_club(v_club.id);
  return v_club;
end;
$$;

revoke all on function public.create_club(text, text, text, text, text, uuid) from public, anon, authenticated;
grant execute on function public.create_club(text, text, text, text, text, uuid) to service_role;

-- Exécute un traitement planifié club par club. Un club en échec n'empêche
-- pas les autres.
create function private.run_for_each_club(p_sql text) returns void
language plpgsql security definer
set search_path to ''
as $$
declare
  v_club uuid;
begin
  for v_club in
    select club.id from public.clubs club where club.status = 'active' order by club.created_at
  loop
    begin
      perform set_config('app.club_id', v_club::text, true);
      execute p_sql;
    exception when others then
      raise warning 'Traitement planifié en échec pour le club %: % (%)',
        v_club, sqlerrm, sqlstate;
    end;
  end loop;
  perform set_config('app.club_id', '', true);
end;
$$;

revoke all on function private.run_for_each_club(text) from public;

-- Les tâches planifiées qui traitent des données de club passent club par club.
do $$
declare
  v_job record;
begin
  for v_job in
    select jobname, schedule, command
    from cron.job
    where jobname not in ('purge-cron-job-run-details', 'purge-client-incident-log')
  loop
    perform cron.schedule(
      v_job.jobname,
      v_job.schedule,
      format('select private.run_for_each_club(%L);', rtrim(v_job.command, ';'))
    );
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- 9. Inscription : le profil naît dans son club
-- ---------------------------------------------------------------------------

create or replace function public.handle_new_auth_user() returns trigger
language plpgsql security definer
set search_path to ''
as $$
declare
  v_club uuid;
begin
  -- Le club vient de l'inscription (fonction Edge). À défaut, du contexte
  -- courant ; sans club, l'inscription est refusée par la contrainte.
  begin
    v_club := nullif(new.raw_user_meta_data ->> 'club_id', '')::uuid;
  exception when invalid_text_representation then
    v_club := null;
  end;
  v_club := coalesce(v_club, private.current_club_id());

  insert into public.profiles(
    id, club_id, email, first_name, last_name, role, is_goalkeeper, status
  )
  values (
    new.id,
    v_club,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data->>'first_name', ''),
    coalesce(new.raw_user_meta_data->>'last_name', ''),
    'pronostiqueur',
    false,
    'pending'
  )
  on conflict (id) do update
  set email = excluded.email,
      first_name = case when public.profiles.first_name = '' then excluded.first_name else public.profiles.first_name end,
      last_name = case when public.profiles.last_name = '' then excluded.last_name else public.profiles.last_name end,
      updated_at = now();
  return new;
end;
$$;
