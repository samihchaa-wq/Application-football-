# Audit UX/UI : lib/features/sports_management/presentation/ (lecture seule)

Périmètre : les 33 fichiers .dart de presentation/ et widgets/, tous lus en entier.
Jugement par le code, sans appareil. Tout ce qui demande un rendu réel est marqué « À vérifier ».
Les points déjà connus (bandeau notifications, `'$error'` brut, `loading: SizedBox.shrink()` en général, largeurs fixes citées, `MediaQuery.of`) ne sont pas répétés, sauf quand un nouvel écran est touché.

Vérifications faites par recherche dans le code, pour étayer des constats :
- `_showPlayerInfo` (fiche joueur de l'effectif) n'est jamais déclenchée par un geste.
- Aucun `PopScope` / `WillPopScope` dans tout `sports_management/`.
- Aucun contrôle du mouvement réduit (`disableAnimations`) dans tout `sports_management/`.
- `AppFormats.dateTime` convertit bien en heure locale.

---

### lib/features/sports_management/presentation/admin_guests_page.dart
- [Gênant] (axe 2) L299-310 : `_pickGuestPhoto` fait `await pickImage` puis `await readAsBytes()` puis `setState` sans test `mounted`, et hors du `try` → si on quitte l'écran pendant le choix de photo, plantage ; si la lecture du fichier échoue, rien n'est affiché → l'admin ne sait pas pourquoi la photo n'a pas changé → mettre le choix de fichier dans le `try` et tester `mounted` avant `setState`.
- [Gênant] (axe 4) L495-505 : l'interrupteur s'appelle « Catalogue réutilisable » mais il sert à afficher ou masquer les invités archivés (`_showArchived`) → l'admin ne comprend pas ce qu'il active → renommer « Afficher les invités archivés ».
- [Gênant] (axe 1) L388-402 : `DropdownButtonFormField` sans `isExpanded` et item `Text('${adversaire} · date')` sans ellipsis → un nom d'adversaire long déborde de la ligne (bande jaune et noire) surtout à texte agrandi → ajouter `isExpanded: true` et `overflow: ellipsis`.
- [Gênant] (axe 4) L120-202 : les contrôleurs du dialogue sont détruits (`dispose`, L200-201) juste après le retour de `showDialog`, alors que le dialogue joue encore son animation de fermeture → risque d'erreur « contrôleur utilisé après destruction » → À vérifier ; correction : les créer dans un widget de dialogue qui les détruit lui-même. Même motif dans admin_squad_plan_page_effectif.dart L560-561.
- [Détail] (axe 4) L133-143 : champ « Prénom » sans `textInputAction` ni `onSubmitted` : Entrée ne valide pas, il faut aller toucher le bouton. L180-183 : l'erreur « Le prénom est obligatoire. » ne disparaît pas quand on tape. `maxLength: 80` affiche un compteur « 0/80 » inutile.
- [Détail] (axe 2) L418 : quand une erreur survient alors que des matchs sont déjà chargés (échec de `_loadData`), seul un `Text(_error)` brut apparaît, sans bouton « Réessayer » (le bouton n'existe que si la liste de matchs est vide, L363-372) → ajouter « Réessayer ».
- [Détail] (axe 2) L373-375 : « Aucun match à venir. » en texte nu, sans consigne ni lien vers la création d'un match.
- [Détail] (axe 2) L507-511 : « Le catalogue est vide. » est affiché aussi quand il n'y a que des invités archivés et que le filtre les cache → distinguer « rien encore » de « rien ne correspond au filtre » (« Aucun invité actif. Afficher les archivés ? »).
- [Détail] (axe 3) L531-562 : trois `IconButton` côte à côte en `trailing` d'un `ListTile` (≈ 150 px) → à 320 px de large ou texte agrandi le nom de l'invité est écrasé sur 1 caractère ou déborde → À vérifier.
- [Détail] (axe 4) L593-599 : `_formatDate` fabrique « 12/07 21:00 » (sans année, avec « : ») alors que l'app utilise `AppFormats` (« 12/07/26 • 21h00 ») → format incohérent.
- [Détail] (axe 3) L449 (via `PlayerAvatar`, composition_pitch.dart) : l'avatar n'a pas d'étiquette pour les lecteurs d'écran, donc initiales + nom sont lus deux fois.
- Bon point : confirmation de retrait claire (L231-253, retour `null` géré), drapeau `_busy` contre le double envoi, retours par message à chaque action.

### lib/features/sports_management/presentation/admin_squad_plan_effectif_roster.dart
- [Gênant] (axe 3) L107-124 et L209-215 : déplacer un joueur n'est possible que par appui long + glisser, ou « toucher le joueur puis toucher la colonne » via un `GestureDetector` (non focalisable au clavier, sans rôle bouton) → impossible au clavier ou au lecteur d'écran ; le geste de sélection n'est pas non plus expliqué à l'écran → utiliser un menu « Déplacer vers… » sur chaque joueur (accessible) et une phrase d'aide.
- [Gênant] (axe 2) L132-239 + admin_squad_plan_page_effectif.dart L414 : la fiche joueur (date de réponse, rang en liste d'attente, nombre de tours) n'est jamais ouverte : `onShowInfo` sert seulement à écrire un indice vocal (L213), aucun geste n'appelle `_showPlayerInfo`. La fonction existe mais est inaccessible → l'admin ne voit jamais ces informations → brancher un appui long ou un bouton « i » sur la tuile.
- [Gênant] (axe 3) L282-313 : cloche « Relancer » = `InkResponse` rayon 15, padding 2, icône 14 px → zone de toucher ≈ 18-34 px, imbriquée dans la tuile cliquable (risque de sélectionner au lieu de relancer) ; le compteur « 3 » à côté n'a de sens que par infobulle (inexistante au toucher) → zone ≥ 44 px et libellé visible « Relancé 3 fois » dans la fiche.
- [Gênant] (axe 1) L79-93 : en-tête de colonne = titre + bouton « Relancer tous » dans la même ligne ; à texte agrandi (voir effectif_avatar_grid.dart) le titre « Sans réponse (18) » est tronqué par `ellipsis` et le nombre, placé à la fin, disparaît → mettre le bouton sous le titre quand la place manque.
- [Détail] (axe 3) L185-193 et L276-280 : toucher n'importe où sur la tuile d'un invité ouvre la suppression ; seul un « x » de 13 px, en couleur, l'annonce ; l'indice vocal « Touche pour sélectionner le joueur » (L213) est faux pour un invité.
- [Détail] (axe 3) L151-157 : l'état de disponibilité (présent/absent/sans réponse) est porté par la couleur du prénom (vert/rouge/gris) dans la colonne « Convoqués » ; seul le contexte de colonne le dit pour les autres → ajouter une icône ou un libellé ; contraste du gris `availabilityUnknown` sur fond teinté : À vérifier.
- [Détail] (axe 3) L87-92 : bouton « Relancer tous » `minimumSize` hauteur 34 (< 44).

### lib/features/sports_management/presentation/admin_squad_plan_page.dart — rien à signaler (lu en entier)
Fichier de déclarations (imports, enum, constructeur de page) ; les constats de l'écran sont dans ses fichiers « part ».

### lib/features/sports_management/presentation/admin_squad_plan_page_state.dart
- [Bloquant] (axe 2) L156-161 puis L419-428 : si le chargement de la liste des matchs échoue (réseau coupé), `_error` est renseigné, `_matches` reste vide, et l'écran affiche « Aucun match disponible : crée un match depuis l'onglet Matchs » → l'admin croit qu'il n'a plus de match, alors que c'est une panne de réseau, et aucun « Réessayer » n'est proposé → traiter `_error` avant `_matches.isEmpty` avec message humain + bouton.
- [Gênant] (axe 2) L528-531 et L546-552 : si `_loadWorkspace` échoue, on voit seulement un `Text(_error)` brut sous les onglets, aucun bouton « Réessayer », et la zone d'onglet reste vide (aucune carte tant que `_convocations`/`_composition` sont nuls) → écran vide sans issue, sauf tirer pour rafraîchir (non évident) → carte d'erreur avec « Réessayer ».
- [Gênant] (axe 4) L297-306 : changer d'onglet relance un chargement complet (6 appels réseau, L174-219) sans vérifier qu'une décision d'effectif est encore en attente d'écriture (timer de 700 ms, contrairement à `_reloadAfterSportsSignal` L378-385 qui le vérifie). Une décision prise moins d'une seconde avant le changement d'onglet (ou le tirer-pour-rafraîchir L473) est écrasée par la réponse du serveur → décision perdue sans message → tester `_effectifAutosave?.isActive` ou vider l'écriture avant de recharger.
- [Gênant] (axe 2) L98 et L707 : pendant tout chargement (`_busy`, y compris les rechargements automatiques sur signal sportif ou changement d'onglet), un geste de l'admin est ignoré en silence (retour immédiat) et les onglets sont grisés (L522) → l'admin glisse un joueur et il ne se passe rien, sans explication → afficher « Mise à jour en cours… » ou mettre le geste en file.
- [Gênant] (axe 1) L492-523 : jusqu'à 5 segments (Info, Effectif, Compo, Live, Prono) dans un `SegmentedButton` sans repli ; à 320 px ou texte à 160 % les libellés se coupent ou débordent → À vérifier ; prévoir défilement horizontal ou onglets défilants.
- [Détail] (axe 3) L397-417 : pas de barre de titre ; la page n'a aucun titre pour les lecteurs d'écran (seulement une flèche retour dans `MatchSheetTopRow`).
- [Détail] (axe 2) L418 : chargement correct (flèche retour conservée), mais spinner sans texte ; chargement des onglets (L546) sans squelette.
- Bon point : confirmation avant les gestes qui préviennent un joueur (L104-122, retour `null` géré), autosave protégé contre les écritures concurrentes, `mounted` testé après chaque `await`.

### lib/features/sports_management/presentation/admin_squad_plan_page_effectif.dart
- [Gênant] (axe 4) L519-523 et L545-549 : dans « Ajouter un invité », un prénom vide fait un `return` silencieux : le bouton ne réagit pas et aucun message n'apparaît. Le dialogue équivalent de la page Invités affiche « Le prénom est obligatoire. » (et son commentaire dit que celui-ci le fait déjà) → recopier le message d'erreur. Pas de majuscule automatique ni de `textInputAction` non plus.
- [Gênant] (axe 4) L630-654 : le champ « Convoqués » est la limite d'effectif ; un `onChanged` programme l'enregistrement 0,7 s plus tard. Pour passer de 14 à 12, l'admin efface puis tape « 1 » : « 1 » est valide (1-30) donc la limite 1 part au serveur, qui décide des convocations automatiques, avant que « 12 » soit tapé → valeurs intermédiaires enregistrées → n'enregistrer qu'à la fin de saisie (focus perdu / `onSubmitted`). Pas de `inputFormatters` (chiffres seulement) et pavé numérique iOS sans touche « OK » : pas de `textInputAction`.
- [Gênant] (axe 4) L630-654 et board card L143 : le même nombre s'appelle « Convoqués » (admin, juste au-dessus d'une colonne « Convoqués (n) ») et « Limite indicative » (joueur) → ambigu → « Limite de convoqués ».
- [Gênant] (axe 2) L756-761 : aucun enregistrement manuel, seule la mention « Enregistrement… » apparaît le temps de l'envoi, sans confirmation de réussite ; le message « Effectif verrouillé au coup d'envoi. » est tout en bas, sous les quatre colonnes. Un geste refusé car verrouillé (L98) ne dit rien → l'admin ne sait pas si c'est enregistré ni pourquoi ça ne bouge pas → bandeau en haut quand verrouillé, et « Enregistré à HH h MM ».
- [Gênant] (axe 1) L793-800 : les trois boutons compacts sont dans `FittedBox(scaleDown)` à 1/3 de largeur ; avec « Ajouter un invité » ou « Liste d'attente » à texte agrandi, le texte est réduit sous 12 px, ce qui annule l'agrandissement → À vérifier ; empiler les boutons (une colonne) au-delà de 1,2 d'échelle de texte.
- [Détail] (axe 1) L652 : `Colors.orange` en dur pour l'avertissement de dépassement (couleur seule + orange sur clair : contraste À vérifier).
- [Détail] (axe 2) L563-577 : l'ajout d'un invité recharge tout l'écran sans message de succès (la page Invités en affiche un).
- [Détail] (axe 3) L352 : `'Relancer ${player.displayName} ?'` avec une espace normale avant « ? » (le reste de l'app utilise l'espace insécable ` `) → le « ? » peut passer seul à la ligne.
- [Détail] (axe 2) L404-411 : le message de relance concatène jusqu'à trois phrases dans une alerte de 4 s : trop long pour être lu à temps ; à garder dans un dialogue ou durée plus longue.
- [Détail] (axe 2) L723-745 : déposer sur « Sans réponse » un joueur qui a répondu est refusé sans indication (`acceptsPlayer`) ; idem sur les autres colonnes pour les invités.
- Bon point : confirmations placées sur les seuls gestes irréversibles (notification, « noter absent »), explications honnêtes du risque (« Elle ne peut pas être rattrapée »), anti-double envoi (`_busy`, `_effectifSaving`).

### lib/features/sports_management/presentation/admin_squad_plan_page_composition.dart
- [Gênant] (axe 2) L469-470 : `allowException = selectedCount > limit` : si la sélection dépasse la limite d'effectif, la publication passe en forçant l'exception sans le dire, alors qu'aucun avertissement de dépassement n'est affiché sur l'onglet Compo (il n'existe que sur Effectif) → l'admin dépasse la limite sans l'avoir décidé → afficher « 16 joueurs pour une limite de 14, publier quand même ? ».
- [Gênant] (axe 4) L915-920 vs L444-459 : le bouton s'appelle « Enregistrer » alors que la première fois il publie et notifie tous les convoqués (le dialogue le dit seulement après le toucher) ; les fois suivantes il republie sans prévenir personne ni le dire → « Publier la composition » (première fois), « Mettre à jour la composition publiée » ensuite. Après publication, le message est « Composition enregistrée. » (L510) au lieu de « Composition publiée, joueurs prévenus ».
- [Gênant] (axe 2) L654-690 : « Aperçu » ne bloque pas le double appui et attend `upcomingMatchFixtureProvider.future` et le maillot du match sans délai maximal ni indicateur (le côté joueur a 4 s de limite, `player_composition_video.dart`) → rien à l'écran pendant l'attente et deux vidéos qui s'empilent si on retouche → drapeau « en cours » + délai.
- [Gênant] (axe 1) L806-826 : `SizedBox(height: 56)` autour de « Simuler une composition » (2 lignes max, moitié de largeur ≈ 150 px) : à texte agrandi, 3 lignes tiennent plus de 56 px → texte coupé → hauteur libre (`minimumSize`).
- [Gênant] (axe 4) L424-432 + absence de `PopScope` : les modifications de la composition (`_compositionDirty`) sont perdues si l'admin quitte la page avec la flèche retour, sans « Quitter sans enregistrer ? » → ajouter la confirmation.
- [Détail] (axe 4) L917-919 : « Enregistrer » est grisé tant que rien n'a bougé, sans raison affichée.
- [Détail] (axe 2) L589-600 et L901-911 : « Aperçu de la vidéo » grisé si le terrain est vide ou la fonction désactivée, sans le dire.
- [Détail] (axe 4) L833-848 : aucune consigne pour déplacer les joueurs (appui long pour glisser, ou toucher un poste puis un joueur) ; aucun bouton « Annuler mes changements » après une simulation.
- [Détail] (axe 3) L616-650 : la vidéo se lance automatiquement à la première visite (admin non auteur) sans geste, et sans respect du mouvement réduit (voir composition_presentation.dart).
- Bon point : confirmation de la simulation seulement si des joueurs sont déjà placés (L347-358), publication confirmée avant l'envoi de notification, `mounted` testé partout.

### lib/features/sports_management/presentation/admin_squad_plan_page_widgets.dart
- [Détail] (axe 3) L129-146 : tuile de banc = `GestureDetector` (via `CompositionPlayerTile`) sans rôle bouton ni accès clavier ; glisser par appui long uniquement. Même motif que composition_pitch.dart.
- Reste du fichier (sélection partagée, ligne d'info, menu de dispositif avec `isExpanded`, classe `_GuestInput`) : rien à signaler.

### lib/features/sports_management/presentation/admin_waitlist_page.dart
- [Gênant] (axe 3) L493-498 : les boutons « + » et « − » ont pour infobulle « Ajouter » / « Retirer » sans le nom du joueur : sur 20 lignes, le lecteur d'écran lit vingt fois « Ajouter » ; zone 34 × 44 px (largeur < 44) → « Ajouter un tour à Paul », largeur 44.
- [Détail] (axe 2) L197-198 : l'écran sert aussi aux joueurs en lecture seule (`editable: false`) mais le message vide dit « Ajoute des joueurs à l'effectif… » → adapter selon le rôle.
- [Détail] (axe 4) L292-298 et L402 : en-têtes « Saison précédente » / « Tour cette saison » et chiffres nus : on ne comprend pas que le premier nombre est un nombre de présences (« 12 » sur combien ?) → « Présences » ou « 12 / 20 ».
- [Détail] (axe 1) L364-373 : prénom en `maxLines: 1` + `ellipsis` dans une colonne figée de 112-150 px ; à texte agrandi les noms sont coupés sans moyen de les lire (pas d'infobulle ni de fiche).
- [Détail] (axe 2) L176-189 : message d'erreur en texte nu (pas d'icône) avec « Réessayer » : correct mais discret.
- [Détail] (axe 2) L161 : pendant un envoi, tous les boutons +/− de toutes les lignes se grisent en silence.
- Bon point : gestion très soignée des envois incertains (identifiant de requête, `timeout`, nouvel essai identique, message « La modification n'est pas encore confirmée »), `LayoutBuilder` plutôt que largeur fixe, titre de page.

### lib/features/sports_management/presentation/match_availability_provider.dart — rien à signaler (lu en entier)
Fournisseur de données, aucune interface.

### lib/features/sports_management/presentation/match_lineup_page.dart
- [Gênant] (axe 2) L38 : `matchInfo` est lu avec `.valueOrNull` : pendant le chargement ou en cas d'échec il vaut `null`, et la page se construit alors comme un match ordinaire (`isInternal` = faux, `kickoffAt` nul) : les onglets Live / Prono peuvent apparaître puis disparaître (match entre nous), et une panne réseau n'est jamais signalée → À vérifier ; gérer `loading` / `error` du fournisseur.
- [Gênant] (axe 2) L197-211 + match_availability_board_card.dart L36, L55-58 : l'onglet « Effectif » peut être entièrement vide (chargement ou effectif pas encore visible) avec seulement le lien « Voir la liste d'attente » sous un espace vide → expliquer « L'effectif sera visible à partir du … ».
- [Gênant] (axe 2) L119-137 : `RefreshIndicator` attend `Future.wait` de `.future` sans `try` ; hors ligne, ces futures échouent, l'exception remonte sans message et le geste « tirer pour rafraîchir » finit sans explication → attraper l'erreur et afficher « Impossible d'actualiser ».
- [Gênant] (axe 2) L380-382 et L513-534 : erreur de composition = icône + « momentanément indisponible » sans bouton « Réessayer ».
- [Détail] (axe 1) L158-194 : même `SegmentedButton` à 5 segments que côté admin (voir plus haut).
- [Détail] (axe 2) L262 : redirection vers le calendrier d'un match annulé avec un `Scaffold()` vide pendant un instant (flash blanc).
- [Détail] (axe 2) L329 : `SingleChildScrollView` inutile dans `PublishedLineupCard` (défilement imbriqué possible si la carte est dans une page qui défile) → À vérifier.
- [Détail] (axe 3) L471-475 : le titre « Voir les listes » en `TextStyle` sans taille → suit le thème ; rien à faire.
- Bon point : sections non autorisées redirigées vers l'onglet valable (L98-104), message de composition non publiée (L395), indicateur « Voir les listes » replié.

### lib/features/sports_management/presentation/match_report_page.dart
- [Gênant] (axe 2) L470-473 : après une connexion interrompue, le message dit « Actualise la page avant de revalider », mais cet écran n'a ni bouton d'actualisation ni tirer-pour-rafraîchir (`_load` n'est appelé qu'à l'ouverture et sur « Réessayer ») → l'admin doit recharger tout le navigateur → ajouter un bouton « Recharger le compte rendu ».
- [Gênant] (axe 4) L380-384 : un problème de validation (score ≠ buts, buteur absent de l'effectif, plus de 11 titulaires) n'apparaît que dans un message passager de 4 s, sans amener sur l'onglet ni le but concerné (l'erreur peut concerner l'autre onglet) → pastille sur l'onglet fautif et message persistant au-dessus du bouton.
- [Gênant] (axe 1) L569-644 : en-tête fixe (carte de score ≈ 150 px, onglets, bandeau) + bouton du bas hors zone défilante : avec le clavier ouvert (champ « Min » dans l'onglet Faits), l'espace restant pour la liste est très réduit sur petit téléphone → À vérifier ; passer l'en-tête dans la zone défilante.
- [Détail] (axe 2) L567 : `report == null || lineup == null` → `SizedBox.shrink()` : écran blanc sans message si l'effectif manque (alors que `_squadIssue` prévoit « Effectif indisponible »).
- [Détail] (axe 4) L290-297 : dans la boîte « Quels buts supprimer ? », quand le bon nombre est coché, cocher une autre case est ignoré sans retour → décocher d'abord ; à dire.
- [Détail] (axe 1) L823-831 : score en `SizedBox(width: 40)` : un score à deux chiffres à texte agrandi ne tient pas (≥ 10).
- [Détail] (axe 3) L823-831 : le changement de score n'est pas annoncé aux lecteurs d'écran (pas de `liveRegion`).
- [Détail] (axe 3) L714-741 : « fenêtre de correction fermée » est peint en rouge d'erreur (`errorContainer`) alors que c'est une information, pas une erreur.
- [Détail] (axe 3) L945-949 : titres de section en `labelSmall` (≈ 11 px) en majuscules espacées.
- [Détail] (axe 2) L588 etc. : « tout reste local jusqu'au bouton du bas » n'est dit qu'en embarqué (L577-588, bandeau) ; hors Live, aucun rappel que quitter l'écran perd les changements, et pas de `PopScope`.
- Bon point : confirmation avant validation avec résumé du score (L387-435, retour `null` géré), cas « envoi incertain » traité sans double validation (L461-474), infobulles nommées sur les boutons +/- (L816-821), scores bornés, `mounted` testé.

### lib/features/sports_management/presentation/sport_motm_vote_page.dart
- [Gênant] (axe 2) L108-118 : en cas d'échec de chargement du scrutin, une carte avec le message seul, sans « Réessayer » (il faut deviner le tirer-pour-rafraîchir) → bouton.
- [Gênant] (axe 3) L187-211 : la sélection d'un candidat est une liste de `ListTile` avec icône coche / rond ; aucun `Semantics(selected / inMutuallyExclusiveGroup)` ni `RadioListTile` → le lecteur d'écran ne dit jamais quel joueur est choisi → utiliser `RadioListTile`.
- [Gênant] (axe 2) L96-100 : tirer pour rafraîchir attend `.future` d'un fournisseur qui peut échouer : erreur non gérée, sans message (même motif que match_lineup_page.dart).
- [Détail] (axe 2) L243-249 : l'échec d'envoi du vote s'affiche en texte rouge tout en bas de la liste, sans icône ; le vote étant définitif, un snackbar ou une carte juste sous le bouton serait plus sûr.
- [Détail] (axe 3) L364 et L417 : la couronne est un emoji texte « 👑 » (42 px) sans étiquette ; sur le web hors ligne la police d'emoji peut manquer → À vérifier ; décoratif → `ExcludeSemantics`.
- [Détail] (axe 3) L528-533 : compteur en `Colors.white` en dur, 13 px.
- [Détail] (axe 2) L270-278 : erreur de la carte « Homme du match » sans « Réessayer » (loading `SizedBox.shrink`, déjà connu).
- Bon point : confirmation explicite d'un vote définitif et secret avec retour `null` géré (L42-62), drapeau `_isSubmitting`, messages clairs pour chaque état (déjà voté, consultation, annulé, bientôt ouvert), `toLocal()` sur les dates.

### lib/features/sports_management/presentation/widgets/composition_kit_scope.dart — rien à signaler (lu en entier)
Pendant le chargement du maillot les avatars restent neutres, puis changent d'aspect à l'arrivée du maillot : possible clignotement → À vérifier.

### lib/features/sports_management/presentation/widgets/composition_pitch.dart
- [Gênant] (axe 3) L497-499 : `CompositionPlayerTile` = `GestureDetector` sans rôle bouton ni accès clavier ; il sert au banc (placement par toucher) et au terrain → impossible au clavier ; les pastilles de buts / passes / homme du match (L519-545) ne sont lues par aucun lecteur d'écran → ajouter `Semantics(label: 'Paul, 2 buts, 1 passe')`.
- [Gênant] (axe 1) L209-262 : `CompositionPitchWithBench` réduit tout le bloc (banc + terrain de 340 px de large) par `FittedBox(scaleDown)` : avec un banc de 3 colonnes (538 px de gabarit) sur un écran de 360 px, le facteur est ≈ 0,65 → prénoms de 11 px ramenés à ≈ 7 px (`PitchPlayerName` se réduit encore) → illisible à texte agrandi → À vérifier ; limiter à 2 colonnes sur petit écran ou passer le banc sous le terrain.
- [Détail] (axe 3) L633, L674, L731 : chiffres des pastilles en 11 px ; initiales d'avatar à 0,32 × taille (≈ 9 px pour 30 px, L891).
- [Détail] (axe 3) L902-944 : `Image.network` sans `semanticLabel` ni `excludeFromSemantics` : « image » annoncée à chaque joueur.
- [Détail] (axe 3) L135-147 : glisser = appui long (500 ms) ; sur ordinateur à la souris, cela demande de maintenir le clic.
- Bon point : photo de repli sur initiales, une seule nouvelle tentative après erreur de signature, vignettes de joueurs inconnus clairement marquées (L560-598, étiquette vocale).

### lib/features/sports_management/presentation/widgets/composition_presentation.dart
- [Gênant] (axe 3) L377-379 : la vidéo joue « à demi-vitesse » (temps divisé par 2) et se lance sans geste à l'ouverture depuis la notification ou à la première visite ; aucun contrôle du mouvement réduit (`disableAnimations`) dans tout le dossier → durée longue et mouvements de caméra imposés ; seul « Passer » (L681) atténue → respecter `MediaQuery.disableAnimationsOf` (pas de vidéo automatique) et vérifier la durée réelle à l'écran.
- [Gênant] (axe 3) L681-686 + elements L49-70 : boutons « Passer » / « Fermer » : `InkWell` avec 14 × 8 px de marge et texte 13 px → zone ≈ 32 px de haut (< 44) et fond translucide sur une vidéo claire → contraste À vérifier.
- [Détail] (axe 3) L706-731 : un `GestureDetector` sans rôle, sur un texte de 11 px (`textFaint`), ouvre un dialogue technique « Vidéo du stade » (utile à l'admin pour le support, mais invisible comme action) ; messages techniques (« erreur 4 », « repeinte impossible ») vus par l'admin.
- [Détail] (axe 3) L456 : `BlockSemantics` rend la vidéo muette pour les lecteurs d'écran (les contrôles restent) : acceptable, la page dessous porte l'information ; à garder.
- [Détail] (axe 1) L290-295 : attente de 6 s maximum avant de lancer la vidéo avec ce qui est prêt (bonne protection) ; indicateur « Préparation de la vidéo… » présent.
- Bon point : bouton « Fermer » dispo dès le chargement, préchargement des photos avec délai, repli sur l'image fixe, vidéo rejouable (« Revoir »), arrêt propre des minuteries.

### lib/features/sports_management/presentation/widgets/composition_presentation_camera.dart — rien à signaler (lu en entier)
Calculs de caméra uniquement.

### lib/features/sports_management/presentation/widgets/composition_presentation_elements.dart
- [Gênant] (axe 3) L49-70 : `_PillButton` : zone ≈ 32 px de haut, texte 13 px (voir ci-dessus).
- [Détail] (axe 3) L413-420 : puce d'accent en 12 px (Oswald) ; L363-396 nom d'équipe 32 px réduit par `FittedBox` : correct.
- Reste (peinture, silhouette, courbes) : rien à signaler.

### lib/features/sports_management/presentation/widgets/composition_presentation_stage.dart
- [Détail] (axe 3) L402 : « LE ONZE DE DÉPART » en 10 px, L576 libellés du banc en 11 px, L289 et L363 en 12 px avec grand espacement ; le texte de la scène est mis à l'échelle de l'écran (≈ 0,8 sur petit téléphone) : ≈ 8-10 px réels, mais l'animation est brève → À vérifier.
- [Détail] (axe 1) L626-721 : à chaque image, ≈ 22 vignettes `PlayerAvatar` + `Opacity` + `Transform` sont reconstruites (`ValueListenableBuilder` sur le temps) : risque de saccades sur téléphone ancien → À vérifier en mode profil.
- [Détail] (axe 3) L249-255 : date « Sam. 12 nov. » écrite à la main (jour local mais jour de semaine via `AppFormats`) ; cohérence À vérifier.
- Bon point : scène calée sur l'écran réel, repli propre si le terrain n'est pas mesuré.

### lib/features/sports_management/presentation/widgets/effectif_avatar_grid.dart
- [Gênant] (axe 1) L102-125 et L190-202 : grille figée à 3 joueurs par ligne (`columns = 3`) ; chaque tuile fait ≈ 100 px sur téléphone, avec avatar de 30 px, il reste ≈ 55 px pour le prénom à 12,5 px, `maxLines: 1` + `ellipsis` → à 160 % le prénom devient « Ma… » ; aucune autre façon de lire le prénom complet → passer à 2 colonnes (ou 1) quand le texte est agrandi (`textScaler`).
- [Gênant] (axe 1) L59-74 : titre de colonne « Titre (nombre) » tronqué par `ellipsis` : le nombre, en fin de chaîne, disparaît en premier.
- [Détail] (axe 3) L169 : zone cliquable de la tuile minimale 39 px (< 44).
- [Détail] (axe 3) L206-210 : l'information « Coach : hors quota, hors composition » n'existe qu'en infobulle (non disponible au toucher) sur une icône de 14 px.
- [Détail] (axe 1) L234-262 : un seul seuil à 900 px ; entre 600 et 899 px (tablette portrait) une seule colonne pleine largeur, trois joueurs par ligne très espacés → À vérifier (seuil 600).
- Bon point : même composant utilisé pour l'admin et pour les joueurs, le même ordre et les mêmes couleurs ; `LayoutBuilder` par contraintes.

### lib/features/sports_management/presentation/widgets/football_pitch.dart
- [Détail] (axe 3) L227 : taille de prénom par défaut 11 px, réduit par `FittedBox` (L252) si le nom est long : peut descendre sous 8 px.
- Reste (peinture du terrain, ombrage, tracés) : rien à signaler ; peinture vectorielle, bon pour le poids de l'app.

### lib/features/sports_management/presentation/widgets/formation_pitch_editor.dart
- [Gênant] (axe 3) L504-506, L556-557 : sur téléphone, dans le compte rendu et le Live, le terrain est réduit pour laisser la place au banc : largeur de pitch ≈ 260 px → marqueurs ≈ 47 px, avatar et emplacement vide ≈ 38 px, donc cible de toucher < 44 px pour poser un joueur (le geste principal) → À vérifier ; agrandir la zone sensible (padding transparent).
- [Gênant] (axe 3) L552-600 : poste vide = `InkWell` avec icône + « ATT » ; aucun `Semantics` (poste vide, toucher pour sélectionner) ; aucun libellé de poste pour un joueur placé → le lecteur d'écran ne sait pas où l'on place qui.
- [Détail] (axe 1) L679-692 : l'étiquette du prénom (jusqu'à 1,6 × la largeur du marqueur) déborde de chaque côté, et le terrain est rogné (`ClipRRect`) : pour un ailier au bord (x ≈ 0,08) un prénom long est coupé à gauche ou à droite → À vérifier (le mode prénoms seuls corrige déjà ce cas, L765-769).
- [Détail] (axe 4) L701-713 : glisser exige un appui long ; pour la souris cela surprend ; la méthode « toucher puis toucher » n'est expliquée nulle part (aucune consigne écrite).
- [Détail] (axe 3) L176-177 : taille de prénom entre 10,5 et 12,5 px.
- Bon point : double méthode (glisser ou toucher/toucher), sélection signalée par bordure + icône (pas seulement la couleur), défilement automatique pendant le glisser.

### lib/features/sports_management/presentation/widgets/internal_team_composition_view.dart
- [Gênant] (axe 4) L683-824 combiné à admin_squad_plan_page_state.dart L539-545 : la vue « match entre nous » est retirée de l'arbre quand l'admin change d'onglet (Info, Effectif…) : son état `_entries`, `_dirty` et les noms d'équipe saisis sont perdus sans avertissement, alors que la composition normale, elle, garde ses modifications dans l'écran parent → « Quitter sans enregistrer ? » ou état conservé.
- [Gênant] (axe 2) L589-590 : `_entries ??= …` n'est rempli qu'une fois ; si la composition est ensuite publiée ou modifiée (rafraîchissement, autre admin), la vue affichée par un joueur ou par l'admin garde l'ancienne liste jusqu'à recréation de l'écran → À vérifier.
- [Gênant] (axe 2) L574-579 : erreur « Composition indisponible. » sans icône ni « Réessayer ».
- [Gênant] (axe 4) L708-824 : aucune consigne pour affecter un joueur à une équipe : il faut toucher le joueur puis toucher le maillot de l'équipe (ou le bloc « Non affectés ») ; rien ne l'écrit à l'écran → ajouter une phrase d'aide au-dessus de « Non affectés ».
- [Détail] (axe 4) L808-822 : en mode « Sur papier » le bouton « Enregistrer la composition » enregistre un brouillon ; en mode « Sur terrain » il met en ligne et notifie (confirmation) : même libellé pour deux effets.
- [Détail] (axe 1) L748-775 : libellés d'équipe (jusqu'à 40 caractères) dans un `SegmentedButton` à deux segments : débordement possible → À vérifier.
- [Détail] (axe 4) L792-800 : message de validation de 12 px en rouge, seulement en mode terrain ; le bouton grisé en mode papier n'a pas besoin d'explication.
- Bon point : confirmation avant mise en ligne et avant réinitialisation (retours `null` gérés), indicateur dans le bouton pendant l'envoi, message « pas encore en ligne » pour les compositions héritées.

### lib/features/sports_management/presentation/widgets/internal_team_composition_widgets.dart
- [Gênant] (axe 1) L827-840 : `_PlayerChip` = `Row(mainAxisSize.min)` avec `Text(entry.displayName)` sans `Flexible` ni `ellipsis`, placé dans une colonne d'équipe d'environ 130 px (deux colonnes `Expanded`, L45-88) : un nom comme « Jean-Baptiste » ou un texte agrandi provoque un débordement (bande jaune et noire) → `Flexible` + `ellipsis`.
- [Gênant] (axe 3) L761-795 et L708-712 : affectation par `GestureDetector` (zone « Non affectés », zones de maillot) non focalisable, sans rôle bouton ; seul le maillot a un `Semantics(button)`.
- [Détail] (axe 3) L812-851 : l'`InkWell` du joueur est recouvert par le fond de l'`AnimatedContainer` : aucun effet visuel au toucher hormis le cadre de sélection.
- [Détail] (axe 4) L425-434 : champ « Équipe n » du terrain sans `textInputAction` (celui de la vue papier en a un).
- [Détail] (axe 1) L239 : hauteur fixe de 96 px pour la tuile de maillot ; le texte (compteur « n joueurs », 11 px) est en superposition, OK à texte agrandi, mais À vérifier.
- Bon point : libellés vocaux de maillot ET d'équipe, comptage de joueurs en toutes lettres, champs de nom limités à 40 caractères.

### lib/features/sports_management/presentation/widgets/match_availability_board_card.dart
- [Gênant] (axe 2) L37-52 : erreur « Effectif momentanément indisponible » sans « Réessayer ».
- [Gênant] (axe 2) L55-58 : un effectif non visible (pas encore ouvert) rend `SizedBox.shrink()` : aucun message « visible à partir de… » (voir match_lineup_page.dart).
- [Détail] (axe 3) L130-137 : avertissement de dépassement = icône orange + infobulle (indisponible au toucher), sans texte à côté ; `Colors.orange` en dur.
- [Détail] (axe 2) L33-34 : tant que `matchInfo` charge, `isInternal` vaut faux : « Liste d'attente » et « Limite indicative » apparaissent un instant pour un match entre nous.
- [Détail] (axe 3) L228-240 : bonne étiquette vocale par joueur, mais l'état (convoqué, absent, sans réponse) n'est donné que par le titre de colonne.

### lib/features/sports_management/presentation/widgets/match_availability_selector.dart
- [Gênant] (axe 2) L94-96 : si `canRespond` est faux (réponses closes, pas éligible), le bloc disparaît entièrement : le joueur ne voit ni sa réponse enregistrée ni la raison pour laquelle il ne peut plus répondre → « Les réponses sont closes. Tu as répondu Présent. »
- [Gênant] (axe 3) L384-403 : Présent / Absent : le bouton choisi est plein, l'autre à contour, mais aucun `Semantics(selected: true)` ; le lecteur d'écran lit « Présent, bouton » dans les deux cas → ajouter `selected` / un état « choisi ».
- [Gênant] (axe 2) L56-77 : erreur « Ta disponibilité est momentanément indisponible » sans « Réessayer ».
- [Détail] (axe 3) L450-456 : « Modifie ou annule ta période dans Paramètres » sans bouton vers Paramètres ; L443-448 un `Text` vide si aucune raison (espace inutile).
- [Détail] (axe 3) L461 (thème) : le `TextButton` du thème a une hauteur minimale de 42 px (< 44) ; les boutons pleins / à contour ont 48 px (OK).
- Bon point : changement de réponse confirmé (retour `null` géré), progression pendant l'envoi, trois issues d'écriture distinguées (confirmée mais actualisation en échec, résultat inconnu, erreur), `mounted` testé.

### lib/features/sports_management/presentation/widgets/match_goal_actions_editor.dart
- [Gênant] (axe 4) L364-377 : la minute tapée au-delà de 90 (ex. « 95 ») est ignorée par le modèle mais reste affichée dans le champ (le texte n'est pas remis à la valeur précédente) ; le commentaire annonce « le champ la refuse » : en réalité il l'affiche → l'admin croit avoir enregistré 95 alors que l'ancienne minute part → remettre le texte à la valeur valide ou afficher « Entre 0 et 90 ».
- [Détail] (axe 4) L180-181 : « Passe décisive » est grisée sans buteur, sans le dire → « Choisis d'abord le buteur ».
- [Détail] (axe 4) L326-348 : pas de `textInputAction` ; pavé numérique iOS sans touche « OK » ; libellé « Min » en `textFaint` sur `surface` (contraste À vérifier) ; 2 chiffres maximum.
- [Détail] (axe 1) L64-81 : `ReorderableListView` non défilant dans une page qui défile : sur mobile, aucune poignée visible (appui long) et pas de défilement automatique pendant le glissement → À vérifier ; réordonner sert surtout aux minutes inconnues, à expliquer.
- [Détail] (axe 3) L426-431 : étiquette « Buteur » / « Passe décisive » en 11 px.
- Bon point : état vide expliqué (« Change le score… »), dialogues dont la fermeture (`null`) est gérée, buts à compléter signalés par couleur ET par texte (« Non attribué »).

### lib/features/sports_management/presentation/widgets/match_squad_editor.dart
- [Détail] (axe 4) L176 : « Retirer ${nom} ? » avec une espace normale avant « ? ».
- [Détail] (axe 4) L137-139 : dans le compte rendu, toucher un joueur du banc ouvre une demande de retrait (pas de placement par toucher comme sur l'onglet Compo) : gestes différents d'un écran à l'autre ; la confirmation protège.
- [Détail] (axe 1) L103-162 : `IntrinsicHeight` + colonne de banc de largeur fixe (≈ 55 px) : le banc, plus long que le terrain, rallonge la ligne ; noms à texte agrandi coupés (À vérifier).
- Bon point : mise en page par `LayoutBuilder` (largeur disponible), confirmation de retrait expliquant l'effet sur les buts, `PfButtonStyles.danger`.

### lib/features/sports_management/presentation/widgets/player_composition_video.dart
- [Gênant] (axe 2) L290-303 + L305-380 : « Aperçu de la vidéo » : le bouton se grise (`_playing`) mais rien n'indique que ça charge ; la préparation peut durer jusqu'à ≈ 11 s (4 s + 4 s + 3 s de délais, plus des lectures sans délai pour le maillot) avant que l'écran s'ouvre → indicateur dans le bouton.
- [Détail] (axe 2) L299-303 : `try/finally` sans `catch` : une exception pendant `_loadData` reste silencieuse (bouton réactivé, rien d'affiché).
- [Détail] (axe 4) L257 : l'intitulé « Aperçu de la vidéo » est un terme d'admin ; côté joueur « Revoir la présentation ».
- [Détail] (axe 3) L266-288 : lancement automatique à l'ouverture depuis la notification, sans geste ni respect du mouvement réduit.
- Bon point : mémoire locale en `try/catch` (échec silencieux sans risque), une seule tentative automatique par version de compo, la vidéo ne se lance pas par-dessus une autre page.

### lib/features/sports_management/presentation/widgets/stadium_club_colors_web.dart
- [À vérifier] (axe 1) L217-249 : recoloriage de la vidéo par WebGL, une image par image (`texImage2D` à chaque image) : charge et batterie sur téléphone d'entrée de gamme.
- Reste : repli propre quand WebGL est indisponible ; rien d'autre à signaler.

### lib/features/sports_management/presentation/widgets/stadium_poster.dart — rien à signaler (lu en entier)
Image décorative, dans une zone masquée aux lecteurs d'écran.

### lib/features/sports_management/presentation/widgets/stadium_video.dart — rien à signaler (lu en entier)
Aiguillage web / hors web uniquement (4 lignes).

### lib/features/sports_management/presentation/widgets/stadium_video_stub.dart — rien à signaler (lu en entier)

### lib/features/sports_management/presentation/widgets/stadium_video_web.dart
- [Détail] (axe 3) L260-289 : la vidéo est téléchargée entièrement avant lecture (délai 20 s) ; poids du fichier inconnu → peut peser sur les données mobiles ; aucune prise en compte de `prefers-reduced-motion` ni `Save-Data` → À vérifier.
- Bon point : image fixe tant que la vidéo n'est pas prête (jamais un rectangle noir), repli sur version légère, état en clair pour l'admin, nettoyage complet à la destruction.

---

## Fichiers lus en entier (33 / 33)
presentation/ : admin_guests_page, admin_squad_plan_effectif_roster, admin_squad_plan_page, admin_squad_plan_page_composition, admin_squad_plan_page_effectif, admin_squad_plan_page_state, admin_squad_plan_page_widgets, admin_waitlist_page, match_availability_provider, match_lineup_page, match_report_page, sport_motm_vote_page.
presentation/widgets/ : composition_kit_scope, composition_pitch, composition_presentation, composition_presentation_camera, composition_presentation_elements, composition_presentation_stage, effectif_avatar_grid, football_pitch, formation_pitch_editor, internal_team_composition_view, internal_team_composition_widgets, match_availability_board_card, match_availability_selector, match_goal_actions_editor, match_squad_editor, player_composition_video, stadium_club_colors_web, stadium_poster, stadium_video, stadium_video_stub, stadium_video_web.

## Fichiers non lus ou lus en partie
Aucun dans le périmètre. Non lus (hors périmètre, dépendances) : `MatchSheetTopRow` / `MatchSheetListView`, `StickyHeaderTableCard`, `PfStatusBanner`, `pf_button_styles`, `LiveBenchTile`, `pickMatchLiveScorer`, `ClubKits`, `humanizeError`. Les constats qui en dépendent sont marqués « À vérifier ».

## Top 5 des motifs répétés
1. Erreur sans « Réessayer » et sans icône parlante (carte « momentanément indisponible », ou texte nu) : match_lineup_page, board card, availability selector, motm (page et carte), internal view, admin_squad_plan_page_state, admin_guests L418. Tirer-pour-rafraîchir qui attend un futur pouvant échouer, sans `try` : match_lineup_page L119-137, motm L96-100.
2. Gestes tactiles seulement, non accessibles au clavier ni au lecteur d'écran (`GestureDetector`, appui long, sélection puis cible) et sans consigne écrite : roster, composition_pitch, formation_pitch_editor, internal_team widgets. S'y ajoute des zones de toucher trop petites (cloche 18-34 px, boutons de vidéo 32 px, + / − 34 px, tuile 39 px, poste 38 px).
3. Texte réduit ou tronqué au lieu de s'adapter à l'agrandissement : `FittedBox(scaleDown)` (boutons d'effectif, banc, prénoms du terrain), `maxLines: 1` + `ellipsis` dans une grille figée à 3 colonnes, hauteurs fixes (bouton Simuler 56 px, score 40 px, tuile de maillot 96 px), `Row` sans `Flexible` (puce de joueur).
4. Action « silencieuse » : geste ignoré pendant `_busy` ou verrouillage (effectif), champ refusé sans message (prénom invité, minute > 90), bouton grisé sans raison (Enregistrer, Aperçu, Passe décisive), bloc qui disparaît sans explication (réponses closes, effectif non visible).
5. Libellés qui ne disent pas l'effet réel : « Enregistrer » qui publie et notifie (Compo, composition interne), « Catalogue réutilisable » qui filtre les archivés, « Convoqués » qui est une limite, « Aperçu de la vidéo » côté joueur, « Saison précédente » sans unité. Les changements d'onglet / retour arrière ne protègent pas les modifications en cours (aucun `PopScope`, vue interne perdue).

## Bons points notables
- Confirmations placées sur les gestes qui comptent (notification irrévocable, vote définitif, publication, validation du compte rendu), avec la fermeture `null` presque toujours gérée.
- Écritures réseau robustes : cas « résultat inconnu » traité sans double envoi (compte rendu, disponibilité, liste d'attente), identifiants de requête, drapeaux anti-double envoi.
- `mounted` testé après presque tous les `await`.
- Mise en page par contraintes (`LayoutBuilder`) plutôt que par type d'appareil pour l'effectif, le banc et la liste d'attente.
- Messages en français clair, avec espaces insécables avant « ? » dans la plupart des titres de dialogue.
- Vidéo de composition : bouton « Fermer » dès le chargement, préchargement avec délai maximal, repli sur l'image fixe, jamais d'écran noir.
- Infobulles nommées sur les boutons +/- du score, étiquettes vocales de maillot et d'équipe.
