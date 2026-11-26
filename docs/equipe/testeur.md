# Testeur — rapport

## Passage du 2026-11-26 (soir) — domaine : pronos

Prochain domaine prévu : match en direct.

### Fait
- Barème : calcul de l'appli et calcul de la base comparés, identiques (score exact, bon écart, un score juste, bon vainqueur, mauvais = 0).
- Base (lecture seule, chiffres anonymisés) : 2 clubs, 54 matchs, 29 terminés, ~1 000 pronos. Aucun score négatif, aucune cote invalide, aucun prono rangé dans le mauvais club.
- Fermeture des pronos : vérifiée côté base (avant ouverture, après fermeture, match « entre nous », fermeture manuelle → refusé). Un joueur ne peut ni modifier le prono d'un autre ni voir les pronos des autres avant la fin du match.

### Problèmes trouvés
1. **Important — pronos créés pour les joueurs de l'autre club.**
   `supabase/migrations/20261111000100_socle_structure.sql` l. 24728-24750 (fonction qui prépare les pronos vides à la création d'un match).
   Elle prend tous les joueurs actifs de la base, sans filtrer par club. Pas encore arrivé (aucun match créé depuis l'arrivée du 2e club), mais arrivera au prochain match créé : ~21 lignes de pronos vides seront ajoutées pour les joueurs de l'autre club, rangées dans le mauvais club.
   Effet visible : faible pour l'instant (lignes vides, pas de points). Risque : données mélangées entre clubs, compteurs ou rappels faussés si un écran ou un envoi se base un jour sur ces lignes.
2. **Moyen — enregistrer un prono ne vérifie pas que le match est de son club.**
   Même fichier, l. 24625 (fonction d'enregistrement du prono). Un joueur qui connaîtrait l'identifiant d'un match d'un autre club pourrait y poser un prono. Identifiant très difficile à deviner, pas d'effet sur les classements (filtrés par club). Pollution de données seulement.
3. **Faible — match terminé sans score.** 2 matchs sont « terminés » sans score (et sans cote, donc sans effet aujourd'hui). Si un match terminé sans score avait une cote, la base donnerait des points à tous ceux qui ont rempli leur prono (calcul de la vue des points, migration `20261114002000_bareme_pronostics_club.sql`). L'appli, elle, en donnerait 0.

### Décisions attendues (base de données = validation de la personne qui pilote)
- Corriger 1 et 2 : filtrer par club dans les deux fonctions. Je recommande de le confier à l'agent base de données (migration proposée, non appliquée).
- Pour 3 : interdire « terminé » sans score, ou donner 0 point tant que le score manque. Recommandé : 0 point tant que le score manque (plus simple, sans risque sur l'existant).

### Non testé et pourquoi
- `flutter analyze` / `flutter test` : Flutter n'est pas installé sur cette machine de passage.
- Parcours réel dans la version web (Playwright) : impossible sans Flutter pour construire la version web.
- `graphify` absent : recherche faite à la main.
- Rappel de pronos automatique : je n'ai pas vérifié pour quel club il vérifie que le module pronos est activé (il tourne sans utilisateur connecté). À regarder au passage « notifications ».
