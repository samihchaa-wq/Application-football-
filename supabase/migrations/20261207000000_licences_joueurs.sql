-- Licences des joueurs : qui a payé sa licence, et qui a payé les autres
-- dépenses demandées par le club (ajoutées et renommées par l'admin).
--
-- Trois tables, lisibles et modifiables par les seuls administrateurs du club
-- (le suivi des paiements n'est pas public dans l'effectif) :
--   * club_license_expenses : les autres dépenses du club (nom libre) ;
--   * season_player_licenses : licence payée, par joueur et par saison ;
--   * season_player_expense_payments : une ligne = dépense payée par ce joueur.
-- Aucune donnée existante n'est modifiée.

create table public.club_license_expenses (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null default private.current_club_id()
    references public.clubs(id) on delete cascade,
  label text not null
    constraint club_license_expenses_label_check
      check (char_length(btrim(label)) between 2 and 60
             and label !~ '[[:cntrl:]]'),
  created_at timestamptz not null default now()
);
create index club_license_expenses_club_id_idx
  on public.club_license_expenses(club_id);

create table public.season_player_licenses (
  season_player_id uuid primary key
    references public.season_players(id) on delete cascade,
  club_id uuid not null default private.current_club_id()
    references public.clubs(id) on delete cascade,
  license_paid boolean not null default false,
  updated_at timestamptz not null default now()
);
create index season_player_licenses_club_id_idx
  on public.season_player_licenses(club_id);

create table public.season_player_expense_payments (
  expense_id uuid not null
    references public.club_license_expenses(id) on delete cascade,
  season_player_id uuid not null
    references public.season_players(id) on delete cascade,
  club_id uuid not null default private.current_club_id()
    references public.clubs(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (expense_id, season_player_id)
);
create index season_player_expense_payments_club_id_idx
  on public.season_player_expense_payments(club_id);
create index season_player_expense_payments_player_idx
  on public.season_player_expense_payments(season_player_id);

comment on table public.club_license_expenses is
  'Autres dépenses demandées par le club en plus de la licence (nom libre).';
comment on table public.season_player_licenses is
  'Licence payée ou non, par joueur et par saison.';
comment on table public.season_player_expense_payments is
  'Une ligne = ce joueur a payé cette dépense.';

do $$
declare
  t text;
begin
  foreach t in array array[
    'club_license_expenses',
    'season_player_licenses',
    'season_player_expense_payments'
  ] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from public, anon, authenticated', t);
    execute format(
      'grant select, insert, update, delete on public.%I to authenticated, service_role', t);

    -- Seuls les administrateurs du club lisent et écrivent.
    execute format(
      'create policy %I on public.%I for all to authenticated '
      'using (club_id = (select private.current_club_id()) and (select private.is_admin())) '
      'with check (club_id = (select private.current_club_id()) and (select private.is_admin()))',
      t || '_admin_all', t);

    -- Défense en profondeur : aucune future politique ne peut ouvrir un autre club.
    execute format(
      'create policy club_isolation on public.%I as restrictive for all to authenticated '
      'using (club_id = (select private.current_club_id())) '
      'with check (club_id = (select private.current_club_id()))', t);

    -- Socle de sécurité de toutes les tables métier.
    execute format(
      'create policy active_authenticated_profile_only on public.%I as restrictive for all to authenticated '
      'using ((select private.is_active_profile())) '
      'with check ((select private.is_active_profile()))', t);
  end loop;
end $$;

-- Un paiement ne peut viser qu'une dépense et un joueur du même club.
create function private.check_expense_payment_same_club()
returns trigger
language plpgsql
set search_path to ''
as $$
begin
  if not exists (
       select 1 from public.club_license_expenses e
       where e.id = new.expense_id and e.club_id = new.club_id)
     or not exists (
       select 1 from public.season_players sp
       where sp.id = new.season_player_id and sp.club_id = new.club_id) then
    raise exception 'Dépense ou joueur d''un autre club.' using errcode = '42501';
  end if;
  return new;
end;
$$;
revoke all on function private.check_expense_payment_same_club() from public;

create trigger season_player_expense_payments_same_club
before insert or update on public.season_player_expense_payments
for each row execute function private.check_expense_payment_same_club();

create function private.check_license_same_club()
returns trigger
language plpgsql
set search_path to ''
as $$
begin
  if not exists (
       select 1 from public.season_players sp
       where sp.id = new.season_player_id and sp.club_id = new.club_id) then
    raise exception 'Joueur d''un autre club.' using errcode = '42501';
  end if;
  return new;
end;
$$;
revoke all on function private.check_license_same_club() from public;

create trigger season_player_licenses_same_club
before insert or update on public.season_player_licenses
for each row execute function private.check_license_same_club();
