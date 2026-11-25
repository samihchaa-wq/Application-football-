# Audit UX/UI — lib/features/matches/presentation/ (28 fichiers, lus en entier)

Lecture seule, jugé par le code (pas d'appareil). Ce qui demande un rendu réel est marqué « À vérifier ».
Chemins relatifs à `lib/features/matches/presentation/`.

## Formulaires de match / événement

### calendar_entry_form_page.dart
- [Bloquant] (4) L579-588 (+L120, L759, L831) : le champ « Nom du stade (facultatif) » est rempli, prérempli depuis l'adversaire, mais jamais envoyé à l'enregistrement (`_submit` L1102-1120 ne le passe nulle part) → l'admin saisit un nom de stade, il est silencieusement perdu → soit l'enregistrer, soit retirer le champ.
- [Gênant] (2) L1102-1131 : le match est créé (L1102), puis la journée de championnat (L1124) et le rechargement (L1129) sont faits ensuite. Si l'un échoue, un message d'erreur s'affiche mais le formulaire reste ouvert → l'admin retape « Ajouter » et crée un deuxième match identique → séparer « créé » de « suite échouée » (fermer le formulaire avec avertissement) ou protéger contre le doublon.
- [Gênant] (2/4) L1092-1096, L777-807 : les cotes sont calculées en tâche de fond sans indicateur (contrairement à match_form_page). Si l'admin choisit un adversaire puis appuie vite sur « Ajouter », ou si le calcul échoue, le message est « Sélectionne un adversaire pour calculer les cotes » alors que l'adversaire est choisi → message faux, on ne sait pas quoi faire → montrer un état « Calcul des cotes… » et un message « Cotes indisponibles, réessaie » avec bouton.
- [Gênant] (4) L745-766, L768-775, L816-832, L504-510 : changer le type (Championnat/Amical/Événement), Domicile/Extérieur ou l'adversaire remplace l'adresse déjà tapée par l'adresse mémorisée (ou par du vide, L830). Passer à « Événement » vide aussi adresse et heure de rendez-vous (L758-760) → perte de saisie sans prévenir → ne remplacer l'adresse que si le champ est encore vide ou jamais modifié.
- [Gênant] (4) L462-503 : après « Ajouter un adversaire » (L898-904), l'adversaire est bien retenu en interne (`_opponentId`) mais le champ de recherche n'affiche pas son nom (le champ garde son ancien texte ou reste vide, `initialValue` n'est lu qu'à la première construction) → le formulaire semble vide mais valide ; si du texte avait été tapé, il ne correspond plus à l'adversaire retenu → remplir le champ avec le nom créé.
- [Gênant] (4) L834-843, L472-473 : si le nom tapé dans « Rechercher » ne correspond à aucun adversaire, la liste reste vide sans message ; le bouton « + » ouvre une fenêtre qui redemande le nom (non prérempli) → proposer « Ajouter “XYZ” » dans les suggestions et préremplir le nom.
- [Gênant] (3) L605-622 : case « Garder cette adresse » en `dense` + `visualDensity -4` + texte 12 px (bodySmall) : zone à toucher nettement < 44 px, libellé ambigu (quelle adresse ? pour qui ?), cochée par défaut → l'admin écrase l'adresse par défaut du club ou de l'adversaire sans le savoir → libellé explicite comme dans match_form_page L502-507, taille normale, décochée par défaut pour une adresse modifiée à la main.
- [Gênant] (3) L396-411, L1191-1260, L1263-1317 : le choix du type (4 boutons) ne dit au lecteur d'écran lequel est sélectionné (seule la couleur de fond change) → un utilisateur non voyant ne sait pas le type retenu → ajouter `Semantics(selected: true)` ou utiliser SegmentedButton.
- [Gênant] (1/3) L938-956, L958-970, L972-986 (via widgets/match_wheel_picker.dart) : heure, nombre de convoqués, journée : roues à faire défiler uniquement (aucune saisie clavier). Sur ordinateur (PWA) avec souris/clavier, choisir « 21:30 » ou « J14 » est pénible et peu accessible → proposer la saisie au clavier (showTimePicker en mode saisie, champ numérique) sur grand écran.
- [Gênant] (4) L1134 : après création d'un match ou événement, l'écran se ferme sans message de succès → l'admin ne sait pas si c'est enregistré (et ne voit pas toujours la carte, liste longue) → snackbar « Match ajouté » (+ défilement vers la carte).
- [Détail] (4) L323-339, L341-360, L579-603 : aucun `textInputAction` (suivant) sur le nom d'événement ; adresse en multiligne (Entrée = retour à la ligne, pas de « Terminé ») → clavier mobile sans passage au champ suivant → `next` sur le titre, `textInputAction: done` + `maxLines` limité sur l'adresse.
- [Détail] (4) L421-428, L472-473 : champ intitulé « Rechercher » sous le titre « Adversaire » ; aucun champ obligatoire n'est marqué (adversaire, lieu d'un événement, nom d'événement) → lecteur d'écran annonce « Rechercher » seulement → libellé « Adversaire (obligatoire) ».
- [Détail] (4) L515-525 : bouton « + » seul (icône) pour ajouter un adversaire, sans texte visible (match_form_page a le texte) → incompréhensible pour un nouvel admin → icône + « Nouveau ».
- [Détail] (4) L729-743 vs L631-646 : l'événement utilise deux lignes ListTile « Date / Heure », le match deux tuiles côte à côte ; deux gabarits pour la même chose → unifier. Date sans jour de semaine (history_entry_page l'affiche) → risque de se tromper de jour.
- [Détail] (4) L230 : titre de page « Ajouter » (et « Modifier » dans match_form_page) trop vague pour onglet navigateur / lecteur d'écran → « Ajouter au calendrier », « Modifier le match ».
- [Détail] (1) L226, L264 : `busy` inclut `state.isLoading`, état partagé avec toute l'appli : un rechargement en direct du calendrier grise le formulaire et le bouton pendant la saisie → À vérifier à l'écran.
- [Détail] (2/4) L857 (et history_entry_page L132, match_form_page L638, match_wheel_picker L164) : le contrôleur du champ de la fenêtre est détruit dès le retour de `showDialog`, alors que la fenêtre finit de se fermer → erreur « controller used after dispose » possible → À vérifier (visible surtout en debug).
- [Détail] (4) L1018-1046 : aucune confirmation si on quitte le formulaire avec des saisies (pas de PopScope) → retour arrière = tout perdu.

