# Photo unique des joueurs — décisions du 14 novembre 2026

Une seule photo par joueur. L'import dans Profil et dans l'effectif propose :

- **Type joueur** : source à fond transparent obligatoire, cadrée une fois sur le maillot par défaut et la couronne. Le même visage est composé avec la tenue du match, y compris en vidéo, après-match et matchs entre nous.
- **Autre** : photo libre, cadrée avec le seul repère de couronne. Pas de découpe de tête ni de maillot superposé ; les règles d'attribution de la couronne restent identiques.

Le poste GB sur le terrain prime sur le poste habituel de la fiche pour choisir les couleurs gardien. Sans poste placé, le rôle habituel reste le repli.

Les anciennes variantes ne sont plus chargées, proposées ni téléversées par le nouveau client. Les tables, migrations et objets historiques restent conservés pour la compatibilité. Les portraits existants utilisent le mode Type joueur et leur photo principale.

Le mode est attaché à la référence de l'objet photo (`avatar_player_<timestamp>`, `avatar_other_<timestamp>`). Il voyage donc avec les photos déjà retournées par les RPC, les caches et les URL signées ; aucune migration, aucune nouvelle colonne ni modification de permissions n'est requise. Les dossiers propriétaires/saison et le bucket privé existant sont conservés.

Validation préparée : tests des références relatives/signées et des anciens portraits ; widgets de choix, de refus d'une source opaque en mode joueur et de couronne sans maillot en mode Autre ; tests de priorité du poste GB ; adaptation des tests de vidéo et d'après-match à la photo unique. La CI doit analyser, tester et construire le Web avant intégration. La validation interactive sur le site reste distincte.
