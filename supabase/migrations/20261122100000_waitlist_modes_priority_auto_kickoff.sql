-- Petit Filet #183 : 3 modes, option de priorité et +1 toujours attribué.
-- Ne touche pas à AS Grinta original. À tester en environnement isolé.
begin;

-- Catalogue des règles par équipe, valeur par défaut ON pour compatibilité.
CREATE OR REPLACE FUNCTION private.club_rule_catalogue()
 RETURNS TABLE(key text, label text, description text, unit text, group_label text, default_value integer, min_value integer, max_value integer, sort_order integer)
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
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
     'Quand il y a plus de présents que de places : historique AS Grinta, ordre d’arrivée, ou choix de l’administrateur. La priorité des +1 est un réglage indépendant.',
     'mode', 'Liste d’attente', 0, 0, 2, 65),
    ('waitlist_priority_enabled', 'Priorité des +1',
     'Si activé, les +1 gagnés cette saison donnent priorité dans les convocations automatiques. Désactivé : sélection selon le mode choisi. Les +1 continuent toujours à être attribués au coup d’envoi.',
     'bool', 'Liste d’attente', 1, 0, 1, 66),
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
$function$;

-- Mode Historique : delta des +1 depuis point de départ, ordre initial,
-- présences passées, noms (parité AS Grinta). Option OFF ignore les crédits.
CREATE OR REPLACE FUNCTION private.rebuild_sport_waitlist_order(p_season_id uuid, p_actor uuid DEFAULT NULL::uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_offset integer;
begin
  -- Sérialiser les reclassements de la même saison.
  perform 1 from public.seasons where id = p_season_id for update;
  if not found then
    raise exception 'Season not found' using errcode = 'P0002';
  end if;

  -- Pas d'écriture quand le classement est déjà le bon.
  if not exists (
    select 1 from (
      select e.position, row_number() over (
        order by
          case when private.club_rule('waitlist_priority_enabled') = 1 then
            case when private.club_rule('waitlist_mode') = 0
              then e.manual_waitlist_count - coalesce(st.start_count, 0)
              else e.manual_waitlist_count
            end
          else 0 end,
          st.start_position nulls last,
        e.previous_season_attendance_count,
          lower(p.last_name), lower(p.first_name), e.season_player_id
      )::integer as expected
      from public.sport_waitlist_entries e
      join public.season_players p on p.id = e.season_player_id
      left join private.sport_waitlist_start st
        on st.season_id = e.season_id
       and st.season_player_id = e.season_player_id
      where e.season_id = p_season_id
    ) ranks where ranks.position <> ranks.expected
  ) then
    return;
  end if;

  -- Positions intermédiaires au-delà des anciennes : respecte
  -- UNIQUE(season_id, position) pendant la réécriture.
  select coalesce(max(position), 0) + count(*)::integer + 1
    into v_offset
  from public.sport_waitlist_entries where season_id = p_season_id;

  update public.sport_waitlist_entries
     set position = position + v_offset
   where season_id = p_season_id;

  with ranked as (
    select e.season_player_id, row_number() over (
      order by
          case when private.club_rule('waitlist_priority_enabled') = 1 then
            case when private.club_rule('waitlist_mode') = 0
              then e.manual_waitlist_count - coalesce(st.start_count, 0)
              else e.manual_waitlist_count
            end
          else 0 end,
          st.start_position nulls last,
        e.previous_season_attendance_count,
        lower(p.last_name), lower(p.first_name), e.season_player_id
    )::integer as position
    from public.sport_waitlist_entries e
    join public.season_players p on p.id = e.season_player_id
    left join private.sport_waitlist_start st
      on st.season_id = e.season_id
     and st.season_player_id = e.season_player_id
    where e.season_id = p_season_id
  )
  update public.sport_waitlist_entries e
     set position = r.position,
         updated_by = coalesce(p_actor, e.updated_by),
         updated_at = now()
    from ranked r
   where e.season_id = p_season_id
     and e.season_player_id = r.season_player_id;
end;
$function$;

CREATE OR REPLACE FUNCTION private.match_waitlist_position(p_match_id uuid, p_season_player_id uuid, p_season_position integer)
 RETURNS integer
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_rank integer;
begin
  if p_season_player_id is null
     or private.club_rule('waitlist_mode') <> 1 then
    return p_season_position;
  end if;

  select ranked.rank into v_rank
  from (
    select p.season_player_id, row_number() over (
      order by case when private.club_rule('waitlist_priority_enabled') = 1
                    then coalesce(e.manual_waitlist_count, 0)
                    else 0 end asc,
        p.availability_updated_at desc nulls first, p.id desc
    )::integer as rank
    from public.match_sport_participants p
    join public.season_players sp on sp.id = p.season_player_id
    left join public.sport_waitlist_entries e
      on e.season_player_id = p.season_player_id
     and e.season_id = sp.season_id
    where p.match_id = p_match_id
      and p.is_eligible
      and p.availability_status = 'available'
      and not sp.is_coach
  ) ranked
  where ranked.season_player_id = p_season_player_id;

  return v_rank;
end;
$function$;

-- Priorité au crédit en mode Arrivée uniquement si option ON.
CREATE OR REPLACE FUNCTION private.recompute_match_convocations_internal(p_match_id uuid, p_reset_overrides boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_actor uuid := (select private.uid());
  v_season_id uuid;
  v_limit integer;
  v_match_type text;
  v_kickoff timestamptz;
  v_status text;
  v_available integer;
  v_convoked integer;
  v_waiting integer;
  v_auto_slots integer;
  -- 0 : par présence l'an dernier (rotation d'origine) ; 1 : ordre
  -- d'arrivée ; 2 : par choix de l'administrateur.
  v_mode integer := private.club_rule('waitlist_mode');
begin
  perform private.require_sports_management_enabled();
  select m.season_id, w.squad_size_limit, m.match_type, m.kickoff_at, m.status
    into v_season_id, v_limit, v_match_type, v_kickoff, v_status
  from public.matches m
  join public.match_sport_workflows w on w.match_id = m.id
  where m.id = p_match_id for update of w;
  if not found then
    raise exception 'Sport workflow not found' using errcode = 'P0002';
  end if;

  -- L'effectif est déjà verrouillé à T-15 : ne rien réécrire pour ce match.
  if v_status = 'a_venir'
     and v_kickoff is not null
     and now() < private.match_prediction_closes_at(v_kickoff) then
    -- Une liste toute neuve est triée selon les trois critères ; ensuite,
    -- pas de retri ici : l'ordre choisi par l'administrateur est conservé.
    -- La liste n'est retriée que lorsque des +1 changent (coup d'envoi,
    -- annulation) ou lorsque l'administrateur clique sur « Recalculer ».
    perform private.ensure_sport_waitlist(v_season_id, v_actor);

    -- Un choix manuel de l'admin est conservé (comme avant la refonte, il
    -- peut pré-placer un joueur absent ou sans réponse). Il disparaît sur
    -- demande explicite, pour un joueur inéligible, ou quand un joueur
    -- présent se désiste (voir clear_manual_override_on_availability).
    update public.match_sport_participants p
       set convocation_manual_override = false,
           updated_at = now()
     where p.match_id = p_match_id
       and p.season_player_id is not null
       and p.convocation_manual_override
       and (
         p_reset_overrides
         or not p.is_eligible
         or p.convocation_status not in ('convoked', 'not_convoked')
       );

    select greatest(0, v_limit - count(*)::integer) into v_auto_slots
    from public.match_sport_participants p
    join public.season_players sp on sp.id = p.season_player_id
    where p.match_id = p_match_id
      and p.convocation_manual_override
      and p.convocation_status = 'convoked'
      and not sp.is_coach;

    -- Match « entre nous » : inchangé, tous les présents sont convoqués.
    -- Mode « par choix » : tous les présents sont convoqués et
    -- l'administrateur place lui-même en attente ceux qui sont en trop.
    if v_match_type = 'entre_nous' or v_mode = 2 then
      v_auto_slots := 2147483647;
    end if;

    -- Un seul passage fixe l'état de TOUS les membres du match :
    -- le rang ne concerne que les joueurs présents, éligibles et non forcés.
    with ranked as (
      select p.id, row_number() over (
        order by
          -- Ordre d'arrivée : le premier à s'être dit présent passe d'abord.
          case when v_mode = 1
                      and private.club_rule('waitlist_priority_enabled') = 1
                 then e.manual_waitlist_count end desc nulls last,
          case when v_mode = 1 then p.availability_updated_at end asc nulls last,
          e.position desc, p.id
      ) as priority
      from public.match_sport_participants p
      join public.sport_waitlist_entries e
        on e.season_player_id = p.season_player_id
       and e.season_id = v_season_id
      where p.match_id = p_match_id
        and p.is_eligible
        and p.availability_status = 'available'
        and not p.convocation_manual_override
    ), decision as (
      select p.id,
        private.match_waitlist_position(p_match_id, p.season_player_id, e.position) as position,
        sp.is_coach, r.priority,
        p.convocation_manual_override and not sp.is_coach as manual,
        case
          when sp.is_coach and p.availability_status = 'available'
            then 'convoked'::public.sport_convocation_status
          when sp.is_coach
            then 'not_applicable'::public.sport_convocation_status
          when p.convocation_manual_override
            then p.convocation_status
          when r.priority <= v_auto_slots
            then 'convoked'::public.sport_convocation_status
          when r.priority > v_auto_slots
            then 'not_convoked'::public.sport_convocation_status
          else 'not_applicable'::public.sport_convocation_status
        end as status
      from public.match_sport_participants p
      join public.season_players sp on sp.id = p.season_player_id
      left join public.sport_waitlist_entries e
        on e.season_player_id = p.season_player_id
       and e.season_id = v_season_id
      left join ranked r on r.id = p.id
      where p.match_id = p_match_id
    )
    update public.match_sport_participants p
       set convocation_status = d.status,
           convocation_manual_override = d.manual,
           -- Compatibilité avec le Live : un joueur qui figurait en attente
           -- dans la dernière composition publiée rejoint le banc s'il est
           -- ensuite convoqué. Cette trace ne modifie jamais sa priorité.
           promoted_after_withdrawal_at = case
             when d.status = 'convoked'
              and exists (
                select 1
                from public.match_composition_publications pub
                where pub.match_id = p_match_id
                  and pub.version = (
                    select max(latest.version)
                    from public.match_composition_publications latest
                    where latest.match_id = p_match_id
                  )
                  and (pub.snapshot -> 'entries') @> jsonb_build_array(
                    jsonb_build_object(
                      'participant_id', p.id::text,
                      'convocation_status', 'not_convoked'
                    )
                  )
              ) then coalesce(p.promoted_after_withdrawal_at, now())
             else null
           end,
           promoted_from_participant_id = null,
           waitlist_position_snapshot =
             case when d.is_coach then null else d.position end,
           waitlist_recommended_not_convoked =
             not d.manual and coalesce(d.priority > v_auto_slots, false),
           -- Un tour d'attente ne compte que pour un joueur présent.
           waitlist_turn_should_consume = d.status = 'not_convoked'
             and p.availability_status = 'available',
           waitlist_turn_state = case
             when d.is_coach then 'not_applicable'::public.sport_waitlist_turn_state
             when p.waitlist_turn_state = 'consumed'
               then 'consumed'::public.sport_waitlist_turn_state
             when d.status = 'not_convoked'
              and p.availability_status = 'available'
               then 'pending'::public.sport_waitlist_turn_state
             when d.status = 'convoked'
               then 'waived'::public.sport_waitlist_turn_state
             else 'not_applicable'::public.sport_waitlist_turn_state
           end,
           waitlist_turn_updated_at = now(),
           updated_at = now()
      from decision d
     where p.id = d.id;

    update public.match_sport_workflows
       set convocation_generated_at = now(),
           updated_by = coalesce(v_actor, updated_by),
           updated_at = now()
    where match_id = p_match_id;
  end if;

  select count(*)::integer,
         count(*) filter (where p.convocation_status = 'convoked')::integer,
         count(*) filter (where p.convocation_status = 'not_convoked')::integer
    into v_available, v_convoked, v_waiting
  from public.match_sport_participants p
  join public.season_players sp on sp.id = p.season_player_id
  where p.match_id = p_match_id
    and p.is_eligible
    and p.availability_status = 'available'
    and not sp.is_coach;

  return jsonb_build_object(
    'match_id', p_match_id,
    'squad_size_limit', v_limit,
    'available_count', v_available,
    'convoked_count', v_convoked,
    'not_convoked_count', v_waiting,
    'over_limit_count', greatest(0, v_convoked - v_limit)
  );
