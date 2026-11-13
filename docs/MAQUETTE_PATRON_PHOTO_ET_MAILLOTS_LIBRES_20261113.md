# Petit Filet — validation du patron et ensembles maillot joueur/gardien

Décision du 13 novembre 2026. Maquette validée visuellement en conversation par le propriétaire. **La validation de la maquette ne constitue pas une validation fonctionnelle ni un déploiement.**

## Contrat UX du recadrage

- Écran « Ajouter la photo du joueur » sombre et responsive : aperçu grand format à gauche, patron explicatif, conseils, trois exemples (correct / trop haut / décalé) et aperçu final habillé.
- Guides : sommet de la tête, hauteur des yeux, base du menton et haut du maillot ; axe vertical, silhouette de tête, repères de coins et damier de transparence.
- La photo se déplace et se zoome au doigt ou à la souris ; le jersey sélectionné suit le cadrage dans l'aperçu, sans influencer les pixels exportés.
- Le portrait source reste indépendant du maillot : ni guides, ni silhouette, ni tenue ne sont incrustés. Transparence PNG conservée. Le vrai visage n'est jamais retouché par l'application.
- Le fichier d'origine est déjà choisi quand cette modale est ouverte : le bouton fonctionnel est « Utiliser cette photo », pas un deuxième sélecteur de fichier. Le cadrage et la validation sont deux opérations distinctes.
- En absence de tenue explicitement fournie au recadrage, utiliser un modèle de prévisualisation du club ; ne pas en faire un choix de maillot définitif pour tous les matchs.

## Nouvelle décision métier — ensembles illimités

1. Réglages → Maillots du club : initialement **un seul ensemble**. Le bouton « Ajouter un maillot » permet d'en créer autant que nécessaire.
2. Chaque ensemble contient obligatoirement : nom, maillot des joueurs, maillot de gardien associé, couleurs (primaire/secondaire) et motif, avec aperçu des deux.
3. Un administrateur choisit **un ensemble** pour chaque match ; le maillot de gardien est déduit de cet ensemble, pas choisi indépendamment.
4. La tenue sélectionnée s'affiche dans Infos match, compositions avant/pendant/après match et vidéo. Les modifications de réglages du club ne changent pas les matchs dont les snapshots ont été figés.
5. En mode « entre nous », chaque équipe conserve son propre ensemble sans fuite visuelle.
6. Droits d'écriture strictement administrateur du club ; lecture isolée par club ; compatibilité avec les anciens identifiants et snapshots.

## Écart technique identifié et découpage requis

La branche principale au 13 novembre contient `JerseyOption` avec trois identifiants `france`, `orange`, `blue`, et `ClubKits.parse` impose exactement trois éléments. Les RPC et les références de match reposent sur cette liste fixe. **On ne peut donc pas présenter aujourd'hui un nombre de tenues illimité comme opérationnel.**

- **Lot A (cette PR) :** refaire la modale de recadrage pour respecter le patron validé, avec maillot et aperçu final purement visuels ; tests Flutter associés.
- **Lot B (PR dédiée et migration SQL additive) :** introduire des identifiants stables non limités, convertir sans perte les trois identifiants historiques, revoir la validation serveur, le formulaire match, l'édition Réglages et tous les modèles de sérialisation. Une migration existante n'est jamais réécrite.
- **Lot C (PR dédiée) :** exhaustivité des surfaces (Infos, avant/Live/après, vidéo, archives, gardiens, entre-nous), tests multiclubs et snapshots gelés, tests réels PWA/mobile.

## Garde-fous de livraison

Aucune écriture Supabase commerciale, aucune modification d'AS Grinta. Cette PR n'applique pas de migration et ne publie pas l'application. Fusion seulement si revues et contrôles sur le SHA exact sont verts ; vérification visuelle mobile et navigation réelle nécessaires.
