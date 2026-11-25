# Audit UX/UI — badges, joueurs, statistiques, pronostics (lecture seule)

Chemins relatifs à `lib/features/`. 35 fichiers .dart lus en entier. Aucun rendu réel : tout est jugé par le code.
Chaque ligne : `[gravité] (axe) L<ligne> : problème → effet → correction`.
Axes : 1 tailles d'écran, 2 états, 3 accessibilité/web, 4 formulaires.

---------------------------------------------------------------------
# BADGES
---------------------------------------------------------------------

### badges/presentation/armoire_page.dart
- [Gênant] (1) L280-284 : la taille d'une case se calcule avec la largeur de tout l'écran (`MediaQuery.of(...).size.width`), pas avec la place réellement disponible, et fixe 5 colonnes → sur téléphone étroit (320 px) l'emblème fait ~51 px et son texte ~5 px, illisible ; sur ordinateur les cases s'étalent sans limite de largeur → badges minuscules ou grille mal alignée → utiliser LayoutBuilder + largeur max de lecture (ex. 760 px) et un nombre de colonnes selon la largeur.
- [Gênant] (3) L291, L367, L562 : les cases de badge sont des `GestureDetector` sans libellé ni focus clavier → sur le web on ne peut pas y accéder au clavier, un lecteur d'écran n'entend pas le nom du badge ni « bouton » → InkWell + Semantics(button, label: nom du badge).
- [Gênant] (2) L75-86 : en cas d'erreur, seulement un message dans une liste ; aucun bouton « Réessayer » (il faut deviner qu'on peut tirer l'écran vers le bas, impossible à la souris) → ajouter un bouton qui relance le chargement. De plus L71 : `await ref.read(myArmoireProvider.future)` relance l'erreur dans le geste d'actualisation (erreur non attrapée) → entourer d'un try/catch.
- [Détail] (2) L367-378 : le geste « marquer comme vu » n'est ni attendu ni protégé (`markBadgeSeen` sans await/catch) puis la liste est recalculée tout de suite → le point « nouveau » peut rester ou une erreur silencieuse partir dans le vide → attendre l'écriture dans un try/catch.
- [Détail] (3) L408-445 : « nouveau » (point 11 px) et « arboré » (étoile) ne sont portés que par la forme/couleur, rien pour le lecteur d'écran → ajouter un libellé « Nouveau » / « Arboré ».
- [Détail] (3) L151-156, L348-355 : « Mystère » et la phrase d'aide en `textFaint` 11-12 px, contraste faible → utiliser `textSecondary` et ≥ 12 px.
- [Détail] (3) L323-346 : la case verrouillée (cadenas) n'a aucun texte alternatif → « Badge mystère, à découvrir ».
- [Détail] (2) L74 : le chargement est une roue seule, pas un squelette en forme de grille → effet de saut à l'arrivée.
- [À vérifier] (1) L515-551 : l'emblème « En progression » est calculé à partir de la hauteur du texte (4 passes) ; à texte agrandi à 160 % il peut devenir très grand et ne laisser presque plus de largeur au texte → tester 130-160 %.
- [Détail] (1) L515-551 : mesure du texte de tous les badges à chaque reconstruction (TextPainter ×4 passes × N badges) → coût inutile ; mettre en cache.

