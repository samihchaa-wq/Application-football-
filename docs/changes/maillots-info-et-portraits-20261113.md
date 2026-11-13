# Maillots Petit Filet — deux rendus selon la surface

Décision produit du 13 novembre 2026. Cette livraison introduit **l'habillage effectif des photos** pour les compositions et leur vidéo, avec une présentation différente de « Info maillots ».

## Présentation

- **Info / choix du maillot / réglages :** le composant `KitJersey` est un simple pictogramme avec les couleurs du club, le col et le motif. Aucune texture de tissu ni portrait n'y est simulé.
- **Compositions avant, Live, après match et vidéo :** quand l'option `dress_players` est activée dans les réglages, les portraits réutilisent `KitPortrait`, le maillot du match et les couleurs du gardien si besoin. Les photographies d'origine ne sont **jamais réenregistrées avec une tenue**.
- **Fiche joueur :** hors contexte d'un match particulier, la première tenue proposée du club sert d'aperçu, avec la même option `dress_players`. Aucun historique n'est reconstitué avec une couleur actuelle.
- **Petites pastilles (< 44 px) et joueurs sans photo :** restent neutres pour la lisibilité ; pas de faux visage.
- **Patron de photo :** la photo est découpée au-dessus du col dans l'aperçu pour éviter que les anciennes épaules ne traversent le maillot. Le découpage, les repères et le jersey sont seulement visuels ; le PNG/JPEG exporté conserve les pixels photo et la transparence.

## Portée et limites vérifiables

- Réutilise `CompositionKitScope` : dans un match démarré/clos, la tenue vient du snapshot si disponible, pas des couleurs actuelles.
- Le rendu textile est **procédural**. Il améliore le volume et les coutures, mais **n'est pas une reproduction photoréaliste démontrée** sur des vraies photos ; validation visuelle iPhone/PWA indispensable.
- La limite historique des trois identifiants `france/orange/blue` et le schéma de `clubs.kits` **ne changent pas dans ce lot**. Les maillots illimités exigent le lot de migration/domaine distinct indiqué dans `docs/MAQUETTE_PATRON_PHOTO_ET_MAILLOTS_LIBRES_20261113.md`.
- Aucun test de réception de notification, montage vidéo exporté ou parcours E2E avec photo privée n'est revendiqué ici.
- Pas de migration, écriture Supabase commerciale, déploiement Cloudflare ou modification d'AS Grinta.

## Tests

- Vérifier que joueur et gardien avec photos ont un `KitPortrait` dans `CompositionKitScope` si `dress_players` est actif.
- Vérifier que les miniatures restent neutres et que la fiche joueur peut fournir sa tenue.
- Conserver les tests du `PortraitJerseyPainter` qui interdisent toute peinture sur le visage.
- Rejouer `flutter analyze`, `flutter test`, build Web via CI. Tester de vraies photos PNG/JPEG et les quatre phases (avant/Live/après/vidéo) sur un appareil avant publication.
