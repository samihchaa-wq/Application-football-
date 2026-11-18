# Petit Filet — corrections match test et épuration des textes (18 novembre 2026)

## Périmètre et protection

- **Dépôt commercial uniquement** : `Application-football-`. Aucun accès en écriture à AS Grinta original.
- Vérification ponctuelle de la base commerciale en **lecture seule** : pour le match du 18/11/2026 à 01:00 (Europe/Paris), composition publiée à 01:17, donc **pas publiée** lors de la capture à 00:45.
- Pas de déploiement, fusion ou migration dans cette intervention.

## Trois incidents

1. **Avant le coup d'envoi (T−15)** : la session Live ne possède pas forcément de composition. Le spectateur récupère désormais la composition publiée si elle existe ; sinon l'absence de publication est clairement distinguée d'une erreur de chargement.
2. **Calendrier** : la carte du prochain match emploie désormais `CalendarScoreline`, avec équipe à domicile et équipe extérieure de part et d'autre du « VS », conformément aux autres cartes.
3. **Gardien** : la tenue est déterminée par le poste réellement occupé (`GB`), y compris si le joueur n'est pas gardien dans l'effectif. Les déplacements et les changements de dispositif mettent à jour le libellé tactique ; les anciennes compositions avec un ancien libellé bénéficient d'un repli sur les coordonnées.

## Textes redondants identifiés et retirés

- **Avant-match Live** : le bandeau « Le match n’a pas encore démarré » doublonnait le contexte de la page.
- **Fiche de match, cartes Effectif et Composition** : « Sélectionner puis enregistrer l’effectif », « Consulter les joueurs convoqués », « Créer, enregistrer et publier la composition », « Consulter la composition publiée ». Les titres et l'action de la carte suffisent.
- **Effectif** : « Mise à jour en direct ». La limite, lorsqu'elle s'applique, demeure visible.
- **Codes d'invitation** : « Donné par l’administrateur de ton club ».
- **Nom court du club** : « Affiché sur les scores. Ex. : FCV ».
- **Historique, joueur sans compte** : « Pour un joueur qui n’a pas de compte ».
- **Historique, adversaire** : « [nom du club] contre… ».

## Exemples et textes de remplissage retirés des saisies

| Écran | Contenus retirés |
| --- | --- |
| Création de saison (administration et menu) | `2026-2027` comme texte de remplissage ; remplacé par l'étiquette « Nom de la saison » |
| Bibliothèque des adversaires et stades | « Équipe, stade ou adresse », « Ex. FC Les Tilleuls », « Ex. Stade municipal », « Rue, code postal, ville… » |
| Notification manuelle | « Entraînement déplacé », « Rendez-vous à 19h au lieu de 18h30 » |
| Attribution des badges | « Rechercher un gardien… », « Rechercher une personne… » ; remplacés par « Rechercher » |
| Réglages du club | « Ex. bilan, notifications, maillots… », « Rue, code postal, ville » |
| Formulaire de match | « Terrain, rue, ville… » |
| Événement / match dans calendrier | « Ex. Soirée du club, repas, réunion… », « Terrain, adresse, salle, restaurant… », « Rechercher… », « Terrain, rue, ville… » |
| Indisponibilités | « Vacances, travail, déplacement… » |
| Faits du match | « ? » comme exemple de minute |
| Match entre nous | « Équipe 1 » / « Équipe 2 » en filigrane de saisie ; noms désormais indiqués comme libellés de champ |

## Éléments volontairement conservés

- **Tous les boutons « i »** et explications associées dans les réglages du club.
- Libellés de champs et textes de boutons nécessaires à la saisie et à l'accessibilité.
- Erreurs de validation (mot de passe, formulaire, autorisations), messages d'erreur serveur, avertissements de conséquences irréversibles.
- Aide sur les exigences des mots de passe, récupération de compte, confidentialité des motifs d'indisponibilité, consentements légaux.
- Retours d'état utiles (« aucune donnée », erreur, chargement, succès), qui ne sont pas de simples explications évidentes.

## Vérifications

- Tests de non-régression **ajoutés dans le dépôt** : placement et tenue gardien, alignement des équipes dans le calendrier, affichage « Composition non publiée » côté spectateur.
- L'ajout des tests ne démontre pas leur succès : vérifier les contrôles CI sur la PR (formatage/analyse Flutter, tests, build web).
- **Limite de l'audit** : revue statique du code et recherches de textes ; aucun parcours manuel exhaustif de tous les écrans sur appareil n'a été effectué. Ne pas présenter ce travail comme une certification complète de tous les microtextes.

## Nettoyage complémentaire des textes évidents

- **Terrain de composition vide :** retrait de « Glisse un joueur ici ou utilise son menu. ».
- **Zones de dépôt :** retrait de « Dépose un joueur ici. » et « Aucun joueur. » quand le compteur suffit.
- **Calendrier mensuel vide :** retrait de « Change de mois avec les flèches pour continuer. ».
- **Calendrier historique vide :** retrait de « Historique [saison] — change de mois avec les flèches. ».
- **Effectif vide :** retrait de « Les membres validés apparaissent ici tout seuls. Ajoute avec le bouton ci-dessus un joueur qui n’a pas encore de compte. » ; l'action conserve son libellé.

## Recette visuelle complémentaire avant fusion

1. iPhone, calendrier domicile / extérieur : deux noms courts, très longs et écran étroit, sans chevauchement avec « VS ».
2. Live T−15 : composition déjà publiée, composition jamais publiée, erreur de réseau ; distinguer la vue spectateur du pilotage coach.
3. Sur le terrain : placer un joueur de champ en GB, échanger avec un défenseur, passer sur le banc et changer de dispositif ; vérifier couleurs du gardien avant / pendant / après match.
4. Formulaires : labels à vide et lors de la saisie ; validations et lisibilité VoiceOver.
5. Analyse Flutter, tests ciblés, build Web et essai réel sur téléphone. Une CI verte n'est pas une preuve de recette smartphone.
