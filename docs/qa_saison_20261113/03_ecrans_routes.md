# Écrans et routes — registre de test

> Source : arbre de `main` et routeur `lib/app/router/app_router.dart`, le 13/11/2026. La présence du fichier n'est pas la preuve qu'il soit atteignable. Statut **NON VÉRIFIÉ** pour chaque parcours.

## Fichiers d'écran (42)

| ID | Source | Repéré dans le dépôt | Résultat à l'écran |
|---|---|---|---|
| E-01 | `lib/app/router/deferred_route_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-02 | `lib/features/admin/presentation/admin_menu_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-03 | `lib/features/admin/presentation/admin_notification_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-04 | `lib/features/admin/presentation/admin_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-05 | `lib/features/admin/presentation/club_kits_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-06 | `lib/features/admin/presentation/club_settings_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-07 | `lib/features/admin/presentation/opponent_stadium_library_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-08 | `lib/features/auth/presentation/auth_loading_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-09 | `lib/features/auth/presentation/auth_register_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-10 | `lib/features/auth/presentation/auth_sign_in_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-11 | `lib/features/auth/presentation/choose_club_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-12 | `lib/features/auth/presentation/confirm_email_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-13 | `lib/features/auth/presentation/forced_password_change_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-14 | `lib/features/auth/presentation/legal_document_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-15 | `lib/features/badges/presentation/armoire_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-16 | `lib/features/badges/presentation/badge_admin_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-17 | `lib/features/club/presentation/club_suspended_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-18 | `lib/features/match_live/presentation/match_live_pre_kickoff_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-19 | `lib/features/match_live/presentation/match_live_running_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-20 | `lib/features/matches/presentation/calendar_entry_form_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-21 | `lib/features/matches/presentation/historical_match_detail_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-22 | `lib/features/matches/presentation/history_entry_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-23 | `lib/features/matches/presentation/match_details_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-24 | `lib/features/matches/presentation/match_form_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-25 | `lib/features/matches/presentation/matches_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-26 | `lib/features/matches/presentation/upcoming_match_prediction_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-27 | `lib/features/more/presentation/more_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-28 | `lib/features/notifications/presentation/notifications_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-29 | `lib/features/players/presentation/player_card_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-30 | `lib/features/players/presentation/player_stat_ranking_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-31 | `lib/features/players/presentation/players_registry_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-32 | `lib/features/predictions/presentation/pronos_hub_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-33 | `lib/features/profile/presentation/profile_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-34 | `lib/features/season_wrapped/presentation/season_wrapped_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-35 | `lib/features/sports_management/presentation/admin_guests_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-36 | `lib/features/sports_management/presentation/admin_squad_plan_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-37 | `lib/features/sports_management/presentation/admin_waitlist_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-38 | `lib/features/sports_management/presentation/match_lineup_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-39 | `lib/features/sports_management/presentation/match_report_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-40 | `lib/features/sports_management/presentation/sport_motm_vote_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-41 | `lib/features/statistics/presentation/stats_hub_page.dart` | CODE | **NON VÉRIFIÉ** |
| E-42 | `lib/features/unavailability/presentation/unavailability_page.dart` | CODE | **NON VÉRIFIÉ** |

## Routes déclarées (48)

