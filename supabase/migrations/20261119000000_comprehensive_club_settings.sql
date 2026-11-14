-- Extension additive des réglages : aucune valeur existante n’est modifiée.
-- Défauts = comportement antérieur. Seules les commandes futures sont bloquées ;
-- les événements, les attributions et les statistiques passés sont conservés.

create or replace function private.club_rule_catalogue()
returns table (
  key text,
  label text,
  description text,
  unit text,
  group_label text,
  default_value integer,
  min_value integer,
  max_value integer,
  sort_order integer
)
language sql immutable
set search_path to ''
as $$
  select * from (values
    ('features_open_days', 'Ouverture avant le match',
     'Combien de jours avant le coup d’envoi s’ouvrent les disponibilités, la composition et les pronostics.',
     'jours', 'Avant le match', 6, 1, 21, 10),
    ('features_open_hour', 'Heure d’ouverture',
     'Heure (en France) à laquelle ils s’ouvrent ce jour-là.',
     'h', 'Avant le match', 12, 0, 23, 20),
    ('prediction_close_minutes', 'Fermeture des pronostics',
     'Combien de minutes avant le coup d’envoi les pronostics se ferment (et le mode live s’ouvre).',
     'min', 'Pronostics', 15, 0, 240, 30),
    ('prediction_reminder_hour', 'Heure du rappel de pronostic',
     'Heure (en France) du rappel envoyé le jour du match à ceux qui n’ont pas pronostiqué.',
     'h', 'Pronostics', 16, 0, 23, 40),
    ('prediction_reminder_lead_minutes', 'Rappel avant un match tôt',
     'Si le match commence avant l’heure du rappel, le rappel part ce nombre de minutes avant la fermeture des pronostics.',
     'min', 'Pronostics', 60, 15, 600, 45),
    ('motm_window_hours', 'Durée du vote de l’Étoile du match',
     'Combien d’heures après le coup d’envoi le vote reste ouvert.',
     'h', 'Après le match', 24, 6, 168, 50),
    ('correction_window_hours', 'Délai de correction du résultat',
     'Combien d’heures après sa validation le résultat peut encore être corrigé.',
     'h', 'Après le match', 24, 1, 168, 60),
    ('waitlist_mode', 'Liste d’attente : qui passe en premier',
     'Quand il y a plus de disponibles que de places : par présence l’an dernier, par ordre d’arrivée, ou par choix de l’administrateur.',
     'mode', 'Liste d’attente', 0, 0, 2, 65),
    ('waitlist_cutoff_days', 'Liste d’attente : jour limite',
     'Combien de jours avant le match la liste d’attente cesse de créditer des places (0 = le jour même).',
     'jours', 'Liste d’attente', 1, 0, 7, 70),
    ('waitlist_cutoff_hour', 'Liste d’attente : heure limite',
     'Heure (en France) de ce jour limite.',
     'h', 'Liste d’attente', 12, 0, 23, 80),
    ('prediction_points_exact', 'Barème : score exact',
     'La cote du bon résultat est multipliée par ce nombre quand le score exact est trouvé. S’applique aussi aux matchs déjà joués.',
     '×', 'Barème des pronostics', 20, 0, 50, 90),
    ('prediction_points_goal_difference', 'Barème : bon écart de buts',
     'Bon vainqueur (ou match nul) avec le bon écart de buts, sans le score exact. S’applique aussi aux matchs déjà joués.',
     '×', 'Barème des pronostics', 15, 0, 50, 91),
    ('prediction_points_one_score', 'Barème : un des deux scores',
     'Bon vainqueur et le bon nombre de buts d’une des deux équipes. S’applique aussi aux matchs déjà joués.',
     '×', 'Barème des pronostics', 15, 0, 50, 92),
    ('prediction_points_winner', 'Barème : bon vainqueur seulement',
     'Bon vainqueur, sans autre précision juste. S’applique aussi aux matchs déjà joués.',
     '×', 'Barème des pronostics', 10, 0, 50, 93),
    ('notify_prediction_reminder', 'Notification : rappel de pronostic',
     'Rappeler le jour du match à ceux qui n’ont pas encore pronostiqué.',
     'bool', 'Notifications', 1, 0, 1, 39),
    ('notify_availability_open', 'Notification : disponibilités ouvertes',
     'Prévenir les joueurs quand ils peuvent dire s’ils sont disponibles pour un match.',
     'bool', 'Notifications', 1, 0, 1, 21),
    ('notify_availability_reminders', 'Notification : relances des disponibilités',
     'Relancer à J-3 et à J-1 ceux qui n’ont pas encore répondu.',
     'bool', 'Notifications', 1, 0, 1, 22),
    ('motm_self_vote', 'Étoile du match : voter pour soi',
     'Autoriser un joueur à voter pour lui-même. Interdit par défaut.',
     'bool', 'Étoile du match', 0, 0, 1, 51),
    ('notify_motm_open', 'Notification : vote de l’Étoile du match',
     'Prévenir les votants quand le vote s’ouvre.',
     'bool', 'Notifications', 1, 0, 1, 52),
    ('notify_motm_result', 'Notification : résultat de l’Étoile du match',
     'Annoncer le résultat du vote à l’équipe et au gagnant.',
     'bool', 'Notifications', 1, 0, 1, 53),
    ('notify_convocation', 'Notification : convocation et liste d’attente',
     'Prévenir un joueur quand il passe de la liste d’attente aux convoqués, ou l’inverse.',
     'bool', 'Notifications', 1, 0, 1, 66),
    ('notify_composition', 'Notification : composition publiée',
     'Prévenir les convoqués quand la composition est publiée.',
     'bool', 'Notifications', 1, 0, 1, 67),
    ('odds_mode', 'Cotes des pronostics',
     'Calculées automatiquement d’après les résultats du club, ou sans cotes : un pronostic rapporte alors seulement le multiplicateur du barème (score exact = 2 points par défaut). S’applique aux prochains matchs.',
     'mode', 'Cotes', 0, 0, 1, 94),
    ('odds_draw_factor', 'Cotes : poids du match nul',
     'Plus ce nombre est grand, plus la cote du match nul est haute (il rapporte plus de points). S’applique aux prochains matchs.',
     '×', 'Cotes', 15, 10, 30, 95),
    ('odds_form_memory_days', 'Cotes : mémoire de la forme',
     'Au bout de combien de jours un résultat compte deux fois moins dans la forme du moment de l’équipe. S’applique aux prochains matchs.',
     'jours', 'Cotes', 180, 30, 720, 96),
    ('odds_h2h_memory_days', 'Cotes : mémoire des confrontations',
     'Au bout de combien de jours un match contre le même adversaire compte deux fois moins. S’applique aux prochains matchs.',
     'jours', 'Cotes', 900, 90, 3600, 97),
    ('match_duration_minutes', 'Durée d’un match',
     'Temps de jeu prévu (90 min pour deux mi-temps de 45 min). Proposé pour chaque nouveau match et à l’ouverture du direct, modifiable à chaque match.',
     'min', 'Matchs', 90, 20, 120, 120),
    ('live_pilot_mode', 'Direct : qui le pilote',
     'Le coach de la saison seulement, ou aussi les administrateurs. Utile si le club n’a pas désigné de coach.',
     'mode', 'Mode live', 0, 0, 1, 121),
    ('notify_live_kickoff', 'Notification : coup d’envoi et fin du match',
     'Pendant le direct, prévenir au coup d’envoi et au coup de sifflet final.',
     'bool', 'Notifications', 1, 0, 1, 122),
    ('notify_live_goals', 'Notification : buts en direct',
     'Pendant le direct, prévenir à chaque but marqué ou encaissé.',
     'bool', 'Notifications', 1, 0, 1, 123),
    ('notify_match_changes', 'Notification : match annulé ou déplacé',
     'Prévenir les membres quand un match est annulé ou change de date ou d’heure.',
     'bool', 'Notifications', 1, 0, 1, 124),
    ('notify_badges', 'Notification : badge débloqué',
     'Prévenir un joueur quand il gagne un badge.',
     'bool', 'Notifications', 1, 0, 1, 131),
    ('wrapped_music', 'Bilan de saison : musique',
     'Jouer la musique pendant le bilan de fin de saison. Chaque joueur peut toujours couper le son.',
     'bool', 'Bilan de saison', 1, 0, 1, 132),
    ('notify_admin_signups', 'Notification : nouvelle inscription',
     'Prévenir les administrateurs quand un nouveau compte attend leur validation.',
     'bool', 'Notifications', 1, 0, 1, 140)
,
    ('live_substitutions', 'Direct : remplacements', 'Autoriser les remplacements et les salves pendant le direct. Les événements déjà enregistrés restent conservés.', 'bool', 'live', 1, 0, 1, 200),
    ('live_formation_changes', 'Direct : changer de dispositif', 'Autoriser le changement de dispositif et le repositionnement des joueurs pendant le direct.', 'bool', 'live', 1, 0, 1, 201),
    ('live_add_players', 'Direct : ajouter des joueurs', 'Autoriser les ajouts tardifs à la feuille du direct. Ils entrent sur le banc.', 'bool', 'live', 1, 0, 1, 202),
    ('live_remove_players', 'Direct : retirer du banc', 'Autoriser le retrait d’un joueur du banc pendant le direct.', 'bool', 'live', 1, 0, 1, 203),
    ('live_scorers', 'Direct : saisir les buteurs', 'Autoriser l’attribution des buts aux joueurs. Désactiver ne supprime aucune attribution existante ; le score reste saisissable.', 'bool', 'live', 1, 0, 1, 204),
    ('live_assists', 'Direct : saisir les passeurs', 'Proposer et enregistrer les passes décisives. Nécessite la saisie des buteurs ; les anciennes passes sont conservées.', 'bool', 'live', 1, 0, 1, 205),
    ('live_own_goals', 'Direct : CSC adverses', 'Autoriser l’attribution d’un but à un contre-son-camp adverse. Le score reste saisissable sans attribution.', 'bool', 'live', 1, 0, 1, 206),
    ('live_event_deletion', 'Direct : corriger par suppression', 'Autoriser la suppression d’un événement et la diminution du score. Les ajouts restent possibles.', 'bool', 'live', 1, 0, 1, 207),
    ('live_restart', 'Direct : recommencer le match', 'Autoriser la commande de remise à zéro du direct, toujours soumise à confirmation et impossible après export.', 'bool', 'live', 1, 0, 1, 208),
    ('live_takeover', 'Direct : reprendre la main', 'Autoriser un coach habilité à reprendre la main à un autre téléphone. Le pilote unique et les contrôles de rôle restent obligatoires.', 'bool', 'live', 1, 0, 1, 209),
    ('live_pause', 'Direct : mettre le chrono en pause', 'Autoriser les pauses manuelles du chrono. La reprise et les commandes de mi-temps et de fin restent disponibles.', 'bool', 'live', 1, 0, 1, 210),
    ('live_show_playing_time', 'Direct : temps de jeu affichés', 'Afficher les minutes de jeu près du prénom sur le terrain du coach. Le calcul et l’historique sont toujours conservés.', 'bool', 'live', 1, 0, 1, 211),
    ('live_show_bench_counts', 'Direct : compteurs de passages', 'Afficher les repères de passages sur le banc et sur le terrain du coach. Aucun compteur enregistré n’est effacé.', 'bool', 'live', 1, 0, 1, 212),
    ('live_next_out', 'Direct : suggérer les prochaines sorties', 'Colorer les prénoms des joueurs proposés à la prochaine rotation. Le coach garde le choix des remplacements.', 'bool', 'live', 1, 0, 1, 213),
    ('live_names_only', 'Direct : prénoms sans portraits', 'Sur le tableau du coach, afficher les prénoms à la place des portraits sur le terrain et le banc.', 'bool', 'live', 0, 0, 1, 214),
    ('live_journal_expanded', 'Direct : journal du coach déplié', 'Ouvrir par défaut le journal complet du coach. Il peut toujours le replier pendant le match.', 'bool', 'live', 0, 0, 1, 215),
    ('live_substitution_colors', 'Direct : couleurs des salves', 'Colorer les salves du journal et les compteurs de passages. Les repères restent lisibles sans couleurs.', 'bool', 'live', 1, 0, 1, 216),
    ('composition_simulation', 'Composition : aide à la simulation', 'Proposer à l’administrateur une composition simulée. La sélection et l’enregistrement manuels restent disponibles.', 'bool', 'composition', 1, 0, 1, 217),
    ('composition_video', 'Composition : animation vidéo', 'Proposer l’animation de présentation aux joueurs et aux administrateurs. La composition fixe reste visible.', 'bool', 'composition', 1, 0, 1, 218),
    ('composition_video_autoplay', 'Vidéo : lancement automatique', 'Lancer la vidéo à la première visite après publication. Si coupé, la vidéo reste consultable avec son bouton.', 'bool', 'composition', 1, 0, 1, 219),
    ('composition_video_notification_replay', 'Vidéo : rejouer depuis la notification', 'Relancer une vidéo déjà vue si la composition est ouverte depuis sa notification. Dépend du lancement automatique.', 'bool', 'composition', 1, 0, 1, 220),
    ('notify_availability_j3', 'Relance disponibilité à J-3', 'Envoyer la relance à trois jours du match. Dépend aussi de l’interrupteur général des relances de disponibilité.', 'bool', 'squad', 1, 0, 1, 221),
    ('notify_availability_j1', 'Relance disponibilité à J-1', 'Envoyer la relance la veille du match. Dépend aussi de l’interrupteur général des relances de disponibilité.', 'bool', 'squad', 1, 0, 1, 222),
    ('notify_live_full_time', 'Notification : fin du direct', 'Annoncer la fin du match. Dépend aussi de l’interrupteur coup d’envoi et fin du match.', 'bool', 'live', 1, 0, 1, 223),
    ('notify_live_goal_us', 'Notification : buts marqués', 'Notifier les buts du club. Dépend aussi de l’interrupteur des buts en direct.', 'bool', 'live', 1, 0, 1, 224),
    ('notify_live_goal_them', 'Notification : buts encaissés', 'Notifier les buts adverses. Dépend aussi de l’interrupteur des buts en direct.', 'bool', 'live', 1, 0, 1, 225),
    ('notify_match_cancelled', 'Notification : annulation', 'Notifier les annulations de matchs. Dépend aussi de l’interrupteur match annulé ou déplacé.', 'bool', 'matches', 1, 0, 1, 226),
    ('notify_match_rescheduled_date', 'Notification : changement de date', 'Notifier les changements de date des matchs. Dépend aussi de l’interrupteur match annulé ou déplacé.', 'bool', 'matches', 1, 0, 1, 227),
    ('notify_match_rescheduled_time', 'Notification : changement d’horaire', 'Notifier les changements d’heure des matchs. Dépend aussi de l’interrupteur match annulé ou déplacé.', 'bool', 'matches', 1, 0, 1, 228),
    ('notify_convocation_promoted', 'Notification : promotion en convoqué', 'Notifier le passage de la liste d’attente aux convoqués. Dépend aussi de l’interrupteur convocation et liste d’attente.', 'bool', 'squad', 1, 0, 1, 229),
    ('notify_convocation_demoted', 'Notification : passage en attente', 'Notifier le passage des convoqués à la liste d’attente. Dépend aussi de l’interrupteur convocation et liste d’attente.', 'bool', 'squad', 1, 0, 1, 230),
    ('notify_motm_winner', 'Étoile : notification au gagnant', 'Envoyer le message personnel au gagnant. L’annonce générale dépend du réglage résultat de l’Étoile du match.', 'bool', 'rewards', 1, 0, 1, 231)
  ) as catalogue(key, label, description, unit, group_label,
                 default_value, min_value, max_value, sort_order);
