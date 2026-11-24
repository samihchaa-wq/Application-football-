# Audit UX/UI complet — 24 novembre 2026

Version analysée : `main` au 24/11/2026 (après les PR #234, #239, #242). Méthode : mesures dans le code (nombre de boutons, couleurs, icônes, textes) + captures d'écran d'une copie locale de l'appli (téléphone 375 px, ordinateur 1280 px) sur un club de démo. Rien n'a été modifié pendant l'audit.

## Les 10 constats qui comptent le plus

1. **Le bandeau « Notifications bloquées » est sur toutes les pages** (tous les écrans capturés) et prend environ 15 % de la hauteur du téléphone. Il pousse le contenu et se répète à chaque écran.
2. **Les boutons de suppression ressemblent aux boutons normaux.** Le thème peint un dégradé rouge sur tous les boutons pleins : la couleur « danger » prévue pour au moins 5 confirmations (finir la saison, supprimer un joueur, tout effacer au live, etc.) est écrasée. « Confirmer » et « Supprimer définitivement » ont le même aspect.
3. **Le rouge veut tout dire** : bouton principal, danger, erreur, onglet sélectionné, Absent, marque. Impossible de savoir au premier coup d'œil si un rouge est « valider » ou « attention ».
4. **Deux verts, deux jaunes, deux rouges pour les résultats.** Les scores du calendrier reprennent les couleurs du thème (copiées en dur dans le code) ; le camembert et les pastilles V/N/D des statistiques utilisent d'autres couleurs, écrites en dur.
5. **Texte trop petit** : 8 et 9 px sur les noms des joueurs du terrain, 9 px sur le bouton « Ma saison », 10 px sur le compteur de notifications (minimum recommandé : 11 à 12 px).
6. **Icônes en 4 styles mélangés** (contour, arrondi, trait fin, plein) et la même action change d'icône selon l'écran : « Enregistrer » a 3 icônes différentes, « Réessayer » 2, « Ajouter » 3.
7. **Textes explicatifs trop longs sur les écrans** : 89 textes de plus de 110 caractères dans l'appli, dont une quinzaine affichés en permanence (liste d'attente, maillots, parrainage, abonnement au calendrier…).
8. **Chiffres sans légende** : la carte Prono affiche « 1 124 / N 933 / 2 1120 » (les points de chaque résultat, multipliés par 100) sans dire ce que c'est.
9. **Statistiques : trois étages de choix** (Joueurs/Équipe/Prono, puis Actuelle/Précédente/Toutes, puis les colonnes à faire défiler) pour un seul tableau. Les colonnes cachées à droite ne sont pas signalées.
10. **Formulaire « Ajouter » incohérent avec le reste** : ses blocs sont teintés bordeaux (les autres écrans sont gris-bleu), et « Nombre de joueurs convoqués 14 joueurs » dit deux fois « joueurs ».

## 1. Boutons

Chiffres : 159 boutons pleins, 72 à contour, 122 boutons texte, 82 boutons-icônes.

