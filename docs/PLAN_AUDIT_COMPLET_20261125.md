# Plan d'audit complet — 25/11/2026

Statut : **plan validé par QCM, audit pas commencé.**

## Contexte (réponses au QCM)
- But : tout à la fois (fiabilité, ménage, bugs, sécurité).
- Utilisateurs réels : aucun pour l'instant.
- Support : **web installable uniquement** (pas de dossier Android ni iPhone
  dans le projet). « App installée » = site ajouté à l'écran d'accueil, sur
  Android comme sur iPhone. Aucune publication sur les stores n'est prévue.
- Stripe : état inconnu, à vérifier en lecture seule.
- Fonctionnalités cœur, toutes prioritaires : matchs + live, pronos + badges,
  stats + saison, gestion du club.
- RGPD : hors périmètre pour l'instant.

## Règles de travail
- Profondeur : **les 370 fichiers passés au crible**, plus les 83 migrations,
  les 11 fonctions serveur et les 283 tests.
- Base de production : lecture seule, aucune écriture.
- Corrections au fil de l'eau, mais seulement les **petits correctifs** en
  autonomie. Je demande avant de toucher à la base, aux paiements ou à ce que
  voit l'utilisateur.
- Une demande de fusion (PR) par phase.
- Je te préviens seulement en cas de problème grave ; sinon, rapport final.
- Lectures simples confiées à des assistants moins chers (éclaireur) ;
  l'analyse et les corrections restent à moi.
- Anciens audits (docs/AUDIT_*) : je vérifie que leurs points sont vraiment
  corrigés.
- Chaque constat : gravité (bloquant / important / mineur), preuve, correctif.
  Rien n'est déclaré « OK » sans vérification.
- Résultats dans `docs/AUDIT_COMPLET_20261125.md`.

## Phases

| # | Phase | Contenu |
|---|---|---|
| 0 | État des lieux | graphe à jour, compilation web, analyse statique, tests, couverture, état Stripe |
| 1 | Sécurité + données | droits par club et par rôle, fonctions serveur, secrets, invitations |
| 2 | Paiements Stripe | achat, remboursement, webhook, cas d'échec |
| 3 | Base de données | migrations rejouables, index, requêtes lentes, sauvegarde |
| 4 | Logique métier | matchs + live, pronos + badges, stats + saison, gestion du club |
| 5 | Architecture | gestion de l'état, découpage, code mort, doublons |
| 6 | UX/UI | états vide/chargement/erreur, formulaires, écran de téléphone, installation web |
| 7 | Performance | chargement initial du site, listes, images, fluidité |
| 8 | Tests | trous sur les zones sensibles, tests fragiles |
| 9 | Docs | INDEX/HANDOFF à jour, docs obsolètes |

## Livrable final
Top 10 des risques, corrections faites, corrections en attente de ton
accord, ce qui n'a pas pu être testé et pourquoi.

## Limites
- Pas de vrai téléphone : tests dans un navigateur qui imite un téléphone.
- Paiements : mode test seulement.
