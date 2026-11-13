# Campagne de saison simulée — 31 rencontres prévues (AUCUNE CRÉÉE)

Ce fichier décrit **un scénario à exécuter**, pas 31 matchs réellement joués. 31 rencontres sont prévues afin d'obtenir 30 matchs joués et un match annulé avant la clôture. Une rencontre reportée doit être finalement jouée. Le modèle actuel ne contient pas `coupe` : les quatre matchs de coupe sont bloqués tant que le type n'est pas défini/implémenté, ou le périmètre amendé explicitement.

Toutes les lignes : **NON VÉRIFIÉ**. Aucun résultat réel, score, nom d'adversaire réel ni date enregistrée. Les 26 formations déclarées dans le code sont distribuées sur M01–M26 (avant les matchs de coupe). Les dates précises sont à choisir via l'administration fictive lors de l'exécution, en respectant les fenêtres d'ouverture.

## 1. Calendrier des 31 scénarios

| ID | Type souhaité | Lieu | Adversaire fictif | Formation prévue | Variation ciblée | Sort attendu | Statut réel |
|---|---|---|---|---|---|---|---|
| M01 | championnat | domicile | Adversaire fictif A | 4-4-2 à plat | 0-0, défense et gardiens | joué attendu | **NON VÉRIFIÉ** |
| M02 | championnat | extérieur | Adversaire fictif B | 4-4-2 losange | 15-14, grand nombre de buteurs | joué attendu | **NON VÉRIFIÉ** |
| M03 | championnat | domicile | Adversaire fictif 3 | 4-2-3-1 | moins de 11 présents | joué attendu | **NON VÉRIFIÉ** |
| M04 | championnat | extérieur | Adversaire fictif 4 | 4-3-3 défensif | trop de convoqués et quota | joué attendu | **NON VÉRIFIÉ** |
| M05 | championnat | domicile | Adversaire fictif 5 | 4-3-3 offensif | changement d'avis joueur | joué attendu | **NON VÉRIFIÉ** |
| M06 | championnat | extérieur | Adversaire fictif 6 | 4-3-3 faux neuf | pilotage Live coach | joué attendu | **NON VÉRIFIÉ** |
| M07 | championnat | domicile | Adversaire fictif A | 4-2-1-3 | pilotage Live admin | joué attendu | **NON VÉRIFIÉ** |
| M08 | championnat | extérieur | Adversaire fictif B | 4-3-2-1 sapin | report puis reprise normale | reporté, puis joué | **NON VÉRIFIÉ** |
| M09 | championnat | domicile | Adversaire fictif 1 | 4-2-2-2 | mode sans cotes | joué attendu | **NON VÉRIFIÉ** |
| M10 | championnat | extérieur | Adversaire fictif 2 | 4-4-1-1 | vote sur soi autorisé | joué attendu | **NON VÉRIFIÉ** |
| M11 | championnat | domicile | Adversaire fictif 3 | 4-1-4-1 | vote sur soi interdit | joué attendu | **NON VÉRIFIÉ** |
| M12 | championnat | extérieur | Adversaire fictif 4 | 4-1-3-2 | ex aequo au vote | joué attendu | **NON VÉRIFIÉ** |
| M13 | championnat | domicile | Adversaire fictif A | 4-5-1 | réponse tardive | joué attendu | **NON VÉRIFIÉ** |
| M14 | championnat | extérieur | Adversaire fictif B | 4-2-4 | double clic de publication | joué attendu | **NON VÉRIFIÉ** |
| M15 | championnat | domicile | Adversaire fictif 7 | 4-3-1-2 | deux matchs le même jour (avec M16) | joué attendu | **NON VÉRIFIÉ** |
| M16 | championnat | extérieur | Adversaire fictif 8 | 3-5-2 | deux matchs le même jour (avec M15) | joué attendu | **NON VÉRIFIÉ** |
| M17 | championnat | domicile | Adversaire fictif 1 | 3-4-3 | nom accentué et emoji | joué attendu | **NON VÉRIFIÉ** |
| M18 | championnat | extérieur | Adversaire fictif 2 | 3-4-1-2 | commentaire d'absence privé | joué attendu | **NON VÉRIFIÉ** |
| M19 | championnat | domicile | Adversaire fictif A | 3-4-2-1 | écran mobile étroit | joué attendu | **NON VÉRIFIÉ** |
| M20 | championnat | extérieur | Adversaire fictif B | 3-1-4-2 | mode sombre et maillot noir | joué attendu | **NON VÉRIFIÉ** |
| M21 | amical | domicile | Club fictif Amical 3 | 3-3-1-3 | perte réseau / reprise | joué attendu | **NON VÉRIFIÉ** |
| M22 | amical | extérieur | Club fictif Amical 1 | 5-3-2 | deux admins en conflit | joué attendu | **NON VÉRIFIÉ** |
| M23 | amical | domicile | Club fictif Amical 2 | 5-2-3 | ouverture anticipée | joué attendu | **NON VÉRIFIÉ** |
| M24 | amical | extérieur | Club fictif Amical 3 | 5-4-1 | ouverture différée | joué attendu | **NON VÉRIFIÉ** |
| M25 | entre_nous | interne | Deux équipes du club | 5-2-1-2 | entre-nous équipe 1 vs équipe 2 | joué attendu | **NON VÉRIFIÉ** |
| M26 | entre_nous | interne | Deux équipes du club | 5-3-1-1 | entre-nous effectifs impairs | joué attendu | **NON VÉRIFIÉ** |
| M27 | coupe | domicile | Club fictif Coupe B | 4-4-2 à plat | coupe : modèle à implémenter | joué attendu | **NON VÉRIFIÉ** |
| M28 | coupe | extérieur | Club fictif Coupe A | 4-4-2 losange | coupe : déplacement et pénalités à définir | joué attendu | **NON VÉRIFIÉ** |
| M29 | coupe | domicile | Club fictif Coupe B | 4-2-3-1 | coupe : adversaire récurrent | joué attendu | **NON VÉRIFIÉ** |
| M30 | coupe | extérieur | Club fictif Coupe A | 4-3-3 défensif | coupe : stage élimination à définir | joué attendu | **NON VÉRIFIÉ** |
| M31 | amical | domicile | Club fictif Amical 1 | 4-3-3 offensif | annulation et vérification ICS/push | annulé | **NON VÉRIFIÉ** |

