# Petit Filet — dossier de recette intégrale (13 novembre 2026)

**Rapport provisoire, aucune saison simulée réellement.** Le rapport distingue toujours `CODE`, `DB (lecture)`, `NON VÉRIFIÉ`, `OK` et `KO`. Aucun `OK` n'a été accordé sans séance authentifiée. Base, dépôt AS Grinta, Carte soirée, PR de production et comptes : inchangés. La saison Club Test A reste ouverte.

## Accès rapide

1. [Verdict, écarts, blocages, preuves et état des deux clubs](04_rapport_et_verdict.md)
2. [164 fonctionnalités métier — toutes avec un résultat explicite](01_grille_metier.md)
3. [257 fonctions SQL publiques, 8 Edge, 67 badges de A, modules, règles, notifications, rôles](02_serveur_badges_reglages.md)
4. [286 fonctions SQL internes privées](02b_fonctions_internes.md)
5. [42 écrans et 48 déclarations de routes](03_ecrans_routes.md)
6. [31 matchs de campagne (dont 1 annulé), 26 formations, 341 étapes non exécutées](05_scenario_31_matchs.md)
7. [Contrôles Flutter repérés dans 181 fichiers d'interface](ui_lots/controle_01.md) : 16 lots listés ci-dessous.

## Contrôles d'interface par lot

**587 occurrences de constructeurs interactifs** identifiées dans la source sur **181 fichiers Dart** de présentation, widgets et shell. Ce n'est **pas** le nombre de boutons rendus réellement : un constructeur peut créer plusieurs boutons, ou un geste personnalisé peut ne pas être reconnu. Un test visuel reste nécessaire.

| Lot | Fichiers du balayage | Occurrences | Résultat écran |
|---|---:|---:|---|
| [01](ui_lots/controle_01.md) | 1–12 | 5 | **NON VÉRIFIÉ** |
| [02](ui_lots/controle_02.md) | 13–24 | 7 | **NON VÉRIFIÉ** |
| [03](ui_lots/controle_03.md) | 25–36 | 50 | **NON VÉRIFIÉ** |
| [04](ui_lots/controle_04.md) | 37–48 | 95 | **NON VÉRIFIÉ** |
| [05](ui_lots/controle_05.md) | 49–60 | 28 | **NON VÉRIFIÉ** |
| [06](ui_lots/controle_06.md) | 61–72 | 12 | **NON VÉRIFIÉ** |
| [07](ui_lots/controle_07.md) | 73–84 | 48 | **NON VÉRIFIÉ** |
| [08](ui_lots/controle_08.md) | 85–96 | 71 | **NON VÉRIFIÉ** |
| [09](ui_lots/controle_09.md) | 97–108 | 41 | **NON VÉRIFIÉ** |
| [10](ui_lots/controle_10.md) | 109–120 | 34 | **NON VÉRIFIÉ** |
| [11](ui_lots/controle_11.md) | 121–132 | 32 | **NON VÉRIFIÉ** |
| [12](ui_lots/controle_12.md) | 133–144 | 57 | **NON VÉRIFIÉ** |
| [13](ui_lots/controle_13.md) | 145–156 | 49 | **NON VÉRIFIÉ** |
| [14](ui_lots/controle_14.md) | 157–168 | 39 | **NON VÉRIFIÉ** |
| [15](ui_lots/controle_15.md) | 169–180 | 19 | **NON VÉRIFIÉ** |
| [16](ui_lots/controle_16.md) | 181–181 | 0 | **NON VÉRIFIÉ** |

## Ce qui reste pour conclure

1. Navigateur contrôlable et sessions admin/joueur fictives par les écrans du site, ou exécution Flutter locale reliée à la même base en suivant strictement les permissions de test.
2. Compléter l'effectif à 25+, construire 300 historiques et 31 rencontres uniquement avec les fonctions normales ; jouer 30 rencontres, annuler une, arrêter avant clôture.
3. Photographier les écarts, comparer toutes les statistiques par calcul indépendant, vérifier en DB via SELECT et isoler les vrais défauts en PR de correction avec tests automatiques.
4. Clôturer seulement une copie jetable autorisée pour tester récompenses, récapitulatifs, musique et archives.

## Interdictions maintenues

Ne jamais écrire dans la base d'AS Grinta, dans Carte soirée, ni modifier l'application originale ; ne pas fusionner de PR, appliquer de migration commerciale, supprimer de compte ou clôturer A sans l'accord explicite du propriétaire.

