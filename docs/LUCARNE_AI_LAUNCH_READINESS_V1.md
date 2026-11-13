# Lucarne AI — Calcul vérifiable de préparation au lancement (V1)

Statut : proposition documentaire, **non déployée**. Le bureau Lucarne AI est un projet distinct, en lecture seule de ce dépôt commercial. Aucune donnée fictive ne doit être présentée comme réelle.

## Deux indicateurs indépendants

**Avancement du chantier** = somme des poids des tâches terminées et vérifiées / somme des poids des tâches recensées. Ne pas calculer avant inventaire complet, attribution des poids et règles de preuve ; afficher « non calculable » sinon. Une PR ouverte n'est pas une tâche terminée.

**Préparation au lancement** = critères de lancement validés / critères applicables ; afficher aussi les critères bloquants P0 non validés. Le pourcentage n'autorise **jamais** à lui seul une publication : tout P0 non validé implique « NO-GO ».

## Critères de lancement (à instruire, non validés par défaut)

| ID | Mission | Critère | Preuve minimale | Bloquant |
| --- | --- | --- | --- | --- |
| L01 | M01/M02 | Fonctionnalités essentielles multiclub validées | Inventaire signé + parcours testés | P0 |
| L02 | M03 | Tests critiques et CI fiables | Exécutions CI vertes et rapport de tests | P0 |
| L03 | M04 | Isolation stricte entre clubs A et B | Tests négatifs RLS/RPC/storage avec preuves | P0 |
| L04 | M04/M09 | Sauvegarde et restauration vérifiées | Procès-verbal de restauration sur environnement isolé | P0 |
| L05 | M07 | RGPD, droits des médias, CGU/CGV et informations légales validés | Avis juridique/documentation approuvée | P0 |
| L06 | M02/M09 | Auth, e-mails, URL et déploiement maîtrisés | Test de bout en bout sur environnement commercial autorisé | P0 |
| L07 | M08 | Club pilote et premier match testés | Retour utilisateur et parcours complet documenté | P0 |
| L08 | M06 | Offre, prix, facturation et support prêts | Décisions commerciales et processus approuvés | P0 |
| L09 | M09 | Supervision, incidents et coûts cadrés | Exercices d'incident et budget validés | P0 |
| L10 | M05 | Identité Lucarne et expérience mobile validées | Revue UX + tests mobiles | P1 |

## Schéma minimal pour une entrée de preuve

```json
{"criterion_id":"L03","status":"unknown","evidence_urls":[],"verified_at":null,"reviewed_by":null,"blocking":true}
```

Statuts autorisés : `unknown`, `in_progress`, `blocked`, `verified`, `not_applicable`. `verified` exige preuve URL + revue ; `not_applicable` exige justification explicite. Les critères sans preuve restent inconnus. Aucune progression chiffrée ne doit être affichée avant le premier audit documenté.

## Contrat de lecture du bureau indépendant

- Lire uniquement les **issues, PR, commits et contrôles GitHub** publics ; aucun secret ou jeton Supabase dans le navigateur.
- Associer les preuves aux critères par identifiant L01-L10 et afficher la dernière synchronisation et les erreurs de lecture.
- Le suivi des automatisations ChatGPT n'est **pas disponible** par la seule API GitHub : ne jamais inférer « agent actif » à partir d'une PR.
- QCM dans le bureau : sauvegarde locale/export de la décision possible ; **aucune exécution réelle sans canal authentifié et confirmation humaine pour opérations sensibles**.
- Pas de fusion automatique, pas de modification de la visibilité du dépôt public, pas d'écriture Supabase, pas d'intervention sur AS Grinta original.

## Sources de blocage connues à examiner

Issues #37 (cloisonnement), #45 (protection main), #39 (juridique), #28 (sonde de supervision) ; PR #41 (audit sécurité), #44 (garde qualité), #53 (relais), #62 (journal). Ces références ne prouvent pas que les critères correspondants sont satisfaits.

## Prochain jalon

M03 et M04 examinent les critères et les preuves ; M00 produit un premier rapport factuel, avec statut inconnu tant que la vérification manque. Le bureau doit afficher ce rapport et ses liens sans inventer un pourcentage.
