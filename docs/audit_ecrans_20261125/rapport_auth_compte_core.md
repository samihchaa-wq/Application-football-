# Audit UX/UI — groupe « auth / compte / notifications / partagés / app / thème »

Lecture seule, jugé par le code (aucun appareil). Tout est lu en entier (liste en fin de rapport).
Les éléments déjà connus (bandeau notifications rouge, `'$error'` brut, `_error` en bas, textes 10-11 px, largeurs fixes admin/calendrier…) ne sont pas répétés, sauf quand un nouvel écran est touché.

## A. Défauts à fort effet (composants partagés, ils se répercutent sur beaucoup d'écrans)

- [Gênant] (axe 2) core/widgets/pf_loader.dart L68, L108, L160 + pf_skeleton.dart L24 : `PfLoader.*`, `PfSkeleton.*`, `PfProgressIndicator()` (indéterminé) et `PfLinearProgressIndicator()` (indéterminé) ne dessinent RIEN (`SizedBox.shrink`). 17 usages de PfLoader/PfSkeleton et 60 de PfProgressIndicator dans l'appli. → Partout où l'écran attend des données, l'utilisateur voit du vide, sans pouvoir distinguer « ça charge », « c'est vide » et « c'est planté » ; les libellés d'accessibilité (`semanticLabel`) sont aussi perdus. Les pages qui s'appuient dessus : écran d'attente après connexion (« Préparation de ton espace… » n'est même pas affiché), chargement d'une page admin différée (deferred_route_page.dart L58 : écran vide), historique des notifications, indisponibilités, boutons « en cours » (l'icône disparaît, seul le libellé change). → Au minimum afficher un texte « Chargement… » discret (sans animation) avec un `Semantics(liveRegion)`, ou un squelette statique.
- [Gênant] (axe 2) app/router/app_router.dart L103-113 : le routeur n'a ni `errorBuilder` ni `errorPageBuilder`. → Une adresse inconnue (vieux favori, faute de frappe, lien tronqué) affiche la page d'erreur par défaut de go_router, en anglais, sans style ni bouton vers le calendrier. → Ajouter une page « Page introuvable » avec bouton « Retour au calendrier ».
- [Gênant] (axe 2) app/router/initial_app_location_parser.dart L21-32 + L81-92 : un lien de réinitialisation expiré ou déjà utilisé arrive avec `#error=access_denied&error_code=otp_expired` ; `_isSuccessfulPasswordRecoveryHash` répond non, la route retombe sur `/matches`, puis le routeur envoie vers la connexion. → La personne arrive sur l'écran de connexion sans aucune explication (« mon lien ne marche pas » sans message). → Détecter `error=` dans le fragment et ouvrir une page « Lien expiré, demande-en un nouveau » (le texte existe déjà dans forced_password_change_page.dart L75-77).
- [Gênant] (axe 4/1) core/theme/app_theme.dart L415-455 : champs de saisie « remplis » de la même couleur que les cartes (fond `surface` sur carte `surface`) avec un contour au repos à ~1,6:1 de contraste (calcul : contour #6B7885 à 38 % sur #141A22). → Sur fond sombre, on devine à peine où taper ; sous le seuil 3:1 des composants d'interface. Touche tous les formulaires. → Contour au repos plus clair (alpha ≥ .7) ou fond de champ plus clair que la carte.
- [Gênant] (axe 3) core/widgets/pf_secondary_tabs.dart L17, L47-48, L86 : sous-onglets de 36 px de haut avec `tapTargetSize.shrinkWrap`, police fixe 12,5 px, `maxHeight` 36. → Zone à toucher < 44 px (la règle générale « padded » de app.dart L169 est annulée ici) ; à texte agrandi, un libellé qui passe sur 2 lignes est coupé. Utilisé par Indisponibilité, Statistiques, etc. → minimum 44 px de zone tactile, hauteur élastique.
- [Gênant] (axe 3) core/widgets/sticky_header_table.dart L447-519 : la colonne triée n'est signalée que par la couleur du libellé « sans flèche » ; le sens (croissant/décroissant) n'est lu que par les lecteurs d'écran. → Pour une personne qui voit, impossible de savoir dans quel sens le tableau est trié ni (daltonisme) quelle colonne est active. → Ajouter une petite flèche ▲/▼.
- [Gênant] (axe 3) core/widgets/calendar_scoreline.dart L69-86, match_fixture.dart L36-53 : le résultat (victoire/nul/défaite) n'est porté que par la couleur du score (vert/orange/rouge) ; le libellé d'accessibilité dit seulement « Nom 3, Nom 4 ». → Information perdue pour les daltoniens et les lecteurs d'écran. → Ajouter « Victoire/Nul/Défaite » dans le libellé et un signe visible (V/N/D) à côté.
- [Gênant] (axe 3) core/widgets/calendar_scoreline.dart L695-699 (+ match_detail_header_card.dart L177-183) : l'adresse du match est cliquable mais c'est un `InkWell` posé sur une ligne de texte de 12 px, sans icône ni soulignement. → Zone à toucher d'environ 15 px de haut, rien n'indique qu'on peut toucher, le lecteur d'écran n'annonce pas « Ouvrir l'itinéraire ». → Zone ≥ 44 px, icône « lieu » + `Semantics(button, label: "Itinéraire vers …")`.
- [Gênant] (axe 3) core/widgets/pf_app_bar.dart L61-64 : l'écusson « Retour au calendrier » est un `GestureDetector`. → Pas atteignable au clavier (Tab), pas d'info-bulle ; seul un lecteur d'écran peut l'activer. → `InkWell`/`IconButton` avec focus visible.
- [À vérifier] (axe 1) app/shell/app_shell.dart L415-427 : libellés de la barre du bas à 17 px (Oswald, espacement .6) dans un bouton de ~160 px (360 px d'écran), texte agrandi jusqu'à 160 % (app.dart L183). → « Statistiques » sera probablement tronqué par « … » dès ~130 % de texte. → Réduire la police ou autoriser 2 lignes ; vérifier sur téléphone 360 px à 130 % et 160 %.
- [À vérifier] (axe 1) app/app.dart L191-225 : les bandeaux du haut (connexion perdue, club, notifications) sont posés dans un `SafeArea` AU-DESSUS du navigateur, mais le navigateur reçoit toujours la marge « encoche » dans son `MediaQuery`. → Quand un bandeau est visible sur téléphone à encoche (iPhone), la barre de chaque page rajoute probablement une 2e fois la marge du haut (bande vide sous le bandeau). → Vérifier à l'écran ; sinon retirer la marge du `MediaQuery` sous les bandeaux.
- [Détail] (axe 1) app/app.dart L181 : `MediaQuery.of(context)` dans le `builder` global. → Chaque image de l'animation du clavier reconstruit le cadre de l'application (bandeaux compris). → `MediaQuery.textScalerOf` + `copyWith` ciblé, ou `MediaQuery.withClampedTextScaling`.
- [Détail] (axe 3) app/app.dart L179-184 : le texte est plafonné à 160 % (plancher 110 %). → Une personne qui règle son système à 200 % reste à 160 % (WCAG 1.4.4 demande 200 %). → Relever le plafond à 2,0 et corriger les écrans qui cassent.
- [Détail] (axe 3) aucune page ne définit son titre : aucun `Title(...)` dans lib/ (recherche faite). → Sur le web, tous les onglets et toutes les entrées d'historique s'appellent pareil ; les lecteurs d'écran n'annoncent pas le changement de page (WCAG 2.4.2). → `Title(title: 'Profil – Petit Filet', …)` dans chaque page principale.
- [Détail] (axe 1) core/theme/app_spacing.dart L9 : marge latérale standard 8 px. → Contenu très près des bords (zone de geste « retour » iOS, ombres des cartes rognées). → 12-16 px sur téléphone.
- [Détail] (axe 3) core/theme/app_theme.dart L222 : un seul thème sombre (nommé `light`), aucune prise en compte de `prefers-color-scheme`. → Pas de thème clair en plein soleil. → À décider (choix produit).

## B. Détail par fichier

### lib/features/auth/presentation/auth_register_page.dart
- [Gênant] (axe 4) L74-77, L88-161 : toutes les erreurs de saisie passent par un `SnackBar` unique, aucun champ n'est marqué en erreur et le focus n'est pas envoyé au premier champ fautif. → Sur un formulaire de ~10 champs, le message disparaît en quelques secondes et on ne sait pas quel champ corriger. → `errorText` par champ + focus sur le premier fautif.
- [Gênant] (axe 2) L201-206 : `_showError` (donc `ScaffoldMessenger.of(context)`) est appelé dans les `catch` après un `await` sans test `mounted`. → Si la personne quitte la page pendant l'envoi, exception au lieu d'un retour propre. → `if (!mounted) return;` avant.
- [Gênant] (axe 2/4) L190-200 : après la fenêtre « Compris », on va sur la connexion sans pré-remplir l'identifiant que l'on vient de montrer. → La personne doit retaper un identifiant généré qu'elle a peut-être oublié de copier. → Passer l'identifiant en paramètre (`/auth/sign-in?u=…`) et le pré-remplir.
- [Détail] (axe 4) L245-255 : le code d'invitation « 8 lettres ou chiffres » n'a ni limite de longueur, ni filtre (espaces, tirets collés), ni `helperText`. → Code collé avec un espace → message d'erreur seulement à la fin. → `inputFormatters` (majuscules, 8 max) + aide.
- [Détail] (axe 4) L259-290, core/widgets/pf_adaptive_form.dart L23 : trois champs en 2 colonnes serait bancal ; en pratique `PfAdaptiveForm` ne passe jamais en 2 colonnes ici (carte 760 px − 2×30 de marge = 700 px < seuil 720). → Sur ordinateur, formulaire étiré en une seule colonne. → Abaisser le seuil ou élargir la carte.
- [À vérifier] (axe 1) L224-242 : `SegmentedButton` « Rejoindre un club / Créer un club » avec icônes, sans `expandedInsets`, sur 320 px et texte agrandi. → Risque de libellés coupés ou de débordement. → Tester à 160 %.
- [Détail] (axe 4) L342-384 : champs mot de passe sans indication « obligatoire » ; message de politique de mot de passe long (helperMaxLines 4) qui pousse le bouton. → Acceptable ; envisager un indicateur de force.

### lib/features/auth/presentation/forced_password_change_page.dart
- [Gênant] (axe 2) L33-49, L70-88, L229-238 : lien de réinitialisation invalide/expiré → un message rouge s'affiche sous le bouton, mais aucun bouton « Retour à la connexion » ni « Redemander un lien ». La page `new-password` n'a pas non plus de « Se déconnecter ». → Impasse : le seul moyen de sortir est de modifier l'adresse à la main. → Ajouter « Retour à la connexion » (et « Se déconnecter » pour le mot de passe provisoire).
- [Gênant] (axe 4) L92-107 vs L229 : erreurs de règle de mot de passe en `SnackBar`, erreurs serveur en texte rouge sous le bouton (hors écran sur petit téléphone, clavier ouvert). → Deux endroits différents pour le même type de message. → Un `errorText` sous le champ concerné.
- [Détail] (axe 4) L174-209 : aucun `textInputAction` (« Suivant » sur le 1er champ). → Le clavier n'enchaîne pas vers la confirmation. → `TextInputAction.next` / `done`.
- [Détail] (axe 3) L229-238 : le message d'erreur n'est pas dans une région « live ». → Un lecteur d'écran ne l'annonce pas. → `Semantics(liveRegion: true)`.
- [Détail] (axe 2) L117-124 : succès hors récupération → seul un `SnackBar` « enregistré » puis le routeur décide ; si la redirection tarde, la page reste affichée sans indication. → Acceptable ; prévoir un état « Redirection… ».

### lib/features/auth/presentation/auth_sign_in_page.dart
- [Gênant] (axe 2/4) L35-40 vs L66-73 : champs vides → `SnackBar` ; identifiants faux → bandeau en haut du formulaire. → Deux façons différentes de dire une erreur sur le même écran. → Tout dans le bandeau (ou sous les champs).
- [Gênant] (axe 1) L181-277 : `ForgotPasswordDialog` (et, de la même façon, `ContactEmailDialog` profile_page.dart L709, `DeleteAccountDialog` my_data_section.dart L138, la fenêtre « changer le mot de passe » profile_page.dart L540) : `AlertDialog` sans `scrollable: true`, avec un long paragraphe + un champ. → Sur petit téléphone, clavier ouvert (ou paysage), le contenu dépasse et les boutons « Envoyer/Annuler » deviennent inaccessibles (seule `RegistrationSuccessDialog` L47 a `scrollable: true`). → `scrollable: true` partout.
- [Détail] (axe 4) L247-256 : pas de `textInputAction.done`, pas de `autofocus`, e-mail non pré-rempli (même si la personne a déjà saisi quelque chose). → Un pas de trop. → Mettre le focus au champ à l'ouverture.
- [Détail] (axe 2) L137-153 : « Espace gestionnaire » (accès éditeur) proposé à tous les joueurs sur l'écran de connexion. → Bruit et confusion pour les joueurs. → Le cacher derrière un lien discret ou une adresse dédiée.
- [Détail] (axe 3) L75-84 : champs sans `AutofillGroup` local (couvert par celui de PfAuthSurface) ; pas de `keyboardType` identifiant. → Rien de bloquant.

### lib/features/auth/presentation/choose_club_page.dart
- [Gênant] (axe 2) L110-132 : si `claimClub` réussit mais que `refreshProfile` échoue, le `catch` affiche « Le rattachement au club a échoué ». → La personne réessaie alors qu'elle est déjà rattachée → erreur de doublon ou confusion. → Séparer les deux étapes et dire « Rattaché, mais le chargement a échoué : réessaie ».
- [Gênant] (axe 2) L257-261 : « Se déconnecter » appelle `signOut` sans confirmation ni retour ; en cas d'échec (`state.error = 'La déconnexion a échoué.'`) rien ne s'affiche sur cet écran (il n'affiche pas `authState.error`). → Bouton qui semble ne rien faire. → Afficher l'erreur d'auth ou un `SnackBar`.
- [Gênant] (axe 4) L82-99, L225-231 : erreurs groupées en bas (connu), et prénom/nom validés seulement par `length < 2` avec le message « Renseigne ton prénom et ton nom » (alors que l'inscription utilise `isValidPersonName`). → Message trompeur pour un nom d'une lettre ; règles différentes d'un écran à l'autre. → Réutiliser la même validation que l'inscription.
- [Détail] (axe 4) L166-212 : aucun `textInputAction`, aucun `autofillHints` (prénom/nom), pas de soumission au clavier. → Parcours clavier plus lent. → `next`/`done` + `onSubmitted`.
- [Détail] (axe 2) L251-255 : « Ouvrir la Console gestionnaire » proposé à tout compte sans club. → Un joueur y tombe et se perd. → Réserver aux comptes éditeur (`isPlatformOperator`).

### lib/features/auth/presentation/confirm_email_page.dart
- [Gênant] (axe 2) L40-57 : si `confirm` réussit puis `refreshProfile` échoue, le `catch` affiche « Confirmation impossible… Réessaie » ; le lien est pourtant déjà consommé. → Au « Réessayer », on obtient « Lien invalide » alors que l'adresse est confirmée. → Isoler l'erreur du rafraîchissement.
- [Gênant] (axe 2) L26-30, L32-58 : la confirmation part dès l'ouverture de la page ; un rechargement de page (F5) affiche « Lien invalide » même si c'était réussi. → Inquiète sans raison. → Mémoriser le succès (ou dire « déjà confirmée »).
- [Détail] (axe 3) L63-96 : le changement d'état (en cours → confirmé) n'est pas annoncé (`liveRegion`). → Lecteur d'écran muet. → `Semantics(liveRegion: true)`.
- [Détail] (axe 2) L98-110 : bouton « Se connecter » vers `/matches` (le routeur renvoie vers la connexion) ; correct mais détourné. → Pointer directement `/auth/sign-in`.

### lib/features/auth/presentation/consent_fields.dart
- [Gênant] (axe 4) L36-70 : âge et CGU sont obligatoires mais rien n'est signalé sur le champ (pas d'astérisque, pas de contour rouge) ; l'erreur n'arrive qu'à l'envoi, par `SnackBar` ou texte global. → On ne sait pas pourquoi « Créer » est refusé. → Mettre en rouge le groupe manquant.
- [Détail] (axe 4) L38-40 : si `enabled` est faux, la case radio garde son aspect actif (le tap est juste ignoré). → Aspect trompeur pendant l'envoi. → `onChanged: null` pour griser.
- [Détail] (axe 1) L86-108 : jusqu'à 4 `TextButton` « Lire … » dans un `Wrap`. → Long bloc de liens en création de club. → Regrouper en un seul « Lire les documents ».

### lib/features/auth/presentation/accept_updated_terms_page.dart
- [Gênant] (axe 4) L94, L140-151 : bouton « Accepter et continuer » grisé tant qu'âge et case ne sont pas cochés, sans phrase d'explication. → On ne comprend pas ce qui manque. → Texte « Coche la case et indique ton âge » sous le bouton.
- [Détail] (axe 2) L165-170 : « Me déconnecter » sans confirmation ni affichage d'erreur en cas d'échec. → Silencieux. → Idem choose_club.
- [Détail] (axe 4) L125-129 : « Version du 2026-11-20 » (format technique). → Pas du français. → « Version du 20 novembre 2026 ».
- [Détail] (axe 2) L60-66 : si le profil rechargé porte encore l'ancienne version, la page reste sans message. → Impasse silencieuse (cas rare). → Afficher « Réessaie » si la version n'a pas changé.

### lib/features/auth/presentation/registration_success_dialog.dart
- [Détail] (axe 2) L55-67 : l'identifiant à retenir est la seule chose à garder et la fenêtre se ferme sans exiger de copie ; le bouton « Copier » annonce bien le résultat (L68-69, point positif). → Voir le pré-remplissage proposé dans auth_register_page. → Idem.

### lib/features/auth/presentation/sign_out_confirmation.dart — rien à signaler (lu en entier). (Remarque : les 3 autres boutons « Se déconnecter » — choose_club L257, auth_loading L88/L159, accept_terms L165 — n'ont pas cette confirmation : incohérence mineure.)

### lib/features/auth/presentation/legal_document_page.dart
- [Gênant] (axe 2) L53-56 : « autre document » utilise `context.go`, qui remplace la pile ; ensuite `canPop()` est faux et la flèche retour envoie vers la connexion (L20-24). → En pleine inscription, ou connecté qui lit les nouvelles CGU, on perd sa place (formulaire vidé, retour à la connexion). → `context.pushReplacement` (ou `push`).
- [Détail] (axe 1) L31-60 : `ListView` plein écran sans largeur maximale. → Sur ordinateur, lignes de 1 500 px illisibles. → `ConstrainedBox(maxWidth: ~720)`.
- [Détail] (axe 3) L35 : titres de section sans `Semantics(header: true)`. → Navigation par titres impossible au lecteur d'écran.
- [Détail] (axe 1) L43-46 : « Version du 2026-… » format technique (idem accept_terms).

### lib/features/auth/presentation/auth_loading_page.dart
- [Gênant] (axe 2) L105-113 : tant que la session se résout, la page montre `PfLoader.page(message: 'Préparation de ton espace…')`, qui ne dessine rien (voir A). → Écran vide jusqu'à 15 s (délai de secours d'auth_state L133), sans bouton de sortie. → Texte visible + « Se déconnecter » après quelques secondes.
- [Gênant] (axe 2) L143-157 : « Vérifier maintenant » (compte en attente) relance la requête mais ne dit rien du résultat (spinner invisible + pas de message « toujours en attente »). → On ne sait pas si on a cliqué pour rien. → Message court « Toujours en attente » après la réponse.
- [Gênant] (axe 2) L88-95, L159-165 : « Se déconnecter » sans retour en cas d'échec (l'erreur d'auth n'est pas affichée ici). → Bouton muet.
- [Détail] (axe 3) L40-141 : trois états très différents (chargement, erreur, attente) sans annonce `liveRegion` au changement. → Lecteur d'écran silencieux.
- [Détail] (axe 2) L116-141 : l'écran d'attente n'indique ni le club, ni qui contacter. → La personne ne sait pas à qui demander de valider. → Afficher le nom du club.

### lib/features/auth/presentation/auth_state.dart
- [Gênant] (axe 2) L63, L383-396, L423-426, L435-457 : un seul champ `error` partagé entre connexion, déconnexion, mot de passe, profil, photo. → Une erreur ancienne (ex. « Connexion temporairement indisponible ») peut s'afficher dans le Profil (profile_page.dart L361) ; les écrans qui ne l'affichent pas (choose_club, attente) perdent l'échec de déconnexion. → Erreurs par action (ou effacer à l'ouverture d'un écran).
- [Détail] (axe 2) L13, L363-365 : délai de connexion 12 s puis « Connexion temporairement indisponible » même pour un identifiant faux lent. → Message peu précis. → Distinguer délai dépassé / réseau.
- [Détail] (axe 2) L538-540 : `isAdminViewProvider` = `isRealAdminProvider` (doublon). → Non visible.

### lib/features/auth/presentation/widgets/email_verification_panel.dart
- [Détail] (axe 2) fichier entier : `EmailVerificationPanel` n'est utilisé nulle part (recherche faite hors du fichier). → Code mort, texte et comportements non testés à l'écran. → Supprimer ou brancher.
- Points positifs : compte à rebours « Renvoyer dans N s » explicite, `liveRegion` sur le message.

### lib/features/profile/presentation/profile_page.dart
- [Gênant] (axe 3/1) L286-320 : champ « Date de naissance » = `InkWell` posé sur un `Text` vide (ou la date) dans un `InputDecorator`. → Zone à toucher d'environ 20 px de haut ; l'icône calendrier (L294) n'est pas cliquable. → `InkWell` autour de tout le champ, hauteur ≥ 48 px.
- [Gênant] (axe 2) L615 : `updatePassword(result)` sans message de succès ; en cas d'échec, l'erreur n'apparaît que dans le cadre rouge tout en bas de la page (L361-398). → On ne sait pas si le mot de passe a changé ; l'erreur est souvent hors écran. → `SnackBar` « Mot de passe modifié » / erreur.
- [Gênant] (axe 2) L522-530, L512-520 : après l'envoi du lien de confirmation d'e-mail, la page n'est pas rafraîchie : le bouton continue de dire « Ajouter une adresse e-mail » au lieu de « E-mail à confirmer ». → On croit que ça n'a pas marché. → `refreshProfile()` après la fermeture de la fenêtre.
- [Gênant] (axe 2) L273-284, L324-326 : téléphone et date de naissance désactivés tant que `fetchPrivateDetails` n'a pas répondu ; en cas d'échec, le texte dit « indisponibles » sans bouton « Réessayer ». → Champs gelés jusqu'au rechargement de la page. → Bouton « Réessayer ».
- [Gênant] (axe 1) L118-125 : `ListView` plein écran sans largeur maximale (le shell limite à 1 080 px, mais c'est encore très large pour 5 champs). → Champs de 1 000 px sur ordinateur. → `maxWidth` ~560 px.
- [Gênant] (axe 2) L535-616 : `TextEditingController` libérés (L612-613) juste après le `await showDialog`, alors que la fenêtre joue encore son animation de fermeture. → Risque d'erreur « controller utilisé après dispose » (surtout en mode debug) ; à tester. Aucun état « en cours » dans la fenêtre. → Laisser la fenêtre posséder ses contrôleurs (StatefulWidget).
- [Détail] (axe 4) L540-571 : champs de la fenêtre sans `textInputAction`/`onSubmitted` ; la confirmation n'a pas d'`autofillHints`. → Entrée ne valide pas.
- [Détail] (axe 4) L575-583 : erreur de la fenêtre affichée en texte libre sous les champs, pas en `errorText`. → Non rattachée au champ.
- [Détail] (axe 4) L246, L257, L268, L281 : l'erreur d'un champ reste affichée tant qu'on n'a pas ré-enregistré (pas d'effacement à la frappe). → Message périmé. → Effacer à `onChanged`.
- [Détail] (axe 4) L277-284 : téléphone sans `inputFormatters` ni `onSubmitted` (alors que `textInputAction.done`). → « OK » du clavier ne fait rien.
- [Détail] (axe 3) L158-181 : bouton appareil photo de 32 px (padding 8 + icône 16) ; le lien « Changer ma photo » en dessous compense. → Petit, mais doublé.
- [Détail] (axe 2) L417-419 : `pickImage`/`readAsBytes` sans `try/catch` (permission refusée, fichier illisible). → Exception muette. → Message « Photo illisible ».
- [Détail] (axe 2) L350-360 : bouton « Enregistrer les modifications » sans changement de libellé en cours (seule l'icône disparaît, invisible : voir A). → Pas de retour visible. → « Enregistrement… ».
- [Détail] (axe 2) L37, L389 : `_localError` n'est jamais renseigné (toujours `null`). → Code mort.
- [Détail] (axe 2) L661-760 : (`ContactEmailDialog`) `'$error'` brut déjà connu (L699) ; fenêtre non défilable (voir auth_sign_in).
- [À vérifier] (axe 1) L113-116 : mise en page « compacte » si hauteur < 700 px (téléphone en paysage, petit écran) : marges et tailles changent. → Tester le rendu à 568 px de haut.

### lib/features/profile/presentation/my_data_section.dart
- [Gênant] (axe 2) L33-54 : l'export réussi ne donne aucun retour ; sur navigateur de bureau, `Share.shareXFiles` peut ne rien proposer ; l'échec dit « n'ont pas pu être préparées » même si le partage a été refusé. → On ne sait pas si le fichier a été enregistré. → « Fichier prêt » + repli par téléchargement direct.
- [Détail] (axe 4) L151-157 : champ de confirmation sans `autofocus`, sans `onSubmitted`. → Il faut toucher le champ puis le bouton ; Entrée ne valide pas.
- [Détail] (axe 2) L102-110 : le bouton « Supprimer mon compte » reste discret (bon) ; la confirmation par mot à recopier est solide (point positif).

### lib/features/unavailability/presentation/unavailability_page.dart
- [Gênant] (axe 2) L84-86, L118-129 : `ref.invalidate(...)` après un `await` dans un `ConsumerWidget` sans vérifier que l'écran existe encore. → Si on quitte pendant l'annulation, exception Riverpod. → Passer en `ConsumerStatefulWidget` + `mounted`.
- [Gênant] (axe 2) L89-115, L265-269 : le bouton de carte « Annuler » (supprimer la période) porte le même mot que les boutons « Annuler » ordinaires ; la fenêtre répond « Garder » / « Annuler la période ». → Risque de se tromper de bouton. → « Supprimer cette période » + « Conserver ».
- [Gênant] (axe 2) L139-141, L326-327 : chargement = `PfProgressIndicator` invisible (voir A). → Page vide pendant la requête. → Texte/ squelette.
- [Détail] (axe 1) L156-161, L339-344 : actualisation par tirage vers le bas seulement. → Sur ordinateur, aucun bouton « Actualiser » (sauf en erreur). → Bouton discret dans la barre.
- [Détail] (axe 3) L287-316 : pastille d'état « Terminée » (gris `textFaint` sur fond 14 % de la même couleur), « À venir » (`primaryBright` 14 %). → Contraste probablement < 4,5:1. → À mesurer à l'écran.
- [Détail] (axe 2) L318-361 : liste admin « Équipe » sans filtre ni tri visible (en cours / à venir / terminées mélangées ?). → Longue liste difficile à lire. → Regrouper par état.
- [Détail] (axe 2) L120-128 : aucun retour pendant l'annulation (bouton déjà fermé) ; succès par `SnackBar`. → Correct mais la carte reste affichée jusqu'au rechargement.

### lib/features/unavailability/presentation/unavailability_form_sheet.dart
- [Gênant] (axe 2) L17-22, L95-103 : la feuille est fermable (glisser, toucher à côté) pendant l'enregistrement ; au succès, `navigator.pop(true)` s'exécute sans test `mounted`. → Si la feuille est déjà fermée, ce `pop` ferme la PAGE Indisponibilité en dessous, et la liste n'est pas actualisée. → `isDismissible: false` pendant `_saving` (PopScope) + test `mounted`.
- [Détail] (axe 1) L123 : `MediaQuery.of(context).viewInsets` (connu) ; la feuille s'ouvre dans l'écran du shell, déjà redimensionné par le clavier. → À vérifier : double marge possible sur téléphone.
- [Détail] (axe 4) L147-164 : pas de `textInputAction`, pas de focus automatique sur « Raison ». → Un pas de plus.
- [Détail] (axe 4) L55-77 : en modification d'une période déjà commencée, le sélecteur « Du » ne propose pas la date passée de début (`firstDate` = aujourd'hui). → Date d'origine non re-sélectionnable. → `firstDate = min(aujourd'hui, début actuel)`.
- [Détail] (axe 2) L202-205 : pas de retour de succès (seulement la fermeture). → Acceptable ; ajouter « Enregistrée ».
- [Détail] (axe 3) L228-237 : `_DateField` ne devient pas grisé quand `onTap` est nul (pendant l'envoi). → Aspect actif mais inerte.

### lib/features/notifications/presentation/notification_history_view.dart
- [Gênant] (axe 2) L80-85, L141-152 : si l'actualisation échoue alors que la liste est déjà affichée, `_error` est renseigné mais jamais montré (l'erreur n'apparaît que quand `entries == null`). → Le tirage vers le bas semble ne rien faire. → `SnackBar` d'erreur à l'actualisation.
- [Gênant] (axe 3) L216-246 : « non lue » = fond teinté + pastille ; le libellé d'accessibilité ne le dit pas (pas de `Semantics`). → Information perdue pour lecteur d'écran et daltoniens (la pastille est transparente une fois lue). → « Non lue » dans le libellé.
- [Détail] (axe 2) L88-108 : suppression immédiate, sans confirmation ni « Annuler » ; l'échec restaure bien la ligne (point positif). → Suppression irréversible mais peu grave. → `SnackBar` « Supprimée — Annuler ».
- [Détail] (axe 2) L72-79, L67-71 : ouvrir l'écran marque TOUT comme lu même si on n'a vu que les premières lignes. → Info « combien en manquent » perdue. → Marquer comme lu au fil de l'affichage ou à la sortie.
- [Détail] (axe 3) L275-283 : bouton de suppression compact (40 px) en gris `textFaint`. → Petit et peu contrasté. → 44-48 px.
- [Détail] (axe 2) L184-186, L228-229 : lignes sans lien (`onTap` nul) ont le même aspect que les lignes cliquables. → On touche sans effet. → Chevron sur les lignes cliquables.
- [Détail] (axe 1) L169-189 : liste pleine largeur (borne à 1 080 px par le shell). → Lignes très larges.

### lib/features/notifications/presentation/push_device_banner.dart
- [Gênant] (axe 2) L71-74, L124-127 : « Non merci » enregistre un refus définitif sans dire où le réactiver. → La personne ne sait plus comment les remettre. → `SnackBar` « Tu pourras les activer dans la cloche → Paramètres ».
- [Gênant] (axe 2) L76-79, L167-170 : le bouton « Plus tard » écrit `writeInstallHintDismissed(true)` : renoncement définitif sous un libellé temporaire. → Libellé trompeur (à confirmer côté stockage : pas de date de retour visible ici). → Renommer « Masquer » ou réafficher après N jours.
- [Détail] (axe 2) L50-51, L72-73 : `ref.invalidate` avant le test `mounted` ; `writePushOptOut` sans `try/catch`. → Possible exception si l'écran est quitté / stockage bloqué.
- [Détail] (axe 2) L229-366 : guide d'installation Android décrit seulement Chrome ; sortie « dismissed » de `pushPromptInstall` sans retour (L213-217). → Autres navigateurs oubliés.

### lib/features/notifications/presentation/notification_inbox_button.dart
- [Détail] (axe 3) L37, L115-125 : bouton 40 px (élargi à 48 par `materialTapTargetSize.padded`), chiffre de la pastille 11 px non agrandissable (`TextScaler.noScaling`). → Texte < 12 px (connu), mais ici volontaire. → 12 px.
- [Détail] (axe 3) L63-68 : point d'avertissement ambre (appareil muet) uniquement par la couleur ; le libellé d'accessibilité le dit (point positif).

### lib/features/notifications/presentation/notifications_page.dart
- [Gênant] (axe 2) L197-200, L404-407 : en cas d'erreur de chargement des préférences, simple texte « Impossible de charger… » sans bouton « Réessayer ». → Seul le tirage vers le bas relance (inexistant à la souris). → Bouton « Réessayer ».
- [Gênant] (axe 2) L207-231, L310-316 : chaque cloche enregistre une copie complète des préférences construite à partir d'un instantané ; deux réglages basculés coup sur coup partent chacun de l'ancienne valeur de l'autre. → Le 2e enregistrement peut annuler le 1er (à confirmer côté serveur : fusion ou remplacement ?). → Envoyer seulement le champ modifié.
- [Gênant] (axe 2) L489-573, L441-443 : le menu « Test » (17 types de notifications dont « Passage en convoqué », « Match annulé », « Nouveau compte en attente ») est visible par TOUS les joueurs, sans libellé explicatif. → Fonction technique exposée ; un joueur peut déclencher une fausse notification d'annulation sur son téléphone et se tromper. → Réserver aux admins ou à un mode développeur.
- [À vérifier] (axe 3) L548-552 : `OutlinedButton(onPressed: () {})` sous `IgnorePointer` à l'intérieur d'un `PopupMenuButton`. → Deux éléments focalisables : au clavier, Entrée sur le bouton intérieur ne fait rien. → Tester Tab + Entrée.
- [Détail] (axe 2) L694-698 : `ref.invalidate` avant `if (!mounted)`. → Exception possible si on quitte pendant la demande d'autorisation.
- [Détail] (axe 2) L736-743 : « Indisponibles sur cet appareil » sans cause ni action. → Culs-de-sac (navigateur non compatible, iPhone non installé ?). → Lien vers le guide d'installation.
- [Détail] (axe 3) L330-340 : cloche de 40 px comme interrupteur (avec `toggled`, point positif), couleur vert/gris. → OK au lecteur d'écran ; petit au toucher.
- [Détail] (axe 2) L117-122 : `ListTileTheme` sans `ListTile` dedans (code mort).

### lib/features/more/presentation/calendar_subscription_tile.dart
- [Gênant] (axe 2) L143-148 : après « Apple Calendrier », le message dit « Pas de « S'abonner » dans Calendrier ? Ouvre la page d'abonnement. » sans dire que le lien a été copié. → Message énigmatique. → « Lien copié. Si Calendrier ne s'ouvre pas, ouvre la page d'abonnement. »
- [Détail] (axe 2) L88 : échec d'ouverture avalé (`catchError → false`) ; compensé par le message. → Acceptable.
- [Détail] (axe 2) L57-62 : spinner `CircularProgressIndicator` direct (visible, contrairement à `PfProgressIndicator`). → Incohérence avec le reste.
- [Détail] (axe 2) L16-33 : le lien de calendrier est permanent, sans bouton « Régénérer le lien » (personne ne peut révoquer un lien partagé par erreur). → Risque de confidentialité. → Prévoir une régénération.
- [Détail] (axe 1) L227-229 : « abonnement à faire sur Google Agenda en version web » (jargon). → « sur ordinateur ou navigateur ».

### lib/features/more/presentation/more_page.dart
- [Détail] (axe 2) L84-103 : « Équipes & stades » : le rafraîchissement du calendrier au retour n'a ni indicateur ni message de succès. → Silencieux.
- [Détail] (axe 2) L39 : les Notifications ne sont pas listées dans Paramètres (seulement via la cloche). → Découvrabilité faible. → Une ligne « Notifications ».
- [Détail] (axe 3) L146-153 : « Se déconnecter » en rouge `error` sur fond sombre (contraste à confirmer).
- [Détail] (axe 1) L222-229 : détails (identifiant · rôle) sans limite de lignes. → Retour à la ligne, correct.

### lib/core/widgets/pf_loader.dart — voir A (défaut central).

### lib/core/widgets/incident_error_view.dart
- [Détail] (axe 3) L28-31 : `Semantics(label: …)` sur un conteneur dont les enfants sont aussi lus. → Lecture en double possible. → `excludeSemantics` ou ne pas dupliquer.

### lib/core/widgets/pf_empty_state.dart
- [Détail] (axe 3) L37-40, L85-92 : même schéma (label global + enfants) → lecture en double ; message en `textFaint` (contraste ~6:1 sur `surface`, ok ; à vérifier sur teintes).
- Points positifs : respect du mouvement réduit (L26-27, L112-114), largeur bornée à 420 px, action avec largeur mini.

### lib/core/widgets/collapsible_section_card.dart — rien à signaler (lu en entier).

### lib/core/widgets/pf_secondary_tabs.dart — voir A.

### lib/core/widgets/pf_auth_surface.dart
- [Détail] (axe 1) L57-62 : logo de 150 px de haut fixe au-dessus de chaque formulaire d'authentification. → Sur téléphone en paysage ou petit écran, le logo occupe le premier écran ; l'inscription commence « sous le pli ». → Réduire à 80-100 px quand la hauteur < 700.
- [Détail] (axe 3) L51-65, L68 : le titre de page n'est pas marqué `header` (seul le logo l'est). → Lecteur d'écran : « Petit Filet » titre, puis texte simple. → `Semantics(header: true)` sur le titre.
- [Détail] (axe 1) L37 : `MediaQuery.viewInsetsOf` est lu après le `Scaffold` (il ne voit plus la hauteur du clavier) ; sans effet. → Ligne inutile.
- Points positifs : `SingleChildScrollView` + `keyboardDismissBehavior`, `SafeArea`, largeur maximale, `AutofillGroup`.

### lib/core/widgets/pf_adaptive_form.dart
- [Détail] (axe 1) L23 : seuil de 720 px mesuré sur la largeur DISPONIBLE (pas celle de l'écran) → jamais atteint dans une carte de 760 px ; avec un nombre impair de champs, le dernier reste seul à demi-largeur. → Voir auth_register_page.

### lib/core/widgets/pf_status_banner.dart
- [Détail] (axe 3) L44-47 : même risque de lecture en double (label + enfants) ; titre en gras 700 (L87) alors que tout le reste est forcé en 400 (hiérarchie typographique incohérente dans l'appli).

### lib/core/widgets/pf_accessibility_scope.dart
- [Détail] (axe 3) L35-59 : défilement automatique à chaque changement de focus clavier (`ensureVisible`, alignement .5) → l'écran « saute » même si l'élément est déjà visible. → N'agir que si l'élément est hors fenêtre.
- [À vérifier] (axe 3) L77-86 : le glisser à la souris sur une zone scrollable est activé partout. → Peut gêner la sélection de texte à la souris (pages légales en `SelectableText`). → Tester.
- Points positifs : parcours de focus en ordre de lecture, suivi du focus (WCAG 2.4.7).

### lib/core/widgets/pf_app_bar.dart
- [Gênant] (axe 2) L14-30 : `PfAppBar` n'a pas de bouton retour de secours : si la page est ouverte directement (rechargement, lien) la flèche n'existe pas ; avec Statistiques désactivées, il n'y a pas non plus de barre du bas (app_shell.dart L247). → Impasse : plus aucun moyen de revenir au calendrier. → `leading` de repli (écusson ou flèche vers `/matches`).
- [Détail] (axe 1) L149-158 : jusqu'à 4 boutons (Wrapped, trophée, cloche, réglages) ≈ 190 px dans l'en-tête. → Sur 320 px, le titre est tronqué (`ellipsis`). → À vérifier à l'écran.
- [Détail] (axe 3) L61-64 : voir A (GestureDetector).

### lib/core/widgets/pf_background.dart, kit_pattern_paint.dart, kit_portrait_silhouette.dart, portrait_alignment_guide.dart, equal_height_column.dart, drag_auto_scroll.dart, player_photo_mode_picker.dart — rien d'important à signaler (lus en entier).
- Note drag_auto_scroll.dart (tout le fichier) : le glisser-déposer de la composition n'a pas d'alternative au clavier ou au simple toucher (à vérifier dans l'écran concerné, hors groupe).
- Note player_photo_mode_picker.dart L29 : le choix courant n'est signalé que par une coche (pas de `selected`).

### lib/core/widgets/support_contact.dart
- [Détail] (axe 2) L37 : `launchUrl(mailto)` sans test du résultat. → Sans messagerie configurée, le bouton ne fait rien ; l'adresse reste sélectionnable (bon). → `SnackBar` « Copie l'adresse ».

### lib/core/widgets/calendar_scoreline.dart
- [À vérifier] (axe 1) L98-128, L254 : noms d'équipes à 17 px, score à ~21 px, tous deux agrandis jusqu'à 160 % ; chaque équipe a une demi-largeur moins le score. → À 320-360 px et 160 %, les noms (surtout un mot long) risquent d'être coupés au milieu ; tester.
- [Détail] (axe 3) L650-656 : texte de date à 12 px, fixe. → Limite basse.
- Voir A (couleur seule, adresse cliquable).

### lib/core/widgets/match_contribution_icons.dart
- [Détail] (axe 3) L22, L36, L63, L95 : buts/HDM en emoji (⚽ 👑) et crampon en image sans libellé. → Les emoji dépendent de la police du navigateur (carré vide possible si police absente) ; l'icône de passe n'a aucune description. → `Semantics(label)` dans le parent + icônes vectorielles.
- [Détail] (axe 1) L36 : la couronne grandit avec le texte alors que le ballon est mis à l'échelle fixe. → Tailles incohérentes.

### lib/core/widgets/match_date_column.dart
- [À vérifier] (axe 1) L119-120 : `MatchDateHeader` limite la date à 1 ligne avec « … » quand il n'y a pas de label. → À texte agrandi, la date/heure peut être coupée (information essentielle). Utilisé par pronos_hub_history_section.dart L231. → Autoriser 2 lignes.
- [Détail] (axe 1) L36 : `bold ? w400 : w400` (aucune différence de graisse) ; couleur `hintColor` pour la 2e ligne (contraste faible) ; `MatchDateColumn` n'a plus d'usage externe trouvé. → Code mort.

### lib/core/widgets/match_fixture.dart
- [Gênant] (axe 1) L69-77 : nom d'équipe sur 1 ligne avec « … » dans `Expanded`. → Sur téléphone, « AS Clinique Pas… » : on ne peut pas lire le nom complet (utilisé par sport_motm_vote_page L366 et l'historique). → 2 lignes autorisées.
- Voir A (couleur seule du résultat). Point positif : mouvement réduit respecté (L57-58, L81-83).

### lib/core/widgets/match_sheet_top_row.dart
- [Détail] (axe 3) L88-102 : flèche retour de 36 px de large (`shrinkWrap`, `maximumSize`). → Zone étroite pour le pouce, contre le bord. → 44 px.
- [Détail] (axe 1) L7-10 : « tirer l'écran vers le bas recharge la fiche » : aucun bouton d'actualisation (idem sticky_header_table L284). → À la souris, rien n'indique comment actualiser.
- Point positif : repli vers `/matches` quand il n'y a pas d'écran précédent (L104-111).

### lib/core/widgets/match_address_sheet.dart
- [Gênant] (axe 2) L129-131 : sur le web, l'itinéraire s'ouvre avec `webOnlyWindowName: '_self'` dans la page actuelle. → L'application est quittée ; au retour (précédent du navigateur) elle se recharge et l'état est perdu ; en application installée iPhone, le retour peut ne pas exister. → Ouvrir dans un nouvel onglet ou une vue interne.
- [Détail] (axe 2) L119-149 : trois étapes (adresse → « Choisir le GPS » → appli). → Un tap de trop. → Boutons GPS directement dans la 1re feuille.
- [Détail] (axe 2) L123-143 : `launchUrl`, `Clipboard.setData` sans `try/catch` (seul le retour `false` est géré). → Exception muette si le navigateur refuse.

### lib/core/widgets/match_detail_header_card.dart
- [Détail] (axe 2) L10-18 : un type inconnu (`null`) est étiqueté « Championnat » alors que la palette le traite à part (L39-48 de calendar_card_palette). → Ancien match mal étiqueté. → « Type inconnu ».
- Voir A (adresse cliquable). Point positif : zone du lien HDM d'au moins 48 px (L148).

### lib/core/widgets/kit_portrait.dart
- [Détail] (axe 3) L59-61 : chaque portrait annonce « Joueur — Maillot X » sans le nom du joueur. → Onze fois la même phrase à la lecture de la composition. → Libellé = nom du joueur, ou exclure du lecteur.

### lib/core/widgets/sticky_header_table.dart
- [Gênant] (axe 1) L11, L6 : colonne figée de 216 px + largeur minimale 620 px. → Sur 360 px, la colonne « Joueur » occupe ~60 % de l'écran : 2 colonnes de stats visibles ; seul indice = un dégradé et une flèche à droite (L333-386, bon point), qui n'est pas cliquable à la souris. → Réduire la colonne figée (ex. 140-160) sur écran étroit ; flèche cliquable.
- [Détail] (axe 3) L13 : en-têtes de colonne à 11,5 px (connu, < 12).
- [Détail] (axe 1) L296, L425 : `IntrinsicHeight` sur chaque ligne (double mise en page). → Coût de défilement sur longue liste.
- [Détail] (axe 3) L154-159 : aucune sémantique de tableau (en-têtes non associés aux cellules). → Lecteur d'écran : suite de nombres sans nom de colonne. → Libellés par cellule.
- Voir A (sens de tri invisible).

### lib/core/widgets/photo_crop_preview.dart
- [Gênant] (axe 3) L239-254 : recadrage uniquement au doigt/souris (pincer, glisser, molette) ; aucun bouton +/− ni curseur de zoom, aucune description. → Impossible pour une personne qui ne peut pas faire de gestes précis ou qui navigue au clavier/lecteur d'écran. → Curseur de zoom + flèches de déplacement + `Semantics`.
- [Gênant] (axe 1) L119-132 : le test « photo à fond transparent » parcourt tous les pixels de la photo pleine résolution sur le fil principal (jusqu'à ~48 millions d'octets pour 12 Mpx). → Gel de plusieurs secondes sur téléphone/web après le choix de la photo ; aucun indicateur (voir A). → Réduire l'image avant le test.
- [Gênant] (axe 2) L133-144, L391-396 : message « nécessite une photo à fond transparent… choisis Autre » sans bouton pour changer de mode ou choisir une autre photo. → Il faut fermer et recommencer. → Boutons « Choisir une autre photo » / « Passer en mode Autre ».
- [Gênant] (axe 2) L219-226 : l'erreur d'export est un `SnackBar` affiché SOUS la fenêtre (le dialogue couvre presque tout l'écran, L350-353). → Message à moitié caché derrière le voile. → Afficher dans la fenêtre (comme `_imageError`).
- [Détail] (axe 2) L31-32, L329-333 : le paramètre `instructions` n'est jamais affiché (texte codé en dur) ; le titre « Recadrer la photo » est remplacé par « Ajouter la photo du joueur » (L367-369) même pour le mode « Autre ». → Libellés incohérents.
- [Détail] (axe 1) L350-353 : hauteur de fenêtre calculée (largeur × 1,36 + 210) ; en paysage, l'aperçu défile dans la fenêtre et rivalise avec le glisser de la photo. → À vérifier sur téléphone couché.
- [Détail] (axe 2) L420-428 : spinner `CircularProgressIndicator` direct (visible) : incohérent avec l'absence de loader ailleurs.

### lib/core/widgets/pf_animated_crest.dart
- Point positif : mouvement réduit respecté (L40-52). Utilisé seulement au démarrage (main.dart L213). Rien à signaler.

### lib/app/app.dart — voir A (MediaQuery, bandeaux, plafond du texte).
- [Détail] (axe 2) L204-208 : « Réessayer » du bandeau « Connexion perdue » sans retour visible. → Le bandeau reste jusqu'au prochain test réseau.

### lib/app/shell/app_shell.dart
- Voir A (libellés de la barre du bas).
- [Détail] (axe 1) L247-276 : barre du bas de 52 px + marges (~76 px) présente aussi sur les écrans de formulaire (profil, admin). → Hauteur utile réduite quand le clavier est fermé. → Masquer sur les sous-pages.
- Points positifs : rail latéral sur grand écran/paysage (L200-203), largeur de lecture bornée (L207-215), `Semantics(selected)` sur les boutons.

### lib/app/shell/module_navigation.dart — rien à signaler (lu en entier).

### lib/app/router/auth_redirect.dart
- [Détail] (axe 2) L26-33, L96-119 : pendant l'attente, on passe par `/auth/loading` dont le chargement est invisible (voir A). → Écran vide à froid. 
- Points positifs : destination mémorisée à travers la connexion, redirections vers l'extérieur refusées (L241-249, L315-327), pages légales accessibles sans compte.

### lib/app/router/app_router.dart — voir A (pas d'`errorBuilder`).
- [Détail] (axe 2) L117-356 : les pages de profil, notifications, admin sont des sous-routes de la branche Calendrier : bonnes pour la navigation, mais voir pf_app_bar.dart (retour de secours).

### lib/app/router/deferred_route_page.dart
- [Gênant] (axe 2) L58 : chargement différé = `Scaffold(body: PfLoader.page())` → écran vide (voir A) ; l'erreur, elle, est bien gérée avec « Réessayer » et référence d'incident (point positif).

### lib/app/router/initial_app_location_parser.dart — voir A (lien expiré). `initial_app_location.dart`, `initial_app_location_stub.dart`, `initial_app_location_web.dart` — rien à signaler (lus en entier).

### lib/core/theme/app_theme.dart — voir A (contour des champs, thème unique).
- [Détail] (axe 3) L316-333, L414-415 : titres forcés en graisse 400 dans de nombreux écrans (`fontWeight: FontWeight.w400` partout) → hiérarchie visuelle faible. 
- [Détail] (axe 2) L497-531 : `navigationBarTheme` / `navigationRailTheme` définis mais non utilisés (la navigation est faite à la main). → Code mort.
- Points positifs : contraste garanti pour les couleurs de club (`_readableOn`, `onPrimaryButton`, L80-113), transitions coupées en mouvement réduit (L16), tailles mini 48 px des boutons.

### lib/core/theme/pf_button_styles.dart, app_spacing.dart, pf_card_border.dart, calendar_card_palette.dart — rien d'important (lus en entier). Note app_spacing.dart L9 : marge 8 px (voir A).

## C. Compte des constats par gravité (sections A et B)
(voir réponse finale)

## D. Fichiers lus en entier
auth/presentation : auth_register_page, forced_password_change_page, auth_sign_in_page, choose_club_page, confirm_email_page, consent_fields, accept_updated_terms_page, registration_success_dialog, sign_out_confirmation, legal_document_page, auth_loading_page, auth_state, widgets/email_verification_panel (13/13).
profile/presentation : profile_page, my_data_section (2/2). unavailability/presentation : unavailability_page, unavailability_form_sheet (2/2). notifications/presentation : notification_history_view, push_device_banner, notification_inbox_button, notifications_page (4/4). more/presentation : calendar_subscription_tile, more_page (2/2).
core/widgets (26/26) : pf_loader, incident_error_view, calendar_scoreline, match_contribution_icons, pf_empty_state, collapsible_section_card, match_date_column, match_fixture, kit_portrait, kit_pattern_paint, kit_portrait_silhouette, pf_animated_crest, pf_secondary_tabs, match_sheet_top_row, match_address_sheet, pf_auth_surface, pf_skeleton, support_contact, pf_status_banner, drag_auto_scroll, sticky_header_table, pf_background, pf_adaptive_form, match_detail_header_card, photo_crop_preview, portrait_alignment_guide, player_photo_mode_picker, pf_accessibility_scope, equal_height_column, pf_app_bar.
app (10/10) : app.dart, shell/app_shell.dart, shell/module_navigation.dart, router/auth_redirect.dart, initial_app_location_parser/stub/web/.dart, deferred_route_page.dart, app_router.dart.
core/theme (5/5) : pf_button_styles, app_spacing, pf_card_border, calendar_card_palette, app_theme.
Consultés en plus (extraits, pour vérifier une hypothèse) : features/match_live/presentation/widgets/match_live_notification_bell.dart (L95-142), features/legal/domain/legal_documents.dart (constantes de version).

## E. Fichiers NON lus ou lus en partie
Aucun fichier de la liste demandée n'a été lu en partie. Le comportement visuel (rendu réel, texte agrandi, clavier, contraste mesuré) n'a pas été testé : tout ce qui en dépend est marqué « À vérifier ».
Hors liste, non lus : les pages qui utilisent ces composants (calendrier, stats, composition, admin), le détail de `AppFormats`, `ClubConfigurationStatusBanner`, le dépôt de préférences (point « copie complète des préférences »).

## F. Top 5 des motifs répétés
1. Attentes invisibles : tous les loaders sont des `SizedBox.shrink` (pf_loader, pf_skeleton) → écrans vides, boutons « en cours » sans indicateur, libellés d'accessibilité perdus.
2. Erreurs de formulaire : `SnackBar` ou texte global en bas, pas d'`errorText`, pas de focus sur le champ fautif, pas de `textInputAction` (inscription, club, profil, mot de passe, fenêtres).
3. Fenêtres (`AlertDialog`) non défilables avec un champ de saisie : risque de boutons masqués par le clavier (mot de passe oublié, e-mail, suppression de compte, changement de mot de passe).
4. Information portée par la couleur seule ou sans libellé : résultat des matchs, état « non lu », colonne triée, icônes emoji sans description.
5. Actions sans retour ou retour perdu : « Se déconnecter » sur des écrans qui n'affichent pas l'erreur, changement de mot de passe sans succès visible, état partagé `error` de l'authentification, `ref`/`context` utilisés après un `await` sans test.

## G. Bons points notables
- Mouvement réduit respecté (pf_empty_state, match_fixture, pf_animated_crest, transitions de page).
- Contraste des couleurs de club contrôlé par le code (app_theme `_readableOn`, `onPrimaryButton`).
- Confirmation de suppression de compte par mot à recopier ; déconnexion avec confirmation sur Profil/Paramètres.
- `PfAuthSurface` : défilement, clavier, largeur bornée, SafeArea ; `ForgotPasswordDialog` ne révèle pas si l'adresse existe.
- Écran d'erreur de chargement différé avec « Réessayer » + référence d'incident ; bandeau « Connexion perdue » global.
- Cloche de notification : `toggled`, libellés explicites, point d'avertissement documenté en accessibilité.
- Rail latéral et largeur de lecture bornée sur grand écran ; focus clavier suivi (PfAccessibilityScope).
- Redirections d'authentification prudentes (pas de redirection externe, destination conservée).
