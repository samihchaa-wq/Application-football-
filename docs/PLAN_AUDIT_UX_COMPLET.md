# Plan d'audit UX/UI complet (4 axes)

Statut : plan à valider. Aucun code modifié.
Périmètre : toute l'app (175 fichiers d'écrans dans `lib/features/*/presentation`, 23 composants communs dans `lib/core/widgets`, `web/`).
Appareils : téléphone, tablette, ordinateur.
Suite : rapport classé par gravité, validation, puis corrections.

## Ce qui existe déjà

`docs/AUDIT_UX_UI_20261124.md` (hier) couvre : boutons, couleurs, textes, marges, icônes, bandeau de notifications.
Cet audit-ci **ne le refait pas**. Il couvre ce qui n'y est pas : adaptation aux tailles d'écran, états (chargement/vide/erreur), accessibilité, formulaires. Les points d'hier encore ouverts sont repris seulement s'ils recoupent un axe.

## Méthode

1. Cartographier les écrans : routes (`lib/app/router`), liste ci-dessous, rôle (joueur / admin / plateforme).
2. Lire le code de chaque écran avec la grille de son axe.
3. Si l'app web se lance : captures à 360, 390, 768, 1024, 1280 px, sur un club de démo. Sinon : code seul, et le rapport le dit.
4. Compter les problèmes par motif (une règle violée = une ligne, avec le nombre d'écrans touchés), pas une ligne par écran.
5. Classer : **Bloquant** (on ne peut pas utiliser), **Gênant**, **Détail**.
6. Pas de correction avant validation du rapport.

## Écrans à couvrir (par groupe)

| Groupe | Écrans |
|---|---|
| Connexion | connexion, inscription, confirmation e-mail, choix du club, mot de passe forcé, CGU mises à jour, document légal, chargement |
| Calendrier / matchs | liste, détail, formulaire match, entrée calendrier, prono match à venir, historique (saisie, import, détail) |
| Match en direct | avant coup d'envoi, en cours, composition, rapport, vote homme du match |
| Effectif / joueurs | effectif du club, registre, fiche joueur, classement par stat, plan d'effectif admin (3 onglets), liste d'attente, invités |
| Stats / pronos | hub stats, hub pronos, bilan de saison, armoire à badges |
| Compte | profil, indisponibilités, notifications, préférences, « Plus » |
| Admin | menu admin, réglages du club (10 sections), maillots, abonnement, notification admin, bibliothèque stades, badges admin |
| Hors normal | club suspendu, contrôle plateforme, erreurs d'incident |

## Axe 1 — Adaptation aux tailles d'écran (skill `adaptive-layout`)

À vérifier :
- Barre de navigation adaptée à la largeur (en bas sur téléphone, latérale ou autre sur grand écran).
- Largeur maximale lisible du contenu sur ordinateur ; pas de formulaire étiré sur 1 000 px.
- Écrans liste + détail : deux colonnes sur tablette/ordinateur ou page unique ?
- Largeurs fixes en pixels, débordements (texte coupé, bandes jaunes/noires), `Row` sans `Flexible`.
- Zones sûres (encoche, barre du bas iPhone) et clavier qui masque un champ.
- Orientation jamais verrouillée ; tablette en paysage.
- Taille du texte système agrandie (200 %) : rien ne casse ?
- Tableaux larges (stats, effectif) : défilement signalé, en-tête fixe.
- Composants à surveiller : `pf_adaptive_form`, `sticky_header_table`, `equal_height_column`, `app/shell`.
- Méthode de test : captures à 5 largeurs + tests d'images de référence existants dans `test/`.

## Axe 2 — États : chargement, vide, erreur (skill `ui-states-and-feedback`)

À vérifier, écran par écran :
- Les 4 états existent-ils : chargement / vide / erreur / contenu ?
- Chargement : squelette de la forme du résultat (`pf_skeleton`) plutôt qu'une roue ; pas de clignotement.
- Rafraîchissement : le contenu reste affiché pendant le rechargement.
- « Rien encore » distingué de « rien ne correspond au filtre », chacun avec une action.
- Erreurs : message clair pour la personne (jamais le texte technique brut), bouton « Réessayer » qui relance vraiment.
- Hors ligne : bandeau, actions bloquées ou mises en attente, retour de connexion.
- Confirmations : annulation possible (« Annuler ») plutôt que « Êtes-vous sûr ? » quand l'action est réversible ; suppression irréversible = vraie confirmation.
- Bon niveau de message : texte discret, bandeau, fenêtre, selon la gravité.
- Fenêtres fermées en tapant à côté : traité comme une réponse à part.
- Message affiché après une attente (snackbar après `await`) : écran encore là ?
- Changements visibles seulement à l'œil (couleur, compteur) : annoncés aux lecteurs d'écran.
- Composants à surveiller : `pf_empty_state`, `pf_loader`, `pf_skeleton`, `pf_status_banner`, `incident_error_view`.

## Axe 3 — Bonnes pratiques web et accessibilité (skill `web-design-guidelines`)

Le skill charge ses règles depuis une source externe : les récupérer au début de l'audit. Si c'est impossible, utiliser la grille interne de `ui-ux-pro-max` et le dire.

À vérifier :
- Contraste du texte (4,5:1), y compris en mode sombre ; texte sous 12 px.
- Zones à toucher d'au moins 44 px, avec espace entre elles ; boutons-icônes avec un nom.
- Navigation au clavier : ordre logique, focus visible, aucun piège.
- Lecteur d'écran : noms des boutons-icônes, images décoratives ignorées, titres de page.
- Couleur jamais seule porteuse du sens (Présent/Absent, V/N/D) : ajouter icône ou texte.
- Animations : respect de « réduire les animations » du système.
- Zoom du navigateur non bloqué ; `web/index.html` : viewport, thème, langue de la page, titre.
- PWA : manifeste, icônes, écran d'installation, mode hors ligne (`sw.js`), bouton retour.
- Poids et vitesse de chargement (score Lighthouse si le navigateur de test marche).
- Images : taille, espace réservé (pas de saut de mise en page).
- Composant à surveiller : `pf_accessibility_scope`.

## Axe 4 — Formulaires et saisie (skill `forms-and-input`)

Formulaires à passer en revue : connexion, inscription, mot de passe, match, entrée calendrier, historique, indisponibilité, profil, réglages du club, maillots, notification admin, invités, import historique, rapport de match.

À vérifier :
- Chaque champ a un libellé visible (pas seulement un texte grisé qui disparaît).
- Erreur affichée sous le champ, en français clair, au bon moment (après saisie, pas à la première lettre).
- Vérifications faites sur le serveur (nom déjà pris…) : pas dans la validation instantanée ; message d'attente et d'échec.
- Clavier adapté : e-mail, nombre, téléphone ; majuscules ; saisie automatique ; touche « Suivant » / « Valider ».
- Passage d'un champ à l'autre au clavier ; focus sur le premier champ en erreur.
- Bouton d'envoi : état « en cours » (pas de double envoi), actif ou grisé selon un critère expliqué.
- Champs mot de passe : afficher/masquer, gestionnaire de mots de passe.
- Dates/heures : sélecteurs, format français.
- Perte des données saisies (retour arrière, rotation, erreur réseau).
- Fuites techniques : contrôleurs et focus bien libérés (stabilité, pas visible).
- Rebuild à chaque lettre tapée (lenteur).
- Textes d'aide, valeurs par défaut, champs facultatifs indiqués.

## Axes transversaux (rapides)

- Sécurité de saisie : champs de rôle admin visibles seulement à qui de droit (renvoi au skill `vibesec` si un écran touche aux permissions).
- Cohérence avec `docs/IDENTITE_VISUELLE_MISSION05.md` : à citer comme référence, pas à rouvrir.

## Livrables

1. `docs/AUDIT_UX_COMPLET_<date>.md` :
   - les 10 constats les plus importants (langage simple, avec effet pour l'utilisateur) ;
   - un tableau par axe : règle, écrans touchés (nombre + liste), gravité, correction proposée, effort (petit/moyen/gros) ;
   - ce qui n'a pas pu être vérifié, et pourquoi.
2. Captures dans `docs/` seulement si utiles au rapport.
3. Après validation : corrections par lots (un lot = un axe ou un composant commun), tests existants relancés, une branche, pas de PR sans demande.

## Ordre des lots de correction (proposé)

1. Bloquants, tous axes.
2. Composants communs (une correction ici corrige beaucoup d'écrans).
3. États vide/erreur/chargement manquants.
4. Formulaires.
5. Adaptation tablette/ordinateur.
6. Détails.

## Limites connues

- Pas de vrai téléphone ni tablette ici : captures dans un navigateur de test seulement. Le tactile réel, les vibrations, le clavier du téléphone et le mode PWA installé ne seront pas vérifiés.
- L'app web ne se lance que si Flutter et la base de test sont utilisables ici ; sinon audit par lecture du code.
- Les notifications push ne sont pas testables ici.
- Le skill `web-design-guidelines` peut nécessiter un accès réseau.

## Estimation

Cartographie + rapport : 1 session longue (à découper par groupe d'écrans, avec note dans `docs/HANDOFF.md` entre les groupes). Corrections : selon le rapport.