| ID | Route | Contrat source | Résultat par rôle |
|---|---|---|---|
| R-01 | `/` | CODE | **NON VÉRIFIÉ** |
| R-02 | `/home` | CODE | **NON VÉRIFIÉ** |
| R-03 | `/accueil` | CODE | **NON VÉRIFIÉ** |
| R-04 | `/matches` | CODE | **NON VÉRIFIÉ** |
| R-05 | `/matches/:matchId` | CODE | **NON VÉRIFIÉ** |
| R-06 | `/matches/history/:matchId` | CODE | **NON VÉRIFIÉ** |
| R-07 | `/matches/:matchId/lineup` | CODE | **NON VÉRIFIÉ** |
| R-08 | `/matches/:matchId/vote` | CODE | **NON VÉRIFIÉ** |
| R-09 | `/matches/:matchId/finalize` | CODE | **NON VÉRIFIÉ** |
| R-10 | `/matches/:matchId/prediction` | CODE | **NON VÉRIFIÉ** |
| R-11 | `/matches/:matchId/composition` | CODE | **NON VÉRIFIÉ** |
| R-12 | `/matches/:matchId/guests` | CODE | **NON VÉRIFIÉ** |
| R-13 | `/admin` | CODE | **NON VÉRIFIÉ** |
| R-14 | `/admin/settings` | CODE | **NON VÉRIFIÉ** |
| R-15 | `/admin/stadiums` | CODE | **NON VÉRIFIÉ** |
| R-16 | `/admin/administration` | CODE | **NON VÉRIFIÉ** |
| R-17 | `/admin/season` | CODE | **NON VÉRIFIÉ** |
| R-18 | `/admin/matches` | CODE | **NON VÉRIFIÉ** |
| R-19 | `/admin/composition` | CODE | **NON VÉRIFIÉ** |
| R-20 | `/admin/guests` | CODE | **NON VÉRIFIÉ** |
| R-21 | `/admin/waitlist` | CODE | **NON VÉRIFIÉ** |
| R-22 | `/waitlist` | CODE | **NON VÉRIFIÉ** |
| R-23 | `/admin/badges` | CODE | **NON VÉRIFIÉ** |
| R-24 | `/admin/notification` | CODE | **NON VÉRIFIÉ** |
| R-25 | `/admin/club` | CODE | **NON VÉRIFIÉ** |
| R-26 | `/admin/club/maillots` | CODE | **NON VÉRIFIÉ** |
| R-27 | `/admin/history` | CODE | **NON VÉRIFIÉ** |
| R-28 | `/more` | CODE | **NON VÉRIFIÉ** |
| R-29 | `/players` | CODE | **NON VÉRIFIÉ** |
| R-30 | `/profile` | CODE | **NON VÉRIFIÉ** |
| R-31 | `/armoire` | CODE | **NON VÉRIFIÉ** |
| R-32 | `/notifications` | CODE | **NON VÉRIFIÉ** |
| R-33 | `/unavailability` | CODE | **NON VÉRIFIÉ** |
| R-34 | `/stats` | CODE | **NON VÉRIFIÉ** |
| R-35 | `/stats/joueur` | CODE | **NON VÉRIFIÉ** |
| R-36 | `/stats/joueur/classement` | CODE | **NON VÉRIFIÉ** |
| R-37 | `/pronos` | CODE | **NON VÉRIFIÉ** |
| R-38 | `/wrapped` | CODE | **NON VÉRIFIÉ** |
| R-39 | `/predictions` | CODE | **NON VÉRIFIÉ** |
| R-40 | `/predictions/leaderboard` | CODE | **NON VÉRIFIÉ** |
| R-41 | `/statistics` | CODE | **NON VÉRIFIÉ** |
| R-42 | `/auth/loading` | CODE | **NON VÉRIFIÉ** |
| R-43 | `/auth/sign-in` | CODE | **NON VÉRIFIÉ** |
| R-44 | `/auth/register` | CODE | **NON VÉRIFIÉ** |
| R-45 | `/auth/choose-club` | CODE | **NON VÉRIFIÉ** |
| R-46 | `/auth/confirm-email` | CODE | **NON VÉRIFIÉ** |
| R-47 | `/legal/:slug` | CODE | **NON VÉRIFIÉ** |
| R-48 | `/auth/new-password` | CODE | **NON VÉRIFIÉ** |

## À compléter par recette visuelle
Chaque écran doit être parcouru avec admin, joueur, en attente, archivé, visiteur, et sur Club Test B lorsque pertinent ; recenser boutons et menus contextuels au moment de l'exécution, comparer avec AS Grinta en lecture seule. Les boutons sont **NON VÉRIFIÉS** : le simple recensement des fichiers n'est pas un inventaire exhaustif des contrôles visibles.
