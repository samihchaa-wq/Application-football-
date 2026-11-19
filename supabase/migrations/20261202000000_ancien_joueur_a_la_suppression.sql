-- Noms des anciens joueurs, sur le modèle des applis de club courantes.
--
-- Règles (décision de l'éditeur du 19/11/2026) :
--   1. un joueur qui quitte le club garde son nom dans l'historique ; rien ne
--      le modifie automatiquement (inchangé : seul le départ du club ne touche
--      à aucun nom) ;
--   2. quand un membre supprime son compte, son nom devient « Ancien joueur »
--      partout dans l'historique (au lieu d'être raccourci en « Yves D. »), et
--      sa photo de joueur est effacée ; ses autres données personnelles
--      disparaissent avec le compte (e-mail, téléphone, date de naissance…) ;
--   3. chaque ancien joueur reste une fiche distincte : le deuxième ancien
--      joueur d'un même club s'appelle « Ancien joueur 2 », pour que les
--      statistiques de deux anciens joueurs ne se mélangent jamais (les
--      feuilles de match historiques retrouvent un joueur par son nom écrit) ;
--   4. les invités ne changent pas.
--
-- L'écran « Anciens joueurs » est retiré de l'appli : ses deux fonctions ne
-- sont plus appelables depuis l'appli (elles restent en place, sans droit).
-- L'éditeur anonymise un joueur à la main, sur demande, avec
-- private.anonymize_player(id) depuis l'éditeur SQL de Supabase.

-- ---------------------------------------------------------------------------
-- 1. Suppression d'un compte : « Ancien joueur » et photo effacée
-- ---------------------------------------------------------------------------

-- Remplace la version de 20261129020000 : seule la partie « nom de joueur »
-- change (« Ancien joueur » au lieu de « Yves D. », photo effacée).
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

comment on function private.prepare_profile_for_hard_deletion(uuid) is
  'Avant l''effacement d''un compte : remplace son nom de joueur par « Ancien joueur », efface sa photo et ses données propres, vide ses traces d''auteur.';

-- ---------------------------------------------------------------------------
-- 2. Anonymisation à la main, par l'éditeur
-- ---------------------------------------------------------------------------

-- Remplace le nom d'un joueur par « Ancien joueur » partout dans l'historique
-- de son club et efface sa photo de joueur. Pour une demande reçue par
-- e-mail. Exécution réservée au propriétaire de la base (éditeur SQL de
-- Supabase) : aucun compte de l'appli, ni la clé de service, ne peut
-- l'appeler. Renvoie le nouveau nom.
--
--   select id, display_name from public.players where display_name ilike '%dujardin%';
--   select private.anonymize_player('<id trouvé ci-dessus>');
create function private.anonymize_player(p_player_id uuid) returns text
language plpgsql
set search_path to ''
as $$
declare
  v_club uuid;
  v_name text;
begin
  select club_id into v_club from public.players where id = p_player_id;
  if v_club is null then
    raise exception 'Joueur introuvable : %', p_player_id using errcode = 'P0002';
  end if;
  -- Le traitement agit dans le club du joueur, pour cette transaction.
  perform set_config('app.club_id', v_club::text, true);
  perform set_config('as_grinta.allow_postmatch_composition_write', 'on', true);
  v_name := private.rename_player_everywhere(p_player_id, 'anonymous');
  update public.season_players set photo_url = null
  where player_id = p_player_id and photo_url is not null;
  return v_name;
end;
$$;

revoke all on function private.anonymize_player(uuid)
  from public, anon, authenticated, service_role;

comment on function private.anonymize_player(uuid) is
  'Remplace le nom d''un joueur par « Ancien joueur » dans tout l''historique de son club et efface sa photo. Éditeur SQL de Supabase uniquement.';

-- ---------------------------------------------------------------------------
-- 3. L'écran « Anciens joueurs » est retiré : ses fonctions sont fermées
-- ---------------------------------------------------------------------------

revoke execute on function public.admin_list_former_players() from authenticated;
revoke execute on function public.admin_rename_former_player(uuid, text) from authenticated;

-- ---------------------------------------------------------------------------
-- 4. Rattrapage : noms déjà raccourcis (« Yves D. »)
-- ---------------------------------------------------------------------------

-- Joueurs raccourcis par l'ancien traitement (suppression de compte ou
-- écran « Anciens joueurs »), d'après sa trace. Le 19/11/2026, la base
-- commerciale n'en comptait aucun (vérifié en lecture seule) ; la boucle ne
-- fait alors rien.
do $$
declare
  v_player record;
begin
  for v_player in
    select distinct player.id, player.club_id
    from private.sport_admin_audit_log trace
    join public.players player on player.id::text = trace.metadata ->> 'player_id'
    where trace.action = 'rename_former_player'
      and trace.metadata ->> 'mode' = 'short'
      -- Jamais un membre qui a (de nouveau) un compte actif.
      and not exists (
        select 1 from public.profiles profile
        where profile.player_id = player.id and profile.status = 'active'
      )
      and not exists (
        select 1 from public.season_players season_player
        join public.profiles profile on profile.id = season_player.profile_id
        where season_player.player_id = player.id and profile.status = 'active'
      )
  loop
    perform set_config('app.club_id', v_player.club_id::text, true);
    perform set_config('as_grinta.allow_postmatch_composition_write', 'on', true);
    perform private.rename_player_everywhere(v_player.id, 'anonymous');
    update public.season_players set photo_url = null
    where player_id = v_player.id and photo_url is not null;
  end loop;
end;
$$;