### match_form_page.dart
- [Gênant] (2/4) L161-189 + L903-904 : si la lecture du « nombre de convoqués » échoue, un snackbar s'affiche mais le champ garde la valeur par défaut 14 et le bouton Enregistrer reste actif → l'enregistrement écrase la vraie limite du match par 14 sans que l'admin le sache → bloquer l'enregistrement tant que la valeur n'est pas chargée, avec « Réessayer ».
- [Gênant] (4) L147-159, L191-224, L337-341 : même problème d'adresse écrasée que dans le formulaire de création : en modifiant un match existant, basculer Championnat/Amical, Domicile/Extérieur ou changer d'adversaire remplace l'adresse déjà enregistrée par l'adresse mémorisée (ou vide) → perte de saisie → ne pas écraser une adresse déjà présente/modifiée.
- [Gênant] (2/4) L602-608 : message d'erreur du contrôleur (`state.error`) affiché tout en bas, sous « Supprimer définitivement », hors de l'écran sur téléphone ; il peut aussi être une vieille erreur de chargement du calendrier sans rapport avec le formulaire → l'admin n'est pas prévenu → snackbar/bandeau en haut, et effacer à l'ouverture.
- [Gênant] (2/4) L87-100, L891-899 : si le calcul des cotes échoue (`odds == null`), les cotes affichent « — » sans explication ; l'enregistrement dit alors « Sélectionne un adversaire… » alors qu'il est sélectionné → message trompeur → « Cotes indisponibles, réessaie » + bouton.
- [Gênant] (4) L87-91 : `previewMatchOdds` sans try/catch : une exception laisse le petit indicateur « Cotes calculées » tourner indéfiniment (`_suggestingOdds` reste vrai) → à vérifier, entourer d'un try/finally.
- [Gênant] (4) L494-509 : « Garder cette adresse pour cette équipe » cochée par défaut (L59) : une adresse ponctuelle remplace le terrain par défaut → décocher par défaut quand l'adresse a été modifiée.
- [Gênant] (1/3) L294-314, L1046 : boutons « Championnat » à moitié de largeur, texte `maxLines: 2` sans ellipsis : à 160 % sur 360 px le mot unique « Championnat » (~125 px) ne tient pas dans ~120 px et se coupe en plein mot → À vérifier ; réduire le libellé ou passer en colonne à grand texte.
- [Gênant] (1) L320-346 : liste déroulante « Adversaire » non étendue (`isExpanded` absent) à côté d'un bouton, dans une demi-largeur : un nom long (« Olympique des Coteaux… ») peut déborder → À vérifier ; `isExpanded: true` + ellipsis.
- [Gênant] (3) L404-409 + widgets/jersey_option_tile.dart : voir ce fichier (maillot choisi non annoncé).
- [Gênant] (2) L703-738 : le bouton « Supprimer définitivement le match » du formulaire donne un avertissement générique (« supprime aussi ses cotes et ses pronostics »), moins complet que celui du menu (buteurs, Live, composition, selon l'état). Après suppression, `Navigator.pop` renvoie à la fiche du match supprimé (À vérifier : erreur ou fiche vide) → réutiliser le même texte d'avertissement et revenir au calendrier.
- [Détail] (2/4) L124-130 : lecture de l'adresse du club sans gestion d'erreur : en cas d'échec, rien n'est dit et l'adresse n'est pas préremplie.
- [Détail] (4) L580-590 : bouton Enregistrer désactivé si `canManage` est faux, sans explication ; libellé inchangé pendant l'enregistrement (seule l'icône tourne).
- [Détail] (4) L881, L915 : `updatedAt!` forcé : si absent, l'erreur affichée peut être un texte technique.
- [Détail] (4) L479-492 : adresse en multiligne (Entrée = nouvelle ligne), pas de `textInputAction`, compteur « 0/300 ».
- [Détail] (4) L230-233, L249-250, L868-871, L956-1011 : tout le code de création (`widget.match == null`) est mort car le build renvoie `CalendarEntryFormPage` : deux formulaires divergent déjà (cotes visibles ici, pas dans l'autre) ; à terme risque d'incohérence.
- [Détail] (4) L267 : titre « Modifier » seul.
- [Détail] (1) L1062-1093 `_OddsDisplay` : trois cartes « Victoire/Nul/Défaite » sur une ligne, texte 1 ligne ellipsis, valeur sans ellipsis : à 160 % sur 320 px, valeur de 4 caractères dans ~90 px : tient probablement → À vérifier.

### history_entry_page.dart
- [Gênant] (2/4) L151-155, L200-204, L283-304 : si un champ obligatoire manque (adversaire, date…), le message n'apparaît qu'en snackbar, qui se pose par-dessus les boutons « Enregistrer » du bas (le commentaire L178 le sait) ; aucun champ n'est surligné ni focalisé → l'utilisateur ne voit pas quel champ manque → errorText sous le champ concerné + focus sur le premier fautif.
- [Gênant] (4) L208-212 : aucune protection si on quitte la page après avoir saisi présents/buteurs/composition → tout est perdu au retour arrière ; la saisie rapide d'une saison entière rend la perte coûteuse → confirmation de sortie.
- [Gênant] (2) L134 : « Ancien joueur » avec moins de 2 caractères : la fenêtre se ferme et rien ne se passe, sans message → laisser la fenêtre ouverte avec un errorText.
- [Gênant] (3) L504-531, L686-698 : boutons − / + des buteurs et des scores ont tous le même nom vocal (« Retirer », « Ajouter ») sans dire pour qui ; la valeur du score n'est pas lue avec son équipe → impossible à utiliser au lecteur d'écran → « Retirer un but à Prénom Nom », « Ajouter un but pour l'adversaire ».
- [Gênant] (4) L598-602 : changer de dispositif tactique efface sans demander tous les titulaires déjà placés (`starters: const []`) → perte de saisie → confirmer ou conserver ce qui peut l'être.
- [Détail] (4) L329-351, L407-414 : pas de `textInputAction` (suivant) sur adversaire/lieu ; champs obligatoires (Adversaire, Date, Score) non marqués dans les libellés (seulement une phrase d'intro).
- [Détail] (4) L418-444 : score par défaut 0 – 0 : un match enregistré sans avoir touché au score est accepté comme 0-0.
- [Détail] (1) L385-405 : deux SegmentedButton (Domicile/Extérieur, Championnat/Amical) à 160 % sur 320 px : À vérifier (libellés non adaptables).
- [Détail] (1) L627 : `SizedBox(width: 48)` pour l'étiquette de poste (« MDC », « BUT »…) : à 160 % le texte peut déborder → À vérifier.
- [Détail] (1) L352-375 : suggestions d'adversaire limitées à 360 px de large, non alignées sur le champ.
- [Détail] (1) L283-304 : deux gros boutons fixés en bas ; avec le clavier ouvert sur petit téléphone, ils réduisent fortement la zone de saisie.
- [Détail] (3) L571-575 : ExpansionTile « Composition » : ouverture au toucher OK, mais le sous-titre « Facultatif » disparaît au clic ? non, reste ; rien à signaler d'important. (Informatif.)
- [Détail] (2) L58-77, L217-231 : chargement = cercle sans squelette ; erreur = message + Réessayer (bon).
- [Bon] dates en français complet (jour + mois), `_saving` empêche le double envoi, contrôleurs disposés.

### history_import_page.dart
- [Gênant] (2) L198-200, L201-207 : le message d'erreur est affiché sous les deux cartes, en rouge, sans icône, et peut être hors de l'écran après avoir choisi un fichier ; le bouton « Réessayer » n'apparaît que si le contexte n'a pas pu être chargé → erreur de fichier invalide peu visible → bandeau ou snackbar + défilement.
- [Gênant] (2) L240-241 : le résultat « N matchs importés » est un simple texte en bas de page, sans icône ni annonce vocale, et aucun bouton « Voir le calendrier » → l'utilisateur doute que l'import ait réussi → carte de succès + lien.
- [Gênant] (4) L89-93 : « Un conflit bloque intégralement le fichier » (jargon, et ne dit pas ce qu'est un conflit) ; liste de contrôle affiche la date au format AAAA-MM-JJ brut (L222) et `$match['score_for']` sans nom d'équipe → aperçu peu lisible, pas de format français.
- [Détail] (2) L142 : le chargement utilise `CircularProgressIndicator` au lieu du loader de l'appli (`PfProgressIndicator`).
- [Détail] (4) L246-268 : le « prompt » à copier est un gros texte non visible dans la page : l'admin copie sans voir ce qu'il copie ; pas d'aperçu.
- [Détail] (3) L146-150 : `Text` sans style de titre ; hiérarchie « 1. 2. 3. » seulement par titres de cartes (OK).
- [Détail] (1) L218-225 : seules 20 lignes affichées ; la mention « Et N autres » est correcte mais sans défilement dédié.
- [Détail] (4) L54-79 : l'état précédent (`_batch`) est effacé si un second fichier invalide est choisi (perte du premier aperçu) → à signaler.

### upcoming_match_prediction_page.dart
- [Détail] (3) L14 : titre « Ton prono » correct ; le contenu dépend entièrement de `InlineMatchPredictionCard` (hors périmètre). Pas de SafeArea explicite pour le bas de page (ListView avec padding 40 : suffisant).

## Calendrier

### calendar_matches_view.dart
- [Gênant] (2) L205-218 : en cas d'erreur de chargement dans la vue « Par mois », le message s'affiche (PfEmptyState) mais sans bouton « Réessayer » ; la liste est dans un ListView sans RefreshIndicator (L206) → le tirer-pour-rafraîchir ne marche pas ici → ajouter un bouton qui relance le chargement.
- [Gênant] (2) L132-133 : `clubEventsProvider` lu avec `valueOrNull ?? []` : si le chargement des événements échoue, les événements disparaissent du calendrier sans aucun message (erreur avalée) → bandeau « Événements indisponibles ».
- [Détail] (2) L202-203 : chargement = cercle sans squelette (le défilé utilise un squelette ailleurs).
- [Détail] (1) L167-172 : contenu plafonné à 1120 px ; en mode liste le plafond est 760 (toolbar L36) : la barre et la liste sont alignées (bon).
- [Détail] (2) L173-186 : `IndexedStack` garde les deux vues construites : la vue « mois » se charge même quand on est dans le défilé (À vérifier côté performance).

### calendar_matches_widgets.dart
- [Gênant] (3) L153-171 : flèches précédent/suivant (mois et saison) : tooltips présents (bon) mais, à bornes atteintes, la flèche devient grisée sans explication ; si le nom d'une saison n'est pas au format AAAA-AAAA (`_seasonRange`, L667-675), les bornes sont nulles et les deux flèches de mois sont mortes sans message → montrer « Aucune saison datée ».
- [Gênant] (1) L158-166 : libellé du mois/saison (« 2025-2026 — actuelle ») sans `maxLines`/ellipsis dans un espace borné entre deux boutons de 48 px ; à 160 % sur 320 px : revient à la ligne, ça passe mais la boîte grandit → À vérifier.
- [Gênant] (3) L526-527 et L578-603 : carte entière cliquable via InkWell (bon, clavier OK) mais un match annulé (`MatchDisplayPhase.cancelled`) renvoie `onTap` nul : carte non cliquable sans indication visuelle ; la couleur grise « annulé » est seule à le dire en dehors du libellé de statut → À vérifier.
- [Gênant] (2) L209-224, L342-357 : « Aucun rendez-vous en Mars 2026 » identique que ce soit « rien de prévu » ou « rien ne correspond » ; pas d'action (ex. « Ajouter », pour l'admin) → ajouter un bouton pour l'admin.
- [Gênant] (2) L196-197 : `allHistoricalMatchesProvider ... valueOrNull ?? []` : les anciens matchs archivés disparaissent du mois sans message si leur chargement échoue.
- [Détail] (3) L112-114 : largeurs fixes 300 et 320 px (déjà connu) ; avec le seuil `compact < 720` l'ensemble tient dans 688 px (OK).
- [Détail] (3) L402-456 : `ClubEventCard` : crayon d'édition (IconButton, tooltip OK) ; après modification, `invalidate` sans attendre ni message de succès (voir calendar_feed_event_card).
- [Détail] (1) L215-220, L348-353 : `SizedBox(height: 360)` fixe pour l'état vide : sur téléphone paysage (hauteur ~360) il occupe tout l'écran.
- [Détail] (3) L680-695 : noms de mois en majuscule initiale (« Janvier 2026 ») : en français on écrit « janvier » ; cosmétique.

### matches_page.dart
- [Gênant] (2) L148-154 : en cas d'erreur, le texte du contrôleur est affiché brut dans une carte, sans icône ni bouton « Réessayer » (le seul recours est de tirer pour rafraîchir) → PfEmptyState avec Réessayer.
- [Gênant] (2) L146-147 : pendant n'importe quelle action admin (annuler/supprimer), `state.isLoading` remplace toute la liste par un squelette → la page « clignote » et l'admin perd sa position → ne montrer le squelette que lors du premier chargement.
- [Détail] (3) L217-247 : pastille de chronologie (icône 13 px dans un rond de 23 px) : décorative, non exclue des lecteurs d'écran ; sens (terminé / en direct / à valider) porté par l'icône seulement, mais le libellé de statut existe (bon).
- [Détail] (1) L357-359, L339-349 : texte de statut 12 px, date 13 px en gris `textFaint` : contraste à vérifier sur fond sombre.
- [Détail] (3) L381-405 : match annulé non cliquable sans explication.
- [Détail] (2) L72-86 : le défilement automatique vers le match cible se rejoue à chaque rechargement si le contexte n'est pas encore prêt → À vérifier (saut de page).
- [Détail] (1) L421 : date « 12/03/2026 • 21h00 » correcte en français.

### matches_controller.dart
- [Gênant] (2) L226-248, L273, L300-326 etc. : les erreurs de `createMatch`/`updateMatch` (droits, cotes hors plage, « Le match a changé. Recharge l'écran ») sont stockées dans `state.error` : un échec d'enregistrement peut donc remplacer tout un écran de liste par une carte d'erreur (le commentaire L186-188 reconnaît le problème pour d'autres méthodes) ; MatchFormPage, lui, n'affiche cette erreur que tout en bas → incohérent → renvoyer le message comme `deleteMatch`.
- [Gênant] (2) L120-132, L167-173 : cache local affiché d'abord, puis, en cas d'échec réseau, l'erreur est effacée en silence (`hasLocalFallback`) → l'utilisateur voit d'anciennes données sans savoir qu'elles sont périmées ni qu'il est hors ligne → petit bandeau « Données de HH:MM, hors ligne ».
- [Détail] (2) L112 : « Authentification requise. » : texte sec, sans action de connexion.

## Fiches de match

### match_details_page.dart
- [Gênant] (2) L112-123 : si la fiche ne charge pas, simple texte dans une carte, sans bouton « Réessayer » (seul le tirer-pour-rafraîchir marche) ; même chose pour historical_match_detail_page L58-66 et L109-113 → bouton Réessayer.
- [Gênant] (2) L291-299 : bouton « Modifier les statistiques » réservé à l'admin : en chargement ou en erreur de lecture du vote (`error: SizedBox.shrink`), le bouton disparaît sans rien dire ; après la fin du délai de correction, il disparaît aussi sans explication → l'admin croit à un bug → message « Correction possible jusqu'à HH:MM » / « Correction fermée ».
- [Gênant] (3) L763-806 : tableau des pronostics sans en-têtes (« Joueur / Prono / Points ») ; le sens des bordures violet/or/vert (×2, ×1,5, ×1, calculées L746-761) n'est porté que par la couleur, sans légende ; `points.round()` arrondit les ×1,5 → le joueur ne comprend ni son score ni la couleur → en-têtes, légende (« Score exact ×2 »…), points avec décimale si besoin.
- [Gênant] (2) L624, L556 : composition et « faits du match » absents ou en erreur → rien n'est affiché (`SizedBox.shrink`), pas de « Aucune composition publiée » → l'utilisateur ne sait pas s'il manque des données ou si elles chargent.
- [Détail] (3) L501-539 : cartes « Effectif / Composition / Suivre le direct » : InkWell sur toute la carte (bon) ; icône dans CircleAvatar non exclue (décorative).
- [Détail] (2) L138-139, L413 : `isMatchLiveTooEarly` et la carte « Suivre le direct » sont calculés une fois au rendu : si la page reste ouverte jusqu'à T-15 min, la carte n'apparaît pas toute seule (À vérifier).
- [Détail] (2) L141-145 : si les réglages du club ne se lisent jamais, la roue tourne indéfiniment (pas de délai maximum) → À vérifier.
- [Détail] (1) L108 : `SizedBox(height: 170)` fixe dans l'état de chargement.
- [Détail] (3) L690-707 : rang du classement du vote en gris, « n voix » sans pluriel géré pour 0 (non affiché), pas de problème réel ; photo du joueur sans texte alternatif utile (`PlayerAvatar`, hors périmètre).

### historical_match_detail_page.dart
- [Gênant] (2) L67-70 : si une archive n'a ni composition ni joueurs, la page montre seulement l'en-tête, sans phrase « Pas de détails pour ce match » → page qui semble cassée → message explicatif.
- [Gênant] (2) L323-363 : suppression avec confirmation claire (« Tu pourras le saisir à nouveau », bon) ; `showDialog` renvoie null géré (`!= true`). Mais la page se ferme avec `maybePop` après un snackbar : le snackbar peut s'afficher sur la page suivante (acceptable). Pas de défaut majeur.
- [Détail] (2) L148-153 : « Domicile / extérieur non renseigné » en texte brut, non stylé, sous la carte.
- [Détail] (2) L54-56 : chargement = roue sans squelette.
- [Détail] (3) L370-376 : bouton « Supprimer ce match de l'historique » en TextButton neutre (pas rouge) : action destructive peu signalée visuellement.

### upcoming_match_prediction_page.dart : voir plus haut.

## Composants (widgets/)

### widgets/calendar_actions_bar.dart
- [Détail] (3) L26-33 : `foregroundColor: Colors.white`, `backgroundColor: AppTheme.primary` en dur (déjà connu pour les couleurs). Bouton de 44 px de haut (bon). Rien d'autre.

### widgets/championship_round_tile.dart
- [Gênant] (1/3) L34-47 : le texte, y compris l'avertissement « déjà utilisée cette saison », est dans un FittedBox `scaleDown` sur une seule ligne : sur petit écran ou texte agrandi il rétrécit jusqu'à devenir illisible, précisément quand le message important s'ajoute → permettre le retour à la ligne (`maxLines: 2`) et mettre l'avertissement en sous-titre.
- [Détail] (3) L50 : si `enabled` est faux, `onTap` est nul mais la tuile garde l'apparence active (`enabled:` du ListTile non transmis).
- [Détail] (3) L44-46 : avertissement en rouge (couleur) accompagné du texte (bon).

### widgets/historical_match_card.dart
- [Détail] (3) L44-45 : carte cliquable via InkWell (bon) ; aucune étiquette sémantique d'ensemble (« Match du … contre … »), le lecteur d'écran lit des fragments → regrouper avec `Semantics`.
- [Détail] (2) L60-64 : « Domicile / extérieur non renseigné » centré, sans style.

### widgets/calendar_feed_event_card.dart
- [Gênant] (2) L24-38 : après modification, `await ref.read(clubEventsProvider.future)` sans try/catch ni `mounted` : si le rechargement échoue, exception non gérée, aucun message ; pas de snackbar « Événement mis à jour » ni après suppression (le commentaire L30-36 le sait) → feedback de succès/échec.
- [Détail] (3) L41-47 : IconButton avec tooltip (bon) ; couleur de l'icône = bordure d'événement : contraste à vérifier.

### widgets/match_result_score_chip.dart
- [Gênant] (3) L40-67 : date en `Colors.white` en dur à 12 px : sur thème clair, texte blanc sur fond clair illisible (À vérifier ; mêmes constats dans match_info_tab L249-253). Couleur victoire/nul/défaite seule porte le résultat (vert/orange/rouge) sans libellé → inaccessible à un daltonien et à un lecteur d'écran (la zone sans `onTap` n'a pas de `Semantics`).
- [Détail] (3) L72-80 : zone tactile du chip = taille du contenu (≈ 40-48 px) : limite.
- [Détail] (1) L57-65 : `FittedBox` réduit la date au lieu de la couper (bien), mais sous 12 px effectifs possible à grande échelle.

### widgets/upcoming_match_fixture_header.dart
- [Gênant] (2) L70-97 : chargement et erreur → `SizedBox.shrink` (`maybeWhen ... orElse`) : l'en-tête du match n'apparaît jamais en cas d'erreur, aucun message ni Réessayer → l'utilisateur ne voit ni date ni lieu.
- [Détail] (2) L73-78 : match sans heure ou terminé/annulé → rien rendu (voulu), mais aucune indication.

### widgets/match_meeting_time_picker.dart
- [Gênant] (3) L114-140 : choix « -30min / Choisir » : bouton choisi = plein, sinon contour ; aucune indication vocale de l'état sélectionné → ajouter `Semantics(selected)`.
- [Détail] (4) L30, L59-64 : texte d'aide « Rendez-vous à 20:30 » en bodySmall ; format `20:30` (les autres écrans utilisent « 21h00 ») → harmoniser.
- [Détail] (4) L42 : « -30min » sans espace ni sens clair (« 30 min avant ») ; le libellé « Choisir » ne dit pas ce qu'on choisit.
- [Détail] (2) L94-98 : message d'erreur en snackbar seulement.

### widgets/kit_jersey.dart
- Rien à signaler (lu en entier). Bon : `Semantics(image: true, label)`, contour adapté aux maillots sombres.

### widgets/match_form_section.dart
- [Détail] (3) L41-50 : icône décorative de section non exclue des lecteurs d'écran ; titre de section sans `Semantics(header: true)`.
- [Détail] (3) L107-150 `MatchFormPickerTile` : zone tactile ~ 62 px (bien) ; mais aucun libellé vocal combinant « Date : 12/03/2026, bouton » ; valeur et libellé lus séparément.

### widgets/jersey_option_tile.dart
- [Gênant] (3) L91-103, L118-138 : le maillot choisi n'est signalé que visuellement (cadre + coche) ; le lecteur d'écran ne dit pas « sélectionné » (le `KitJersey` donne seulement « Maillot <nom> ») → ajouter `Semantics(selected: selected, button: true)`.
- [Gênant] (1/3) L46-67 : rangée de maillots à défilement horizontal, tuiles de 108 px, sans indice qu'il y en a d'autres (pas de flèche ni demi-vignette coupée garantie) ; au clavier/souris sur ordinateur, défilement horizontal peu découvrable → afficher en grille qui passe à la ligne (Wrap).
- [Détail] (3) L97 : le cadre sans coche de `JerseyOption` désélectionnable en retapant : comportement non annoncé (« retaper pour désélectionner »).
- [Détail] (1) L148-156 : étiquette 1 ligne ellipsis dans la tuile (bien) ; hauteur contrainte par l'`AspectRatio` : à 160 % le texte peut mordre sur le maillot (À vérifier).

### widgets/convocation_launch_picker.dart
- [Gênant] (3) L145-183 : trois boutons « J-N / Maintenant / Choisir » sur une ligne avec `fontSize: 13` fixe : aucune adaptation au texte agrandi, `maxLines: 1` sans ellipsis : « Maintenant » (~85 px à 160 %) dans ~(330-60)/3 ≈ 85 px → risque de coupure ; sélection non annoncée aux lecteurs d'écran → À vérifier + `Semantics(selected)`.
- [Gênant] (2) L84-101 : le bouton « Choisir » est parfois refusé par un simple snackbar « Le match est trop proche » : le bouton reste actif ; le message disparaît vite → désactiver « Choisir » avec explication affichée sous les boutons.
- [Détail] (4) L141-142 : format « 12/03/2026 à 21:30 » (autres écrans « 21h30 ») → harmoniser. Jargon : « Lancement des convocations », « J-3 » : sans explication pour un admin débutant → phrase d'aide.
- [Détail] (1) L124-143 : formats de date dupliqués dans 4 fichiers au lieu d'`AppFormats` (risque d'incohérence).

