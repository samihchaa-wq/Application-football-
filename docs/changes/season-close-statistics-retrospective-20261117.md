# Statistiques et rétrospective après clôture

La consultation de « Précédente » dépendait d'une saison ouverte. Entre la
clôture et l'ouverture suivante, les joueurs disparaissaient et le bilan
équipe retombait à zéro. Les matchs et bilans restaient enregistrés.

La nouvelle référence commune désigne la dernière saison terminée ou archivée
quand aucune saison n'est ouverte. Après ouverture, elle désigne à nouveau la
dernière saison clôturée antérieure. Joueurs, Équipe et Prono utilisent cette
même référence, limitée au club de l'utilisateur. Les imports historiques
restent le repli existant lorsqu'il n'y a pas d'effectif applicatif.

L'onglet Prono propose désormais Actuelle / Précédente / Toutes et conserve
la sélection en passant d'un onglet de statistiques à l'autre. Les points et
le barème existants sont conservés, y compris l'affichage entier ×100.
Le classement général historique reste disponible aux autres écrans et aux
anciens clients.

La disponibilité de la vidéo et son contenu participent désormais au
rafraîchissement partagé. L'arrivée asynchrone des bilans produit également un
signal : une consultation faite avant la fin du calcul ne masque plus le
bouton jusqu'au redémarrage. Le contrat personnel du bilan reste inchangé.

## Validation

- Test SQL de deux clubs : clôture sans saison suivante, buts/passes/résultats,
  classement Prono par période, arrivée du bilan, nouvelle saison, cloisonnement.
- Test mobile de sélection de période Prono, aller-retour entre onglets.
- Test du bouton vidéo après invalidation, puis masquage à l'ouverture suivante.
- Contrat de synchronisation étendu aux nouveaux caches et à la table des bilans.
- La CI GitHub doit reconstruire la base isolée, exécuter les pgTAP/RLS et le
  lint, puis analyser/tester/construire Flutter. Consulter les résultats du SHA.

## Livraison

Nouvelle migration additive `20261123020000_statistics_between_seasons.sql`.
Aucune ancienne migration ni résultat de match n'est modifié. Travail limité
au dépôt commercial. Pas de modification de la base distante ni de déploiement
pendant la préparation. La fusion déclenche la chaîne de sortie commerciale ;
vérifier les contrôles et autoriser ce lot avant intégration.
