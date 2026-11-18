# Petit Filet — Correctifs Live, maillot gardien et nettoyage des textes (18/11/2026)

## Périmètre

Changements sur la version **commerciale** uniquement. Aucun changement sur AS Grinta original, Supabase commercial, migrations, comptes ou déploiement. Ce fichier inventorie les libellés superflus repérés au cours du contrôle du code Flutter ; il ne constitue **pas** une certification visuelle de chaque parcours sur iPhone.

## Correctifs des captures

1. **T–15 / Live spectateur :** `get_match_live_state` peut renvoyer une composition Live nulle avant l'ouverture de l'espace de travail. La vue spectateur essaie maintenant la composition publiée `get_published_match_composition`. Si elle n'existe pas, elle affiche « Composition non publiée. » plutôt que de laisser croire qu'une composition publiée a disparu. L'affichage du terrain ne nécessite pas de démarrer la session ni de modifier la base.
2. **Rencontre à venir :** la carte `HomeNextMatchCard` utilise `CalendarScoreline` (domicile | VS | extérieur) plutôt que `MatchFixture` aligné à gauche. Le sens domicile / extérieur est conservé.
3. **Maillot de gardien :** sur le terrain, l'apparence prend le **poste occupé** comme référence ; un joueur de champ dans les buts porte la tenue de gardien et l'inverse sur un poste de champ. Les glisser-déposer et changements de dispositif propagent l'étiquette du poste, tandis que les anciennes positions peuvent corriger une étiquette obsolète. Sur le banc, la tenue conserve le rôle habituel.

## Inventaire des textes et exemples supprimés ou remplacés

| Zone de l'application | Textes inutiles identifiés | Traitement |
| --- | --- | --- |
| Création de saison (Administration, Plus) | `2026-2027` affiché comme exemple | Remplacé par le libellé `Nom de la saison` |
| Bibliothèque adversaires / stades | `Équipe, stade ou adresse`, `Ex. FC Les Tilleuls`, `Ex. Stade municipal`, `Rue, code postal, ville…` | Placeholders supprimés, libellés conservés |
| Notification rédigée par un admin | `Entraînement déplacé`, `Rendez-vous à 19h au lieu de 18h30.` | Exemples supprimés, champs `Titre` et `Message` conservés |
| Badges, recherche de personne | `Rechercher un gardien…`, `Rechercher une personne…` | Libellé unique `Rechercher` |
| Réglages du club | `Ex. bilan, notifications, maillots…`, `Rue, code postal, ville` | Exemples supprimés ; boutons `i` d'information préservés |
| Formulaire de match | `Terrain, rue, ville…` | Exemple supprimé ; `Adresse (facultatif)` conservé |
| Formulaire d'événement | `Ex. Soirée du club, repas, réunion…`, `Terrain, adresse, salle, restaurant…` | Exemples supprimés |
| Formulaire calendrier / match | `Terrain, rue, ville…`, `Rechercher...` | Exemple d'adresse supprimé ; recherche explicitement libellée |
| Indisponibilité | `Vacances, travail, déplacement…` | Exemple supprimé ; informations de confidentialité conservées |
| Actions de but | `?` comme indication de minute | Placeholder supprimé ; champ `Min` conservé |
| Composition, nom des deux équipes | `Équipe 1` / `Équipe 2` en texte d'exemple intérieur au champ | Transformés en libellés |
| Inscription | `Donné par l'administrateur de ton club.`, `Affiché sur les scores. Ex. : FCV` | Aides redondantes supprimées |
| Rejoindre un club | `Donné par l'administrateur de ton club.` | Aide redondante supprimée |
| Saisie d'historique | `Pour un joueur qui n'a pas de compte.`, `<club> contre…` | Aides redondantes supprimées |
| Terrain de composition vide | `Glisse un joueur ici ou utilise son menu.` | Texte retiré, zone de dépôt inchangée |
| Zones de dépôt | `Dépose un joueur ici.`, `Aucun joueur.` sous un compteur de 0 | Textes retirés |
| Calendrier mensuel vide | `Change de mois avec les flèches pour continuer.` | Retiré ; titre du mois vide conservé |
| Calendrier historique vide | `Historique <saison> — change de mois avec les flèches.` | Retiré ; titre du mois vide conservé |
| Effectif vide | `Les membres validés apparaissent ici tout seuls. Ajoute avec le bouton ci-dessus…` | Retiré ; bouton et titre `Effectif vide` conservés |
| Live avant coup d'envoi | `Le match n'a pas encore démarré` au-dessus de la composition | Bandeau redondant retiré |

## Textes volontairement conservés

- **Erreurs, validations et états bloquants** : préciser ce qu'il faut corriger et pourquoi une action n'a pas abouti.
- **Mots de passe** : exigences de sécurité, et e-mail de récupération.
- **Confidentialité** : qui voit la raison d'une indisponibilité, ne pas communiquer de données médicales.
- **Actions irréversibles** : supprimer définitivement un joueur ou voter une seule fois et anonymement.
- **Réglages** : boutons d'information `i` et leurs explications associées, conformément à la demande.

Ne pas retirer en masse les `tooltip`, `Semantics` ou libellés d'accessibilité : certains n'apparaissent pas en texte à l'écran, mais sont essentiels aux lecteurs d'écran.

## Vérification à effectuer avant fusion

- iPhone : calendrier à venir domicile/extérieur, très longs noms de club, largeur étroite, notifications et boutons inchangés.
- T–15 : composition publiée / non publiée / réseau indisponible, rôle coach et rôle spectateur, absence de démarrage involontaire du Live.
- Éditeur de composition : joueur de champ déplacé dans les buts puis sur le banc, échange avec le gardien, changement de dispositif, historique et rechargement depuis Supabase.
- Formulaires modifiés : libellés visibles à vide et pendant saisie, validations et messages d'erreur conservés, accessibilité VoiceOver.
- Flutter : formatage, analyse, tests ciblés puis build Web. L'absence de Flutter dans l'environnement local implique de s'appuyer sur les contrôles GitHub ; **une PR verte n'est pas une validation sur appareil réel**.

## Limite de l'inventaire

La recherche a couvert les occurrences indexées de `hintText`, `helperText`, les exemples explicites et plusieurs consignes UI identifiables. Pour répondre littéralement à « l'intégralité des textes inutiles » sur tous les états et écrans, une recette visuelle systématique de chaque parcours reste indispensable : des textes générés par données serveur, ou des états rarement visités, ne se déduisent pas de ces seules recherches. Ce document ne doit pas être présenté comme un audit exhaustif de l'interface.
