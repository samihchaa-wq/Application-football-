# MISSION 02 — Transformation multiclub (coordination avec le fil 00)

Mise à jour : 12 novembre 2026. Références : [CHANTIER.md](CHANTIER.md) (PR #29), [HANDOFF.md](HANDOFF.md), audit fil 01 (PR #25).

## Lot M02-C05 — Terrain à domicile par club

**Statut : implémenté dans une branche et proposé en PR, pas déployé, pas validé en conditions réelles.**

- **Objectif :** ticket C05 de l'audit : régler l'adresse permanente du stade depuis « Réglages du club ». Garder la possibilité de la remplacer match par match.
- **Réemploi du fonctionnement existant :** `club_settings.home_address` est déjà utilisé dans les formulaires de match pour préremplir un match à domicile. Aucun écran de match n'est reconstruit.
- **Client Flutter :** un champ dans les réglages, possibilité de vider l'adresse ; lecture via RLS, écriture via RPC réservé à l'admin.
- **Migration proposée, non appliquée :** `20261112060000_club_home_address_settings.sql`, contrôle du rôle `private.is_admin()`, écriture limitée à `private.current_club_id()`, longueur <= 200 et exclusion des caractères de contrôle. Base commerciale inchangée.
- **Tests ajoutés :** Widget Flutter (chargement, modification, effacement) ; pgTAP (admin A, refus membre, isolation du club B, validations, remise à zéro).
- **Contrôles :** attendre les résultats GitHub CI et SQL ; **ne pas déclarer testé** tant que ces contrôles ne sont pas verts.
- **Risques :** migration obligatoire avant déploiement du client ; serveur et client ne doivent pas être déployés dans le mauvais ordre.
- **Transmission fil 03 :** tester adresse enregistrée, préremplissage d'un match domicile, modification ponctuelle et absence d'effet sur matchs extérieurs ; recharger les réglages après déconnexion/reconnexion.
- **Transmission fil 04 :** contrôler RPC membre, admin club A/B, accès REST direct à `club_settings`, longueur, rôles et privilèges effectifs.
- **Décision propriétaire requise :** **accord explicite avant application de la migration à la base commerciale**, fusion et déploiement sous pilotage du fil 00.

## À faire ensuite, sans chevaucher les autres fils

1. **C06/D11 :** rendre le quota habituel de convoqués paramétrable par club, tout en conservant les quotas propres à un match ; code actuel : `sports_management.config.usual_squad_size` (14 par défaut). Lot distinct.
2. **P12/P13 :** maillots du club + compatibilité avec portraits de joueurs ; à coordonner avec fil 05 et droit à l'image (fil 07).
3. **R09 :** vocabulaire de trophées/HDM neutre selon arbitrage du fil 05.
4. **A06, P02/P03/P04 :** collisions des identifiants, formats de football et compositions adaptées.
5. **D12/D13, M20 :** liste d'attente et historique : travail à récupérer des fils existants ; ne pas réécrire le moteur.

## Règles suivies

Aucun accès en écriture à la base commerciale ; jamais de changement dans AS Grinta original. Chaque lot = branche et PR dédiée ; pas de fusion avant revue et contrôles verts. La PR #29 reste pilotée par le fil 00.
