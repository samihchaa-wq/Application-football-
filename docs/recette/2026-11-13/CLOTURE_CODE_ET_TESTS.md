# Clôture de saison : effets vérifiés dans le code et le schéma (pas exécutés)

**13 novembre 2026.** Informations lues exclusivement via `SELECT` sur Supabase commercial et fichiers GitHub `main`. Aucun match simulé, aucune saison archivée, aucune copie jetable créée.

## Avant de cliquer : garde-fous serveur identifiés

L'appel `public.set_season_status(season_id, 'archived')` déclenche un `BEFORE UPDATE` `trg_guard_season_competition_finality` qui appelle `private.assert_season_can_archive`. Il refuse une saison si :
- au moins un match n'a pas le statut `termine`, `archive` ou `annule` ;
- une rencontre terminée est encore dans sa fenêtre de correction après-match.

Ces refus sont **vérifiés dans le code de la base**, pas reproduits avec un véritable JWT admin. Il faut tester que ces erreurs sont bien compréhensibles à l'écran.

## Après un passage en `archived` : effets identifiés

1. `trg_finalize_season_competition` appelle `public.award_season_titles` **dans la même transaction** : calcule et attribue les titres de saison selon présence, buts, passes, Étoile, pourcentage de victoire et pronostics (avec conditions d'éligibilité et égalités prévues). Relance également `public.recalculate_all_badges`. Un échec de cette partie annule le changement de statut.
2. `trg_season_wrapped` appelle `private.signal_season_wrapped` pour inscrire un travail dans `private.season_wrapped_jobs`. Le traitement est **différé**, pas nécessairement disponible immédiatement après le clic.
3. La tâche Supabase `process-season-wrapped-jobs` est observée **active, toutes les cinq minutes** au moment de la lecture. `private.process_season_wrapped_jobs` tente jusqu'à cinq fois de construire les bilans et enregistre erreur/tentatives. La livraison réussie de chaque bilan reste **non vérifiée**.
4. `private.build_season_wrapped` calcule par joueur : matchs/victoires/nuls/défaites, clean sheets, buts, Étoiles, poste préféré et répartition des postes, indicateurs de disponibilité et autres éléments visibles dans le code. Il ne produit pas les bilans des saisons non prises en charge par la fonction de compatibilité.
5. `lib/features/season_wrapped/presentation/season_wrapped_page.dart` affiche le bilan personnel et une prévisualisation fictive pour administrateur. `lib/features/season_wrapped/data/wrapped_music.dart` lit `assets/audio/wrapped.mp3` (fichier réellement présent, ~1 Mo) si activé, avec un repli silencieux en cas d'échec. **Lecture sur téléphone et droits de la piste non vérifiés par cette recette** ; le README du dossier décrit une piste synthétisée par le projet.

## Tests de clôture à exécuter sur une base jetable seulement

| ID | Scénario | État |
|---|---|---|
| FIN-01 | Refus d'archiver avec un match `a_venir` | Non vérifié |
| FIN-02 | Refus d'archiver pendant la fenêtre de correction | Non vérifié |
| FIN-03 | Acceptation lorsque tous les matchs sont terminés/annulés et corrigés | Non vérifié |
| FIN-04 | Clôture en double clic et par deux admins simultanés | Non vérifié |
| FIN-05 | Titres des meilleurs buteurs/passeurs/présents/Étoiles/victoires/pronos ; ex æquo | Non vérifié |
| FIN-06 | Recalcul de chaque badge et notification de déblocage sans doublon | Non vérifié |
| FIN-07 | Création d'un travail de bilan et passage de la tâche au statut traité | Non vérifié |
| FIN-08 | Contrôle bilan de **chaque joueur** contre les calculs indépendants | Non vérifié |
| FIN-09 | Musique activée puis coupée, mode silencieux sur iOS, et repli sans son | Non vérifié |
| FIN-10 | Affichage, partage, export PWA et lecture archive après nouvelle saison | Non vérifié |
| FIN-11 | Échec/réessai tâche Wrapped, récupération sans perte | Non vérifié |
| FIN-12 | Tentative de réouverture d'une saison archivée déjà jouée | Non vérifié |

**Ne jamais réaliser ces tests de clôture dans Club Test A.** Sa saison actuelle doit rester ouverte et les 30 rencontres entièrement jouées pour que Samih la clôture lui-même. Préparer une base jetable implique une copie/sauvegarde correctement isolée, d'éventuels coûts à faire approuver et les règles de protection des identifiants fictifs.
