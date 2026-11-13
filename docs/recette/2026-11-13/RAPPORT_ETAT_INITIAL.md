# Rapport d'état initial — Recette intégrale Petit Filet

Date : 13 novembre 2026. Dépôt visé : main, commit `2dc59830baf986e6a7d4b6fa93aabcf9869b17b9`.

## Verdict en 5 lignes

1. **NON VALIDÉ** pour accueillir un vrai club sans réserve.
2. Les tests de code automatiques existent ; aucune saison complète n'a été jouée dans cette mission.
3. Aucune interaction authentifiée réelle ni réception push/e-mail n'a été observée.
4. La base commerciale comporte déjà deux clubs fictifs, mais aucun jeu de 300 historiques et 30 matchs saisonniers.
5. La grille des tests est créée ; toutes ses lignes restent **non vérifiées** tant qu'aucune preuve écran ou exécution métier n'existe.

## Préparation observée : requêtes SELECT en base commerciale

| Indicateur | Club Test A | Club Test B |
|---|---:|---:|
| Profils | 21 | 21 |
| Joueurs affectés à la saison ouverte 2026-2027 | 21 | 21 |
| Administrateurs actifs | 1 | 1 |
| Joueurs/pronostiqueurs actifs | 20 | 20 |
| Matchs à venir (1 amical + 1 championnat) | 2 | 2 |
| Badges en catalogue | 67 | 67 |

En base globale : 2 fiches d'historique, 84 pronostics, 0 session Live, 0 vote Étoile, 0 bilan Wrapped et 0 snapshot de tenue enregistré. Les **42 profils sont actifs** (aucun profil en attente/archivé). Les deux clubs sont actifs. A a un logo absent et un nom court `CTA2`; B a un logo renseigné et couleurs primaire/secondaire identiques (bleu). Ces constats sont des données existantes, **pas des anomalies fonctionnelles démontrées**.

Présence technique : 257 signatures de fonctions `public` ; 8 fonctions Edge déclarées actives ; une famille d'alertes du linter de sécurité signale 164 fonctions `SECURITY DEFINER` exécutables par `authenticated` — **pas 164 vulnérabilités prouvées**. Un audit de chaque contrôle interne reste nécessaire.

## Tableau des défauts / écarts constatables

| Niveau | Élément | Reproduction / preuve | Attendu | Obtenu | Capture | Cause probable / correction |
|---|---|---|---|---|---|---|
| Bloquant pour la recette | Parcours E2E impossible dans cette session | Ouvrir le site avec un navigateur interactif et les comptes fictifs | Une saison de 30 rencontres jouée et documentée | Site accessible par HTTP, mais interface Flutter non pilotable par les outils disponibles | Non disponible | Exécuter sur navigateur/Flutter local complet + compte de test |
| Gênant, fonction absente du code identifié | Match « coupe » | Vérifier enum `match_model.dart` et formulaire | Créer un match de coupe prévu dans les 30 cas | L'audit et le formulaire listent championnat, amical, entre nous ; écran **non vérifié** | Non disponible | Spécifier intégration de « coupe » dans modèles, UI, SQL, classement, tests ; PR distincte |
| Gênant, préparation | 25 joueurs requis, statuts en attente/archivé/invité | SELECT effectif 2026-2027 du Club A | Au moins 25, plus les statuts variés | 21 joueurs de saison, tous les profils actifs | Non disponible | Compléter jeu de données par UI normale uniquement |
| Gênant, préparation | 300 historiques et 30 matchs à jouer | SELECT objets historiques et matchs | 300 historiques + 30 cycles réels | 2 fiches historiques globales et 2 matchs à venir pour A | Non disponible | Saisie normale via application, relever la durée |
| À vérifier | Couleurs des tenues dans anciens matchs | Publier composition, changer couleurs, revenir en arrière | Le maillot du match passé est figé | 0 snapshot enregistré en base ; **le comportement reste inconnu** | Non disponible | Vérifier déploiement de la migration et parcours ; PR ciblée seulement après reproduction |
| À vérifier | Version du site | Comparer SHA main et dernier déploiement Pages validé | Tester même version que main | Dernier run de publication trouvé sur `f64576a` ; main est `2dc59830` | Non disponible | Vérifier le SHA effectivement servi ; publier séparément uniquement avec accord |

**Aucun correctif n'est déclaré appliqué sans test rouge→vert.** Ce tableau sépare les lacunes de préparation, les points documentés et les véritables bugs qui restent à reproduire.

## Actions réellement menées

Lecture de code et audit, arbre GitHub, inventaire des pages, requêtes **SELECT seulement**, présence des badges, règles, rôles, flux, RPC, état CI. **Aucune opération utilisateur (admin/coach/joueur) n'a été faite**, aucune notification réellement déclenchée, aucune écriture direct DB, migration, suppression de compte, fusion, déploiement ou clôture. Le chemin `tests/cloisonnement/rapport.md` cité dans la consigne est absent de `main` ; les identifiants/mots de passe de test n'ont pas été récupérés depuis ce fichier.

**Site :** `https://petit-filet.pages.dev/` fournit sa page HTTP publique ; la session de travail ne dispose pas d'un navigateur distant interactif pour se connecter et cliquer dans Flutter. **Local :** impossible de démarrer une copie équivalente faute de SDK Flutter et d'accès réseau Git pour cloner le dépôt. Aucun faux test écran n'est comptabilisé.

## Vérifications non exécutées et conditions nécessaires

- Vrais téléphones iOS/Android et PWA : connexion, mode sombre, 320 px, erreurs réseau, arrière-plan.
- Comptes fictifs utilisables dans navigateur contrôlable, y compris admin Club B, en attente et archivé ; vérifier la liste des comptes via un emplacement autorisé.
- Réception réelle de chaque famille de push, e-mail de récupération, rappel et notifications coupées.
- 300 matchs d'historique et 30 matchs de saison via formulaires avec chronomètre et contrôle indépendant de tous les chiffres.
- RLS/permissions sous véritables JWT pour chaque rôle, Storage, Realtime, fonctions SQL, fonctions Edge.
- Copie **jetable** de Supabase pour faire la clôture et contrôler titres, récompenses, bilan de chaque joueur, sans clôturer Club Test A.

## État exact laissé dans Club Test A

**Zéro donnée créée, corrigée ou supprimée par cette mission.** Effectif, matchs, statistiques, saisons, photos, badges, réglages et notifications restent dans leur état initial. La saison 2026-2027 demeure ouverte, prête à poursuivre les tests par un utilisateur. Aucune modification d'AS Grinta, de Carte soirée ou de leur base. Seule une branche GitHub de documentation a été créée ; elle ne doit pas être fusionnée sans validation de Samih.
