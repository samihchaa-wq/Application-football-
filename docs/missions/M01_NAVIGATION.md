# M01 — Navigation à recetter

Baseline 5f404e70f70b4e99d754f7064b567d027d66fe03. Extraction statique du routeur ; aucune ouverture de ces routes par M01. Les IDs R-01 à R-48 reprennent le registre du 13/11. Les 41 entrées de l’audit initial regroupaient certaines redirections ; les comptes ne sont pas directement comparables.

Responsables : M01 qualification, M02 réalisation, M03 recette ; M04 permissions. Pour chaque REC-R-nn : ouvrir depuis menu puis URL directe, contrôler session absente/en attente/active/suspendue, rôle admin/joueur/coach, identifiant inexistant/autre espace, module OFF, retour et rechargement PWA. Les conditions et le contenu précis de chaque écran restent à qualifier ; ce tableau n’est pas un inventaire des boutons.

| ID / scénario | Route | Source | Résultat |
|---|---|---|---|
| R-01 / REC-R-01 | `/` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-02 / REC-R-02 | `/home` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-03 / REC-R-03 | `/accueil` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-04 / REC-R-04 | `/matches` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-05 / REC-R-05 | `/matches/:matchId` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-06 / REC-R-06 | `/matches/history/:matchId` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-07 / REC-R-07 | `/matches/:matchId/lineup` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-08 / REC-R-08 | `/matches/:matchId/vote` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-09 / REC-R-09 | `/matches/:matchId/finalize` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-10 / REC-R-10 | `/matches/:matchId/prediction` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-11 / REC-R-11 | `/matches/:matchId/composition` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-12 / REC-R-12 | `/matches/:matchId/guests` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-13 / REC-R-13 | `/admin` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-14 / REC-R-14 | `/admin/settings` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-15 / REC-R-15 | `/admin/stadiums` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-16 / REC-R-16 | `/admin/administration` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-17 / REC-R-17 | `/admin/season` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-18 / REC-R-18 | `/admin/matches` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-19 / REC-R-19 | `/admin/composition` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-20 / REC-R-20 | `/admin/guests` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-21 / REC-R-21 | `/admin/waitlist` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-22 / REC-R-22 | `/waitlist` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-23 / REC-R-23 | `/admin/badges` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-24 / REC-R-24 | `/admin/notification` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-25 / REC-R-25 | `/admin/club` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-26 / REC-R-26 | `/admin/club/maillots` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-27 / REC-R-27 | `/admin/history` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-28 / REC-R-28 | `/more` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-29 / REC-R-29 | `/players` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-30 / REC-R-30 | `/profile` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-31 / REC-R-31 | `/armoire` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-32 / REC-R-32 | `/notifications` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-33 / REC-R-33 | `/unavailability` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-34 / REC-R-34 | `/stats` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-35 / REC-R-35 | `/stats/joueur` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-36 / REC-R-36 | `/stats/joueur/classement` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-37 / REC-R-37 | `/pronos` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-38 / REC-R-38 | `/wrapped` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-39 / REC-R-39 | `/predictions` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-40 / REC-R-40 | `/predictions/leaderboard` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-41 / REC-R-41 | `/statistics` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-42 / REC-R-42 | `/auth/loading` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-43 / REC-R-43 | `/auth/sign-in` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-44 / REC-R-44 | `/auth/register` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-45 / REC-R-45 | `/auth/choose-club` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-46 / REC-R-46 | `/auth/confirm-email` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-47 / REC-R-47 | `/legal/:slug` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
| R-48 / REC-R-48 | `/auth/new-password` | lib/app/router/app_router.dart | CODE ; parcours non exécuté |