- **Danger indiscernable** (constat 2). Proposition : un style « danger » réel (contour rouge + texte rouge, ou rouge plus sombre), identique partout.
- **Mots des confirmations non uniformes** : « Annuler » est partout (64 fois, bien), mais la confirmation change : « Confirmer » (4), « Oui » (1), « Oui, terminer », « Oui, mi-temps », « Valider » (3), « Supprimer » (14). Proposition : le bouton reprend le verbe de l'action (« Terminer », « Supprimer »), jamais « Oui ».
- **Plusieurs gros boutons rouges pleins sur un même écran** (Effectif : « Lien d'inscription » + « Ajouter un joueur sans compte »). Un seul bouton principal par écran ; les autres à contour.
- **Boutons-icônes sans texte** : cloche sur chaque carte de match (et crayon pour l'admin), trophée / cloche / roue crantée en haut des pages. Les noms n'apparaissent qu'au survol sur ordinateur : sur téléphone, on devine. Proposition : garder la roue crantée et la cloche, mettre le reste dans un menu ou ajouter le texte.
- **Pastilles de choix** (Présent/Absent, -30min/Maintenant/J-6, maillot) : corrigées dans la PR #242. Il reste à vérifier les autres groupes de boutons au même modèle.
- **Zones à toucher** : les boutons mesurés (score du direct, Présent/Absent, fin de match) font 48 px. Point positif ; les autres n'ont pas été mesurés un par un.

## 2. Couleurs

- **Rouge surchargé** (constat 3). Proposition : le rouge = action principale et danger ; les onglets sélectionnés en blanc (ou une teinte neutre) avec un trait de couleur dessous ; l'erreur garde son rouge, avec une icône.
- **Résultats : un seul jeu de couleurs** (constat 4). Reprendre `success` (vert), `warning` (jaune) et `error` (rouge) du thème pour le camembert et les pastilles.
- **Couleurs écrites en dur** : 184 couleurs hors du fichier de thème, 60 « blanc » en dur, 14 couleurs standard (rouge, orange…). Chaque changement de thème oblige à les chercher une par une. Proposition : les ramener au thème, sauf les maillots et les badges (couleurs voulues).
- **Orange/jaune à plusieurs sens** : alerte, trophée, « Points » trié, résultat nul, liste d'attente, « N » sélectionné au prono. Proposition : jaune = attention ou nul seulement.
- **Cartes bordeaux du formulaire « Ajouter »** (constat 10) : reprendre le gris-bleu des autres cartes.
- **Contrastes** : texte sur fond OK partout où j'ai mesuré (les paires de couleurs des matchs sont testées automatiquement depuis la PR #242). Les noms de joueurs sur le terrain à 8-9 px restent le point faible.
- **Coins arrondis** : une douzaine de rayons différents (6, 8, 10, 12, 14, 16, 18, 22, 26, 28…). Proposition : 3 valeurs (petit, moyen, grand) déjà prévues dans le thème.

## 3. Agencement

- **Bandeau global** (constat 1). Proposition : l'afficher une seule fois sur le Calendrier, puis un petit point sur la cloche.
- **Marges de page** : 8, 12, 14, 16, 18, 20 ou 24 px selon l'écran. J'ai essayé de tout mettre à 16 px : plusieurs blocs débordaient (fiche joueur notamment). À faire écran par écran, pas d'un coup.
- **Statistiques** (constat 9). Proposition : un seul étage (la saison dans un menu déroulant) et un indice visuel quand le tableau défile (dégradé à droite).
- **Fiche d'un match, onglet Info** : presque vide (« Rendez-vous 13h30 » et trois pastilles de scores sans nom d'adversaire). Proposition : adresse, météo, ou masquer l'onglet quand il n'y a rien.
- **Fiche d'un match, onglet Effectif** : trois sections colorées (Convoqués, Liste d'attente, Absents) dont une « Aucun joueur. » : masquer les sections vides.
- **Pages d'administration** : « Réglages du club » = 10 sections repliables + une barre de recherche + un (i) par réglage. La structure est correcte pour le volume, mais le (i) réduit la largeur des libellés (« Délai de correction du résultat » est coupé).
- **Boutons du bas** « Calendrier / Statistiques » : très hauts (environ 70 px avec marges), alors qu'il n'y a que deux destinations.
- **Écran Ordinateur** : corrigé pour le Calendrier ; le reste des pages utilise toute la largeur du contenu (1080 px).

## 4. Textes inutiles ou à raccourcir

Textes permanents (hors fenêtres de confirmation, où la longueur se justifie) :

- **Liste d'attente** : « Mode « Historique ». Les +1 sont toujours comptabilisés au coup d'envoi. Ils influencent les convocations automatiques. » + colonnes « Tour cette saison ». Jargon (« +1 », « tour »). À réécrire en une phrase ou à mettre derrière un (i).
- **Maillots du club** : deux blocs de 5 à 6 lignes avant le premier réglage.
- **Abonnement / Parrainage** : un paragraphe de 9 lignes. Résumer en 2 lignes + un lien « Comment ça marche ».
- **Abonnement au calendrier** : 3 messages d'erreur de plus de 130 caractères chacun (Google, Apple, Outlook). Un seul message avec un bouton « Voir comment faire ».
- **Indisponibilité (écran vide)** : 4 lignes. Garder la première.
- **Textes qui répètent le titre ou la couleur** : « Championnat · J9 » écrit alors que la carte est déjà bleu foncé ; « Dimanche 22 Novembre 2026 » (jour complet, majuscule à Novembre) → « Dim. 22 nov. · 14 h ».
- **Mots doublés** : « Nombre de joueurs convoqués 14 joueurs ».
- **Libellés quasi identiques** : « Notification : match annulé ou déplacé » et « Notification : annulation » (réglages du club).
- **Légende des abréviations** des statistiques : utile, mais à remplacer par des noms complets sur grand écran (la place existe).
- **Bandeau notifications** : titre + phrase + 2 boutons pour une seule information (constat 1).

