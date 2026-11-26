-- Licences : remplace le modèle « une seule autre dépense + réglages d'attestation »
-- de 20261207000000 par des dépenses libres, ajoutables et renommables.
-- La migration précédente reste inchangée (historique immuable). Les données
-- déjà saisies sont conservées : « autre dépense payée » devient une dépense
-- nommée d'après l'ancien intitulé.

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

do $$
declare
  t text;
begin
  foreach t in array array[
    'club_license_expenses',
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

-- Reprise des données : « autre dépense payée » -> une dépense nommée.
insert into public.club_license_expenses (club_id, label)
select c.club_id, coalesce(s.other_expense_label, 'Autre dépense')
from (select distinct club_id from public.season_player_licenses where other_paid) c
left join public.club_license_settings s on s.club_id = c.club_id;

insert into public.season_player_expense_payments (expense_id, season_player_id, club_id)
select e.id, l.season_player_id, l.club_id
from public.season_player_licenses l
join public.club_license_expenses e on e.club_id = l.club_id
where l.other_paid;

alter table public.season_player_licenses
  drop column other_paid,
  drop column license_number;

drop table public.club_license_settings;

comment on table public.club_license_expenses is
  'Autres dépenses demandées par le club en plus de la licence (nom libre).';
comment on table public.season_player_expense_payments is
  'Une ligne = ce joueur a payé cette dépense.';
