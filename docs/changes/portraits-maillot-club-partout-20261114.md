# Portraits habillés sur toutes les surfaces — Petit Filet

Décision utilisateur du 14 novembre 2026 : **la photo affichée d'un joueur doit toujours être la composition de sa photographie avec le maillot du club**, et non la photographie brute ; cela concerne profil, fiche joueur, effectif, listes, compositions et vidéo.

## Contrat d'affichage

- Tous les écrans de portraits joueurs utilisent le composant commun `PlayerAvatar`. Après décodage d'une photo valide, `KitPortrait` compose **tête/cou d'origine + haut de maillot**. La photo d'origine n'est jamais réenregistrée.
- **Hors match :** première tenue active du club courant (`ClubKits.enabled.firstOrNull`, ou première tenue configurée si tout est désactivé). Couleur et motif joueur, ou couleurs et motif gardien si `isGoalkeeper` est connu.
- **Dans un match :** `CompositionKitScope` prime sur le défaut, pour garder la tenue sélectionnée dans Infos ; les snapshots d'un match joué restent prioritaires via `MatchCompositionKitScope`.
- **Tous les formats de photos :** grands portraits et miniatures de 24–40 px. Les anciennes exclusions `size >= 44` et `dressPlayers` sont levées pour éviter la photo brute dans l'effectif, le profil ou les listes.
- **Si la photo est absente, en cours de décodage, ou indisponible :** initiales/placeholder existants ; aucun vêtement imaginaire n'est superposé aux initiales.
- Le composant écoute `ClubKits.revision` pour mettre à jour la tenue dans les écrans déjà ouverts, sans réimport de photo. Le changement de club doit continuer à réinitialiser `ClubKits` conformément au flux de session existant.
- L'interrupteur d'administration « Habiller les joueurs », devenu trompeur, est remplacé par une description informative. La colonne `dress_players` reste dans le JSON et les snapshots historiques pour **compatibilité**, mais n'empêche plus l'habillage des portraits.
- Les images d'icônes, logos, écussons et photos sans rapport avec les joueurs ne sont pas habillées.

## Portée et limites

- Cette évolution change **le rendu UI**, pas les fichiers stockés, ni le schéma SQL. Elle n'applique pas automatiquement un maillot à un export JPEG ou PNG téléchargé hors de l'application.
- Pour la photographie du profil, le rôle gardien n'est pas déduit d'une position absente des informations du profil : par défaut la tenue de joueur de champ est utilisée. Les écrans qui savent qu'un joueur est gardien passent `isGoalkeeper` au composant.
- Le modèle de tissu reste le modèle procédural existant, amélioré en PR #109 ; le **photoréalisme n'a pas été confirmé visuellement** sur une véritable galerie de photos ni sur Safari iPhone.
- Le support de **maillots en nombre illimité** nécessite une migration/domaines distincts, non compris.
- Aucun changement distant Supabase, aucune modification d'AS Grinta originale et aucune publication Cloudflare automatique.

## Tests

- Vérifier le `frameBuilder` pour le profil, l'effectif (miniature), la fiche et un gardien : `KitPortrait` après décodage même si `dressPlayers=false`.
- Vérifier que les initiales de repli restent neutres et qu'une photo non décodée n'est pas habillée.
- Vérifier qu'un scope de match gagne sur la tenue par défaut, et que le changement de couleurs du club actualise les portraits.
- Vérifier le rendu en situation sur le site après déploiement : photos réelles PNG transparent et JPEG, profils, fiches, listes, composition et vidéo.