### widgets/club_start_guide.dart
- [Gênant] (2) L66-71 : tant que le guide charge ou si l'une des deux lectures (tableau de bord admin, fiche du club) échoue, il n'affiche rien (`valueOrNull`, `SizedBox.shrink`) ; l'erreur est avalée → un nouvel admin ne voit jamais le guide sans savoir pourquoi.
- [Gênant] (3) L159-196 : une étape terminée est grisée et barrée mais reste dans la liste, `enabled: false` → pas focalisable ; l'étape 3 grisée (saison manquante) n'explique l'ordre que dans son sous-titre (texte désactivé → contraste faible, WCAG) → afficher l'explication en texte normal.
- [Détail] (4) L144-151 : « Masquer le guide » est mémorisé sur l'appareil seulement (SharedPreferences) → réapparaît sur un autre appareil ; pas de confirmation ni de moyen de le ramener.
- [Détail] (3) L92-97 : « 2/4 » seul : pas d'étiquette vocale (« 2 étapes sur 4 terminées »).
- [Détail] (1) L112-143 : sous-titres de 12-14 px dans ListTile `dense` : à 160 % les lignes se serrent (ListTile s'adapte, OK).

### widgets/match_wheel_picker.dart
- [Gênant] (1) L127-130, L182-183 : feuilles à hauteur fixe (330 et 370 px) ; sur téléphone en paysage (~360 px de haut) ou avec le texte agrandi, le contenu dépasse la feuille (pour `pickInt`, la feuille n'a pas `isScrollControlled`, donc elle est plafonnée à ~56 % de la hauteur) → À vérifier : bandeau jaune/noir de débordement.
- [Gênant] (3) L139-156, L193-201 : roues Cupertino utilisables au toucher/souris seulement ; pas de saisie clavier ni de rôle sémantique d'ajustement clair → peu accessible sur ordinateur et pour les lecteurs d'écran.
- [Détail] (3) L12-68 : `showDatePicker` en mode calendrier seul (`calendarOnly`) : bien, mais pas de saisie directe de la date (ex. matchs passés lointains dans history_entry_page : remonter à 1950 oblige à naviguer mois par mois ou via l'année).
- [Détail] (4) L164 : `controller.dispose()` juste après la fermeture de la feuille, pendant son animation de sortie → À vérifier (erreur « used after dispose »).
- [Détail] (4) L246-267 : en-tête de feuille : « Annuler / titre / Valider » sur une ligne ; à 160 % un titre long (« Lancement des convocations ») passe sur 3-4 lignes.

### widgets/match_info_tab.dart
- [Gênant] (2) L28-33 : erreur = « Infos du match indisponibles. » sans cause, sans « Réessayer ».
- [Gênant] (3) L239-258, L249-253 : date des anciennes rencontres en blanc codé en dur à 12 px dans une case de ~60 px (5 cases sur une ligne) ; score en 15 px, résultat par la couleur seule (vert/rouge) → illisible sur fond clair, inaccessible aux daltoniens ; à 160 % le `FittedBox` réduit en dessous de 12 px.
- [Gênant] (3) L261-271 : zone tactile de chaque case ≈ 48 px de haut mais ≈ 55-60 px de large sur 5 colonnes (OK) ; `Semantics` « Ouvrir le match du <date> » ne donne pas le score ni l'adversaire → lecteur d'écran sans information utile.
- [Détail] (1) L40-120 : la ligne « Maillot » = libellé + deux pictos 32x38 + nom (Flexible, sans ellipsis) : OK.
- [Détail] (2) L127-134 : la carte météo n'apparaît que si une adresse existe, sans explication quand elle manque (volontaire, voir commentaire) → petite phrase « Ajoute une adresse pour voir la météo » pour l'admin.
- [Détail] (4) L45 : l'heure « 21h00 » via `AppFormats`; autres formulaires affichent « 21:00 ».

### widgets/admin_match_options_button.dart
- [Gênant] (2) L59-65, L93-99, L144-155 : annuler / terminer / supprimer : pendant l'appel serveur (+ rechargement complet de la liste) aucun indicateur sur le bouton ; en cas de succès d'annulation ou de fin de match, aucun message (« Match annulé ») ; l'admin peut retaper et lancer deux fois l'action (aucun drapeau « en cours ») → désactiver pendant l'action + snackbar de succès.
- [Gênant] (2) L121-156 : suppression irréversible d'un match terminé : une seule confirmation, texte précis (bon), mais sans possibilité d'annuler après coup (pas d'« Annuler » dans un snackbar) — acceptable car la confirmation décrit ce qui part ; cohérence : `_finish` (« ne peut pas être annulée ») est un pas irréversible lui aussi, sans bouton rouge (L83-86) → style d'avertissement.
- [Gênant] (3) L166-237 : menu ⋮/crayon (tooltip « Options du match », bon) mais l'icône est un crayon (« modifier ») alors que le menu contient « Supprimer », « Annuler », « Terminer » → trompeur pour un nouvel admin → icône « plus d'options » (⋮).
- [Détail] (3) L195-235 : entrées de menu en ListTile avec icônes décoratives non exclues ; « Annuler » (annuler le match) prête à confusion avec « annuler l'action » → « Annuler le match ».
- [Détail] (2) L27-30 : `_edit` sans try/catch autour du rechargement.

### widgets/completed_match_composition_card.dart
- [Gênant] (3) L246-259, L249-252 : titre « Banc (n) » en 12 px gris (`textSecondary`) réduit encore par deux `FittedBox` imbriqués (bloc de 406 px mis à l'échelle) : sur téléphone 360 px, le texte du banc et des pastilles descend à environ 9-10 px réels → illisible → À vérifier ; garder le banc en liste sous le terrain sur petit écran.
- [Gênant] (3) L324-326, L333-340 : couronne 👑 et ballons ⚽ (emoji) : le ballon dans la liste de repli n'a pas de `ExcludeSemantics` (lu « football ») alors que la ligne a déjà un libellé complet ; sens « homme du match » porté par l'emoji → OK pour l'oreille (libellé) mais l'emoji seul n'est pas fiable selon l'appareil.
- [Détail] (3) L162-175 : « emplacements grisés » : le sens (poste sans nom) est porté par le gris seul ; la phrase explicative est en 12 px gris clair (`textSecondary`) → contraste à vérifier.
- [Détail] (1) L276-350 : `CompletedPlayersList` ne scrolle pas seule (dans la page) : OK ; texte du nom sans ellipsis dans un `Flexible` : retour à la ligne, OK.
- [Détail] (3) L113-135 : composition absente → « Aucun joueur renseigné. » (bon état vide).

### match_encounter_route.dart
- Rien à signaler (lu en entier) : petite fonction de chemin sans interface.

---

## Fichiers lus en entier (28/28)
match_encounter_route.dart, upcoming_match_prediction_page.dart, calendar_matches_view.dart, calendar_matches_widgets.dart, matches_page.dart, matches_controller.dart, match_details_page.dart, historical_match_detail_page.dart, history_entry_page.dart, history_import_page.dart, match_form_page.dart, calendar_entry_form_page.dart, widgets/calendar_actions_bar.dart, widgets/championship_round_tile.dart, widgets/historical_match_card.dart, widgets/calendar_feed_event_card.dart, widgets/match_result_score_chip.dart, widgets/upcoming_match_fixture_header.dart, widgets/match_meeting_time_picker.dart, widgets/kit_jersey.dart, widgets/match_form_section.dart, widgets/jersey_option_tile.dart, widgets/convocation_launch_picker.dart, widgets/club_start_guide.dart, widgets/match_wheel_picker.dart, widgets/match_info_tab.dart, widgets/admin_match_options_button.dart, widgets/completed_match_composition_card.dart.

## Fichiers non lus ou lus en partie
Aucun dans le groupe. Les composants importés d'autres dossiers (CalendarCardSections, CalendarScoreline, MatchDetailHeaderCard, PfEmptyState, PlayerAvatar, CompositionPitch, InlineMatchPredictionCard, MergedMatchesView, MatchHistoryCard, MatchWeatherCard…) n'ont PAS été lus : leurs constats éventuels ne sont pas couverts ici. Aucun rendu réel n'a été vu : tout ce qui touche aux débordements, contrastes et animations reste à confirmer à l'écran.

## Top 5 des motifs répétés
1. Saisie perdue ou écrasée en silence : adresse remplacée quand on change type/lieu/adversaire (2 formulaires), nom de stade jamais enregistré, dispositif tactique qui vide les titulaires, aucune confirmation en quittant un formulaire.
2. États non annoncés : erreurs sans « Réessayer » (matches_page, match_details_page, historical_match_detail_page, match_info_tab, calendrier mois) et erreurs/chargements avalés par `SizedBox.shrink` / `valueOrNull ?? []` (en-tête de match, composition, événements, archives, guide de démarrage, bouton de correction).
3. Choix par boutons/cartes sans état annoncé aux lecteurs d'écran (type de match, rendez-vous, convocations, maillot choisi) et résultat/couleur porté par la couleur seule (score, pronostics, victoires).
4. Retour d'action absent ou trompeur : pas de message de succès (création, annulation, fin de match, modification d'événement), pas d'indicateur « en cours » ni de garde anti-double-clic sur les actions admin, messages d'erreur faux sur les cotes.
5. Désktop/PWA et grand texte : roues de sélection sans clavier, feuilles à hauteur fixe, boutons à demi-largeur (« Championnat »), textes blancs 12 px codés en dur, FittedBox qui rétrécit jusqu'à l'illisible.

## Bons points notables
- Formulaire d'ajout d'un match passé : dates en français complet, saisie en série, drapeau `_saving`, Réessayer présent au chargement.
- Dialogues de suppression bien rédigés (message adapté à l'état du match, bouton rouge, fermeture à côté gérée par `?? false`).
- `mounted` et `ScaffoldMessenger` capturés avant l'attente dans presque tous les cas.
- Contrôleurs/FocusNode disposés ; `matches_controller` protège contre les réponses périmées (numéro de génération) et affiche d'abord un cache local.
- Pastille de choix de maillot visible (cadre + coche) et peinture du maillot avec libellé sémantique.
- Info-bulles présentes sur la plupart des boutons-icônes ; bouton « Nouvel événement » à 44 px.
