# Lucarne AI — Contrat de journal des agents (proposition V0)

Statut : **proposition non déployée**. Suivi : issue #61. Aucun agent n'est réputé actif sur la seule base de ce document.

## Périmètre
Dépôt commercial uniquement. AS Grinta original, Carte soirée et leurs bases sont exclus. Pas de coût, de secret dans le dépôt public, d'écriture Supabase ni de fusion automatique.

## Format d'un événement (JSON Lines, un objet par ligne)

Champs obligatoires :
- `schema_version` : `1`
- `event_id` : identifiant unique non sensible
- `run_id` : identifiant d'exécution ; `null` si inconnu
- `timestamp_utc` : date ISO 8601 en UTC
- `mission` : `M00` à `M09`
- `agent_role` : rôle, jamais identité personnelle ni jeton
- `task_id` : référence issue/PR ou identifiant interne
- `status` : `queued`, `running`, `blocked`, `review`, `completed`, `failed`, `unknown`
- `evidence_level` : `observed` (API/CI), `reported` (déclaration), `unknown`
- `evidence_urls` : URLs publiques vérifiables (aucun lien secret)
- `summary` : description factuelle et non sensible
- `blockers` : liste de blocages non sensibles
- `next_action` : action proposée

Exemple **fictif — ne pas afficher comme activité réelle** :

```json
{"schema_version":1,"event_id":"example-001","run_id":null,"timestamp_utc":"2026-11-12T00:00:00Z","mission":"M03","agent_role":"qa-reviewer","task_id":"example-only","status":"unknown","evidence_level":"unknown","evidence_urls":[],"summary":"EXEMPLE FICTIF : aucune exécution attestée","blockers":[],"next_action":"Attendre une exécution vérifiable"}
```

## Règles de vérité et de confidentialité
1. `running` ne doit apparaître que si une source d'exécution en cours le prouve ; une PR ouverte n'est pas un agent actif.
2. `completed` exige une preuve de livrable et, quand applicable, des tests ; une PR créée seule ne prouve pas la qualité.
3. Absence de télémétrie = `unknown`, jamais un statut vert par défaut.
4. Horodater la dernière synchronisation, afficher les erreurs API et distinguer données simulées et données observées.
5. Ne jamais journaliser tokens, secrets, emails, photos, données de clubs, logs privés ou données Supabase. Les journaux publics doivent rester minimaux.
6. Une exécution automatisée ne constitue pas un agent permanent ; documenter déclencheur, durée, limite et dépendances.

## Workflow de collaboration proposé
M00 attribue une issue → M02 prépare une PR brouillon → M03 documente les tests → M04 examine les risques → M00 demande validation humaine avant toute fusion. Chaque transition est associée à une preuve GitHub, sinon elle reste `unknown`.

## Conditions avant déploiement du tableau de bord
- Revue de sécurité des données publiées et quotas GitHub API.
- Vérification des conditions et limites de l'hébergement gratuit.
- Démonstration sur une tâche non critique ; aucune écriture en production.
- Accord explicite avant dépense, publication sensible ou fusion.