end;
$function$;

-- Le changement de mode ou d'option recalcule les matchs non verrouillés.
CREATE OR REPLACE FUNCTION private.rebalance_waitlists_after_mode_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_row jsonb := case when tg_op = 'DELETE' then to_jsonb(old) else to_jsonb(new) end;
  v_old integer := case when tg_op = 'INSERT' then 0 else old.value end;
  v_new integer := case when tg_op = 'DELETE' then 0 else new.value end;
  v_season record;
begin
  if v_row ->> 'key' not in ('waitlist_mode', 'waitlist_priority_enabled')
     or v_old = v_new
     or not private.is_feature_enabled('sports_management') then
    return null;
  end if;
  -- Le helper garde le gel avant match et ne réinitialise aucun choix admin.
  for v_season in
    select distinct s.id from public.seasons s
    join public.matches m on m.season_id = s.id
    where s.club_id = (v_row ->> 'club_id')::uuid
      and m.status = 'a_venir'
      and now() < private.match_prediction_closes_at(m.kickoff_at)
    order by s.id
  loop
    perform 1 from public.seasons where id = v_season.id for update;
    perform private.rebuild_sport_waitlist_order(v_season.id, null);
    perform private.rebalance_upcoming_waitlist_matches(v_season.id);
  end loop;
  return null;
