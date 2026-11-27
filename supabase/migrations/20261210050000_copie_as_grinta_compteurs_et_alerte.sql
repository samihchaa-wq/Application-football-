-- Copie AS Grinta : compteurs d'id recalés et alerte en cas d'échec.
--
-- 1. La copie automatique (fonction sync-as-grinta) insère les lignes d'AS
--    Grinta avec leurs id d'origine sans avancer les compteurs des tables.
--    Le prochain ajout fait dans l'appli reprenait un id déjà pris : par
--    exemple « duplicate key match_sport_participant_events_pkey » en
--    validant un compte rendu de match. Constaté le 27/11/2026 :
--    match_sport_participant_events (plus grand id 1759, compteur 1280),
--    historical_player_statistics (330 / 2), player_aliases (622 / 457).
--    On recale ici, une fois, chaque compteur des tables copiées au-delà du
--    plus grand id présent. La fonction refait la même chose à chaque copie.
--    Un compteur n'est jamais reculé.
--
-- 2. Nouveau type d'alerte « sync_failed » pour private.payment_alerts : la
--    fonction y écrit chaque échec de copie, qui apparaît dans l'onglet
--    « À faire » du Poste de contrôle. Avant, l'échec n'était visible que
--    dans net._http_response (la tâche planifiée affiche « succeeded »).

do $$
declare
  v_table text;
  v_column text;
  v_sequence text;
begin
  foreach v_table in array array[
    'players', 'player_aliases', 'seasons', 'opponents', 'profiles',
    'season_players', 'season_player_kit_photos', 'guest_players', 'matches',
    'match_odds', 'match_predictions', 'match_player_stats', 'match_attendance',
    'match_man_of_match', 'season_awards', 'badges', 'profile_badges',
    'badge_inbox_state', 'profile_badge_seen', 'match_sport_workflows',
    'match_sport_participants', 'match_sport_participant_events',
    'sport_waitlist_entries', 'match_compositions', 'match_composition_entries',
    'match_composition_publications', 'match_internal_compositions',
    'match_internal_composition_entries', 'match_sport_finalizations',
    'match_sport_finalization_versions', 'match_sport_motm_elections',
    'match_sport_motm_votes', 'match_sport_motm_results',
    'match_sport_goal_actions', 'match_live_sessions', 'match_live_events',
    'match_live_notification_subscriptions', 'historical_match_scores',
    'historical_match_details', 'historical_match_players',
    'historical_player_name_links', 'historical_player_statistics',
    'historical_team_statistics', 'historical_unscored_match_contributions',
    'club_events', 'calendar_match_tombstones', 'player_unavailabilities',
    'season_wrapped'
  ] loop
    if to_regclass(format('public.%I', v_table)) is null then
      continue;
    end if;
    for v_column, v_sequence in
      select a.attname, pg_get_serial_sequence(format('public.%I', v_table), a.attname)
      from pg_attribute a
      where a.attrelid = format('public.%I', v_table)::regclass
        and a.attnum > 0
        and not a.attisdropped
        and pg_get_serial_sequence(format('public.%I', v_table), a.attname) is not null
    loop
      execute format(
        'select setval(%L::regclass, greatest(coalesce(max(%I), 0), '
        'coalesce(pg_sequence_last_value(%L::regclass), 0), 1)) from public.%I',
        v_sequence, v_column, v_sequence, v_table
      );
    end loop;
  end loop;
end;
$$;

alter table private.payment_alerts
  drop constraint payment_alerts_kind_check;
alter table private.payment_alerts
  add constraint payment_alerts_kind_check
  check (kind in ('dispute', 'refund_unmatched', 'payment_failed', 'sync_failed', 'other'));

comment on table private.payment_alerts is
  'Alertes à traiter par l''éditeur : paiements (contestation de carte…) et échecs de la copie AS Grinta (sync_failed).';