Règle proposée : une phrase par écran au maximum ; tout le reste derrière un (i) ou un lien « En savoir plus ».

## 5. Icônes inutiles ou incohérentes

Chiffres : 238 icônes différentes ; 72 boutons avec icône + texte.

- **Icône qui répète le texte, sans rien apporter** : « Annuler » (croix), « Modifier » (crayon), « Supprimer » (poubelle) sur des boutons qui disent déjà l'action ; « Copier » (copie) ×4 ; « Se déconnecter » ; « Réinitialiser » (2 icônes différentes). Proposition : garder l'icône seulement sur les boutons à action unique et fréquente (Ajouter, Partager), la retirer sur les autres.
- **Icône + flèche > sur chaque ligne** des listes (15 fichiers) : Paramètres, Informations légales, Réglages du club (10 sections). La flèche suffit à dire « ça s'ouvre ». Proposition : retirer les icônes décoratives des lignes de listes de plus de 5 éléments et des 3 lignes légales (bouclier, document, marteau).
- **Triple codage** dans l'Effectif d'un match : couleur + icône + mot (« Convoqués (12) » vert + coche ; « Absents » rouge + croix). Le mot et la couleur suffisent.
- **Badges** : « 0 / MATCHS SAISON » écrit sur le badge, « 0/15 » à droite et une barre de progression : même information trois fois.
- **Icônes d'état à conserver** : cloche (notifications), cadenas (verrouillé), nuage barré (hors ligne), coche d'enregistrement. Elles disent quelque chose que le texte ne dit pas.
- **Style** (constat 6). Proposition : une seule famille (contour arrondi) et un tableau « action → icône » dans la doc.

## 6. Ce qui est bien (à ne pas défaire)

- Zones tactiles de 48 px partout, retour visuel au toucher.
- États vides soignés (icône + titre + une phrase + action) sur les listes principales.
- Fenêtres de confirmation qui nomment la conséquence (finir la saison, recommencer le direct).
- Contraste de la plupart des textes, et polices de titres/texte cohérentes (Oswald / Roboto).
- Tout est testé automatiquement : 1 549 tests, dont le contraste des couleurs des matchs.

## 7. Plan proposé (du plus utile au moins urgent)

1. **Lot A — rapide, très visible** : bandeau notifications une seule fois ; vrai style « danger » ; mots des confirmations ; polices 11 px minimum ; un seul vert/jaune/rouge pour les résultats.
2. **Lot B — nettoyage des textes** : les 15 textes permanents, la liste d'attente, les mots doublés, les sections vides masquées.
3. **Lot C — icônes** : une famille de style, une icône par action, retrait des icônes décoratives des listes.
4. **Lot D — structure** : statistiques sur un seul étage avec indice de défilement, onglet Info du match, boutons d'en-tête, formulaire « Ajouter » aux couleurs des autres cartes.
5. **Lot E — couleurs en dur** : ramener les 184 couleurs au thème (plus long, sans effet visible, mais évite les oublis).

Recommandation : A puis B (une seule PR chacun), les autres ensuite.

## 8. Ce qui n'a pas été vérifié

- Vrai téléphone (iPhone, Android), texte agrandi, mode paysage.
- Écrans de plateforme (console gestionnaire, facturation) : mesurés dans le code, pas capturés.
- Vidéo de composition et « Ma saison » (Wrapped).
- Le mode clair n'existe plus (thème unique sombre) : aucun contrôle de ce côté.
