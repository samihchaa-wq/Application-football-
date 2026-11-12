-- Preuve de l'acceptation du contrat par le club.
--
-- Quand une personne crée un club, elle accepte pour lui les conditions
-- d'abonnement (CGV) et l'accord sur le traitement des données des membres
-- (contrat de sous-traitance prévu par l'article 28 du RGPD). Cette table
-- garde la preuve : quel club, qui, quand, quelle version des textes.
--
-- Écrite uniquement par les fonctions serveur d'inscription (rôle
-- service_role) ; aucun accès direct depuis l'application.

create table public.club_contract_acceptances (
  id bigint generated always as identity primary key,
  club_id uuid not null references public.clubs(id) on delete cascade,
  -- La preuve reste si la personne supprime ensuite son compte.
  profile_id uuid references public.profiles(id) on delete set null,
  contract_version text not null
    constraint club_contract_acceptances_version_check
      check (contract_version ~ '^\d{4}-\d{2}-\d{2}$'),
  accepted_at timestamptz not null default now()
);

comment on table public.club_contract_acceptances is
  'Acceptation des conditions d''abonnement et de l''accord sur les données par un club.';

create index club_contract_acceptances_club_id_idx
  on public.club_contract_acceptances (club_id);
create index club_contract_acceptances_profile_id_idx
  on public.club_contract_acceptances (profile_id);

alter table public.club_contract_acceptances enable row level security;
revoke all on public.club_contract_acceptances from public, anon, authenticated;
grant all on public.club_contract_acceptances to service_role;
-- La colonne id crée une séquence, qui reçoit par défaut des droits pour
-- anon et authenticated : on les retire aussi.
revoke all on sequence public.club_contract_acceptances_id_seq
  from public, anon, authenticated;
grant usage, select on sequence public.club_contract_acceptances_id_seq
  to service_role;

create policy club_isolation on public.club_contract_acceptances
  as restrictive for all to public
  using (club_id = (select private.current_club_id()))
  with check (club_id = (select private.current_club_id()));
create policy active_authenticated_profile_only on public.club_contract_acceptances
  as restrictive for all to authenticated
  using ((select private.is_active_profile()))
  with check ((select private.is_active_profile()));
create policy deny_client_access on public.club_contract_acceptances
  as restrictive for all to anon, authenticated
  using (false) with check (false);

-- Fondation d'un club en une seule transaction : le créateur devient
-- administrateur ET la preuve d'acceptation du contrat est enregistrée, ou
-- rien n'est fait. Si l'enregistrement de la preuve échoue, la promotion est
-- annulée avec lui : le profil reste « en attente » et les fonctions serveur
-- peuvent alors supprimer le club vide (discard_empty_club). Aucun club ne
-- peut donc exister avec un administrateur actif mais sans preuve.
create function public.found_club(
  p_club_id uuid,
  p_profile_id uuid,
  p_contract_version text
) returns void
language plpgsql security definer
set search_path to ''
as $$
begin
  perform public.promote_club_founder(p_club_id, p_profile_id);

  insert into public.club_contract_acceptances (club_id, profile_id, contract_version)
  values (p_club_id, p_profile_id, p_contract_version);
end;
$$;

alter function public.found_club(uuid, uuid, text) owner to postgres;
revoke all on function public.found_club(uuid, uuid, text) from public, anon, authenticated;
grant execute on function public.found_club(uuid, uuid, text) to service_role;