$$;

-- Les fonctions RPC conservent leurs contrôles de rôle, de pilote, de
-- session et de club. Ce contrôle supplémentaire ne donne aucun droit.
create function private.require_club_feature(p_key text) returns void
language plpgsql stable
set search_path to ''
as $$
begin
  if private.club_rule(p_key) is distinct from 1 then
    raise exception 'Cette action est désactivée dans les réglages du club (%).', p_key
      using errcode = '42501';
  end if;
end;
$$;
alter function private.require_club_feature(text) owner to club_scope;
revoke all on function private.require_club_feature(text) from public, anon, authenticated;
grant execute on function private.require_club_feature(text) to club_scope, service_role;

-- Vérifie aussi les variations de zones : impossible de contourner la règle
-- de remplacement en envoyant une composition sans p_substitution.
create function private.require_live_lineup_features(p_match_id uuid, p_entries jsonb)
returns void language plpgsql stable security definer
set search_path to ''
as $$
begin
  if jsonb_typeof(p_entries) is distinct from 'array' then
    raise exception 'Lineup entries must be a JSON array' using errcode = '22023';
  end if;
  if exists (
    select 1 from public.match_composition_entries old_entry
    join jsonb_array_elements(p_entries) item
      on item ->> 'participant_id' = old_entry.participant_id::text
    where old_entry.match_id = p_match_id
      and old_entry.zone in ('field', 'bench')
      and item ->> 'zone' in ('field', 'bench')
      and item ->> 'zone' <> old_entry.zone::text
  ) then
    perform private.require_club_feature('live_substitutions');
  end if;
  if exists (
    select 1 from public.match_composition_entries old_entry
    where old_entry.match_id = p_match_id and old_entry.zone in ('field', 'bench')
      and not exists (
        select 1 from jsonb_array_elements(p_entries) item
        where item ->> 'participant_id' = old_entry.participant_id::text
          and item ->> 'zone' in ('field', 'bench')
      )
  ) then
    perform private.require_club_feature('live_remove_players');
  end if;
  if exists (
    select 1 from jsonb_array_elements(p_entries) item
    left join public.match_composition_entries old_entry
      on old_entry.match_id = p_match_id
      and old_entry.participant_id::text = item ->> 'participant_id'
    where item ->> 'zone' in ('field', 'bench')
      and (old_entry.zone is null or old_entry.zone not in ('field', 'bench'))
  ) then
    perform private.require_club_feature('live_add_players');
  end if;
  if exists (
    select 1 from public.match_composition_entries old_entry
    join jsonb_array_elements(p_entries) item
      on item ->> 'participant_id' = old_entry.participant_id::text
    where old_entry.match_id = p_match_id and old_entry.zone = 'field'
      and item ->> 'zone' = 'field'
      and (old_entry.x is distinct from (item ->> 'x')::numeric
        or old_entry.y is distinct from (item ->> 'y')::numeric
        or old_entry.slot_label is distinct from (item ->> 'slot_label'))
  ) then
    perform private.require_club_feature('live_formation_changes');
  end if;
