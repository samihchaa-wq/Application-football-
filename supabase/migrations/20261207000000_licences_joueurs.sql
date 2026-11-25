-- Licences des joueurs : qui a payé sa licence, qui a payé l'autre dépense
-- demandée par le club, et les informations de l'attestation de licence.
--
-- Deux tables, lisibles et modifiables par les seuls administrateurs du club
-- (le suivi des paiements n'est pas public dans l'effectif) :
--   * club_license_settings : réglages du club (une ligne par club) ;
--   * season_player_licenses : statut d'un joueur pour sa saison.
-- Aucune donnée existante n'est modifiée.

create table public.club_license_settings (
  club_id uuid primary key default private.current_club_id()
    references public.clubs(id) on delete cascade,
  club_number text
    constraint club_license_settings_club_number_check
      check (club_number is null
             or (char_length(club_number) <= 20 and club_number !~ '[[:cntrl:]]')),
  president_name text
    constraint club_license_settings_president_check
      check (president_name is null
             or (char_length(president_name) between 2 and 120
                 and president_name !~ '[[:cntrl:]]')),
  league_name text
    constraint club_license_settings_league_check
      check (league_name is null
             or (char_length(league_name) between 2 and 120
                 and league_name !~ '[[:cntrl:]]')),
  license_amount_cents integer
    constraint club_license_settings_amount_check
      check (license_amount_cents is null
             or license_amount_cents between 0 and 100000),
  other_expense_label text
    constraint club_license_settings_other_label_check
      check (other_expense_label is null
             or (char_length(other_expense_label) between 2 and 60
                 and other_expense_label !~ '[[:cntrl:]]')),
  other_expense_amount_cents integer
    constraint club_license_settings_other_amount_check
      check (other_expense_amount_cents is null
             or other_expense_amount_cents between 0 and 100000),
  updated_at timestamptz not null default now()
);

comment on table public.club_license_settings is
  'Réglages des licences du club : n° de club, président, ligue, montant de la cotisation, autre dépense demandée.';

create table public.season_player_licenses (
  season_player_id uuid primary key
    references public.season_players(id) on delete cascade,
  club_id uuid not null default private.current_club_id()
    references public.clubs(id) on delete cascade,
  license_number text
    constraint season_player_licenses_number_check
      check (license_number is null
             or (char_length(license_number) <= 30
                 and license_number !~ '[[:cntrl:]]')),
  license_paid boolean not null default false,
  other_paid boolean not null default false,
  updated_at timestamptz not null default now()
);
create index season_player_licenses_club_id_idx
  on public.season_player_licenses(club_id);

comment on table public.season_player_licenses is
  'Licence d''un joueur pour sa saison : numéro, licence payée, autre dépense payée.';

-- Même socle de sécurité que les autres tables du club.
alter table public.club_license_settings enable row level security;
alter table public.season_player_licenses enable row level security;

revoke all on public.club_license_settings from public, anon, authenticated;
revoke all on public.season_player_licenses from public, anon, authenticated;
grant select, insert, update on public.club_license_settings
  to authenticated, service_role;
grant select, insert, update on public.season_player_licenses
  to authenticated, service_role;

create policy club_license_settings_admin_all
on public.club_license_settings for all to authenticated
using (
  club_id = (select private.current_club_id())
  and (select private.is_admin())
)
with check (
  club_id = (select private.current_club_id())
  and (select private.is_admin())
);

create policy season_player_licenses_admin_all
on public.season_player_licenses for all to authenticated
using (
  club_id = (select private.current_club_id())
  and (select private.is_admin())
)
with check (
  club_id = (select private.current_club_id())
  and (select private.is_admin())
  -- la fiche joueur doit être celle du même club
  and exists (
    select 1 from public.season_players sp
    where sp.id = season_player_id
      and sp.club_id = (select private.current_club_id())
  )
);

create policy club_isolation
on public.club_license_settings as restrictive for all to authenticated
using (club_id = (select private.current_club_id()))
with check (club_id = (select private.current_club_id()));

create policy club_isolation
on public.season_player_licenses as restrictive for all to authenticated
using (club_id = (select private.current_club_id()))
with check (club_id = (select private.current_club_id()));

create policy active_authenticated_profile_only
on public.club_license_settings as restrictive for all to authenticated
using ((select private.is_active_profile()))
with check ((select private.is_active_profile()));

create policy active_authenticated_profile_only
on public.season_player_licenses as restrictive for all to authenticated
using ((select private.is_active_profile()))
with check ((select private.is_active_profile()));
