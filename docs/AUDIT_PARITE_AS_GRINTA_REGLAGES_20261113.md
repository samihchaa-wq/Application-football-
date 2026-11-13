# Petit Filet — parité fonctionnelle AS Grinta et refonte des réglages

> **Décision corrigée :** les +1 sont **exclusivement manuels**, attribués par les administrateurs. La [PR #105](https://github.com/samihchaa-wq/Application-football-/pull/105) prépare le retrait du cron sans écriture en production. Cette décision remplace l'ancienne automatisation du coup d'envoi ; les autres constats de parité restent historiques.

**Date : 13 novembre 2026.** Périmètre : dépôt commercial `samihchaa-wq/Application-football-`. Source AS Grinta lue **sans aucune écriture**. Aucun accès en écriture à Supabase, aucun déploiement, aucun test E2E réel.

## Méthode et bilan vérifiable

- Lecture du registre de référence `docs/AUDIT_FONCTIONNALITES_DETAILLE.md` : **164 unités fonctionnelles** classées **77 conserver (C), 33 modifier (M), 36 rendre paramétrables (P), 17 optionnelles (O), 1 supprimer (S)**. Les décisions de ce registre sont des politiques produit, pas un taux d'exécution.
- Comparaison GitHub des arborescences de `main` des deux dépôts, le 13/11/2026 : **290 chemins partagés dans `lib/`**, dont **102 contenus différents**. **0 fichier `lib/` original absent** du commercial ; le commercial contient 51 fichiers `lib/`/`test/` supplémentaires par rapport à l'original.
- **Un seul test original sans équivalent au même chemin** : `test/features/sports_management/domain/composition_simulation_season_replay_test.dart`. Il comprend de vraies identités sportives : **ne pas recopier tel quel dans un dépôt public**. Proposer, séparément, une version entièrement fictive et tester le même invariant.
- Ressources originales non recopiées : `assets/audio/wrapped.mp3`, `assets/images/as_grinta_logo.webp`, trois maillots nommés selon le club original. Éléments spécifiques ou à droits à vérifier ; absence **intentionnelle**, pas preuve d'une fonctionnalité manquante.
- PR récentes **fusionnées** sur le commercial : #57 (règles par club), #69 (+1 manuels), #72 (administration Effectif), #73 (contrôle club suspendu). Au contrôle de ce chantier : **aucune PR ouverte**.
- **Limite importante** : égalité d'arborescence ≠ égalité de comportement ni conformité serveur. Les 102 fichiers Flutter modifiés et les RPC/migrations doivent être vérifiés par scénarios.

## Décision par famille

| Fonctionnalités | Décision | Situation et suite |
|---|---|---|
| Comptes, joueurs, effectifs, matchs, calendrier, compositions, simulation, Live, statistiques et historiques | **Conserver** | Structures présentes dans les deux dépôts ; tests de parcours et droits multiclub encore nécessaires |
| Création et appartenance à un club, invitation, validation, rôles et suspension | **Modifier** | Flux spécifiques au multiclub déjà codés ; tester utilisateur A/B et refus serveur |
| Nom, écusson, couleurs de l'application, maillots joueurs/gardien, terrain à domicile | **Paramétrable** | Écrans et dépôts commerciaux présents ; vérifier propagation aux compositions, vidéo, historique |
| Quota de convocations, mode d'attente, ouverture des fonctions, règles de pronostics, fenêtre de correction | **Paramétrable** | RPC et interface présents ; les +1 sont **automatiques au coup d’envoi** et permanents sur la saison (PR #86) |
| Pronostics, statistiques, Étoile du match, Live, badges, bilan, météo | **Activable/désactivable** | **Sept** interrupteurs existants regroupés par domaine. Ne pas ajouter d'autres interrupteurs sans règles serveur correspondantes |
| Animation vidéo et portraits personnels | **Conserver / adapter** | Présentation à conserver, mais retirer l'identité AS Grinta des médias (issue #71) et vérifier les droits ; ne pas réintroduire les ressources du club original |
| Saison personnalisée, fuseau hors Paris, formation par défaut, autres formats que football à 11, clips individuels | **À étudier / adapter** | Pas prouvé comme fonctions complètes du commercial. Ne pas inventer de réglage inopérant : décision produit, serveur et tests avant développement |
| Barème historique obsolète / ressources liées exclusivement au club initial | **Supprimer uniquement si inutile** | Préserver compatibilité et données passées ; ne jamais supprimer des fonctions utiles ni des données par simple copie |

## Réorganisation livrée dans cette branche

**Écran :** `lib/features/admin/presentation/club_settings_page.dart`.

- Sept catégories repliables : **Identité et maillots ; Effectif et convocations ; Matchs et direct ; Pronostics ; Statistiques et récompenses ; Membres et invitations ; Abonnement**.
- Une huitième catégorie **Autres réglages** apparaît automatiquement en présence de clés/modules nouveaux, pour éviter de masquer silencieusement un réglage inconnu.
- Chaque module/règle a un intitulé court, une commande directe et un petit **i** qui ouvre une fenêtre d'explication. Pas de description permanente. Valeur par défaut des règles visible dans l'aide.
- La liste d'attente utilise une **liste déroulante à trois modes** au lieu de trois blocs d'explication ; l'aide explique les +1 automatiques (PR #86).
- Les mêmes RPC de lecture/écriture, identifiants de clés et bornes sont conservés. Pas de migration, pas de modification des données ou des droits.
- Test Flutter existant adapté à la navigation par catégories, au mode de liste d'attente et à l'aide contextuelle : `test/features/admin/presentation/club_settings_page_test.dart`.

## Contrôles requis avant toute fusion

1. `dart format --output=none --set-exit-if-changed lib/features/admin/presentation/club_settings_page.dart test/features/admin/presentation/club_settings_page_test.dart`.
2. `flutter analyze` et `flutter test test/features/admin/presentation/club_settings_page_test.dart` sur le SHA de la PR.
3. Sur téléphone étroit : intitulés longs, ouverture/fermeture des catégories, défilement, info **i**, tous les boutons +/- et interrupteurs, navigation maillots et sauvegardes.
4. Deux clubs fictifs : modifier les 7 interrupteurs et les règles pour A, vérifier que B n'a pas changé, que l'historique subsiste, et que les fonctions désactivées sont refusées au **serveur**.
5. Vérifier le statut **déployé** des migrations commerciales déjà fusionnées (#69 en particulier) ; **ne pas appliquer de migration sans accord**.
6. Recontrôler 164 scénarios du registre détaillé, notamment ceux associés aux 102 fichiers `lib/` modifiés ; la refonte visuelle ne constitue pas une validation de parité.

## Questions produit restantes

- Se limiter aux équipes de **football à 11** au lancement (choix déjà établi), sans ajouter 5/7/8.
- Formation tactique de départ : garder 4-2-1-3 tant qu'une valeur par club n'est pas intégrée **de bout en bout**.
- Saisons, fuseaux, clips vidéo individuels : travaux distincts après décision, sans déplacer les responsabilités de sécurité/QA.
- Aucun effet destructif : ne jamais altérer AS Grinta original ni ses données.

**Statut :** audit des chemins et classification tracés ; refonte Flutter proposée dans la branche ; **CI/E2E/serveur non encore validés**.
