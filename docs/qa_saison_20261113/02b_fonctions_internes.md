# Grille QA — fonctions SQL internes privées

Source : catalogue PostgreSQL projet commercial, lecture seule 13/11/2026. **Présence en base ne signifie pas qu'une fonction a été appelée avec succès.**

Total : **286 signatures** dans le schéma `private`. Toutes les lignes sont **NON VÉRIFIÉ** en exécution. Les fonctions privées sont à vérifier par leurs déclencheurs ou appels normaux, jamais en utilisant un accès propriétaire pour simuler un rôle joueur/admin. Les fonctions en surcharge sont listées individuellement.

| ID | Fonction interne | SECURITY DEFINER | Inventaire | Résultat fonctionnel |
|---:|---|---|---|---|
| PRIV-001 | `private.add_match_live_players(p_match_id uuid, p_players jsonb, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-002 | `private.add_or_reuse_match_guest(p_match_id uuid, p_guest_player_id uuid, p_first_name text, p_last_name text, p_is_goalkeeper boolean, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-003 | `private.add_profile_to_roster(p_profile_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-004 | `private.adjust_match_live_score(p_match_id uuid, p_team text, p_delta integer, p_scorer_participant_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-005 | `private.adjust_match_live_score_idempotent(p_match_id uuid, p_team text, p_delta integer, p_scorer_participant_id uuid, p_operation_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-006 | `private.admin_availability_change_message(p_display_name text, p_old_status text, p_new_status text, p_changed_at timestamp with time zone)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-007 | `private.admin_cancel_match_motm_vote(p_match_id uuid, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-008 | `private.admin_close_match_motm_vote_early(p_match_id uuid, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-009 | `private.admin_restart_match_motm_vote(p_match_id uuid, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-010 | `private.align_match_live_lineup_participants(p_match_id uuid, p_seed_convoked_on_bench boolean)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-011 | `private.apply_club_match_duration()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-012 | `private.apply_coach_flag_to_participants()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-013 | `private.apply_unavailability_on_new_participant()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-014 | `private.assert_match_admin_edit_open(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-015 | `private.assert_match_postgame_correction_open(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-016 | `private.assert_season_can_archive(p_season_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-017 | `private.assign_match_championship_round()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-018 | `private.attach_match_sport_report_player(p_match_id uuid, p_season_player_id uuid, p_guest_player_id uuid, p_first_name text, p_last_name text, p_is_goalkeeper boolean, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-019 | `private.attach_season_player_to_upcoming_matches(p_season_player_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-020 | `private.badge_image_storage_path(p_value text)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-021 | `private.badge_unlock_push_message(p_names text[])` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-022 | `private.build_season_wrapped(p_season_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-023 | `private.can_manage_badges()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-024 | `private.can_read_sport_participant(p_participant_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-025 | `private.can_read_sport_workflow(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-026 | `private.can_write_match_postgame(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-027 | `private.cancel_deleted_match_live_goal_notification()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-028 | `private.capture_deleted_match_for_calendar()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-029 | `private.capture_live_starting_lineup()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-030 | `private.capture_match_kit_snapshot(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-031 | `private.capture_player_alias()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-032 | `private.cast_match_motm_vote(p_match_id uuid, p_candidate_participant_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-033 | `private.cleanup_player_kit_photos()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-034 | `private.clear_manual_override_on_availability()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-035 | `private.close_due_match_motm_elections(p_now timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-036 | `private.close_match_motm_election(p_match_id uuid, p_require_due boolean)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-037 | `private.club_billable_players()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-038 | `private.club_disabled_notification_kinds()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-039 | `private.club_module_enabled(p_key text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-040 | `private.club_module_keys()` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-041 | `private.club_notification_rules()` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-042 | `private.club_rule(p_key text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-043 | `private.club_rule_catalogue()` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-044 | `private.club_storage_used_bytes()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-045 | `private.club_storage_within_quota(p_bucket text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-046 | `private.club_subscription_summary()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-047 | `private.composition_snapshot(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-048 | `private.configure_match_sport_workflow(p_match_id uuid, p_squad_size_limit integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-049 | `private.configure_match_sport_workflow_v2(p_match_id uuid, p_squad_size_limit integer, p_schedule_mode text, p_requested_at timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-050 | `private.confirm_start_match_live(p_match_id uuid, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-051 | `private.create_match_with_sport_limit(p_season_id uuid, p_opponent_id uuid, p_match_date date, p_match_time time without time zone, p_location text, p_win numeric, p_draw numeric, p_loss numeric, p_squad_size_limit integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-052 | `private.create_player_identity(p_display_name text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-053 | `private.create_postmatch_composition(p_match_id uuid, p_formation_code text, p_entries jsonb, p_allow_squad_size_exception boolean, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-054 | `private.create_sport_availability_notification(p_match_id uuid, p_participant_id uuid, p_profile_id uuid, p_kind text, p_source text, p_scheduled_for timestamp with time zone, p_requested_by uuid, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-055 | `private.current_club_id()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-056 | `private.delete_match_live_event(p_match_id uuid, p_event_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-057 | `private.dispatch_composition_published_push(p_match_id uuid, p_profile_ids uuid[])` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-058 | `private.dispatch_convocation_push(p_match_id uuid, p_profile_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-059 | `private.dispatch_motm_push(p_kind text, p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-060 | `private.dispatch_motm_result_notification(p_kind text, p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-061 | `private.dispatch_sport_notification_event(p_event_id bigint)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-062 | `private.dispatch_waitlist_demotion_push(p_match_id uuid, p_profile_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-063 | `private.edge_function_url(p_function text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-064 | `private.end_match_live(p_match_id uuid, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-065 | `private.enrich_match_convocation_history(p_payload jsonb)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-066 | `private.enrich_sport_waitlist_history(p_payload jsonb)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-067 | `private.ensure_guest_player_identity()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-068 | `private.ensure_historical_player_identity()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-069 | `private.ensure_match_motm_election(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-070 | `private.ensure_profile_player_identity()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-071 | `private.ensure_season_player_identity()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-072 | `private.ensure_sport_waitlist(p_season_id uuid, p_actor uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-073 | `private.ensure_sport_waitlist_base(p_season_id uuid, p_actor uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-074 | `private.exempt_waitlist_on_reschedule()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-075 | `private.exempt_waitlist_when_all_fit()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-076 | `private.featured_badge_display_values(p_profile_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-077 | `private.fill_sport_admin_audit_match_label()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-078 | `private.finalize_due_waitlist_turns_for_season(p_season_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-079 | `private.finalize_match_sport_postgame(p_match_id uuid, p_score_as_grinta integer, p_score_adverse integer, p_participants jsonb, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-080 | `private.finalize_match_waitlist_turns_internal(p_match_id uuid, p_force boolean)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-081 | `private.finalize_season_competition_transition()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-082 | `private.find_reusable_profile_player_identity(p_display_name text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-083 | `private.finish_due_internal_matches(p_now timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-084 | `private.generate_invite_code()` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-085 | `private.get_admin_match_composition(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-086 | `private.get_admin_match_motm_dashboard(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-087 | `private.get_admin_match_sport_finalization(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-088 | `private.get_all_historical_match_results()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-089 | `private.get_finished_bench_counts(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-090 | `private.get_guest_players(p_include_archived boolean)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-091 | `private.get_historical_match_detail(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-092 | `private.get_historical_match_results(p_season_name text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-093 | `private.get_match_availability_board(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-094 | `private.get_match_convocations(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-095 | `private.get_match_guests(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-096 | `private.get_match_live_add_player_options(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-097 | `private.get_match_live_timeline(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-098 | `private.get_match_motm_vote(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-099 | `private.get_match_sport_goal_actions(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-100 | `private.get_match_sport_report(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-101 | `private.get_match_sport_statistics_integrity(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-102 | `private.get_my_match_availability(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-103 | `private.get_notifications_paused()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-104 | `private.get_player_position_history(p_since timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-105 | `private.get_player_season_statistics(p_full_name text, p_is_goalkeeper boolean, p_profile_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-106 | `private.get_public_feature_flags()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-107 | `private.get_published_match_composition(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-108 | `private.get_published_match_sport_result(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-109 | `private.get_sport_availability_reminder_summary(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-110 | `private.get_sport_waitlist(p_season_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-111 | `private.get_sport_waitlist_readonly(p_season_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-112 | `private.guard_finished_match_composition_write()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-113 | `private.guard_internal_composition_t15()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-114 | `private.guard_live_mode_module()` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-115 | `private.guard_match_archive_transition()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-116 | `private.guard_match_lifecycle_write()` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-117 | `private.guard_match_season_finality()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-118 | `private.guard_match_status_chronology()` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-119 | `private.guard_motm_module()` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-120 | `private.guard_postgame_correction_window()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-121 | `private.guard_predictions_module()` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-122 | `private.guard_season_competition_finality()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-123 | `private.handle_convoked_withdrawal(p_match_id uuid, p_participant_id uuid, p_actor uuid, p_actor_kind text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-124 | `private.handle_match_notification_change()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-125 | `private.has_filled_match_prediction(p_profile_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-126 | `private.history_entry_cutoff()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-127 | `private.history_entry_name(p_player jsonb)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-128 | `private.history_season_name(p_date date)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-129 | `private.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-130 | `private.internal_composition_visual_is_complete(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-131 | `private.internal_default_formation_code(p_player_count integer)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-132 | `private.internal_formation_is_allowed(p_code text, p_player_count integer)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-133 | `private.internal_formation_slots(p_code text)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-134 | `private.internal_formation_slots_v4(p_code text, p_player_count integer)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-135 | `private.internal_v4_formation_slots(p_code text)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-136 | `private.is_active_profile()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-137 | `private.is_admin()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-138 | `private.is_club_bucket(p_bucket text)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-139 | `private.is_feature_enabled(p_key text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-140 | `private.is_known_non_player_archive_name(p_name text)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-141 | `private.is_match_coach_or_admin(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-142 | `private.is_match_live_pilot_coach(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-143 | `private.is_match_staff()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-144 | `private.is_moderator()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-145 | `private.is_platform_operator()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-146 | `private.is_player_unavailable_at(p_profile_id uuid, p_kickoff_at timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-147 | `private.jwt()` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-148 | `private.list_admin_match_motm_votes()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-149 | `private.lock_match_composition_version(p_match_id uuid, p_expected_version integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-150 | `private.mark_notifications_read_on_availability_answer()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-151 | `private.mark_notifications_read_on_motm_vote()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-152 | `private.mark_notifications_read_on_prediction()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-153 | `private.match_features_open_at(p_kickoff_at timestamp with time zone)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-154 | `private.match_has_eligible_motm_ballot(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-155 | `private.match_kit_snapshot_value(p_kits jsonb, p_primary text, p_secondary text, p_slot text)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-156 | `private.match_live_current_session_id()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-157 | `private.match_live_notification_scorer_name(p_participant_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-158 | `private.match_live_notifications_eligible(p_match_id uuid, p_at timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-159 | `private.match_live_report_goal_actions_json(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-160 | `private.match_live_snapshot(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-161 | `private.match_motm_anchor_version(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-162 | `private.match_motm_candidate_participants(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-163 | `private.match_motm_closes_at(p_match_id uuid)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-164 | `private.match_motm_opens_at(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-165 | `private.match_motm_result_notification_payloads(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-166 | `private.match_motm_voter_participant(p_match_id uuid, p_profile_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-167 | `private.match_notification_time_label(p_kickoff_at timestamp with time zone)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-168 | `private.match_postgame_correction_closes_at(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-169 | `private.match_prediction_closes_at(p_kickoff_at timestamp with time zone)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-170 | `private.match_prediction_notification_at(p_kickoff_at timestamp with time zone)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-171 | `private.match_predictions_open_at(p_match_id uuid, p_kickoff_at timestamp with time zone)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-172 | `private.match_sport_finalization_snapshot(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-173 | `private.match_sport_goal_actions_json(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-174 | `private.match_sport_report_lineup(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-175 | `private.match_waitlist_position(p_match_id uuid, p_season_player_id uuid, p_season_position integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-176 | `private.match_weather_refresh_interval(p_kickoff_at timestamp with time zone, p_now timestamp with time zone)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-177 | `private.merge_player_identities(p_source_player_id uuid, p_target_player_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-178 | `private.normalize_match_meeting_at()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-179 | `private.normalize_player_name(p_name text)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-180 | `private.notify_admin_player_availability_change()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-181 | `private.notify_admins_of_pending_signup()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-182 | `private.notify_composition_published(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-183 | `private.notify_waitlist_on_convocation_publish()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-184 | `private.notify_waitlist_promotion()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-185 | `private.open_match_live_workspace(p_match_id uuid, p_planned_duration_minutes integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-186 | `private.override_match_availability(p_match_id uuid, p_season_player_id uuid, p_status text, p_private_comment text, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-187 | `private.participant_is_coach(p_season_player_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-188 | `private.player_unavailability_reason_at(p_profile_id uuid, p_kickoff_at timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-189 | `private.prepare_profile_for_hard_deletion(p_profile_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-190 | `private.process_badge_unlock_notifications(p_now timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-191 | `private.process_due_match_live_notifications(p_limit integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-192 | `private.process_due_waitlist_credits()` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-193 | `private.process_match_motm_jobs(p_now timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-194 | `private.process_season_wrapped_jobs()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-195 | `private.process_sport_availability_notifications(p_now timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-196 | `private.profile_badge_display_metrics(p_profile_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-197 | `private.profile_badge_metrics(p_profile_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-198 | `private.profile_badge_stars(p_profile_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-199 | `private.profile_match_exploits(p_profile_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-200 | `private.profile_photo_storage_path(p_value text)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-201 | `private.provision_club(p_club_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-202 | `private.publish_match_composition(p_match_id uuid, p_allow_squad_size_exception boolean, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-203 | `private.publish_match_convocations(p_match_id uuid, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-204 | `private.publish_match_effectif(p_match_id uuid, p_squad_size_limit integer, p_decisions jsonb, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-205 | `private.publish_match_live_composition(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-206 | `private.publish_match_live_recap(p_match_id uuid, p_score_as_grinta integer, p_score_adverse integer, p_participants jsonb, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-207 | `private.purge_client_incident_log(p_now timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-208 | `private.purge_client_incident_log_all_clubs(p_now timestamp with time zone)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-209 | `private.push_due_motm_open_notifications(p_now timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-210 | `private.push_due_motm_result_notifications(p_now timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-211 | `private.queue_badge_unlock_push()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-212 | `private.queue_match_live_full_time_notification()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-213 | `private.queue_match_live_goal_notification()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-214 | `private.queue_match_live_kickoff_notification()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-215 | `private.rebalance_upcoming_waitlist_matches(p_season_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-216 | `private.rebuild_historical_statistics()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-217 | `private.rebuild_sport_waitlist_order(p_season_id uuid, p_actor uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-218 | `private.recalculate_odds_after_rule_change()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-219 | `private.recalculate_sport_waitlist(p_season_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-220 | `private.recalculate_upcoming_odds_after_history_change()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-221 | `private.recompute_match_convocations_internal(p_match_id uuid, p_reset_overrides boolean)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-222 | `private.record_waitlist_presence()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-223 | `private.refresh_historical_match_players(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-224 | `private.reject_profile_badge_audit_mutation()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-225 | `private.remove_match_guest(p_match_id uuid, p_participant_id uuid, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-226 | `private.reopen_match_live(p_match_id uuid, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-227 | `private.reorder_sport_waitlist(p_season_id uuid, p_ordered_player_ids uuid[], p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-228 | `private.request_match_live_notification_delivery(p_notification_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-229 | `private.request_match_weather_refresh(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-230 | `private.request_match_weather_refresh_on_change()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-231 | `private.require_match_live_pilot(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-232 | `private.require_sports_management_enabled()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-233 | `private.reset_internal_match_composition_on_first_effectif_publish()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-234 | `private.resolve_historical_player_name(p_name text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-235 | `private.resolve_match_availability_open_at(p_kickoff_at timestamp with time zone, p_schedule_mode text, p_requested_at timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-236 | `private.resolve_match_squad_size_limit(p_requested integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-237 | `private.resolve_open_sport_season(p_season_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-238 | `private.restart_match_live_session(p_match_id uuid, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-239 | `private.restore_returning_convoked_player(p_match_id uuid, p_participant_id uuid, p_actor uuid, p_actor_kind text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-240 | `private.resync_unavailability_on_reschedule()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-241 | `private.role()` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-242 | `private.run_for_each_club(p_sql text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-243 | `private.save_match_composition(p_match_id uuid, p_formation_code text, p_entries jsonb, p_allow_squad_size_exception boolean, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-244 | `private.save_match_effectif(p_match_id uuid, p_squad_size_limit integer, p_decisions jsonb, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-245 | `private.save_match_live_lineup(p_match_id uuid, p_entries jsonb, p_substitution jsonb)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-246 | `private.save_match_live_lineup_versioned(p_match_id uuid, p_entries jsonb, p_substitution jsonb, p_expected_lineup_revision integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-247 | `private.season_has_historical_competition(p_season_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-248 | `private.season_wrapped_current_season()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-249 | `private.season_wrapped_is_supported(p_season_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-250 | `private.seed_roster_for_season(p_season_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-251 | `private.send_sport_availability_reminder(p_match_id uuid, p_season_player_id uuid, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-252 | `private.set_guest_archived(p_guest_player_id uuid, p_archived boolean, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-253 | `private.set_match_convocation(p_match_id uuid, p_season_player_id uuid, p_status text, p_turn_should_consume boolean, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-254 | `private.set_match_live_clock_state(p_match_id uuid, p_action text, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-255 | `private.set_match_live_event_scorer(p_match_id uuid, p_event_id uuid, p_scorer_participant_id uuid, p_is_opponent_own_goal boolean, p_assist_participant_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-256 | `private.set_match_meeting_at(p_match_id uuid, p_meeting_at timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-257 | `private.set_my_match_availability(p_match_id uuid, p_status text, p_private_comment text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-258 | `private.set_notifications_paused(p_enabled boolean, p_justification text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-259 | `private.set_sports_management_enabled(p_enabled boolean, p_justification text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-260 | `private.signal_club_configuration_change()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-261 | `private.signal_feature_flag_change()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-262 | `private.signal_season_wrapped()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-263 | `private.signal_shared_data_change()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-264 | `private.snapshot_match_live_notification_targets(p_notification_id uuid, p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-265 | `private.sport_waitlist_payload(p_season_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-266 | `private.start_club_trial()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-267 | `private.storage_object_in_current_club(p_bucket text, p_owner text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-268 | `private.storage_path_in_current_club(p_bucket text, p_name text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-269 | `private.submit_match_sport_report(p_match_id uuid, p_score_as_grinta integer, p_score_adverse integer, p_lineup jsonb, p_goal_actions jsonb, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-270 | `private.sync_historical_match_players()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-271 | `private.sync_match_sport_workflow(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-272 | `private.sync_match_sport_workflow_v2(p_match_id uuid, p_schedule_mode text, p_requested_at timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-273 | `private.sync_player_unavailability(p_profile_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-274 | `private.sync_season_player_upcoming_matches()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-275 | `private.transition_match_motm_election(p_match_id uuid, p_now timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-276 | `private.trg_reset_match_motm_after_finalization()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-277 | `private.trigger_match_kit_snapshot()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-278 | `private.try_motm_result_notification(p_kind text, p_match_id uuid, p_sent_at timestamp with time zone)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-279 | `private.uid()` | non | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-280 | `private.update_match_live_goal_notification()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-281 | `private.update_match_with_sport_limit(p_match_id uuid, p_season_id uuid, p_opponent_id uuid, p_match_date date, p_match_time time without time zone, p_location text, p_status text, p_win numeric, p_draw numeric, p_loss numeric, p_squad_size_limit integer)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-282 | `private.update_postmatch_composition(p_match_id uuid, p_formation_code text, p_entries jsonb, p_allow_squad_size_exception boolean, p_reason text)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-283 | `private.vault_secrets()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-284 | `private.void_match_waitlist_credits(p_match_id uuid)` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-285 | `private.void_waitlist_on_exemption()` | oui | **DB (lecture)** | **NON VÉRIFIÉ** |
| PRIV-286 | `private.waitlist_credit_cutoff(p_kickoff timestamp with time zone)` | non | **DB (lecture)** | **NON VÉRIFIÉ** |

La logique déclenchée par les triggers, les fonctions de planification et le système Auth/Storage nécessite une trace de parcours et une validation séparée : le catalogue SQL n'est pas un test de bout en bout.
