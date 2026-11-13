# Maillots portés sur les portraits — Petit Filet

Demande de Samih du 13 novembre 2026 : le choix de la tenue du match doit
s'appliquer aux compositions avant/pendant/après, à la vidéo et à l'historique.
Le joueur doit disposer d'un patron de maillot et de couronne au recadrage.

## Fonctionnement

Dans Réglages du club → Maillots du club, l'administrateur active
« Habiller les joueurs avec le maillot du match ». Désactivé par défaut.
Il choisit le modèle (uni, rayures, bandes horizontales, diagonale) et les
couleurs des joueurs et du gardien pour chacune des trois tenues.
L'aperçu Infos et les portraits partagent les mêmes modèles.

Le rendu de portrait est partagé par les compositions et la présentation
animée, y compris les joueurs sans photo. Le visage reste celui de la photo,
le maillot remplace uniquement le bas du buste. Le joueur doit recadrer son
visage dans l'ovale ; il peut prévisualiser les tenues sans réimporter sa photo.
La couronne reste au même emplacement. La photo source est conservée sans
maillot/couronne incrustés, et le PNG conserve sa transparence.

Les snapshots existants restent inchangés. Les nouveaux snapshots figent aussi
le modèle et l'option au début du Live ou à la finalisation sans Live. Changer
les tenues du club ne réhabille donc pas rétroactivement les matchs figés.
Les portraits alternatifs existants restent disponibles ; leur sélection suit
le maillot historique lorsqu'un snapshot existe.

## Ajustement visuel du 13/11 — coupe du haut de maillot

Le retour sur smartphone montrait un grand demi-cercle coloré, un col trop
épais et des pointillés traversant la poitrine. Le modèle de rendu partagé
(`PortraitJerseyPainter`) a été repris : épaules en pente, silhouette de
manches courtes, emmanchures discrètes, liserés de manches et col rond fin.
Les seuls pointillés du recadrage restent ceux de l'ovale du visage.
Le rayon des coins intérieurs de l'aperçu passe également de 45 à 14 px :
le cadrage ne transforme plus le bas du maillot en disque arrondi.

Cette correction ne change ni les couleurs et motifs enregistrés, ni le choix
du maillot par match, ni les portraits stockés. Elle est visible sur toutes les
surfaces qui utilisent `KitPortrait` (aperçu, compositions et vidéo), après
intégration et nouvelle publication de l'application. Des tests de pixels
vérifient notamment le cou dégagé et la pente des épaules ; **le rendu exact
sur téléphone reste à valider visuellement**, surtout avec de vraies photos
aux proportions variées.

## Périmètre et activation

Migration additive `20261116030000_portraits_match_kits.sql` : validation des
modèles et booléens dans la RPC d'administration existante, préservation des
clés omises par les anciens clients, même cloisonnement et permissions, capture
des nouvelles clés dans les snapshots. Aucun nouveau droit client sur les
snapshots. Aucun changement d'anciennes migrations ni du verrou distant.
La RPC verrouille la ligne du club pour préserver les nouveaux champs en cas
de mise à jour concurrente d'un ancien client.

La migration a été créée avec la CLI puis ordonnée après la dernière migration
du dépôt (20261116020000). Sa présence ne signifie pas qu'elle a été appliquée.
Aucune écriture ni publication sur le projet commercial, AS Grinta ou Carte
soirée n'a été effectuée pour ce lot. Aucun coût engagé.

## Validation

Tests ajoutés/étendus : rendu du maillot sans recouvrement du visage, couleurs
et modèles distincts joueur/gardien, option désactivée, sélection/sauvegarde
administrateur, aperçu de plusieurs tenues sans incrustation dans l'export,
persistance historique après modification du club, validation SQL, compatibilité
avec anciens clients et absence de modification d'un deuxième club.

Les suites Flutter (analyse, tests, build Web), pgTAP/RLS et lint SQL sont
confiées aux workflows de PR sur le SHA exact. Contrôle visuel sur smartphone
et vérification après déploiement restent à effectuer.
