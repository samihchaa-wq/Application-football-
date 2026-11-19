-- Suppression d'un compte sans « compte technique ».
--
-- Constat du 19/11/2026 (lecture seule de la base commerciale) : la
-- suppression d'un compte (par le membre, par un administrateur, ou pour
-- inactivité) réattribuait les traces du compte (qui a créé un match, validé
-- un compte rendu, publié une composition…) à un compte technique
-- 00000000-0000-0000-0000-000000000001. Ce compte n'existe pas dans la base
-- commerciale : toute suppression échouait (« Technical replacement profile
-- is missing »), ce qui empêchait l'exercice du droit à l'effacement.
--
-- Désormais, ces traces deviennent vides (« compte supprimé ») : les colonnes
-- concernées acceptent NULL, et la suppression du profil les vide toute seule
-- (ON DELETE SET NULL) en dernier recours. La fonction de préparation les
-- vide elle-même d'abord, parce que les compositions de matchs terminés sont
-- protégées et ne se modifient qu'avec l'autorisation qu'elle pose.

-- ---------------------------------------------------------------------------
-- 1. Traces d'auteur : vides quand le compte disparaît
-- ---------------------------------------------------------------------------

do $$
declare
  v_ref record;
begin
  for v_ref in
    select * from (values
      ('private', 'sport_admin_audit_log', 'actor_profile_id', 'sport_admin_audit_log_actor_profile_id_fkey'),
      ('public', 'guest_players', 'created_by', 'guest_players_created_by_fkey'),
      ('public', 'guest_players', 'updated_by', 'guest_players_updated_by_fkey'),
      ('public', 'match_composition_publications', 'published_by', 'match_composition_publications_published_by_fkey'),
      ('public', 'match_compositions', 'last_modified_by', 'match_compositions_last_modified_by_fkey'),
      ('public', 'match_compositions', 'published_by', 'match_compositions_published_by_fkey'),
      ('public', 'match_live_events', 'created_by', 'match_live_events_created_by_fkey'),
      ('public', 'match_live_sessions', 'updated_by', 'match_live_sessions_updated_by_fkey'),
      ('public', 'match_sport_finalization_versions', 'created_by', 'match_sport_finalization_versions_created_by_fkey'),
      ('public', 'match_sport_finalizations', 'corrected_by', 'match_sport_finalizations_corrected_by_fkey'),
      ('public', 'match_sport_finalizations', 'validated_by', 'match_sport_finalizations_validated_by_fkey'),
      ('public', 'match_sport_workflows', 'created_by', 'match_sport_workflows_created_by_fkey'),
      ('public', 'match_sport_workflows', 'updated_by', 'match_sport_workflows_updated_by_fkey'),
      ('public', 'sport_waitlist_entries', 'created_by', 'sport_waitlist_entries_created_by_fkey'),
      ('public', 'sport_waitlist_entries', 'updated_by', 'sport_waitlist_entries_updated_by_fkey'),
      ('public', 'matches', 'created_by', 'matches_created_by_fkey')
    ) as refs(schema_name, table_name, column_name, constraint_name)
  loop
    execute format('alter table %I.%I alter column %I drop not null',
      v_ref.schema_name, v_ref.table_name, v_ref.column_name);
    execute format('alter table %I.%I drop constraint %I',
      v_ref.schema_name, v_ref.table_name, v_ref.constraint_name);
    execute format(
      'alter table %I.%I add constraint %I foreign key (%I) references public.profiles(id) on delete set null',
      v_ref.schema_name, v_ref.table_name, v_ref.constraint_name, v_ref.column_name);
  end loop;
end;
$$;

-- Un match créé sans auteur explicite n'est plus attribué au compte
-- technique (absent de la base commerciale) : il reste sans auteur.
alter table public.matches alter column created_by drop default;
alter table public.matches drop constraint matches_created_by_required;

-- ---------------------------------------------------------------------------
-- 2. Préparation de la suppression
-- ---------------------------------------------------------------------------

-- Remplace la version de 20261111000100_socle_structure.sql. Appelée par
-- manage-user (suppression par le membre ou par un administrateur) et par la
-- suppression des comptes inactifs, avant l'effacement du compte.
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

  -- Le nom de joueur reste dans l'historique du club, raccourci : « Yves D. »
  -- (politique de confidentialité). Un échec ici ne doit jamais empêcher
  -- l'effacement du compte : le nom reste alors entier, et un administrateur
  -- peut le raccourcir ensuite (page « Anciens joueurs »).
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
      perform private.rename_player_everywhere(v_player_id, 'short');
    exception when others then
      raise warning 'Nom du joueur % non raccourci : % (%)', v_player_id, sqlerrm, sqlstate;
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

comment on function private.prepare_profile_for_hard_deletion(uuid) is
  'Avant l''effacement d''un compte : raccourcit son nom de joueur, efface ses données propres et vide ses traces d''auteur.';
