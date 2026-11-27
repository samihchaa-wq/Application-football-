-- Licences : chaque saison a ses propres dépenses (décision du 27/11/2026).
--
-- Avant : une dépense (« Survêtement »…) était commune à toutes les saisons du
-- club ; seuls les paiements dépendaient de la saison (par la fiche joueur).
-- Après : une dépense appartient à une saison. Une nouvelle saison démarre
-- sans dépense.
--
-- Reprise des données, sans perte :
--   * une dépense payée dans une seule saison est rattachée à cette saison ;
--   * une dépense payée dans plusieurs saisons est dédoublée : une copie par
--     saison, chaque paiement suit la copie de sa saison ;
--   * une dépense sans aucun paiement va dans la saison ouverte du club, sinon
--     dans sa saison la plus récente ;
--   * seul cas de suppression : une dépense d'un club qui n'a aucune saison
--     (aucun paiement n'a donc pu y être coché).
--
-- Les règles d'accès (admins du club seulement) ne changent pas.

alter table public.club_license_expenses
  add column season_id uuid references public.seasons(id) on delete cascade;

-- Couples (dépense, saison) réellement utilisés par des paiements.
create temporary table license_expense_seasons on commit drop as
select
  p.expense_id,
  sp.season_id,
  row_number() over (partition by p.expense_id order by min(s.created_at), sp.season_id) as rank,
  gen_random_uuid() as copy_id
from public.season_player_expense_payments p
join public.season_players sp on sp.id = p.season_player_id
join public.seasons s on s.id = sp.season_id
group by p.expense_id, sp.season_id;

-- La première saison garde la dépense d'origine.
update public.club_license_expenses e
set season_id = les.season_id
from license_expense_seasons les
where les.expense_id = e.id and les.rank = 1;

-- Les saisons suivantes reçoivent une copie.
insert into public.club_license_expenses (id, club_id, label, created_at, season_id)
select les.copy_id, e.club_id, e.label, e.created_at, les.season_id
from license_expense_seasons les
join public.club_license_expenses e on e.id = les.expense_id
where les.rank > 1;

-- Chaque paiement suit la copie de sa saison.
update public.season_player_expense_payments p
set expense_id = les.copy_id
from license_expense_seasons les, public.season_players sp
where les.rank > 1
  and p.expense_id = les.expense_id
  and sp.id = p.season_player_id
  and sp.season_id = les.season_id;

-- Dépenses sans paiement : saison ouverte du club, sinon la plus récente.
update public.club_license_expenses e
set season_id = (
  select s.id from public.seasons s
  where s.club_id = e.club_id
  order by (s.status = 'open') desc, s.created_at desc, s.id
  limit 1
)
where e.season_id is null;

delete from public.club_license_expenses where season_id is null;

alter table public.club_license_expenses
  alter column season_id set not null;

create index club_license_expenses_season_id_idx
  on public.club_license_expenses(season_id);

-- Une dépense ne peut viser qu'une saison de son club.
create function private.check_license_expense_season()
returns trigger
language plpgsql
set search_path to ''
as $$
begin
  -- Saison absente : la contrainte « non vide » donne l'erreur exacte.
  if new.season_id is null then
    return new;
  end if;
  if not exists (
       select 1 from public.seasons s
       where s.id = new.season_id and s.club_id = new.club_id) then
    raise exception 'Saison d''un autre club.' using errcode = '42501';
  end if;
  return new;
end;
$$;
revoke all on function private.check_license_expense_season() from public;

create trigger club_license_expenses_same_club_season
before insert or update on public.club_license_expenses
for each row execute function private.check_license_expense_season();

-- Un paiement ne peut viser qu'une dépense de la saison du joueur.
create function private.check_expense_payment_same_season()
returns trigger
language plpgsql
set search_path to ''
as $$
begin
  if not exists (
       select 1
       from public.club_license_expenses e
       join public.season_players sp on sp.season_id = e.season_id
       where e.id = new.expense_id and sp.id = new.season_player_id) then
    raise exception 'Dépense d''une autre saison.' using errcode = '23514';
  end if;
  return new;
end;
$$;
revoke all on function private.check_expense_payment_same_season() from public;

create trigger season_player_expense_payments_same_season
before insert or update on public.season_player_expense_payments
for each row execute function private.check_expense_payment_same_season();

comment on column public.club_license_expenses.season_id is
  'Saison de la dépense : chaque saison a ses propres dépenses.';
