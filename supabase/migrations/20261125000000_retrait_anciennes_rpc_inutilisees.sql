-- Retrait de l'accès « compte connecté » aux anciennes RPC que l'appli
-- n'appelle plus.
--
-- Pourquoi : chaque fonction appelable par un compte connecté est une porte à
-- surveiller. Ces 46 fonctions sont des versions remplacées (v1/v2 des
-- créations de match, ancienne création avec cotes, ancien pronostic avec ×2,
-- etc.) ou des outils jamais branchés à l'interface. Elles vérifient toutes
-- leur appelant, mais elles restent une surface d'attaque inutile.
--
-- Preuves d'inutilisation (18/11/2026) :
--   * aucun appel dans lib/, web/ ni supabase/functions/ (recherche par nom,
--     aucun nom de RPC construit dynamiquement dans l'appli) ;
--   * aucun appel dans l'historique Git de lib/ depuis la création du dépôt
--     commercial : aucune ancienne version de l'appli ne les utilise ;
--   * aucun appel dans les journaux d'API de la base commerciale sur 24 h ;
--   * aucune règle d'accès (RLS), vue ou tâche planifiée ne les utilise.
--
-- Ce qui ne change pas :
--   * les fonctions restent en place (rien n'est supprimé) ;
--   * service_role et le propriétaire club_scope gardent leur droit. Les
--     fonctions actuelles qui les appellent en interne (v3 → v2 → v1, etc.)
--     tournent sous club_scope et continuent donc de marcher ;
--   * gardées volontairement : is_match_staff (utilisée par des règles
--     d'accès), is_valid_person_name (appelée par un déclencheur qui tourne
--     sous l'identité de l'appelant), accept_terms (parcours légal) et
--     get_match_live_timeline (fait partie du contrat public du Live,
--     vérifié par live_private_boundary.test.sql).
--   * pour les deux fonctions à plusieurs versions, seule la version
--     inutilisée est visée : save_match_prediction à 4 arguments (×2 retiré)
--     et admin_save_match_composition sans version attendue.
--
-- Retour arrière : `grant execute on function … to authenticated;` sur la
-- signature concernée.
--
-- Signatures explicites : si une fonction n'existe pas sous cette forme, la
-- migration échoue en bloc au lieu de passer à côté.

revoke execute on function public.admin_close_match_motm_vote_early(uuid,text) from authenticated;
revoke execute on function public.admin_configure_match_sport_workflow(uuid,integer) from authenticated;
revoke execute on function public.admin_create_match_complete(uuid,uuid,date,time without time zone,text,numeric,numeric,numeric,integer,text,boolean,text,text) from authenticated;
revoke execute on function public.admin_create_match_complete_v2(uuid,uuid,date,time without time zone,text,numeric,numeric,numeric,integer,text,boolean,text,text,text,timestamp with time zone) from authenticated;
revoke execute on function public.admin_finalize_match_sport_postgame(uuid,integer,integer,jsonb,text) from authenticated;
revoke execute on function public.admin_finalize_match_waitlist_turns(uuid) from authenticated;
revoke execute on function public.admin_get_internal_composition(uuid) from authenticated;
revoke execute on function public.admin_get_match_motm_dashboard(uuid) from authenticated;
revoke execute on function public.admin_get_match_sport_statistics_integrity(uuid) from authenticated;
revoke execute on function public.admin_list_match_motm_votes() from authenticated;
revoke execute on function public.admin_publish_match_convocations(uuid,text) from authenticated;
revoke execute on function public.admin_recalculate_sport_waitlist(uuid) from authenticated;
revoke execute on function public.admin_recent_client_incidents(integer) from authenticated;
revoke execute on function public.admin_recompute_match_convocations(uuid,boolean) from authenticated;
revoke execute on function public.admin_reorder_sport_waitlist(uuid,uuid[],text) from authenticated;
revoke execute on function public.admin_require_password_change(uuid) from authenticated;
revoke execute on function public.admin_restart_match_motm_vote(uuid,text) from authenticated;
revoke execute on function public.admin_save_internal_composition(uuid,text,text,jsonb) from authenticated;
revoke execute on function public.admin_save_internal_composition_v3(uuid,text,text,text,text,text,text,jsonb) from authenticated;
revoke execute on function public.admin_save_match_composition(uuid,text,jsonb,boolean,text) from authenticated;
revoke execute on function public.admin_save_match_effectif(uuid,integer,jsonb,text) from authenticated;
revoke execute on function public.admin_set_match_address(uuid,text,boolean) from authenticated;
revoke execute on function public.admin_set_match_convocation(uuid,uuid,text,boolean,text) from authenticated;
revoke execute on function public.admin_set_match_jersey(uuid,text) from authenticated;
revoke execute on function public.admin_set_match_type(uuid,text) from authenticated;
revoke execute on function public.admin_sync_match_sport_workflow(uuid) from authenticated;
revoke execute on function public.admin_update_match_complete(uuid,uuid,uuid,date,time without time zone,text,text,numeric,numeric,numeric,timestamp with time zone,integer,text,boolean,text,text) from authenticated;
revoke execute on function public.close_match_predictions(uuid) from authenticated;
revoke execute on function public.create_internal_match(uuid,date,time without time zone,text) from authenticated;
revoke execute on function public.create_internal_match_v2(uuid,date,time without time zone,text,text,timestamp with time zone) from authenticated;
revoke execute on function public.create_match_with_odds(uuid,uuid,date,time without time zone,text,numeric,numeric,numeric) from authenticated;
revoke execute on function public.create_match_with_odds_and_sport_limit(uuid,uuid,date,time without time zone,text,numeric,numeric,numeric,integer) from authenticated;
revoke execute on function public.finalize_match_postgame_with_lineup(uuid,integer,jsonb,uuid,integer,uuid[],uuid) from authenticated;
revoke execute on function public.is_moderator() from authenticated;
revoke execute on function public.platform_update_club(uuid,text,text,timestamp with time zone,timestamp with time zone,integer,integer,bigint,text) from authenticated;
revoke execute on function public.profile_badge_metrics(uuid) from authenticated;
revoke execute on function public.save_match_prediction(uuid,integer,integer,boolean) from authenticated;
revoke execute on function public.send_test_push() from authenticated;
revoke execute on function public.set_sports_management_enabled(boolean,text) from authenticated;
revoke execute on function public.staff_app_integrity_report() from authenticated;
revoke execute on function public.staff_profile_username(uuid) from authenticated;
revoke execute on function public.staff_revoke_badge(uuid,text) from authenticated;
revoke execute on function public.update_internal_match(uuid,uuid,date,time without time zone,text,timestamp with time zone) from authenticated;
revoke execute on function public.update_match_with_odds(uuid,uuid,uuid,date,time without time zone,text,text,numeric,numeric,numeric) from authenticated;
revoke execute on function public.update_match_with_odds_and_sport_limit(uuid,uuid,uuid,date,time without time zone,text,text,numeric,numeric,numeric,integer) from authenticated;
revoke execute on function public.update_my_app_preferences(boolean,boolean,boolean) from authenticated;
