# Journal Sécurité (agent Kyky Sécurité)

## 23/11/2026
- Fait (écrit, non testé : pas de base locale ni pgTAP ici) :
  - Lot 1 : déjà couvert. `public_definer_execution.test.sql` exige un garde ou une ligne motivée pour chaque fonction exposée. Rien ajouté.
  - Lot 2 : déjà fait (migration 20261125000000, 41 fonctions). Vérifié en vrai (lecture prod) : 161 fonctions exposées ; seules 4 jamais appelées restent, voulues (démo, règles d'accès, Live public).
  - Lot 3 : migration 20261203030000 + test cron_busy_clubs_only. Le parcours filtrait déjà les clubs suspendus ; il saute maintenant les clubs sans match proche/Live/vote pour 6 tâches.
  - Lot 4 : migration 20261203040000 + test club_creation_limits. Création reste ouverte.
  - Lot 5 : SECURITY_RPC_MATRIX.md et production-operations.md mis à jour.
- Décidé : création de club ouverte (propriétaire, 23/11).
- Reste à faire (moi) : lot 6 (pannes réseau côté appli), brancher check_club_creation_limits dans claim-club et register-account, adapter notifications_v2_contract.test.sql (attend run_for_each_club pour prediction-j5-reminders).
- Reste (propriétaire) : accord pour appliquer les 2 migrations ; valider les seuils de création (3/j adresse, 2/j e-mail, 60 s, 20/h) ; test de charge 500/1000 clubs.
- Outils manquants : graphify (installation refusée par la session), pgTAP/Supabase CLI/docker sans démon. `.claude/agents/kyky.md` supprimé du dépôt (commit 48377f4) : règles lues dans le prompt.
- Hors périmètre : aucun.

## 23/11/2026 (2e passage, soir)
- Vérifié en lecture : test notifications_v2_contract accepte déjà run_for_each_busy_club (rien à adapter).
- Lot 6 : l'appli a déjà un classement central des pannes réseau (error_category.dart, app_errors.dart). Aucun changement fait : Flutter absent ici, donc rien de testable. Reste à auditer écran par écran (propriétaire/Écrans).
- Non fait volontairement : brancher check_club_creation_limits dans claim-club/register-account. Demande de redéployer les fonctions Edge ET d'appliquer la migration 20261203040000 ensemble. Attente accord propriétaire.
- Outils absents : graphify (pas de carte), Flutter, pgTAP/Supabase CLI. Dossier projet « Petit filet » (charte, messages) illisible : erreur 404 de l'outil Projects.
- Hors périmètre : aucun.

## 23/11/2026 (3e passage, nuit)
- Rien de nouveau à écrire : lots 1 à 6 déjà faits ou en attente d'accord propriétaire. Branche en retard de 6 commits sur main (pas fusionnée, par règle).
- Reste (propriétaire) : accord pour appliquer 20261203030000 et 20261203040000 ; seuils de création ; brancher check_club_creation_limits (Edge + migration ensemble).
- Outils absents : graphify, Flutter, pgTAP/Supabase CLI, Docker (pas de démon). Dossier projet « Petit filet » illisible (404).
- Hors périmètre : aucun.

## 24/11/2026 (4e passage)
- Rien de nouveau : lots 1 à 6 faits ou en attente d'accord propriétaire (voir passages du 23/11).
- Reste (propriétaire) : appliquer 20261203030000 et 20261203040000 ; valider seuils de création ; brancher check_club_creation_limits (Edge + migration ensemble).
- Outils absents : graphify, Flutter, pgTAP/Supabase CLI. Dossier projet « Petit filet » (charte, messages) illisible : 404.
- Hors périmètre : aucun.

## 24/11/2026 (5e passage)
- Rien de nouveau à faire : lots 1 à 6 faits ou en attente d'accord propriétaire. Aucune réponse du propriétaire dans KYKY_QUESTIONS.
- Point d'attention : main a une migration plus récente (20261204000000). Mes 2 migrations (20261203030000, 20261203040000) ont une date plus ancienne : à appliquer avec l'option « hors ordre » (--include-all), sinon elles seront sautées.
- Reste (propriétaire) : accord pour appliquer les 2 migrations ; seuils de création ; brancher check_club_creation_limits (Edge + migration ensemble).
- Outils absents : graphify, Flutter, pgTAP/Supabase CLI. Dossier projet « Petit filet » (charte, messages) illisible : 404.
- Hors périmètre : aucun.
