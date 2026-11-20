-- Démo en ligne : comptes partagés protégés.
--
-- Les comptes « demoadmin » et « demojoueur » sont donnés aux prospects. Avant
-- cette migration, n'importe quel visiteur pouvait supprimer le compte de
-- démo ou changer son mot de passe, et tous les suivants trouvaient une démo
-- cassée. Les modifications ordinaires (matchs, joueurs, réglages) restent
-- possibles pour que la démo soit vivante : le script de démo remet tout à
-- neuf chaque nuit (workflow « Démo : remise à zéro »).
--
-- Bloqué côté serveur pour les comptes de démo (identifiants fixes
-- de000000-0000-4000-8000-…) :
--   * changement de mot de passe (par le compte lui-même ou par un admin) ;
--   * suppression du compte (préparation et effacement Auth).
-- Seul le script de démo lève ce verrou, pour sa propre transaction
-- (set_config('pf.demo_reset', 'on', true)).

create or replace function private.is_demo_profile(p_profile_id uuid)
returns boolean
language sql
immutable
set search_path to ''
as $$
  select p_profile_id is not null
     and p_profile_id::text like 'de000000-0000-4000-8000-%';
$$;

revoke all on function private.is_demo_profile(uuid) from public, anon, authenticated;
grant execute on function private.is_demo_profile(uuid) to club_scope, service_role;

comment on function private.is_demo_profile(uuid) is
  'Vrai pour les comptes du club de démonstration (identifiants fixes posés par supabase/demo/club_demo.sql).';

create or replace function private.guard_demo_auth_user()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
begin
  if coalesce(current_setting('pf.demo_reset', true), '') = 'on' then
    return case when tg_op = 'DELETE' then old else new end;
  end if;
  if tg_op = 'DELETE' then
    raise exception 'Les comptes de démonstration ne peuvent pas être supprimés.'
      using errcode = '42501';
  end if;
  if new.encrypted_password is distinct from old.encrypted_password then
    raise exception 'Le mot de passe d''un compte de démonstration ne peut pas être changé.'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

alter function private.guard_demo_auth_user() owner to club_scope;
revoke all on function private.guard_demo_auth_user() from public, anon, authenticated;

drop trigger if exists guard_demo_auth_user_update on auth.users;
create trigger guard_demo_auth_user_update
  before update of encrypted_password on auth.users
  for each row
  when (old.id::text like 'de000000-0000-4000-8000-%')
  execute function private.guard_demo_auth_user();

drop trigger if exists guard_demo_auth_user_delete on auth.users;
create trigger guard_demo_auth_user_delete
  before delete on auth.users
  for each row
  when (old.id::text like 'de000000-0000-4000-8000-%')
  execute function private.guard_demo_auth_user();

-- Préparation de la suppression : reprise à l'identique de
-- 20261202000000_ancien_joueur_a_la_suppression.sql, avec le verrou des
-- comptes de démo AVANT toute modification (sinon le compte serait renommé
-- « Ancien joueur » puis l'effacement Auth refusé).
create or replace function private.prepare_profile_for_hard_deletion(p_profile_id uuid)
returns void
language plpgsql security definer
set search_path to ''
as $$
declare
  v_player_id uuid;
begin
  if p_profile_id is null then
    raise exception 'Profile id is required' using errcode = '22023';
  end if;
  if p_profile_id = '00000000-0000-0000-0000-000000000001'::uuid then
    raise exception 'Technical profile cannot be deleted' using errcode = '22023';
  end if;
  -- Comptes de démonstration : partagés entre prospects, jamais supprimés
  -- depuis l'application (remis à neuf chaque nuit par le script de démo).
  if private.is_demo_profile(p_profile_id)
     and coalesce(current_setting('pf.demo_reset', true), '') <> 'on' then
    raise exception 'Les comptes de démonstration ne peuvent pas être supprimés.'
      using errcode = '42501';
  end if;

  -- Le joueur reste dans l'historique du club sous le nom « Ancien joueur »
  -- (politique de confidentialité), sa photo est effacée. Un échec ici ne
  -- doit jamais empêcher l'effacement du compte : l'éditeur peut alors
  -- anonymiser le joueur à la main (private.anonymize_player).
  for v_player_id in
    select distinct linked.player_id
    from (
      select profile.player_id from public.profiles profile
      where profile.id = p_profile_id and profile.player_id is not null
      union
      select season_player.player_id from public.season_players season_player
      where season_player.profile_id = p_profile_id
    ) linked
  loop
    begin
      perform private.rename_player_everywhere(v_player_id, 'anonymous');
      update public.season_players set photo_url = null
      where player_id = v_player_id and photo_url is not null;
    exception when others then
      raise warning 'Joueur % non anonymisé : % (%)', v_player_id, sqlerrm, sqlstate;
    end;
  end loop;

  -- Données propres au compte : effacées.
  delete from public.sport_availability_notification_events
  where profile_id = p_profile_id;
  delete from public.match_sport_motm_votes
  where voter_profile_id = p_profile_id;

  -- Traces d'auteur : vidées (« compte supprimé »).
  perform set_config('as_grinta.allow_postmatch_composition_write', 'on', true);

  update private.sport_admin_audit_log set actor_profile_id = null
  where actor_profile_id = p_profile_id;
  update public.guest_players set created_by = null where created_by = p_profile_id;
  update public.guest_players set updated_by = null where updated_by = p_profile_id;
  update public.match_composition_publications set published_by = null
  where published_by = p_profile_id;
  update public.match_compositions set last_modified_by = null
  where last_modified_by = p_profile_id;
  update public.match_compositions set published_by = null
  where published_by = p_profile_id;
  update public.match_sport_finalization_versions set created_by = null
  where created_by = p_profile_id;
  update public.match_sport_finalizations set validated_by = null
  where validated_by = p_profile_id;
  update public.match_sport_finalizations set corrected_by = null
  where corrected_by = p_profile_id;
  update public.match_sport_workflows set created_by = null where created_by = p_profile_id;
  update public.match_sport_workflows set updated_by = null where updated_by = p_profile_id;
  update public.sport_waitlist_entries set created_by = null where created_by = p_profile_id;
  update public.sport_waitlist_entries set updated_by = null where updated_by = p_profile_id;
  update public.match_live_events set created_by = null where created_by = p_profile_id;
  update public.match_live_sessions set updated_by = null where updated_by = p_profile_id;
  update public.matches set created_by = null where created_by = p_profile_id;
end;
$$;
