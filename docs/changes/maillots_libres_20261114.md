# Petit Filet — maillots libres et réglages repliables

## Décision produit
- Un **seul maillot par défaut** (« Domicile ») pour un club non configuré.
- Bouton « Ajouter un maillot » sans limite arbitraire de trois.
- Chaque ajout possède son identifiant stable, son nom, les couleurs et motifs des joueurs et du gardien.
- « Supprimer ce maillot » **archive** la tenue et la retire des choix futurs ; « Restaurer » l'affiche de nouveau.
- La dernière tenue active ne peut être désactivée ni archivée.
- Les clubs déjà configurés gardent leurs trois tenues : aucune suppression automatique des personnalisations ou des références de match.
- La rubrique « Identité et maillots » démarre fermée, au même titre que les autres menus des réglages.
- Les maillots des formulaires de match défilent horizontalement au-delà de la largeur de l'écran.

## Compatibilité et sécurité
- Les identifiants historiques `france`, `orange`, `blue` restent lisibles.
- Les nouveaux identifiants `kit_<identifiant>` ne sont jamais réutilisés.
- La base valide les données et le rôle d'administrateur ; les anciens clients ne peuvent pas écraser silencieusement des tenues ajoutées plus récemment.
- Les snapshots Live/fin de match restent immuables et incluent désormais toutes les tenues configurées.
- Les matchs « entre nous » conservent une tenue de contraste implicite s'il n'y a qu'une seule tenue active.
- L'isolement des clubs/RLS reste inchangé.

## Déploiement
1. Vérifier les tests Flutter et les tests pgTAP, puis effectuer une recette mobile réelle.
2. Après validation, appliquer la migration `20261120000000_kits_illimites_par_club.sql` à la base **Petit Filet uniquement**, avant d'activer le nouveau code client.
3. Publier la version Flutter, vérifier l'ajout de 1 à N tenues, le choix sur un match, les compositions, Live, la vidéo, les archives et un second club.
4. Relever le SHA et les contrôles exacts ; ne jamais modifier la base ni le dépôt AS Grinta original.

**État initial :** PR préparatoire ; aucune migration ni publication automatique autorisée par ce document.
