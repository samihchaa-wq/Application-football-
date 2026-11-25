# Plan d'audit complet — 25/11/2026

Périmètre : app Flutter (370 fichiers, 22 modules), Supabase (83 migrations,
11 fonctions serveur), 283 tests, docs. Statut : **plan à valider, rien audité**.

## Méthode
- Carte du code : graphe graphify (mise à jour en phase 0).
- Chaque constat : gravité (bloquant / important / mineur), preuve (fichier,
  commande), correctif proposé. Rien n'est déclaré « OK » sans vérification.
- Résultats dans `docs/AUDIT_COMPLET_20261125.md`, un chapitre par phase.
- Anciens audits (docs/AUDIT_*) : relus pour vérifier ce qui reste ouvert,
  pas recopiés.

## Phases (ordre = risque décroissant)

| # | Phase | Contenu | Skill |
|---|---|---|---|
| 0 | État des lieux | graphe à jour, compilation, analyse statique, tests, couverture | verification-before-completion |
| 1 | Sécurité | droits par club/rôle (RLS), fonctions serveur, secrets, invitations, données perso | vibesec, supabase |
| 2 | Paiements | Stripe : achat, remboursement, webhook, cas d'échec | stripe-best-practices |
| 3 | Base de données | schéma, migrations rejouables, index, requêtes lentes, sauvegarde/restauration | supabase-postgres-best-practices |
| 4 | Bugs & logique | parcours clés (inscription, match, prono, stats, notifications), cas limites | systematic-debugging, code-review |
| 5 | Architecture & état | Riverpod, découpage, code mort, doublons | state-management-riverpod, simplify |
| 6 | UX/UI | états vide/chargement/erreur, formulaires, mobile/tablette, accessibilité | ui-states-and-feedback, forms-and-input, adaptive-layout |
| 7 | Performance | listes, images, reconstructions d'écran, poids de l'app | flutter-performance |
| 8 | Tests | trous de couverture sur zones sensibles, tests fragiles | test-driven-development |
| 9 | Publication | versions, signature, permissions, déclarations stores, juridique (RGPD) | release-and-store-shipping |
| 10 | Docs | INDEX/HANDOFF à jour, docs obsolètes | — |

## Livrable final
Synthèse : top 10 des risques, plan de correction priorisé, ce qui n'a pas pu
être testé (ex. appareil réel, vrais paiements) et pourquoi.

## Limites connues
- Pas de téléphone réel ni de stores dans ce conteneur.
- Paiements testables en mode test seulement.
- Base Supabase de production : lecture seule, sur ton accord.

## À décider par toi
1. Ordre des phases OK ?
2. Accès production autorisé (lecture) ou local uniquement ?
3. Corriger au fil de l'eau, ou audit d'abord puis corrections ?