end;
$$;
alter function private.require_live_lineup_features(uuid,jsonb) owner to club_scope;
revoke all on function private.require_live_lineup_features(uuid,jsonb) from public, anon, authenticated;
grant execute on function private.require_live_lineup_features(uuid,jsonb) to club_scope, service_role;

CREATE OR REPLACE FUNCTION "public"."coach_add_match_live_players"("p_match_id" "uuid", "p_players" "jsonb", "p_reason" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_state public.match_live_state;
  v_before_selected uuid[];
  v_added_bench_baseline jsonb;
begin
  if not private.is_active_profile() then
    raise exception 'Active profile required' using errcode = '42501';
  end if;
  perform private.require_match_live_pilot(p_match_id);
  perform private.require_club_feature('live_add_players');

  select session.state
  into v_state
  from public.match_live_sessions session
  where session.match_id = p_match_id
  for update;

  select coalesce(array_agg(entry.participant_id), array[]::uuid[])
  into v_before_selected
  from public.match_composition_entries entry
  where entry.match_id = p_match_id
    and entry.zone in ('field', 'bench');

  perform private.add_match_live_players(p_match_id, p_players, p_reason);

  if v_state in ('running', 'paused', 'halftime') then
    select coalesce(
      jsonb_object_agg(entry.participant_id::text, 'bench'::text),
      '{}'::jsonb
    )
    into v_added_bench_baseline
    from public.match_composition_entries entry
    join public.match_live_sessions session on session.match_id = entry.match_id
    where entry.match_id = p_match_id
      and entry.zone = 'bench'
      and not (entry.participant_id = any(v_before_selected))
      and not (
        coalesce(session.starting_lineup_snapshot, '{}'::jsonb)
        ? entry.participant_id::text
      );

    if v_added_bench_baseline <> '{}'::jsonb then
      update public.match_live_sessions session
      set starting_lineup_snapshot =
            coalesce(session.starting_lineup_snapshot, '{}'::jsonb)
            || v_added_bench_baseline,
          updated_at = now()
      where session.match_id = p_match_id;
    end if;
  end if;

  return public.get_match_live_state(p_match_id);
end;
$$;

CREATE OR REPLACE FUNCTION "public"."coach_change_match_live_formation"("p_match_id" "uuid", "p_formation_code" "text", "p_entries" "jsonb", "p_expected_lineup_revision" integer) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_actor uuid := (select private.uid());
  v_formation_code text := nullif(btrim(p_formation_code), '');
begin
  if v_actor is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  perform private.require_match_live_pilot(p_match_id);
  perform private.require_club_feature('live_formation_changes');
  perform private.require_live_lineup_features(p_match_id, p_entries);

  if v_formation_code is null or char_length(v_formation_code) > 32 then
    raise exception 'Invalid formation code' using errcode = '22023';
  end if;

  perform private.save_match_live_lineup_versioned(
    p_match_id,
    p_entries,
    null::jsonb,
    p_expected_lineup_revision
  );

  update public.match_compositions
  set formation_code = v_formation_code,
      last_modified_at = now(),
      last_modified_by = v_actor
  where match_id = p_match_id;

  if not found then
    raise exception 'Match composition not found' using errcode = 'P0002';
  end if;

  return public.get_match_live_state(p_match_id);
end;
$$;

CREATE OR REPLACE FUNCTION "public"."coach_delete_match_live_event"("p_match_id" "uuid", "p_event_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
begin
  if not private.is_active_profile() then
    raise exception 'Active profile required' using errcode = '42501';
  end if;
  perform private.require_match_live_pilot(p_match_id);
  perform private.require_club_feature('live_event_deletion');
  perform private.delete_match_live_event(p_match_id, p_event_id);
  return public.get_match_live_state(p_match_id);
end;
$$;

CREATE OR REPLACE FUNCTION "public"."coach_restart_match_live_session"("p_match_id" "uuid", "p_reason" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
begin
  if not private.is_active_profile() then
    raise exception 'Active profile required' using errcode = '42501';
  end if;
  perform private.require_match_live_pilot(p_match_id);
  perform private.require_club_feature('live_restart');
  perform private.restart_match_live_session(p_match_id, p_reason);
  return public.get_match_live_state(p_match_id);
end;
$$;

CREATE OR REPLACE FUNCTION "public"."coach_save_match_live_lineup"("p_match_id" "uuid", "p_entries" "jsonb", "p_substitution" "jsonb", "p_expected_lineup_revision" integer) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
begin
  if (select private.uid()) is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  perform private.require_match_live_pilot(p_match_id);
  perform private.require_live_lineup_features(p_match_id, p_entries);
  if p_substitution is not null and p_substitution <> '[]'::jsonb then
    perform private.require_club_feature('live_substitutions');
  end if;
  perform private.save_match_live_lineup_versioned(
    p_match_id,
    p_entries,
    p_substitution,
    p_expected_lineup_revision
  );
  return public.get_match_live_state(p_match_id);
end;
$$;

CREATE OR REPLACE FUNCTION "public"."coach_adjust_match_live_score"("p_match_id" "uuid", "p_team" "text", "p_delta" integer, "p_scorer_participant_id" "uuid", "p_operation_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
begin
  if (select private.uid()) is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  perform private.require_match_live_pilot(p_match_id);
  if p_delta < 0 then
    perform private.require_club_feature('live_event_deletion');
  end if;
  if p_scorer_participant_id is not null then
    perform private.require_club_feature('live_scorers');
  end if;
  perform private.adjust_match_live_score_idempotent(
    p_match_id,
    p_team,
    p_delta,
    p_scorer_participant_id,
    p_operation_id
  );
  return public.get_match_live_state(p_match_id);
end;
$$;

CREATE OR REPLACE FUNCTION "public"."coach_set_match_live_clock_state"("p_match_id" "uuid", "p_action" "text", "p_reason" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
begin
  if not private.is_active_profile() then
    raise exception 'Active profile required' using errcode = '42501';
  end if;
  perform private.require_match_live_pilot(p_match_id);
  if p_action = 'pause' then
    perform private.require_club_feature('live_pause');
  end if;
  perform private.set_match_live_clock_state(p_match_id, p_action, p_reason);
  return public.get_match_live_state(p_match_id);
end;
$$;

CREATE OR REPLACE FUNCTION "public"."coach_set_match_live_event_scorer"("p_match_id" "uuid", "p_event_id" "uuid", "p_scorer_participant_id" "uuid" DEFAULT NULL::"uuid", "p_is_opponent_own_goal" boolean DEFAULT false, "p_assist_participant_id" "uuid" DEFAULT NULL::"uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
begin
  if not private.is_active_profile() then
    raise exception 'Active profile required' using errcode = '42501';
  end if;
  perform private.require_match_live_pilot(p_match_id);
  perform private.require_club_feature('live_scorers');
  if p_assist_participant_id is not null and not exists (
    select 1 from public.match_live_events e
    where e.id = p_event_id and e.match_id = p_match_id
      and e.assist_participant_id = p_assist_participant_id
  ) then
    perform private.require_club_feature('live_assists');
  end if;
  if p_is_opponent_own_goal and not exists (
    select 1 from public.match_live_events e
    where e.id = p_event_id and e.match_id = p_match_id and e.is_opponent_own_goal
  ) then
    perform private.require_club_feature('live_own_goals');
  end if;
  perform private.set_match_live_event_scorer(
    p_match_id,
    p_event_id,
    p_scorer_participant_id,
    p_is_opponent_own_goal,
    p_assist_participant_id
  );
  return public.get_match_live_state(p_match_id);
end;
$$;

CREATE OR REPLACE FUNCTION "public"."take_over_match_live_pilot"("p_match_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_actor uuid := (select private.uid());
  v_session_id uuid := private.match_live_current_session_id();
begin
  perform private.require_sports_management_enabled();
  if v_actor is null or v_session_id is null or not private.is_active_profile() then
    raise exception 'Active authenticated session required' using errcode = '42501';
  end if;
  if not private.is_match_live_pilot_coach(p_match_id) then
    raise exception 'Seul le coach peut piloter le Live.' using errcode = '42501';
  end if;

  perform private.require_club_feature('live_takeover');

  perform 1
  from public.match_live_sessions session
  where session.match_id = p_match_id
  for update;

  if not found then
    perform private.open_match_live_workspace(p_match_id, null);
    perform 1
    from public.match_live_sessions session
    where session.match_id = p_match_id
    for update;
  end if;

  update public.match_live_sessions
  set pilot_profile_id = v_actor,
      pilot_session_id = v_session_id,
      pilot_heartbeat_at = now(),
      updated_by = v_actor,
      updated_at = now()
  where match_id = p_match_id;

  return public.get_match_live_state(p_match_id);
end;
$$;

create or replace function private.club_notification_rules()
returns table (kind text, rule_key text)
language sql immutable
set search_path to ''
as $$
  select * from (values
    ('availability_open', 'notify_availability_open'),
    ('availability_manual', 'notify_availability_open'),
    ('availability_j3', 'notify_availability_reminders'),
    ('availability_j1', 'notify_availability_reminders'),
    ('convocation_promoted', 'notify_convocation'),
    ('convocation_demoted', 'notify_convocation'),
    ('composition_published', 'notify_composition'),
    ('match_cancelled', 'notify_match_changes'),
    ('match_rescheduled_date', 'notify_match_changes'),
    ('match_rescheduled_time', 'notify_match_changes'),
    ('live_kickoff', 'notify_live_kickoff'),
    ('live_full_time', 'notify_live_kickoff'),
    ('live_goal_us', 'notify_live_goals'),
    ('live_goal_them', 'notify_live_goals'),
    ('prediction_j5', 'notify_prediction_reminder'),
    ('motm_open', 'notify_motm_open'),
    ('motm_result_general', 'notify_motm_result'),
    ('motm_result_winner', 'notify_motm_result'),
    ('badge_unlocked', 'notify_badges'),
    ('admin_pending_signup', 'notify_admin_signups')
,
    ('availability_j3', 'notify_availability_j3'),
    ('availability_j1', 'notify_availability_j1'),
    ('live_full_time', 'notify_live_full_time'),
    ('live_goal_us', 'notify_live_goal_us'),
    ('live_goal_them', 'notify_live_goal_them'),
    ('match_cancelled', 'notify_match_cancelled'),
    ('match_rescheduled_date', 'notify_match_rescheduled_date'),
    ('match_rescheduled_time', 'notify_match_rescheduled_time'),
    ('convocation_promoted', 'notify_convocation_promoted'),
    ('convocation_demoted', 'notify_convocation_demoted'),
    ('motm_result_winner', 'notify_motm_winner')
  ) as mapping(kind, rule_key);
$$;

-- Un même type dépend désormais de plusieurs règles. DISTINCT empêche
-- toute duplication dans la configuration de send-push.
create or replace function private.club_disabled_notification_kinds()
returns text[] language sql stable security definer
set search_path to ''
as $$
  select coalesce(array_agg(distinct mapping.kind order by mapping.kind), '{}'::text[])
  from private.club_notification_rules() mapping
  where private.club_rule(mapping.rule_key) = 0;
$$;
