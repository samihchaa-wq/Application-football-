# Plan de découpage des modules (27/11/2026)

Point 37 de l'audit du 26/11. Mesuré sur `lib/` au commit de cette note, en
comptant les imports `package:petit_filet/...` entre modules (`app`, `core`,
chaque dossier de `features/`).

## Constat

- 27 paires de modules s'importent mutuellement (l'audit en comptait 28).
- `core` importe 10 features, mais depuis 4 fichiers seulement :
  - `core/club/club_kits.dart` et `core/club/match_kit_snapshot.dart` →
    `features/matches/domain/jersey_option.dart` (un simple type de maillot) ;
  - `core/widgets/pf_app_bar.dart` → les boutons cloche, trophée et bilan de
    saison (`notifications`, `badges`, `season_wrapped`) ;
  - `core/sync/shared_data_sync.dart` → 20 fichiers de 9 features : c'est le
    chef d'orchestre qui recharge les données après un changement serveur.
- Cycle principal : `match_live` ⇄ `sports_management` (28 / 4 imports),
  `matches` ⇄ `sports_management` (15 / 18), `matches` ⇄ `match_live` (5 / 3).

Ce que ça change pour l'utilisateur : rien aujourd'hui. Le risque est pour la
suite : une modification d'un écran peut casser un module qui ne devrait pas
en dépendre, et les tests d'un module tirent tout le reste.

## Plan progressif

Chaque étape est une PR courte, sans changement de comportement, avec un test
d'architecture qui empêche le retour en arrière.

1. Rendre `core` indépendant (première PR, voir plus bas).
2. `match_live` ⇄ `sports_management` : sortir les modèles partagés
   (composition, joueurs du match) dans `sports_management/domain` et faire
   dépendre `match_live` de ce seul dossier.
3. `matches` ⇄ `sports_management` : même méthode, les deux ne partagent que
   des modèles de match et de convocation.
4. `matches` ⇄ `predictions` (3 / 20) : la carte de pronostic affichée dans le
   calendrier est fournie par `predictions` à `matches` par un point
   d'injection, au lieu d'un import direct.
5. Paires restantes (club, auth, profile, billing, platform…) : une par une,
   les plus petites d'abord.

## Première PR : `core` indépendant

- `jersey_option.dart` passe dans `core/club/`. L'ancien chemin devient un
  simple renvoi (`export`) : aucun des 19 fichiers qui l'importent ne change.
- `pf_app_bar.dart` : les trois boutons sont fournis par `app` au démarrage
  (un emplacement « actions par défaut » rempli dans `app.dart`), au lieu
  d'être importés par `core`. À vérifier : les tests d'écran qui affichent la
  barre sans démarrer l'appli devront remplir cet emplacement.
- `shared_data_sync.dart` : la partie « signal » (lecture du signal serveur,
  curseur, décision de recharger) reste dans `core` ; la partie qui sait quoi
  recharger (la liste des 20 fournisseurs) passe dans `app/`. Deux features
  (`feature_flags`, `sports_management`) importent ce fichier : elles ne
  doivent utiliser que la partie « signal ».
- Test d'architecture : aucun fichier de `core/` n'importe `features/` ni
  `app/`.

## Pourquoi cette PR n'est pas encore faite

Le 27/11, 13 autres PR de correctifs sont ouvertes en parallèle. Déplacer des
fichiers centraux (barre d'en-tête, synchronisation) maintenant créerait des
conflits dans plusieurs d'entre elles. À lancer une fois ces PR fusionnées.