### badges/presentation/badge_admin_page.dart
- [Gênant] (4) L449 : le bouton « Créer le badge » est grisé tant qu'aucune image n'est choisie, sans le dire ; le nom vide, lui, ne se voit que par une barre de message en bas (L57-62) → afficher l'erreur sous le champ « Nom » et une phrase « Choisis d'abord une image ».
- [Gênant] (4) L428-444 : champs « Nom » et « Description » sans limite de longueur ni compteur, alors que l'éditeur de texte (badge_text_editor) limite à 60 et 300 → un nom trop long casse l'emblème ou est refusé ; ni `textInputAction` ni `onSubmitted` (Entrée ne passe pas au champ suivant) → reprendre `maxLength` 60/300 et `textInputAction.next`.
- [Gênant] (2) L117, L129-132 : erreur du catalogue = simple texte brut sans mise en forme ni « Réessayer » ; vide = « Aucun badge. » sans explication → utiliser PfEmptyState avec bouton de reprise.
- [Gênant] (1) L564-569 + L635-638 : dans la feuille « Décerner », la liste a une hauteur max de 50 % de l'écran sans tenir compte du clavier, et la colonne n'est pas défilante → quand on tape dans « Rechercher » sur petit téléphone, la feuille déborde (bandes d'erreur) et le bouton peut disparaître → mettre la colonne dans un SingleChildScrollView ou limiter la liste à ce qui reste au-dessus du clavier (`viewInsetsOf`).
- [À vérifier] (2) L549-553 : les messages de confirmation « Badge décerné à… » passent par le ScaffoldMessenger de la page, alors qu'une feuille modale recouvre l'écran → le message est peut-être masqué/assombri derrière la feuille.
- [Détail] (3) L304-353 : bascule « Manuel / Automatique » : l'état choisi n'est donné que par la couleur, hauteur 40 px (< 44), pas de Semantics(selected) → ajouter `selected`, passer à 44 px.
- [Détail] (4) L619-625 : champ « Rechercher » sans `textInputAction.search` ni bouton d'effacement.
- [Détail] (3) L667-671 : les boutons « Décerner » sont tous grisés pendant qu'un envoi est en cours, sans explication visible (il y a un petit rond sur la ligne concernée seulement).
- [Détail] (2) L96-145 : aucun geste « tirer pour actualiser » sur les onglets de liste → un badge créé ailleurs n'apparaît pas sans quitter l'écran.
- [Détail] (1) L568, L637 : `MediaQuery.of` au lieu de `viewInsetsOf` / `sizeOf` (reconstruit tout à chaque changement).

### badges/presentation/badge_detail_sheet.dart
- [Gênant] (2) L291-296 : pendant le chargement des « détenteurs » → `SizedBox.shrink()` (la section apparaît d'un coup, la feuille saute) ; en erreur, texte sans reprise → afficher un petit squelette et un lien « Réessayer ».
- [Gênant] (3) L349-414 : l'échelle des paliers montre tous les paliers de la même façon, seul celui en cours est mis en valeur (couleur + bordure) ; on ne voit pas quels paliers sont déjà gagnés → ajouter « Gagné » / « À venir » en texte.
- [Détail] (3) L239-255 : « Arborer ce badge » : mot peu courant et effet non expliqué (le badge apparaît à côté du prénom dans les stats) → « Afficher ce badge près de mon prénom ».
- [Détail] (1) L157-166 : le bouton rond d'édition d'image dépasse du cadre de l'emblème (`right: -8, bottom: -6`) ; la partie qui sort du cadre ne reçoit pas les touches → zone cliquable réduite.
- [Détail] (4) L196-216 : l'administrateur a deux boutons pour la même action « image » (icône sur l'emblème + bouton « Image »).
- [À vérifier] (1) L134-193 : en-tête = emblème 123 px + texte sur une même ligne ; à 160 % sur téléphone 320 px, la colonne de texte fait ~110 px → titre coupé mot à mot.
- [Détail] (1) L109 : `MediaQuery.of(context).viewInsets` (pas de clavier dans cette feuille, inutile).

### badges/presentation/badge_image_editor.dart
- [Gênant] (3/4) L354-387 : le recadrage se fait uniquement au geste (pincer/glisser) ; aucune consigne écrite, aucun curseur ou boutons +/− → sur ordinateur et pour qui ne peut pas pincer, impossible de zoomer sérieusement (la molette marche peut-être) → ajouter « Pince pour zoomer, glisse pour déplacer » et un curseur de zoom.
- [Gênant] (1) L313-317, L333-336 : la boîte contient une zone fixe de 220 px (+ marges) dans un AlertDialog non défilant → sur téléphone en paysage ou 320 px de large, débordement ; sur 320 px la zone est réduite par la largeur, mais l'export (L158-282) calcule toujours sur 220 → l'image enregistrée peut ne pas correspondre à ce qu'on voit → mettre le contenu dans un SingleChildScrollView et mesurer la zone réelle.
- [Gênant] (2) L99-123 : après « Enregistrer », l'envoi de l'image n'a aucun indicateur (le bouton est juste grisé) ; le préparatif du JPEG (L284-302) non plus → l'utilisateur ne sait pas si ça travaille → rond de chargement dans le bouton / la boîte.
- [Détail] (2) L67-70 : le téléchargement de l'image actuelle avant d'ouvrir l'éditeur n'a pas de retour visuel pour le bouton texte (L140-143).
- [Détail] (2) L217, L294 : messages d'erreur dans un SnackBar du Scaffold de la page, alors qu'une boîte modale est ouverte → message assombri derrière la boîte (À vérifier à l'écran).
- [Détail] (3) L367-385 : image affichée sans libellé alternatif ; guide de cadrage (L433-493) invisible aux lecteurs d'écran.
- [Détail] (4) L215-220 : message unique « Impossible de lire cette image » même si l'accès à la galerie a été refusé → distinguer le cas « autorisation refusée ».
- [Détail] (2) L223-282 : si le JPEG échoue, `source`/`codec` ne sont pas libérés (fuite mémoire légère).

### badges/presentation/badge_emblem_body.dart
- [Gênant] (3) L146-186 : les textes de l'emblème sont proportionnels à sa taille (`size*0.095` = 4,4 px dans les listes de stats à 46 px, ~5 px sur petit écran, 8 px au max dans l'armoire) → le critère (« BUTS · CARRIÈRE ») est illisible dans la plupart des usages → afficher le nom en clair à côté de l'emblème partout où il est petit, ou n'afficher que le chiffre.
- [Gênant] (3) L268-282, L389-406 : chaque texte est écrit deux fois (contour noir + remplissage) → les lecteurs d'écran lisent « BUTS BUTS », « 50 50 » → exclure le calque de contour (`ExcludeSemantics`) et donner un libellé global à l'emblème.
- [Détail] (3) L389-395 : le titre sans nombre ignore volontairement le réglage de taille de texte (RichText) → choix assumé, mais ne suit pas l'agrandissement demandé par l'utilisateur.
- [Détail] (1) L336-372 : jusqu'à 40 mesures de texte par emblème et par reconstruction → léger coût ; à mettre en cache.

### badges/presentation/badge_premium_skins.dart — rien à signaler (lu en entier)
(Dessins statiques, aucune animation. Note de maintenance, pas d'effet utilisateur : les noms `blue`/`navy`/`violet`/`emerald` sont associés à des couleurs historiques sans rapport, L28-66.)

### badges/presentation/badge_threshold_editor.dart
- [Gênant] (4) L62-69, L114-122 : « Enregistrer » est grisé sans dire pourquoi (valeur vide, 0, > 10 000, identique à l'actuelle) ; aucun message sous le champ ; le texte promet « entre les paliers voisins » mais rien ne le vérifie côté écran → `errorText` explicite (« Entre 1 et 10 000 »).
- [Détail] (4) L114-122 : Entrée ne valide pas (`onSubmitted` absent), pas de `textInputAction.done`.
- [Détail] (2) L71-97 : abaisser le seuil décerne tout de suite le badge à plusieurs membres, de façon irréversible (« ne retire pas »), mais sans confirmation chiffrée (« 4 membres le recevront ») → ajouter ce récapitulatif avant d'envoyer.
- [À vérifier] (2) L93-95 : l'erreur serveur passe par un SnackBar derrière la boîte modale.

### badges/presentation/badge_text_editor.dart
- [Détail] (4) L63-69, L133-136 : « Enregistrer » grisé si le nom est vide, sans message sous le champ.
- [Détail] (4) L107-114 : pas de `textInputAction.next` entre « Nom » et « Descriptif ».
- [À vérifier] (2) L93-95 : erreur serveur via SnackBar sous la boîte modale.

### badges/presentation/badge_emblem.dart
- [Détail] (2) L97-105 : `Image.network` sans `loadingBuilder` : pendant le chargement l'emblème est vide, puis l'image surgit (pas de fondu, pas de squelette) ; en erreur, le repli emoji est silencieux.
- [Détail] (3) L126-132, L152-162 : les étoiles de palmarès sont de simples icônes sans texte alternatif (« 2 titres ») ; l'emblème entier n'a pas de `Semantics` (nom, valeur, verrouillé).

### badges/presentation/name_with_badges.dart
- [Détail] (2) L55-58 : si le chargement des badges échoue, le badge disparaît sans rien dire (`asData?.value` avale l'erreur).
- [Détail] (3) L79-110 : le badge à côté du nom n'a ni libellé, ni toucher propre (toucher le badge ouvre la fiche joueur, pas le détail du badge) → ajouter un `Semantics(label: nom du badge)`.
- [Détail] (1) L60-64 : taille minimale 46 px → les lignes de tableau deviennent hautes (~61 px) dès qu'un badge est affiché ; à regarder à l'écran.

### badges/presentation/badge_descriptor.dart
- [Détail] (3) L25-80 : abréviations sur l'emblème (« HDM », « PASSES D. », « CLEAN SHEETS ») peu parlantes pour un non-initié, et « HDM » est écrit « Homme du match » ailleurs → harmoniser le vocabulaire.

### badges/presentation/badge_trophy_button.dart
- [Gênant] (2/4) L68-76 : le bouton attend la réponse du serveur (`markSeen`) avant d'ouvrir l'armoire, sans retour visuel ni garde contre le double toucher → sur réseau lent le trophée semble mort, deux touchers ouvrent l'écran deux fois → ouvrir tout de suite et marquer « vu » en arrière-plan.
- [Détail] (3) L23, L44-64 : zone 40 × 40 px (< 44) ; le point « nouveaux badges » n'existe que visuellement (le libellé reste « Armoire à badges ») → tooltip/Semantics « Armoire à badges, nouveau ».
- [Détail] (3) L41-43 : texte invisible 🏆 (Opacity 0) laissé dans l'arbre, exclu des lecteurs d'écran mais inutile visuellement.

### badges/presentation/locked_badge_emblem.dart
- [Détail] (3) L28-51 : un badge verrouillé n'est signalé que par le gris et le cadenas, aucun libellé « verrouillé » ; contraste du cadenas (`textSecondary` sur fond sombre) à vérifier.

### badges/presentation/badge_image_delivery.dart — rien à signaler (lu en entier)
### badges/presentation/badge_display_scope.dart — rien à signaler (lu en entier)
### badges/presentation/badge_image_picker.dart — rien à signaler (lu en entier)

### badges/presentation/badge_image_picker_web.dart
- [À vérifier] (2) L8-18 : aucune limite de taille/type de fichier côté web ; une très grosse image est décodée sur le fil principal (gel possible) → limiter à quelques Mo avant décodage.

### badges/presentation/badge_image_picker_stub.dart
- [Détail] (2) L5-15 : `imageQuality: 100` avec 1600 px → fichiers lourds ; si la permission galerie est refusée l'exception remonte et l'écran dit « Impossible de lire cette image » (message trompeur).

---------------------------------------------------------------------
# JOUEURS
---------------------------------------------------------------------

### players/presentation/player_card_page.dart
- [Gênant] (2) L106-111, L580-601 : si la fiche ne se charge pas, `_Message` est une liste sans geste d'actualisation ni bouton « Réessayer » → l'utilisateur est bloqué et doit quitter l'écran → bouton « Réessayer » qui invalide le fournisseur.
- [Gênant] (1) L131-139, L436-478 : aucune largeur maximale de lecture ; les badges sont en 4 colonnes calculées sur la largeur totale (`size = width`) → sur ordinateur/tablette, badges géants (> 200 px) et statistiques étalées ; sur 320 px, emblèmes de ~55 px illisibles → plafonner la largeur (ex. 640 px) et le nombre de colonnes (À vérifier si la coque de l'appli limite déjà la largeur).
- [À vérifier] (1) L305-379 : l'en-tête met sur une ligne photo 96 px + prénom + badge (~72 px) ; avec badge sur téléphone 320 px il reste ~50 px pour le prénom, réduit à ~10 px par le FittedBox → lisibilité à tester.
- [Détail] (3) L358-378 : le badge arboré de l'en-tête n'est pas touchable (alors que ceux du bas ouvrent le détail) et n'a pas de libellé.
- [Détail] (3) L489-498 : tuile de badge en `GestureDetector` (pas de focus clavier), malgré le `Semantics(button)`.
- [Détail] (3) L72 : le titre de page est toujours « Fiche joueur », sans le nom du joueur (onglet du navigateur, lecteur d'écran, historique) → « Fiche joueur · Prénom ».
- [Détail] (2) L580-601 : même icône « personne » pour « introuvable » et pour une erreur de chargement.
- [Détail] (2) L170-173, L447-449 : erreurs de section en simple note sans reprise (le tirer-pour-actualiser existe mais n'est pas découvrable).

### players/presentation/player_card_matches.dart
- [Gênant] (1) L150-181 : ligne « puce du type de match + Domicile/Extérieur » sans Flexible ni ellipsis ; avec « ENTRE NOUS » (puce ~87 px) + « Extérieur » + icônes de buts/passes/HDM + score, la colonne centrale n'a que ~110 px sur un téléphone de 360 px → débordement (bandes jaunes/noires) possible dès 100 % de texte → mettre la puce et le texte dans un Wrap/Flexible.
- [Gênant] (1) L113-134 : colonne de date large de 40 px fixes ; à texte agrandi (≥ 130 %) « AOÛT »/« JUIL » ne tient plus (jour 16 px, mois 12 px) → largeur par `IntrinsicWidth`/min 48.
- [Détail] (3) L186-200, L225-251 : les icônes ballon / chaussure suivies d'un chiffre n'ont pas de libellé (« 2 buts », « 1 passe décisive ») ; seul l'Homme du match a une infobulle.
- [Détail] (3) L202-218 : résultat (victoire/nul/défaite) porté par la couleur seule dans la liste (la lettre V/N/D n'y figure pas, contrairement au carré « Bilan »).
- [Détail] (2) L125-131 : date sans année ; sur « Carrière » on ne sait pas de quelle saison vient un match.
- [Détail] (3) L21-37 : les carrés V/N/D n'ont pas de libellé (« Victoire »).

### players/presentation/player_card_stats.dart
- [Gênant] (1) L259-266 : trois légendes « 12 Victoires · 3 Nuls · 5 Défaites » côte à côte dans une `Row` à espacement fixe, sans Flexible ; à 130-160 % de texte ou en 320 px, débordement → utiliser un Wrap.
- [Gênant] (1) L146-154 : étiquettes de cases en majuscules, 12 px, sans coupure maîtrisée dans des cases de ~88 px ; à texte agrandi, « VICTOIRES » est coupé en plein mot → ajouter `maxLines`/`softWrap` et réduire par FittedBox.
- [Gênant] (2/3) L56-64, L119-121 : la mention « N/A » sous la case ne dit pas pourquoi (il faut au moins 5 ou 20 matchs, expliqué seulement sur la page de classement) ; case « Passes » avec « – » (L73-76) sans explication non plus → texte « Pas assez de matchs (min. 20) » / « Non suivi avant 2026-27 ».
- [Détail] (3) L363-407 : pastilles de choix de statistique hautes d'environ 30 px (< 44).
- [Détail] (3) L486-562 : la meilleure saison passe en or (couleur seule, non annoncée) ; la saison en cours est en transparence 45 % (contraste faible à vérifier).
- [Détail] (1) L476-480 : graphique d'évolution qui défile horizontalement sans aucun indice (les anciennes saisons sont hors écran à gauche).
- [Détail] (3) L548 : barres animées (250 ms) sans respecter « réduire les animations ».
- [Détail] (2) L314-317 : « Évolution » absente en silence si le chargement échoue ou s'il n'y a qu'une saison (`error`/`loading: SizedBox.shrink`, déjà compté globalement, ici localisé).
- [Détail] (3) L215-222 : la « forme » (5 derniers matchs) ne dit pas dans quel sens elle se lit (le plus récent à droite).

### players/presentation/players_registry_page.dart
- [Gênant] (2) L31, L61 : erreur de chargement = texte centré brut, sans icône ni « Réessayer », et sans tirer-pour-actualiser (pas de liste) → utiliser PfEmptyState avec bouton.
- [Gênant] (2) L171-183 (et L669-678) : suppression, archivage et réactivation d'un joueur n'ont aucun indicateur d'envoi ni message de réussite (seule la liste change) → risque de double toucher et de doute sur une suppression définitive → SnackBar « Joueur supprimé » + blocage pendant l'envoi.
- [Gênant] (2/4) L596 : `firstName.dispose()` est appelé dès que `showDialog` rend la main, alors que l'animation de fermeture de la boîte reconstruit encore le champ → erreur « controller utilisé après dispose » possible à chaque fermeture → déplacer le contrôleur dans un State de boîte (comme member_contact_dialog).
- [Gênant] (2) L248-259 : sélection de photo, lecture du fichier et recadrage ne sont pas dans un try/catch (seul l'envoi l'est) → permission refusée ou fichier illisible = erreur muette ou plantage.
- [Gênant] (1) L351-354 : dans la liste déroulante « Relier à un compte », la mention clé « actuellement lié à X » est dans le même texte coupé par une ellipse → sur écran étroit l'administrateur ne voit pas qu'il va déplacer une liaison.
- [Détail] (4) L504-508 : pas de focus automatique sur « Prénom », pas de validation avant envoi (champ vide accepté puis erreur serveur en bas), pas de `textInputAction`/Entrée.
- [Détail] (4) L337 : le champ s'appelle « Pronostiqueur » alors que la boîte parle de « compte » ; liste déroulante non cherchable (30+ membres).
- [Détail] (4) L513 : l'interrupteur « Gardien » se grise sans explication quand « Coach » est actif.
- [Détail] (3) L102-115 : un joueur archivé n'est signalé que par le mot « Archivé » dans une phrase longue ; aucun style (grisé) pour le distinguer.
- [Détail] (3) L618-620 : menu de `RosterPlayerMenu` avec la même infobulle « Modifier le joueur » sur chaque ligne (l'autre menu L120 a corrigé avec le nom du joueur).
- [Détail] (2) L706-707 vs L217 : « Retirer de l'effectif » dans un menu, « Archiver » dans l'autre pour la même action ; logique du menu copiée deux fois (L121-191 et L626-685).
- [Détail] (2) L315, L495 : boîtes fermables en touchant à côté pendant l'envoi → l'envoi continue sans retour, `setState` possible après fermeture.

### players/presentation/player_stat_ranking_page.dart
- [Gênant] (2) L152-156, L372-407 : en erreur, message + tirer-pour-actualiser uniquement, pas de bouton « Réessayer » (non découvrable à la souris).
- [Détail] (3) L332-346 : la ligne du joueur mis en avant l'est par couleur + liseré seulement, pas annoncée aux lecteurs d'écran.
- [Détail] (3) L353-369 : le tiret « – » du joueur non classé n'est pas expliqué hors de la ligne de séparation (« Moins de N matchs » est bien là, L267-278 : bon point).
- [Détail] (1) L193-198 : largeur de la colonne des noms recalculée par mesure de texte pour tous les joueurs à chaque reconstruction.

### players/presentation/club_roster_page.dart
- [Gênant] (2) L53-54, L154-159 : si les coordonnées ne se chargent pas (erreur ou chargement en cours), chaque membre affiche « Pas de coordonnées » : c'est faux, et on ne voit pas qu'il y a eu une erreur → afficher « Chargement… »/« Coordonnées indisponibles » + réessayer.
- [Gênant] (2) L28, L58 : erreur de chargement = texte centré brut, sans bouton ni geste d'actualisation.
- [À vérifier] (hors axes — données personnelles) L148-153 : téléphone et date de naissance de chaque membre sont visibles de tous, saisis par un administrateur (member_contact_dialog) ; vérifier que le membre concerné est informé/consent.
- [Détail] (3) L161-167 : le bouton s'appelle « Appeler X » mais copie le numéro sur ordinateur (message affiché seulement après coup) → libellé « Appeler / copier ».
- [Détail] (1) L83-96 : liste étalée sur toute la largeur sur ordinateur, sans recherche ni filtre pour un grand effectif.

### players/presentation/player_card_link.dart
- [Détail] (3) L73-80 : `Semantics(button)` + InkWell fait doublon ; l'URL de la fiche (L6-15) contient le nom complet du joueur (`nom=…`) → donnée personnelle dans l'adresse/historique du navigateur (À vérifier si voulu).

### players/presentation/member_contact_dialog.dart
- [Gênant] (3/4) L91-114 : la zone de la date de naissance est cliquable seulement sur la ligne de texte (InkWell autour d'un `Text`, vide quand aucune date) et l'icône calendrier (L96) n'est pas cliquable alors qu'elle y ressemble → toucher le champ ou l'icône ne fait peut-être rien → englober tout le champ dans l'InkWell et rendre l'icône cliquable.
- [Détail] (4) L33, L85-88 : l'erreur du téléphone reste affichée tant qu'on n'a pas revalidé (jamais effacée à la frappe) ; pas de `textInputAction`.
- [Détail] (4) L81-117 : champs facultatifs non indiqués comme tels.
- [Détail] (1) L77-119 : contenu non défilant ; en paysage ou avec clavier sur petit écran, le bouton « Enregistrer » peut sortir de l'écran.

---------------------------------------------------------------------
# STATISTIQUES
---------------------------------------------------------------------

### statistics/presentation/stats_hub_page.dart
- [Gênant] (2) L372-381 : la carte joueur est un `Container` à fond uni qui contient le `InkWell` → l'effet de toucher est dessiné sous le fond, donc invisible : on ne voit rien quand on touche une carte (À vérifier à l'écran, très probable).
- [Gênant] (1) L428-447 : colonne de valeur à droite de chaque carte, sans largeur imposée : son libellé (« matchs sans encaisser », « passes décisives », « Hommes du match », 11 px) prend ~90-110 px, et ~170 px à 160 % → le nom et le badge n'ont presque plus de place → mettre le libellé sous le chiffre avec `maxLines`/ellipsis ou une largeur max.
- [Gênant] (1) L252-272 : rangée de filtres de tri en défilement horizontal, sans aucun indice qu'il y a d'autres choix à droite (« Homme du match », « Victoires », « Sans encaisser » sont hors écran sur téléphone) ; hauteur fixe 52 px qui rogne les puces à 160 % → ajouter un fondu/flèche et une hauteur souple.
- [Gênant] (2) L217-221 : l'erreur n'offre pas de bouton « Réessayer » (tirer-pour-actualiser seulement).
- [Détail] (4) L107-126 vs player_card_page L148-168 : mêmes périodes nommées « Actuelle / Précédente / Toutes » ici et « Saison / Précédente / Carrière » sur la fiche et le classement → harmoniser.
- [Détail] (3) L366-369 : « HDM », « V · N · D » sans explication, alors que le filtre dit « Homme du match ».
- [Détail] (3) L338-381 : « c'est toi » n'est signalé que par la couleur/bordure.
- [Détail] (2) L129-133 : changer d'onglet détruit l'état du panneau (le tri choisi est remis à « Buts »).

### statistics/presentation/team_statistics_panel.dart
- [Gênant] (3) L561 (`'${margin.abs()}'`), L563-567 : sur le graphique « Écart de score », les victoires et défaites s'écrivent avec le même chiffre (« 2 » pour −2 et +2) ; seule la couleur (rouge/vert) les distingue → illisible pour les daltoniens → écrire « −2 », « 0 », « +2 ».
- [Gênant] (2) L29-83 : aucun état « vide » : en début de saison (0 match) on affiche un anneau vide, des 0, « 0 % », des séries « Aucune série » sans phrase d'explication, alors que le panneau Joueurs en a une → message « Pas encore de match joué cette saison ».
- [Gênant] (2) L31-34, L997-1029 : erreur = simple texte dans une carte, sans titre, icône ni bouton « Réessayer ».
- [Détail] (3) L540-738 : le graphique n'a ni description ni tableau de remplacement pour les lecteurs d'écran ; la légende rouge/jaune/vert est reliée aux barres par la couleur seule.
- [Détail] (1) L650-720 : le graphique défile horizontalement quand il y a beaucoup d'écarts, sans indice.
- [Détail] (1) L285-293 : « 100 % » dans une case de 48 px ; à 160 % de texte il passe probablement à la ligne (À vérifier).
- [Détail] (2) L30 : chargement par roue seule, pas de squelette.
- [Détail] (3) L85-98 : les titres de section ne sont pas déclarés comme titres (`Semantics(header: true)`).
- [Détail] (2) L200-216 : « Derniers matchs » sans dire si le plus récent est à gauche ou à droite.

---------------------------------------------------------------------
# PRONOSTICS
---------------------------------------------------------------------

### predictions/presentation/pronos_hub_page.dart — rien à signaler (lu en entier)
(Bon point : `disableAnimations` respecté L74-75.)

### predictions/presentation/pronos_hub_ranking_sections.dart
- [Gênant] (2) L28-33 : en cas d'erreur, la carte « Classement indisponible » n'est ni défilante ni accompagnée d'un bouton → aucun moyen de réessayer sans quitter l'onglet → ajouter « Réessayer » (`ref.invalidate`).
- [Détail] (2) L22-27 : le chargement avec message est bien soigné (bon point) ; le vide du classement (`_MessageCard` L58 de pronos_hub_components) n'est pas défilant, donc pas d'actualisation.

### predictions/presentation/pronos_hub_components.dart
- [Gênant] (3) L117-126 : l'en-tête de la colonne « nom » est un bouton de tri avec un libellé vide (`label: ''`) → invisible pour tout le monde, annoncé comme un bouton sans nom → libellé « Joueur » ou au moins un Semantics.
- [Détail] (4) L132-163 : en-têtes « Prono », « Bons », « Exacts » sans légende ; « Prono » = nombre de pronostics saisis (ambigu) → infobulle ou ligne de légende.
- [Détail] (3) L262-275 : ligne de l'utilisateur marquée par couleur + liseré, non annoncée.
- [Détail] (1) L104-111 : largeur des noms recalculée par mesure de texte à chaque reconstruction.

### predictions/presentation/pronos_hub_history_section.dart
- [À vérifier] (hors axes — code mort) L8-401 : `_CalendarSection`, `_CalendarMatchCard`, `_AdminMatchActions` ne sont instanciés nulle part (recherche dans tout `lib/`) ; l'écran réel est `merged_matches_view.dart` → à supprimer pour éviter de corriger deux fois. S'il revenait : emoji dans les infobulles et icônes (L101-117, L354-376), couleurs en dur (L206-224), pas de largeur max.

### predictions/presentation/merged_matches_view.dart
- [Gênant] (1/2) L109-116, L89-107 : le « défilement par l'utilisateur » n'est détecté que pour un glissement au doigt (`dragDetails != null`) ; la molette, le clavier (Page↓) ou la barre de défilement ne comptent pas → sur ordinateur, pendant les 5 premières secondes et à chaque arrivée de données (L168-188), la liste est ramenée de force sur le match mis en avant → on se bat contre la page → tester `ScrollStartNotification` sans filtre (ou `UserScrollNotification`).
- [Gênant] (2) L1002-1007 : un match en cours (`liveMatch`) ou terminé en attente de validation (`awaitingValidationMatch`) est rangé sous le titre « À venir » → un match déjà joué est présenté comme futur → section « En cours / À valider » distincte.
- [Gênant] (2) L423-436 : en erreur, message seul, sans bouton « Réessayer » (seul le geste tirer-pour-actualiser, non découvrable à la souris).
- [Détail] (2) L851-856 : avant l'ouverture des disponibilités, la carte à venir n'affiche rien pour dire pourquoi on ne peut pas répondre « Présent/Absent » ni quand ce sera possible (la carte de pronostic, elle, l'explique).
- [Détail] (2) L720-725 : aucun repère visuel du « prochain match » dans la liste (les deux types de carte sont identiques) ; seul le défilement automatique le met en avant.
- [Détail] (4) L991-994 : les séparateurs « Saison 2026-2027 » sont calculés avec une coupure fixe au 1er juillet, pas avec les saisons réellement créées par l'administrateur → décalage possible (À vérifier).
- [Détail] (2) L477-480, L365-368 : la liste est masquée (opacité 0) jusqu'à 3 s pendant le positionnement ; elle reste lisible par les lecteurs d'écran avant d'être « révélée » ; seul un cercle de chargement est visible.
- [Détail] (3) L598-601, L669-713 : titres « Terminés / À venir » non déclarés comme titres ; carte entière en InkWell sans libellé résumé.
- [Détail] (1) L89-107 : une mesure + un nouveau `ensureVisible` à chaque notification de défilement pendant 5 s (charge inutile).

### predictions/presentation/widgets/inline_match_prediction_card.dart
- [Gênant] (2) L67-72 : si le pronostic ne se charge pas, la carte n'affiche qu'un texte, sans bouton « Réessayer », pour l'action centrale de l'application → ajouter le bouton (invalider `inlineMatchPredictionProvider`).
- [Gênant] (4) L83-84, L206-223 : un pronostic jamais saisi s'affiche comme « 0 – 0 » prêt à enregistrer : un seul toucher sur « Enregistrer » valide un nul 0-0 par erreur ; l'état « À saisir » n'est que dans la pastille en haut à droite → afficher « – » tant que rien n'est choisi et griser « Enregistrer ».
- [Gênant] (4) L347-398 : les cinq confrontations précédentes s'affichent sans titre quand elles existent (le seul texte est « Aucune confrontation précédente » en cas de vide) ; chaque case mesure ~49 px pour un score et une date → ajouter « Dernières confrontations », vérifier le texte à 130-160 %.
- [Gênant] (3/4) L160-204 : les cases « 1 · N · 2 » avec cotes ressemblent à des boutons de choix mais ne réagissent pas au toucher (elles reflètent le score saisi) ; « 1/N/2 » non expliqué → présentation « Victoire X / Nul / Victoire Y » ou texte d'aide.
- [Gênant] (2) L228-229 : « Disponible à partir de J−2 à 9 h » : « J−2 » n'est pas compréhensible pour tous et la date réelle n'est pas donnée → « à partir du jeudi 12 à 9 h ».
- [Détail] (3) L431-452 : boutons +/− de 40 × 40 px (< 44) ; la nouvelle valeur n'est pas annoncée (pas de `liveRegion`).
- [Détail] (1) L93-114, L152-158 : à 160 % de texte sur téléphone 320-360 px, deux sélecteurs (2 × ~125 px) + tiret risquent de déborder (À vérifier).
- [Détail] (4) L98-112 : modification non enregistrée perdue si on quitte l'écran, sans avertissement.
- [Détail] (2) L255-259 : `ref.invalidate` est exécuté avant la vérification `mounted` ; si on quitte l'écran pendant l'envoi, utilisation de `ref` après destruction possible.
- [Détail] (3) L476-506 : les cases de cote animent en 150 ms sans respecter « réduire les animations » ; l'état « choisi » repose surtout sur la couleur + l'épaisseur de bordure.
- Bons points : gestion de l'écriture « peut-être réussie » (L265-277), bouton protégé contre le double envoi (L91, L213), explication de la fermeture (L224-239), infobulles par équipe sur +/− (L432, L447).

### predictions/presentation/widgets/match_history_card.dart
- [À vérifier] (3) L38-45 : le résultat (victoire / nul / défaite) est donné par la couleur des scores ; vérifier que `CalendarScoreline` (hors périmètre) ajoute aussi un indice non coloré.

---------------------------------------------------------------------
# FIN DU RAPPORT
---------------------------------------------------------------------

## Fichiers lus en entier (35 / 35)
badges/presentation : armoire_page, badge_admin_page, badge_detail_sheet, badge_image_editor, badge_emblem_body, badge_premium_skins, badge_threshold_editor, badge_text_editor, badge_emblem, name_with_badges, badge_descriptor, badge_trophy_button, locked_badge_emblem, badge_image_delivery, badge_display_scope, badge_image_picker, badge_image_picker_web, badge_image_picker_stub.
players/presentation : player_card_page, player_card_matches, player_card_stats, players_registry_page, player_stat_ranking_page, club_roster_page, player_card_link, member_contact_dialog.
statistics/presentation : stats_hub_page, team_statistics_panel.
predictions/presentation : pronos_hub_page, pronos_hub_ranking_sections, pronos_hub_components, pronos_hub_history_section, merged_matches_view, widgets/inline_match_prediction_card, widgets/match_history_card.

## Fichiers non lus ou lus en partie
Aucun dans la liste. Limites : les widgets partagés appelés mais situés hors du groupe (`CalendarScoreline`, `StickyHeaderTableCard`, `SortableHeaderCell`, `PfEmptyState`, `PfSecondaryTabs`, `MatchResultScoreChip`, `PlayerAvatar`, `AppSpacing`) n'ont pas été lus ; ce qu'ils font (défilement horizontal, rafraîchissement, tailles) est déduit de leur usage. Pas de rendu : toutes les mentions de débordement, de contraste et d'effet de toucher sont des hypothèses à confirmer à l'écran.

## Top 5 des motifs répétés
1. Erreur sans bouton « Réessayer » (seulement tirer-pour-actualiser ou rien) : armoire, fiche joueur, registre, effectif, classement joueur, stats joueurs/équipe, classement pronos, calendrier, carte de pronostic.
2. Textes et zones tactiles trop petits : emblèmes de badge à 4-8 px, puces 30 px, boutons 40 px, textes 11-12 px.
3. Contrôles faits de `GestureDetector`/`InkWell` sans libellé ni focus clavier ; sens porté par la couleur seule (résultats, écarts de score, « nouveau », « verrouillé », ligne de l'utilisateur).
4. Largeurs/textes non élastiques : `Row` sans Flexible (fiche match, légendes, sélecteurs de score), pas de largeur maximale sur ordinateur, défilement horizontal sans indice (filtres de tri, graphiques).
5. Boutons grisés ou validations sans explication, et messages d'erreur d'une boîte/feuille envoyés dans un SnackBar caché derrière elle (seuil, texte, image, « Décerner »).

## Bons points notables
- Tableaux, fiche joueur et statistiques ont bien un squelette de chargement et un état vide (sauf Équipe).
- Pronostic : protection contre le double envoi, cas « écriture peut-être réussie », raison de fermeture expliquée, infobulles précises (inline_match_prediction_card).
- Confirmations soignées et réversibilité bien pensée : attribution de badge (« ne pourra plus lui être retiré »), suppression de joueur avec alternative « Archiver », suppression de liaison (players_registry_page).
- Calendrier : largeur de lecture limitée à 760 px, positionnement sur le bon match, liste lazy.
- `disableAnimations` respecté dans le hub pronostics ; format de date français (jj/mm/aaaa, virgule décimale) ; `Semantics` bien utilisés sur les cases de statistiques et les barres de saison.