end;
$function$;

-- Nouveau début de comptabilisation : aucun rattrapage de matchs passés.
-- Les crédits manuels, journaux, lignes historiques restent conservés.
update private.waitlist_auto_activation
set activated_at = greatest(activated_at, now())
where singleton;

-- Fonction transactionnelle, idempotente par match (registre existant).
create or replace function private.finalize_match_waitlist_turns_internal(
  p_match_id uuid, p_force boolean default false
) returns integer
language plpgsql security definer
set search_path to ''
as $function$
declare
  v_match record;
  v_activation timestamptz;
  v_old_club_setting text := coalesce(current_setting('app.club_id', true), '');
  v_processed_id uuid;
  v_credited integer := 0;
begin
  -- Le verrou match/workflow protege le roster contre une publication admin
  -- concurrente et serialise les credits de deux executions simultanees.
  select m.id, m.season_id, m.club_id, m.kickoff_at, m.status
    into v_match
  from public.matches m
  join public.match_sport_workflows w on w.match_id = m.id
  where m.id = p_match_id
  for update of m, w;

  if not found then return 0; end if;

  select a.activated_at into v_activation
  from private.waitlist_auto_activation a where a.singleton;

  if v_match.kickoff_at is null
     or v_activation is null
     or v_match.kickoff_at < v_activation
     or v_match.kickoff_at > now()
     or v_match.status in ('annule', 'reporte') then
    return 0;
  end if;

  -- Un appel depuis un profil d'un autre club n'est jamais autorise.
  if private.uid() is not null
     and private.current_club_id() is distinct from v_match.club_id then
    raise exception 'Match belongs to another club' using errcode = '42501';
  end if;

  -- Le cron ne possede aucun utilisateur et doit utiliser le bon club pour
  -- lire les regles et recalculer les convocations des autres matchs.
  perform set_config('app.club_id', v_match.club_id::text, true);

  -- Echec explicite plutot que de perdre un credit si une entree manque.
  if exists (
    select 1
    from public.match_sport_participants p
    join public.season_players sp
      on sp.id = p.season_player_id
     and sp.season_id = v_match.season_id
     and sp.club_id = v_match.club_id
    left join public.sport_waitlist_entries e
      on e.season_player_id = p.season_player_id
     and e.season_id = v_match.season_id
     and e.club_id = v_match.club_id
    where p.match_id = v_match.id
      and p.club_id = v_match.club_id
      and p.season_player_id is not null
      and p.is_eligible
      and p.availability_status = 'available'
      and p.convocation_status = 'not_convoked'
      and not sp.is_coach
      and e.season_player_id is null
  ) then
    raise exception 'Missing waitlist entry for match %', v_match.id
      using errcode = 'P0002';
  end if;

  insert into private.waitlist_auto_processed_matches(
    match_id, season_id, club_id, kickoff_at
  ) values (
    v_match.id, v_match.season_id, v_match.club_id, v_match.kickoff_at
  )
  on conflict (match_id) do nothing
  returning match_id into v_processed_id;

  if v_processed_id is null then
    perform set_config('app.club_id', v_old_club_setting, true);
    return 0;
  end if;

  -- Uniquement les presents toujours en attente au coup d'envoi, y compris
  -- ceux places manuellement par l'admin dans le mode "Par choix".
  -- Ni coach, ni absent, ni invite sans joueur de saison.
  with credited as (
    update public.sport_waitlist_entries e
       set manual_waitlist_count = e.manual_waitlist_count + 1,
           updated_at = now()
      from public.match_sport_participants p
      join public.season_players sp
        on sp.id = p.season_player_id
       and sp.season_id = v_match.season_id
       and sp.club_id = v_match.club_id
     where p.match_id = v_match.id
       and p.club_id = v_match.club_id
       and p.is_eligible
       and p.availability_status = 'available'
       and p.convocation_status = 'not_convoked'
       and not sp.is_coach
       and e.season_player_id = p.season_player_id
       and e.season_id = v_match.season_id
       and e.club_id = v_match.club_id
    returning e.season_player_id
  )
  insert into private.sport_waitlist_passage_ledger (
    match_id, season_player_id, first_eligible_at, credited_at, club_id
  )
  select v_match.id, c.season_player_id, now(), now(), v_match.club_id
  from credited c
  on conflict (match_id, season_player_id) do update
    set credited_at = excluded.credited_at,
        voided_at = null;

  get diagnostics v_credited = row_count;
  update private.waitlist_auto_processed_matches
     set credited_count = v_credited where match_id = v_match.id;

  if v_credited > 0 then
    perform private.rebuild_sport_waitlist_order(v_match.season_id, null);
    if private.is_feature_enabled('sports_management') then
      perform private.rebalance_upcoming_waitlist_matches(v_match.season_id);
    end if;
  end if;

  perform set_config('app.club_id', v_old_club_setting, true);
  return v_credited;
