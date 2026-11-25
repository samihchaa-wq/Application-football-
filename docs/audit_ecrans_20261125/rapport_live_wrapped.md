# Audit UX/UI : Live du match (match_live/presentation) et Bilan de saison (season_wrapped/presentation)

Lecture seule, par le code. 24 fichiers lus en entier (8 176 lignes). Rien n'a été lancé à l'écran : tout ce qui demande un rendu est marqué « À vérifier ».
Chemins abrégés : `ML/` = lib/features/match_live/presentation/, `SW/` = lib/features/season_wrapped/presentation/.

Fait structurant à connaître : le thème de l'app est uniquement sombre (app_theme.dart L254). Les `Colors.white` en dur du Live ne posent donc pas de problème de contraste.

---

## match_live

### ML/match_live_pilot.dart — rien à signaler (lu en entier)

### ML/match_live_providers.dart
(Fichier de logique, mais deux comportements se voient à l'écran.)
- [Bloquant] (2) L163-166 : si une relecture périodique (toutes les 30 s) ou celle qui suit une coupure Realtime échoue, l'état est remplacé par une erreur, même si des données valides étaient déjà affichées. Effet : en plein match, une micro-coupure réseau remplace tout l'écran de pilotage par une simple phrase (voir match_live_tab L55), et la place de pilote est libérée (voir match_live_tab L383). Correction : en cas d'échec d'une relecture, garder les données précédentes et afficher seulement un petit bandeau « connexion instable ». À confirmer à l'écran : cela dépend de la version de Riverpod, qui peut ou non conserver l'ancienne valeur.
- [Gênant] (2) L210-213 : le message d'échec dit « Action non confirmée. L'état réel du serveur a été rechargé. » C'est du jargon, et il ne dit pas si le but ou le changement est enregistré. Effet : le coach ne sait pas s'il doit recommencer. Correction : « Le but n'est peut-être pas enregistré : regarde le score avant de recommencer. »
- [Détail] (2) L93-94 : un seul message à la fois, puis effacé (voir match_live_tab L41). Si deux échecs se suivent avec le même texte, le second ne s'affiche pas. Correction : horodater le message.

### ML/match_live_pre_kickoff_page.dart
- [Gênant] (4) L216-221 : le champ « Durée (min) » n'a ni filtre « chiffres seulement », ni touche « OK/Suivant » (textInputAction), ni maximum. On peut donc saisir 9999. L'erreur « Entre un temps de jeu valide » (L375) est une bulle en bas, pas sous le champ, et le champ n'est pas sélectionné. Correction : errorText sous le champ, filtre chiffres, borne de 1 à 150, passage au focus sur le champ fautif.
- [Gênant] (1) L212-265 : une seule ligne regroupe 2 champs et 2 boutons de 48 px, soit 118 px fixes. À 320 px de large, chaque champ n'a plus qu'environ 85 px, et le libellé « Durée (min) » se coupe. À 160 % de texte, la valeur devient illisible. À vérifier à l'écran. Correction : passer sur 2 lignes (Wrap) sous 400 px.
- [Gênant] (2) L338-370 : déposer un joueur sur un poste (`_dropOnSlot`, `_moveToBench`) n'a ni indicateur « enregistrement en cours », ni verrou, ni message en cas d'échec propre à l'action. On peut enchaîner deux glissers pendant que le premier s'enregistre. Correction : poser `_busy` pendant l'appel et afficher un retour.
- [Gênant] (3) L459-468 : la vue spectateur force la taille du texte à 100 % (`maxScaleFactor: 1`). Un spectateur malvoyant ne peut pas agrandir les noms des joueurs. Même choix dans running_widgets L840-849. Correction : plafonner à 1,3 au lieu de 1 et adapter la taille des pastilles.
- [Détail] (2) L372-407 : `_confirmAndStart` n'attrape pas l'erreur (le message vient du fournisseur) et la boîte « Démarrer le match ? » (L380-395) ne rappelle ni la durée ni la composition. Correction : afficher « Durée prévue : 90 min ».
- [Détail] (2) L45-47, L217 : la durée saisie n'est enregistrée qu'au démarrage. Si le coach quitte l'écran avant, elle est perdue. Correction : l'enregistrer à la sortie du champ.
- [Détail] (4) L234-263 : le menu « Système » et les boutons Ajouter/Retirer sont grisés sans explication quand le club a coupé la règle. Correction : une phrase d'aide ou une infobulle sur le bouton grisé.
- [Détail] (2) L121 : « Composition indisponible. » sans bouton « Réessayer ».
- [Détail] (2) L433-449 : le message d'erreur du spectateur invite à « tirer l'écran vers le bas ». Un RefreshIndicator existe bien dans la page parente (match_lineup_page L118), mais il n'y a aucun bouton « Réessayer » pour ceux qui ne le devinent pas.
- [À vérifier] (1) L151-154 : la liste est imbriquée dans le défilement de la page, et le champ Durée est en haut. Il faut vérifier que le clavier numérique ne masque pas le champ.

### ML/match_live_running_page.dart
- [Gênant] (2) L363-369, L441-447, L481-494, L922-952, L1038, L1063, L1092, L1124, L1205 : pause, reprise, mi-temps, fin de match, remise à zéro, choix du buteur, suppression d'un événement et glisser-déposer lancent l'action sans attraper l'erreur, sans indicateur « en cours » et sans verrou anti double appui. Le seul retour est le bandeau générique du fournisseur. Effet : un double appui sur Pause/Reprendre envoie deux ordres, et sur réseau lent rien ne bouge visiblement. Correction : un petit état « en cours » sur la barre de commandes, boutons désactivés pendant l'envoi.
- [Gênant] (2) L116, L375-393, L557-600 : pendant qu'un remplacement est « en attente », le terrain affiche déjà le joueur à sa nouvelle place, comme si c'était fait, alors que rien n'est enregistré. Le bouton « Valider » est tout en bas, sous le journal quand il est déplié (L557-573). Effet : le coach croit le changement fait, et le supérieur à valider peut être hors de l'écran. Correction : bandeau « Changement non validé » collé en bas de l'écran (sticky), ou bordure orange sur les joueurs concernés.
- [Gênant] (3) L1170-1181, L264-265 : le seul indice pour remplacer un joueur est un message qui apparaît après un essai raté (« Glisse ce joueur… »). Le glisser demande un appui long (voir live_bench_tile L124). Rien d'écrit à l'écran n'explique le geste avant la première erreur. La sélection au toucher existe (`FormationPitchTapSelection`) mais n'est pas expliquée. Correction : une ligne d'aide sous le terrain tant qu'aucun changement n'a été fait.
- [Détail] (2) L1011-1040 : « Retirer ce but ? » ne dit pas que le score est recalculé. L1042-1065 : « Mi-temps ? » n'a aucune explication.
- [Détail] (2) L1123 : `setState(_pending.clear)` après une attente sans test `mounted`. Si l'écran est quitté pendant la boîte de dialogue, cela plante.
- [Détail] (3) L468-475 : le libellé « Reset » est un anglicisme, et il est voisin de « Fin » (destructif). L'infobulle dit « Recommencer le match ». Correction : écrire « Recommencer » ou « Effacer ».
- [Détail] (2) L99-109, L113 : « Composition indisponible. » et le message de fin de match n'ont pas de bouton d'action.
- [Détail] (1) L288-409 : toute la branche « page défilante » (menu Dispositif, bouton « Ajouter un joueur », bandeau complet à 4 boutons) n'est jamais atteinte. Le tableau (match_live_tab L118) ne l'appelle que pour un match terminé, et la page sort alors à L99 avant d'y arriver. Les contrôles de `_LiveHeaderBar` (L193-212) sont donc morts aussi. À nettoyer, pour éviter de corriger du code qui ne sert pas.
- [À vérifier] (1) L148-150 : un banc long (8 remplaçants ou plus) fait grandir la colonne dans un IntrinsicHeight. Cela peut dépasser la hauteur du terrain.

### ML/match_live_running_journal.dart
- [Détail] (3) L338-347 : pour un but sans buteur, la zone à toucher fait environ 24 px de haut (20 px d'icône plus 2×2 de marge) et ne montre aucun signe qu'elle est cliquable (pas de flèche, pas de « Touche pour choisir »). Correction : zone de 44 px et texte d'invite. À noter : la barre « Choisir » (running_widgets L291) existe dans la vue pilote.
- [À vérifier] (1) L349-366 : le texte du but est limité à 52 % de la largeur et 2 lignes. « But Club · Prénom · passe Prénom » peut être coupé aux grandes tailles de texte, sans moyen de lire la fin.
- [Détail] (3) L49-51 : l'en-tête repliable n'annonce pas « déplié/replié » aux lecteurs d'écran. Correction : Semantics(expanded:).
- [Détail] (3) L229-230 : l'indentation des buts dépend de MediaQuery.sizeOf, c'est bon. Rien d'autre.

### ML/match_live_running_widgets.dart
- [Gênant] (2) L55-58 : les boutons + et − du score envoient une écriture à chaque appui, avec un identifiant d'opération nouveau à chaque fois (providers L312). Le score affiché ne change qu'après la réponse du serveur, et deux appuis rapides ajoutent deux buts. Effet : un coach qui ne voit rien bouger retape et marque un but de trop. Le « − » retire aussi un but sans confirmation, alors que le journal en demande une. Correction : afficher le nouveau score tout de suite, et désactiver les boutons pendant l'envoi.
- [À vérifier] (1) L138-169, L431-492 : dans le bandeau pilote, chaque équipe affiche « − score + » avec 2×44 px fixes. À 320-360 px de large, il reste très peu de place pour le chiffre, que FittedBox réduit (environ 25 % de sa taille à 320 px, et davantage à deux chiffres). À vérifier à l'écran.
- [Détail] (2) L44-47, L749-752 : tant que l'adversaire charge, ou si le chargement échoue, le nom « Adversaire » s'affiche sans signal. Il change ensuite d'un coup.
- [Détail] (4) L662-678 : le bouton « Annuler » (icône) d'une ligne et le bouton « Annuler » du bas ne font pas la même chose (le second annule tout). Correction : « Tout annuler ».
- [Détail] (3) L566-574 : le joueur du banc « sur le point de sortir » n'est signalé que par un contour rouge. Un daltonien ne le voit pas. Correction : ajouter une icône ou un libellé.
- [Détail] (2) L839-849 : si la composition est absente, le spectateur voit un trou sans message.
- [Détail] (2) L707-721 : le message `_Message` n'a pas de bouton « Réessayer ».
- [Détail] (1) L171-220 : le bandeau compact utilise FittedBox, qui réduit aussi les boutons de 36 px. Code mort aujourd'hui (voir running_page L288), à supprimer plutôt qu'à corriger.

### ML/match_live_tab.dart
- [Bloquant] (2) L55-60 : en erreur, l'onglet n'affiche qu'une phrase, sans bouton « Réessayer ». Combiné avec providers L163 (une seule relecture ratée suffit), le coach perd son tableau de pilotage en plein match. De plus, comme `_CoachLiveView` disparaît, `_PilotSession.dispose` libère la place (L383). Au retour des données, la place est redemandée. Si un autre téléphone l'a prise entre-temps, le coach arrive sur « Quelqu'un d'autre pilote ». À confirmer à l'écran (voir providers L163). Correction : conserver les données et n'afficher qu'un bandeau « connexion perdue ».
- [Gênant] (2) L62-63 : si la vérification « suis-je coach / admin ? » est en chargement ou en erreur, l'app suppose « non ». En chargement, le coach voit brièvement la vue spectateur, puis celle de pilotage, et pour un match terminé le message « En attente de la publication du compte rendu par le coach » (running_page L101). En erreur (coupure), il reste spectateur sans qu'on le lui dise. Correction : traiter « inconnu » comme un chargement et afficher l'erreur avec « Réessayer ».
- [Gênant] (2) L282-331 : « Quelqu'un d'autre pilote déjà le Live » ne dit pas qui, depuis quand, ni quoi faire. Si le club a désactivé la prise de contrôle (L300), il n'y a aucun bouton : une impasse sans explication. Correction : afficher le nom du pilote et « Demande-lui de quitter, ou attends une minute ».
- [Gênant] (2) L372-376, L379-385 : passer l'application en arrière-plan (écran verrouillé, appli de messagerie ouverte, onglet navigateur masqué) libère immédiatement la place de pilote. Pendant un match, c'est un geste courant. Au retour, la place est redemandée automatiquement, mais si quelqu'un d'autre l'a prise entre-temps, il faut « Prendre la main ». À vérifier avec un vrai téléphone et le comportement PWA.
- [Détail] (2) L303-318 : la boîte « Prendre la main ? » n'explique pas que l'autre téléphone perdra la main.
- [Détail] (2) L252-279 : « Personne ne pilote le Live » est un texte nu, sans titre ni cause. Le bouton « Piloter le Live » n'a pas d'indicateur en cours. Si la prise de place échoue, la raison n'est visible que quelques secondes (snackbar).
- [Détail] (3) L418-450 : « Temps réel interrompu. Synchronisation de secours active. » est du jargon, en rouge d'erreur pour un mode dégradé qui fonctionne. L'effet réel, des mises à jour jusqu'à 30 s en retard, n'est pas dit. Le label et le texte sont lus deux fois par un lecteur d'écran. Correction : « Connexion instable : le score peut arriver avec jusqu'à 30 s de retard. » en couleur d'avertissement.

### ML/widgets/live_bench_tile.dart
- [Détail] (3) L124-132, L202-209 : glisser un remplaçant demande un appui long, sans indice. Une alternative au toucher existe (L106-108), mais rien ne l'explique.
- [À vérifier] (3) L69-71, L155-157 : le repère « 2.1 » (passage, série) et sa couleur n'ont aucune légende visible dans ces fichiers. La couleur seule porte le sens de la série.
- [À vérifier] (1) L89-100, L142-153 : le prénom est réduit par FittedBox sans taille minimale, et peut passer sous 12 px.

### ML/widgets/live_substitution_line.dart — rien à signaler (lu en entier)
Point positif : phrase complète pour le lecteur d'écran, flèches en plus de la couleur.

### ML/widgets/match_faits_du_match_card.dart
- [Gênant] (2) L51-55 : chargement et erreur sont traités comme « aucun but » (`valueOrNull`), la carte disparaît. Impossible de distinguer 0-0, « pas encore chargé » et « échec ». Correction : un squelette pendant le chargement et une ligne d'erreur avec « Réessayer ».
- [À vérifier] (1) L125-132 : la colonne de la minute fait 34 px fixes. « 90' » ou « 105' » à texte agrandi passe à la ligne.
- [Détail] (1) L52-54 : `ownIsHome` vaut « vrai » par défaut pendant le chargement. Les lignes se retournent quand l'info arrive.

### ML/widgets/match_live_add_player_sheet.dart
- [Détail] (4) L375-395 : les champs « Prénom » et « Nom » n'ont ni touche « Suivant/OK », ni validation par la touche Entrée, ni focus automatique sur l'onglet « Invité ». L'erreur est affichée globalement au-dessus du bouton (L194-204), pas sous « Prénom ».
- [Détail] (2) L14-31, L100-102, L206-210 : pendant l'envoi, seul le bouton ✕ est désactivé. Toucher à côté ferme la feuille : l'ajout aboutit, mais le message de confirmation (L21) ne s'affiche jamais. Le bouton grisé n'a pas de rond de chargement. Correction : bloquer la fermeture pendant l'envoi (PopScope / isDismissible: false) et mettre un spinner dans le bouton.
- [Détail] (4) L247-252 : le nom de famille n'est pas nettoyé (pas de trim) et un doublon d'invité (même prénom déjà connu) n'est pas signalé.
- [À vérifier] (1) L158-170 : la liste de l'effectif n'a ni recherche ni tri explicite (ordre du serveur). Elle peut être longue.
Bons points : marge de clavier (viewInsets), hauteur bornée, « Réessayer » sur échec de chargement, message d'état vide clair.

### ML/widgets/match_live_clock.dart
- [À vérifier] (2) L62 : le chrono se calcule avec l'heure du téléphone (`DateTime.now()`) contre un horaire serveur. Un téléphone mal réglé affiche un chrono décalé chez les spectateurs (aucune correction d'écart).
- [Détail] (3) L86 : « 12:03 » est lu tel quel par un lecteur d'écran, sans « 12 minutes 3 secondes ».

### ML/widgets/match_live_notification_bell.dart
- [Détail] (3) L118-139 : une couche Semantics enveloppe un IconButton qui a déjà une infobulle, donc l'annonce risque d'être doublée. La cloche inactive (grise) ressemble à un bouton désactivé.
Bons points : drapeau « en cours », vérifications `mounted`, messages clairs pour les deux états.

### ML/widgets/match_live_remove_player_sheet.dart
- [Détail] (3) L25-26 : pas de bouton « Annuler » visible, seulement la poignée. La feuille « buteur » en a un, avec un commentaire qui explique ce besoin (scorer_picker L39-41). Sur ordinateur, on ne ferme qu'en cliquant à côté.
- [Détail] (2) L82 : « Retirer X ? » utilise une espace normale avant le « ? » (les autres écrans emploient l'espace insécable) et ne dit pas que le joueur reste ré-ajoutable.

### ML/widgets/match_live_scorer_picker_dialog.dart
- [À vérifier] (3) L84-96 : liste alphabétique mélangeant terrain et banc, sans photo ni nom de famille. Deux joueurs au même prénom (en mode « prénoms seuls ») se confondent. Correction : titulaires d'abord, ajouter l'initiale du nom.
- Bons points : bouton « Annuler » visible, retour `null` bien distingué des choix « CSC » et « Effacer ».

### ML/widgets/substitution_salvo_frame.dart
- [Détail] (3) L7-20 : 12 couleurs dont plusieurs proches (bleu/indigo/cyan, orange/jaune, citron/vert clair). L'encadré ne se distingue que par la couleur. Le repère chiffré aide.

---

## season_wrapped

### SW/season_wrapped_button.dart
- [Détail] (3) L63-70 : la pastille « A » (11 px) n'est pas expliquée. De plus, la branche « aperçu admin » (L25, L77) n'est plus atteignable : `SeasonWrappedEntryButton` ne crée ce bouton que si un vrai bilan est disponible. Le commentaire L14-16 ne décrit donc plus la réalité.
- [Détail] (3) L30-40 : icône seule (étoile), sans libellé visible. L'infobulle n'existe pas au toucher.
- [À vérifier] (3) L35 : taille minimale 40 px, sous 44 px.

### SW/season_wrapped_entry_button.dart — rien à signaler (lu en entier)

### SW/season_wrapped_page.dart
- [Bloquant] (3) L476-493, L411-451 : le bilan défile seul (6,8 s puis 5,6 s par écran) et le changement d'écran ne se fait que par des GestureDetector, qui ne sont pas focalisables. Aucune touche ← → / Espace / Échap, aucun bouton « Suivant / Précédent / Pause » accessible. Effet : au clavier, avec un lecteur d'écran ou un contacteur, impossible de revenir en arrière, de faire pause ou de lire à son rythme. Ce n'est bloquant que pour ces utilisateurs. Correction : ajouter des raccourcis clavier et des boutons « Précédent / Suivant / Pause » avec libellés.
- [Gênant] (3) L173, L417 : le réglage système « réduire les animations » coupe fondus et compteurs, mais pas l'avance automatique des écrans. Correction : avec ce réglage, ne pas avancer seul.
- [Gênant] (3) L244-256 : la pause ne se fait que par appui long, sans indice. Les légendes apparaissent après 1,4 s (slides L217) et l'écran suivant arrive après 5,6 s : il reste environ 4 s pour lire 60 à 90 caractères en gros. Correction : bouton pause visible et durée adaptée à la longueur du texte.
- [Gênant] (2) L59-63 : l'erreur de chargement dit « Réessaie plus tard », sans bouton « Réessayer », et l'erreur est avalée (aucun journal). Correction : bouton qui relance `mySeasonWrappedProvider`.
- [Gênant] (2) L271-293 : toute panne de partage donne « L'image n'a pas pu être préparée », même quand l'image est prête mais que le navigateur ne sait pas partager un fichier (ordinateur, certains navigateurs). Il n'y a aucune alternative « Télécharger l'image » et aucun retour visible pendant la capture. À vérifier sur ordinateur et sur iPhone en PWA.
- [À vérifier] (2) L470-496 : la couche de gestes couvre tout l'écran, alors que le commentaire (L471) dit que la zone basse est libre. Sur la dernière page, le tiers gauche des boutons « Partager ma saison » et « Partager par thème » risque de déclencher « écran précédent » au lieu du bouton (le tap du tiers gauche est toujours capté). À vérifier à l'écran.
- [À vérifier] (2) L203-211, L215 : la musique démarre à l'ouverture (si elle n'a pas été coupée avant), ce qui peut surprendre en public. Aucune réaction à un onglet ou une appli passée en arrière-plan : le son et le chronomètre peuvent continuer ou sauter.
- [Détail] (3) L534-570 : la barre de progression (3 px) n'a pas de libellé « écran 3 sur 10 » pour un lecteur d'écran.
- [Détail] (1) L339-374 : la feuille « Partager une partie » est une colonne non défilante avec des sous-titres de 12 px. À 160 % de texte ou en paysage, risque de débordement. À vérifier.
- [Détail] (3) L349, L362, L607 : textes de 10 à 12 px (« APERÇU · CHIFFRES D'EXEMPLE » à 10 px).
- [Détail] (2) L84-99 : l'écran de chargement n'a pas de bouton « Fermer » (seulement l'accueil du club).

### SW/season_wrapped_share_sheet.dart
- [Détail] (2) L86-90 : l'habillage est choisi d'après le texte du titre (« Ma présence », « Mon apport »). Si un titre change, l'image sort silencieusement avec l'habillage par défaut.
- [À vérifier] (1) L214-217 : 9 lignes denses (12 px) dans une image de 450 px de haut. À vérifier au rendu.
Bon point : la feuille est dessinée hors écran avec une taille de texte fixée, donc l'image est identique sur tous les téléphones.

### SW/wrapped_ink_pitch.dart
- [Détail] (3) L43-52 : le terrain est un simple dessin sans description. Les pourcentages par poste ne sont pas lisibles par un lecteur d'écran. Correction : un Semantics avec « Gardien 60 %, Défenseur 40 % ».
- [Détail] (2) L124-126 : un poste absent de la table des positions est ignoré en silence, alors que le texte « LE PLUS SOUVENT » le nomme.
- [À vérifier] (1) L149-151 : le pourcentage dans le disque fait environ 12 px pour les petits disques, et ne suit pas l'agrandissement du texte.

### SW/wrapped_motion.dart
- [Gênant] (3) L70, L203-250 : le chiffre qui monte est un texte animé sans libellé final. Un lecteur d'écran peut lire une valeur intermédiaire (« 7 » au lieu de « 37 »), et pendant le fondu (Opacity à 0) le contenu est retiré de l'arbre d'accessibilité (environ 1,4 s). Correction : envelopper de Semantics(label: valeur finale).
Bon point : toutes les animations de ce fichier respectent « réduire les animations ».

### SW/wrapped_slides.dart
- [Gênant] (1) L129-131, L137-145, L439 : aucune largeur maximale. Sur ordinateur ou tablette, un chiffre de 180 px reste collé à gauche et la légende de 30 px s'étire sur toute la fenêtre, avec un terrain figé à 268 px. À vérifier à l'écran sur ordinateur. Correction : centrer le contenu dans une colonne de 480 px.
- [À vérifier] (1) L131, L147 : le haut (74 px) et le bas (40 px) sont fixes, et le titre et la légende sont hors de la zone défilante (seul le milieu défile). À 160 % de texte sur petit téléphone (hauteur de 600 px ou moins), la légende (30 px × 160 %) et le titre peuvent rogner le chiffre ou déborder.
- [Détail] (2) L638-699 : pendant le chargement de l'armoire, « et N autres » s'affiche sous une grille vide (`restants` vaut alors le total), puis les vignettes apparaissent. Si plus de 6 badges n'ont pas de vignette, « et N autres » est faux (L639 soustrait tous les badges sans vignette, L684 n'en affiche que 6).
- [Détail] (3) L242-245, L316 de wrapped_theme : le rang s'affiche « 3E » sans dire de quoi il s'agit (classement parmi qui ?), et se lit mal au lecteur d'écran. Correction : « 3e de l'effectif ».
- [À vérifier] (1) L779-789 : le nom d'un badge dispose de 38 px pour 2 lignes. À 160 % de texte, il déborde sur la rangée suivante.
- [À vérifier] (1) L200-209 : le chiffre qui monte est dans un FittedBox. Sa taille change quand un chiffre s'ajoute pendant le comptage.
- [Détail] (3) L507-511 : les colonnes « V / N / D » n'ont pas de légende dans la colonne (seulement dans la phrase du bas).

### SW/wrapped_theme.dart
- [À vérifier] (3) L125-169 : tout le texte est en Oswald graisse 300 (très fine), y compris à 15 px, parfois sur motif de points. Les couleurs sont bonnes (#93A0AD sur #0B0F14 ≈ 7:1), mais la finesse nuit à la lecture au soleil ou sur petit écran.

---

## Fichiers lus en entier (24 sur 24)
ML : match_live_pilot, match_live_pre_kickoff_page, match_live_providers, match_live_running_journal, match_live_running_page, match_live_running_widgets, match_live_tab, widgets/live_bench_tile, widgets/live_substitution_line, widgets/match_faits_du_match_card, widgets/match_live_add_player_sheet, widgets/match_live_clock, widgets/match_live_notification_bell, widgets/match_live_remove_player_sheet, widgets/match_live_scorer_picker_dialog, widgets/substitution_salvo_frame.
SW : season_wrapped_button, season_wrapped_entry_button, season_wrapped_page, season_wrapped_share_sheet, wrapped_ink_pitch, wrapped_motion, wrapped_slides, wrapped_theme.

## Fichiers NON lus ou lus en partie
Aucun dans le groupe. Pour juger certains points, j'ai seulement consulté (non audités) : app_theme.dart (thème sombre, couleurs), match_live_session.dart (calcul du chrono), match_lineup_page.dart (présence d'un RefreshIndicator). Les composants externes appelés (MatchSquadEditor, FormationPitchEditor, PlayerAvatar, PfEmptyState, BadgeEmblem, CalendarTeamName) n'ont pas été lus.

## Top 5 des motifs répétés
1. Actions du direct sans retour visible ni verrou anti double appui (score +/−, pause, mi-temps, glisser-déposer, ajout) ; l'erreur n'est signalée que par un message générique.
2. Chargement/erreur avalés ou réduits à une phrase sans « Réessayer » (onglet Live, Faits du match, bilan indisponible, « Composition indisponible », droits coach/admin).
3. Taille du texte plafonnée ou fixe : spectateur à 100 %, minute à 34 px, nom de badge à 38 px, haut et bas du bilan fixes, textes de 10 à 12 px.
4. Accessibilité du bilan : navigation uniquement au geste, avance automatique non désactivable, compteurs sans libellé final, dessin du terrain sans description.
5. Gestes non expliqués (appui long pour glisser un joueur, appui long pour mettre en pause le bilan, zone « Choisir le buteur » sans signe d'action).

## Bons points notables
- Live : message de lecteur d'écran complet sur les remplacements (flèches en plus de la couleur) ; boîtes de confirmation pour fin de match, reset et suppression, avec fermeture à côté traitée comme une annulation ; feuille « buteur » et « passe » qui distingue « fermé » de « aucune passe » ; cloche avec drapeau « en cours » et vérifications `mounted` ; feuille d'ajout de joueur qui gère clavier, erreurs et réessai ; reprise automatique de la place de pilote.
- Bilan : respect de « réduire les animations » pour les fondus et compteurs, fonctions de capture robustes (hors écran, taille de texte fixée), états vides rédigés avec soin (« Aucun match joué », « Aucun badge cette saison »), aperçu admin clairement signalé.