## 2. Chaque étape de chaque match (341 lignes)

La colonne résultat indique une absence de test, jamais un succès supposé. Pour le match annulé, les opérations post-annulation devront être **refusées proprement** plutôt que réalisées.

| ID | Match | Étape à vérifier | Résultat |
|---|---|---|---|
| M01-T01 | M01 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M01-T02 | M01 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M01-T03 | M01 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M01-T04 | M01 | Convocations et quota | **NON VÉRIFIÉ** |
| M01-T05 | M01 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M01-T06 | M01 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M01-T07 | M01 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M01-T08 | M01 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M01-T09 | M01 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M01-T10 | M01 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M01-T11 | M01 | Notifications on/off | **NON VÉRIFIÉ** |
| M02-T01 | M02 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M02-T02 | M02 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M02-T03 | M02 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M02-T04 | M02 | Convocations et quota | **NON VÉRIFIÉ** |
| M02-T05 | M02 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M02-T06 | M02 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M02-T07 | M02 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M02-T08 | M02 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M02-T09 | M02 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M02-T10 | M02 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M02-T11 | M02 | Notifications on/off | **NON VÉRIFIÉ** |
| M03-T01 | M03 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M03-T02 | M03 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M03-T03 | M03 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M03-T04 | M03 | Convocations et quota | **NON VÉRIFIÉ** |
| M03-T05 | M03 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M03-T06 | M03 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M03-T07 | M03 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M03-T08 | M03 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M03-T09 | M03 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M03-T10 | M03 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M03-T11 | M03 | Notifications on/off | **NON VÉRIFIÉ** |
| M04-T01 | M04 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M04-T02 | M04 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M04-T03 | M04 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M04-T04 | M04 | Convocations et quota | **NON VÉRIFIÉ** |
| M04-T05 | M04 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M04-T06 | M04 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M04-T07 | M04 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M04-T08 | M04 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M04-T09 | M04 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M04-T10 | M04 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M04-T11 | M04 | Notifications on/off | **NON VÉRIFIÉ** |
| M05-T01 | M05 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M05-T02 | M05 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M05-T03 | M05 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M05-T04 | M05 | Convocations et quota | **NON VÉRIFIÉ** |
| M05-T05 | M05 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M05-T06 | M05 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M05-T07 | M05 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M05-T08 | M05 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M05-T09 | M05 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M05-T10 | M05 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M05-T11 | M05 | Notifications on/off | **NON VÉRIFIÉ** |
| M06-T01 | M06 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M06-T02 | M06 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M06-T03 | M06 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M06-T04 | M06 | Convocations et quota | **NON VÉRIFIÉ** |
| M06-T05 | M06 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M06-T06 | M06 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M06-T07 | M06 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M06-T08 | M06 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M06-T09 | M06 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M06-T10 | M06 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M06-T11 | M06 | Notifications on/off | **NON VÉRIFIÉ** |
| M07-T01 | M07 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M07-T02 | M07 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M07-T03 | M07 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M07-T04 | M07 | Convocations et quota | **NON VÉRIFIÉ** |
| M07-T05 | M07 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M07-T06 | M07 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M07-T07 | M07 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M07-T08 | M07 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M07-T09 | M07 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M07-T10 | M07 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M07-T11 | M07 | Notifications on/off | **NON VÉRIFIÉ** |
| M08-T01 | M08 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M08-T02 | M08 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M08-T03 | M08 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M08-T04 | M08 | Convocations et quota | **NON VÉRIFIÉ** |
| M08-T05 | M08 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M08-T06 | M08 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M08-T07 | M08 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M08-T08 | M08 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M08-T09 | M08 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M08-T10 | M08 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M08-T11 | M08 | Notifications on/off | **NON VÉRIFIÉ** |
| M09-T01 | M09 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M09-T02 | M09 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M09-T03 | M09 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M09-T04 | M09 | Convocations et quota | **NON VÉRIFIÉ** |
| M09-T05 | M09 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M09-T06 | M09 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M09-T07 | M09 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M09-T08 | M09 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M09-T09 | M09 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M09-T10 | M09 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M09-T11 | M09 | Notifications on/off | **NON VÉRIFIÉ** |
| M10-T01 | M10 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M10-T02 | M10 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M10-T03 | M10 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M10-T04 | M10 | Convocations et quota | **NON VÉRIFIÉ** |
| M10-T05 | M10 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M10-T06 | M10 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M10-T07 | M10 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M10-T08 | M10 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M10-T09 | M10 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M10-T10 | M10 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M10-T11 | M10 | Notifications on/off | **NON VÉRIFIÉ** |
| M11-T01 | M11 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M11-T02 | M11 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M11-T03 | M11 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M11-T04 | M11 | Convocations et quota | **NON VÉRIFIÉ** |
| M11-T05 | M11 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M11-T06 | M11 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M11-T07 | M11 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M11-T08 | M11 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M11-T09 | M11 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M11-T10 | M11 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M11-T11 | M11 | Notifications on/off | **NON VÉRIFIÉ** |
| M12-T01 | M12 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M12-T02 | M12 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M12-T03 | M12 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M12-T04 | M12 | Convocations et quota | **NON VÉRIFIÉ** |
| M12-T05 | M12 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M12-T06 | M12 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M12-T07 | M12 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M12-T08 | M12 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M12-T09 | M12 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M12-T10 | M12 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M12-T11 | M12 | Notifications on/off | **NON VÉRIFIÉ** |
| M13-T01 | M13 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M13-T02 | M13 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M13-T03 | M13 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M13-T04 | M13 | Convocations et quota | **NON VÉRIFIÉ** |
| M13-T05 | M13 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M13-T06 | M13 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M13-T07 | M13 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M13-T08 | M13 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M13-T09 | M13 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M13-T10 | M13 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M13-T11 | M13 | Notifications on/off | **NON VÉRIFIÉ** |
| M14-T01 | M14 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M14-T02 | M14 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M14-T03 | M14 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M14-T04 | M14 | Convocations et quota | **NON VÉRIFIÉ** |
| M14-T05 | M14 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M14-T06 | M14 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M14-T07 | M14 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M14-T08 | M14 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M14-T09 | M14 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M14-T10 | M14 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M14-T11 | M14 | Notifications on/off | **NON VÉRIFIÉ** |
| M15-T01 | M15 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M15-T02 | M15 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M15-T03 | M15 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M15-T04 | M15 | Convocations et quota | **NON VÉRIFIÉ** |
| M15-T05 | M15 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M15-T06 | M15 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M15-T07 | M15 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M15-T08 | M15 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M15-T09 | M15 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M15-T10 | M15 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M15-T11 | M15 | Notifications on/off | **NON VÉRIFIÉ** |
| M16-T01 | M16 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M16-T02 | M16 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M16-T03 | M16 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M16-T04 | M16 | Convocations et quota | **NON VÉRIFIÉ** |
| M16-T05 | M16 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M16-T06 | M16 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M16-T07 | M16 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M16-T08 | M16 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M16-T09 | M16 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M16-T10 | M16 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M16-T11 | M16 | Notifications on/off | **NON VÉRIFIÉ** |
| M17-T01 | M17 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M17-T02 | M17 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M17-T03 | M17 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M17-T04 | M17 | Convocations et quota | **NON VÉRIFIÉ** |
| M17-T05 | M17 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M17-T06 | M17 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M17-T07 | M17 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M17-T08 | M17 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M17-T09 | M17 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M17-T10 | M17 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M17-T11 | M17 | Notifications on/off | **NON VÉRIFIÉ** |
| M18-T01 | M18 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M18-T02 | M18 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M18-T03 | M18 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M18-T04 | M18 | Convocations et quota | **NON VÉRIFIÉ** |
| M18-T05 | M18 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M18-T06 | M18 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M18-T07 | M18 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M18-T08 | M18 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M18-T09 | M18 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M18-T10 | M18 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M18-T11 | M18 | Notifications on/off | **NON VÉRIFIÉ** |
| M19-T01 | M19 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M19-T02 | M19 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M19-T03 | M19 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M19-T04 | M19 | Convocations et quota | **NON VÉRIFIÉ** |
| M19-T05 | M19 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M19-T06 | M19 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M19-T07 | M19 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M19-T08 | M19 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M19-T09 | M19 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M19-T10 | M19 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M19-T11 | M19 | Notifications on/off | **NON VÉRIFIÉ** |
| M20-T01 | M20 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M20-T02 | M20 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M20-T03 | M20 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M20-T04 | M20 | Convocations et quota | **NON VÉRIFIÉ** |
| M20-T05 | M20 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M20-T06 | M20 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M20-T07 | M20 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M20-T08 | M20 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M20-T09 | M20 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M20-T10 | M20 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M20-T11 | M20 | Notifications on/off | **NON VÉRIFIÉ** |
| M21-T01 | M21 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M21-T02 | M21 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M21-T03 | M21 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M21-T04 | M21 | Convocations et quota | **NON VÉRIFIÉ** |
| M21-T05 | M21 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M21-T06 | M21 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M21-T07 | M21 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M21-T08 | M21 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M21-T09 | M21 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M21-T10 | M21 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M21-T11 | M21 | Notifications on/off | **NON VÉRIFIÉ** |
| M22-T01 | M22 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M22-T02 | M22 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M22-T03 | M22 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M22-T04 | M22 | Convocations et quota | **NON VÉRIFIÉ** |
| M22-T05 | M22 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M22-T06 | M22 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M22-T07 | M22 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M22-T08 | M22 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M22-T09 | M22 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M22-T10 | M22 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M22-T11 | M22 | Notifications on/off | **NON VÉRIFIÉ** |
| M23-T01 | M23 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M23-T02 | M23 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M23-T03 | M23 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M23-T04 | M23 | Convocations et quota | **NON VÉRIFIÉ** |
| M23-T05 | M23 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M23-T06 | M23 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M23-T07 | M23 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M23-T08 | M23 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M23-T09 | M23 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M23-T10 | M23 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M23-T11 | M23 | Notifications on/off | **NON VÉRIFIÉ** |
| M24-T01 | M24 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M24-T02 | M24 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M24-T03 | M24 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M24-T04 | M24 | Convocations et quota | **NON VÉRIFIÉ** |
| M24-T05 | M24 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M24-T06 | M24 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M24-T07 | M24 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M24-T08 | M24 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M24-T09 | M24 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M24-T10 | M24 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M24-T11 | M24 | Notifications on/off | **NON VÉRIFIÉ** |
| M25-T01 | M25 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M25-T02 | M25 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M25-T03 | M25 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M25-T04 | M25 | Convocations et quota | **NON VÉRIFIÉ** |
| M25-T05 | M25 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M25-T06 | M25 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M25-T07 | M25 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M25-T08 | M25 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M25-T09 | M25 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M25-T10 | M25 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M25-T11 | M25 | Notifications on/off | **NON VÉRIFIÉ** |
| M26-T01 | M26 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M26-T02 | M26 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M26-T03 | M26 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M26-T04 | M26 | Convocations et quota | **NON VÉRIFIÉ** |
| M26-T05 | M26 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M26-T06 | M26 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M26-T07 | M26 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M26-T08 | M26 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M26-T09 | M26 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M26-T10 | M26 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M26-T11 | M26 | Notifications on/off | **NON VÉRIFIÉ** |
| M27-T01 | M27 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M27-T02 | M27 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M27-T03 | M27 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M27-T04 | M27 | Convocations et quota | **NON VÉRIFIÉ** |
| M27-T05 | M27 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M27-T06 | M27 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M27-T07 | M27 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M27-T08 | M27 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M27-T09 | M27 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M27-T10 | M27 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M27-T11 | M27 | Notifications on/off | **NON VÉRIFIÉ** |
| M28-T01 | M28 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M28-T02 | M28 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M28-T03 | M28 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M28-T04 | M28 | Convocations et quota | **NON VÉRIFIÉ** |
| M28-T05 | M28 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M28-T06 | M28 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M28-T07 | M28 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M28-T08 | M28 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M28-T09 | M28 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M28-T10 | M28 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M28-T11 | M28 | Notifications on/off | **NON VÉRIFIÉ** |
| M29-T01 | M29 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M29-T02 | M29 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M29-T03 | M29 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M29-T04 | M29 | Convocations et quota | **NON VÉRIFIÉ** |
| M29-T05 | M29 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M29-T06 | M29 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M29-T07 | M29 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M29-T08 | M29 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M29-T09 | M29 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M29-T10 | M29 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M29-T11 | M29 | Notifications on/off | **NON VÉRIFIÉ** |
| M30-T01 | M30 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M30-T02 | M30 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M30-T03 | M30 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M30-T04 | M30 | Convocations et quota | **NON VÉRIFIÉ** |
| M30-T05 | M30 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M30-T06 | M30 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M30-T07 | M30 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M30-T08 | M30 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M30-T09 | M30 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M30-T10 | M30 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M30-T11 | M30 | Notifications on/off | **NON VÉRIFIÉ** |
| M31-T01 | M31 | Création, modification, report/annulation | **NON VÉRIFIÉ** |
| M31-T02 | M31 | Disponibilités et motifs privés | **NON VÉRIFIÉ** |
| M31-T03 | M31 | Attente trois modes et crédit +1 | **NON VÉRIFIÉ** |
| M31-T04 | M31 | Convocations et quota | **NON VÉRIFIÉ** |
| M31-T05 | M31 | Compositions, simulation et publication | **NON VÉRIFIÉ** |
| M31-T06 | M31 | Pronostics et barème/cotes | **NON VÉRIFIÉ** |
| M31-T07 | M31 | Live coach/admin et corrections | **NON VÉRIFIÉ** |
| M31-T08 | M31 | Résultat, buteurs, correction horaire | **NON VÉRIFIÉ** |
| M31-T09 | M31 | Étoile du match, égalité et clôture | **NON VÉRIFIÉ** |
| M31-T10 | M31 | Statistiques, badges, calculs indépendants | **NON VÉRIFIÉ** |
| M31-T11 | M31 | Notifications on/off | **NON VÉRIFIÉ** |

## 3. Mesures obligatoires

- Avant toute saisie historique, relever le temps de l'ajout d'un match ; répéter avec 300 historiques effectivement saisis via écran ; mesurer calendrier, cotes, simulation et classements (médiane + pire mesure, au moins 5 essais).
- Pour statistiques, constituer un tableau indépendant (présences, buts, passes, victoire/nul/défaite, temps de jeu, clean sheets, votes et points de pronostics), puis comparer à chaque match et à la fin.
- Chaque scénario doit comporter au moins une trace de la version de code, le rôle, le club, la date/heure locale, une preuve d'interface et la relecture SQL en SELECT.
- La vraie fin de saison de A ne doit jamais être lancée. Une copie jetable indépendante reste obligatoire pour vérifier la clôture.