end;
$function$;

-- Coordinateur pg_cron chaque minute, isolé par équipe.
create or replace function private.process_due_waitlist_credits()
returns integer
language plpgsql security invoker
set search_path to ''
as $function$
declare
  v_match record;
  v_total integer := 0;
  v_old_club_setting text := coalesce(current_setting('app.club_id', true), '');
begin
  for v_match in
    select m.id, m.club_id
    from public.matches m
    join public.match_sport_workflows w on w.match_id = m.id
    cross join private.waitlist_auto_activation a
    where a.singleton
      and m.kickoff_at >= a.activated_at
      and m.kickoff_at <= now()
      and m.status not in ('annule', 'reporte')
      and not exists (
        select 1 from private.waitlist_auto_processed_matches done
        where done.match_id = m.id
      )
    order by m.kickoff_at, m.id
    limit 100
  loop
    perform set_config('app.club_id', v_match.club_id::text, true);
    v_total := v_total
      + private.finalize_match_waitlist_turns_internal(v_match.id, false);
  end loop;
  perform set_config('app.club_id', v_old_club_setting, true);
  return v_total;
end;
$function$;

revoke all on function private.finalize_match_waitlist_turns_internal(uuid,boolean)
  from public, anon, authenticated;
revoke all on function private.process_due_waitlist_credits()
  from public, anon, authenticated;
grant execute on function private.process_due_waitlist_credits() to postgres;
grant execute on function private.finalize_match_waitlist_turns_internal(uuid,boolean)
  to postgres;

do $schedule$
begin
  if exists (select 1 from cron.job where jobname = 'waitlist-credit') then
    perform cron.unschedule('waitlist-credit');
  end if;
  perform cron.schedule(
    'waitlist-credit', '* * * * *',
    'select private.process_due_waitlist_credits();'
  );
end;
$schedule$;
commit;
