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

## Lot M02-C06 — Nombre de convoqués par défaut

**Statut : préparé sur branche dépendante de C05, à valider en CI.**

- **Objectif :** ticket C06/D11. Les admins peuvent changer de 1 à 30 joueurs convoqués pour les futurs matchs sans toucher aux effectifs existants.
- **Technique :** réutilise `private.app_feature_flags.config.usual_squad_size` ; RPC admin qui modifie uniquement le club courant et laisse intactes les autres propriétés JSON. Le déclencheur de signal Realtime existant notifie les autres appareils du club.
- **Compatibilité :** les formulaires utilisent déjà `sportsManagement.usualSquadSize` à la création ; quota historique par match conservé, valeur par défaut 14 si club non configuré.
- **Tests :** Flutter (boutons plus/moins) et SQL (quota A/B, 1..30, refus membre). Test sur deux clubs fictifs nécessaire après validation.
- **Migration :** `20261112070000_club_usual_squad_size.sql`, seulement préparée sur GitHub ; aucune écriture sur la base commerciale.
- **Décision propriétaire :** migration, fusion et déploiement soumis à accord explicite, dans l'ordre C05 puis C06.

## À faire ensuite, sans chevaucher les autres fils

1. **P12/P13 :** maillots du club + compatibilité avec portraits de joueurs ; à coordonner avec fil 05 et droit à l'image (fil 07).
2. **R09 :** vocabulaire de trophées/HDM neutre selon arbitrage du fil 05.
3. **A06, P02/P03/P04 :** collisions des identifiants, formats de football et compositions adaptées.
4. **D12/D13, M20 :** liste d'attente et historique : travail à récupérer des fils existants ; ne pas réécrire le moteur.

## Règles suivies

Aucun accès en écriture à la base commerciale ; jamais de changement dans AS Grinta original. Chaque lot = branche et PR dédiée ; pas de fusion avant revue et contrôles verts. La PR #29 reste pilotée par le fil 00.
