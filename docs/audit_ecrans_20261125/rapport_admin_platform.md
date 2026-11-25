# Audit UX/UI : admin, platform, billing, club, feature_flags, home, weather

Lecture seule, par le code (aucun appareil). 31 fichiers lus en entier. Chemins relatifs à `lib/features/`.
Légende : [Bloquant | Gênant | Détail | À vérifier] (axe 1-4) L<ligne>.

---

## admin/presentation

### admin/presentation/club_settings_page.dart
- [Gênant] (4) L116-126, L156-163, L239-243 : toutes les erreurs de saisie (nom, adresse, e-mail, téléphone, SIRET…) passent par une bulle qui disparaît (`_showMessage`), jamais sous le champ → on ne sait plus quel champ est faux après 4 s → mettre `errorText` sous le champ fautif.
- [Gênant] (4) L954-1316 : réglages dispersés en 11 sections, 4 boutons « Enregistrer » indépendants (identité, coordonnées, adresse terrain, + pas de bouton pour les interrupteurs). Rien n'indique qu'un champ modifié n'est pas enregistré ; quitter la page efface en silence → avertir si champ modifié non enregistré (ou enregistrer à la sortie).
- [Gênant] (2) L288-293 : `pickImage` sans `try/catch`. Si le navigateur refuse l'accès aux photos, rien ne s'affiche (erreur non rattrapée) → entourer d'un message « Impossible d'ouvrir la galerie ».
- [Gênant] (2) L260-277 : le compteur « Convoqués par défaut » n'affiche aucun retour de réussite et ignore les appuis pendant l'envoi (L261) → en cliquant vite sur « + » plusieurs fois, des clics sont perdus sans explication → cumuler les clics puis enregistrer une fois, ou afficher un petit indicateur.
- [Détail] (2) L392-406, L408-422 : un interrupteur en cours d'enregistrement devient grisé (désactivé) : ça ressemble à « verrouillé » (L692, L798). Pas d'indicateur de chargement → montrer un petit cercle à côté.
- [Détail] (3) L856, L1186 : la valeur du compteur (`Text('$n')`) est lue seule par un lecteur d'écran, sans nom (« 14 » sans « convoqués ») → entourer d'un `Semantics(label: …)`.
- [Détail] (3) L1029 : écusson `Image` sans `semanticLabel`.
- [Détail] (1) L730 : « sur 9 » écrit en dur (nombre de stats) → utiliser `WrappedStatOption.values.length`.
- [Détail] (1) L848-858 : réglage numérique = `ListTile` avec titre long + info + (−/valeur/+) à droite. À 160 % de texte, le titre est très comprimé → passer le stepper sous le titre quand l'espace manque. (À vérifier à l'écran.)
- [Détail] (2) L974-981 : « Aucun réglage trouvé. » sans bouton « Effacer la recherche ».
- [Détail] (1) L531-533 : la clé des sections change à chaque lettre tapée → toutes les sections se reconstruisent (clignotement) à chaque frappe.
- [Détail] (4) L1073-1122 : espacement incohérent (L1121 `SizedBox(4)` au lieu de 12) ; aucun `textInputAction` (Entrée ne passe pas au champ suivant) ; L1026 et L1283 deux `SizedBox` consécutifs inutiles.
- [Détail] (2) L331-338 : copie du lien sans `try/catch` (le presse-papiers web peut refuser) → message d'échec.
- [À vérifier] (1) L743-745 : boîte de dialogue des stats avec `SizedBox(width: 420)` : à contrôler sur téléphone étroit.

### admin/presentation/admin_page.dart
- [Gênant] (2) L252-255 : écran « Saison » en erreur : texte seul, **pas de bouton « Réessayer »** (alors que l'écran « Effectif » en a un, L73).
- [Gênant] (2) L179-187 : si l'effectif ne charge pas, simple phrase d'erreur, sans « Réessayer ». En plus, le bouton « Ajouter un joueur sans compte » (L218) et les infos de fiche joueur disparaissent sans explication.
- [Gênant] (3) L317-377 : onglets « Validés / En attente » faits main : sélection portée par la couleur seule, graisse identique (L361-363 les deux branches valent w400), aucun `Semantics(selected:)`, pas de focus clavier visible → utiliser `SegmentedButton` (déjà employé dans platform_cash_section).
- [Détail] (2) L138-166 : « Lien d'inscription » : pas d'état « en cours » (double clic possible) ; texte « partage-le sur WhatsApp » figé.
- [Détail] (2) L124-130 : si l'actualisation échoue, l'exception sort de `onRefresh` sans message.
- [Détail] (2) L107-122 : l'effectif charge après les comptes sans indicateur → la liste « sans compte » apparaît après coup et décale la page.
- [Détail] (2) L188-194 : même texte « Aucun compte validé. » que ce soit « vide » ou « rien d'affiché ».

### admin/presentation/admin_profiles_section_v2.dart
- [Gênant] (3) L691 : `trailing: SizedBox.shrink()` supprime la flèche de dépliage → rien n'indique que la ligne se déplie ; les actions (supprimer, rôles…) sont cachées derrière un geste invisible.
- [Gênant] (2) L685-692 : une fois repliée, la ligne ne montre que prénom/photo : un compte **archivé** ou **admin** est indiscernable d'un compte normal (aucun badge). Il faut déplier pour voir « Réactiver ».
- [Gênant] (2) L407-409 : si le chargement des fiches historiques échoue, `historicalPlayers` reste null → affiche « Chargement… » **indéfiniment** (jamais d'erreur, pas de « Réessayer »).
- [Gênant] (2) L146-160, L454-533 : aucune protection contre les doubles envois ni indicateur d'attente sur « Supprimer », « Archiver », rôles, rattachement. Les puces Admin/Gardien/Coach lancent un envoi à chaque appui : basculer vite = écritures contradictoires. → désactiver pendant l'envoi.
- [Gênant] (4) L507-529 : choisir « Coach » décoche silencieusement « Gardien » (`isGoalkeeper:false`) et inversement, sans le dire.
- [Gênant] (2) L479-492 : donner ou retirer le rôle Admin (droit sensible) se fait en un appui sur une puce, sans confirmation ni rappel de ce que ça change.
- [Gênant] (3) L401-445, L542-575 : quatre boutons « Modifier » identiques (Rattachement, Coordonnées, Photo, Mot de passe) → lecteur d'écran : « Modifier ×4 » sans contexte → `Semantics(label: 'Modifier le mot de passe de X')`.
- [Gênant] (4) L563-572 : le bouton « Modifier » du mot de passe ne modifie rien : il fabrique un lien de réinitialisation. Libellé trompeur → « Générer un lien ».
- [Gênant] (3) L454-468 : les puces sont dans `FittedBox(scaleDown)` + `visualDensity.compact` : à texte agrandi elles rétrécissent (texte < 12 px effectif, cible tactile ~28 px sur ordinateur/PWA). L'état « sélectionné » n'est porté que par la couleur (`showCheckmark: false`).
- [Gênant] (2) L636-653 : bouton « Valider ce compte » → `_askPlayerLink` charge l'effectif sans aucun indicateur (voir dialogs) : le clic semble sans effet, double clic = deux boîtes.
- [Détail] (4) L350-373 : « Prénom » est un `Text` à part, pas le libellé du champ → lecteur d'écran lit un champ sans nom. Le champ devient désactivé (L360) sans explication (archivé, pas de saison).
- [Détail] (4) L392-399 : le bouton « Enregistrer le prénom » apparaît seulement si modifié → la carte saute ; si on replie la carte, la saisie est perdue sans avertissement (L109-111).
- [Détail] (2) L167-175, L298-306 : confirmations pour des actions réversibles (« Retirer de l'effectif », « Archiver ») alors qu'un « Annuler » dans la bulle suffirait ; à l'inverse (L313-325) la suppression définitive n'a ni bouton rouge ni nom de l'action (« Confirmer »).
- [Détail] (1) L45 (déjà connu, élargi) : `SizedBox(width:112)` + mots longs (« Rattachement », « Coordonnées ») → coupés en milieu de mot à 160 %.
- [Détail] (1) L71 : valeur Identifiant tronquée à 2 lignes avec « … » sans moyen de la lire en entier.
- [Détail] (2) L544-553, L438-442 : boutons « Modifier » grisés sans raison affichée (pas de saison ouverte, archivé).

### admin/presentation/admin_profile_dialogs.dart
- [Gênant] (2) L28-38 et L174-181 : l'effectif/les fiches historiques sont chargés **avant** d'ouvrir la boîte, sans aucun indicateur → pendant 1-3 s, rien ne se passe après le clic.
- [Gênant] (2) L144-150 : « Copier » le lien de réinitialisation affiche la bulle avec `ScaffoldMessenger.of(dialogContext)` : la bulle apparaît **derrière** la boîte de dialogue (cachée par le fond grisé) → aucun retour visible. → changer le libellé du bouton en « Copié ✓ » ou afficher la bulle au-dessus.
- [Détail] (2) L129-141 : le lien de réinitialisation n'indique ni durée de validité ni « à usage unique : ne le recopie nulle part ».
- [Détail] (1) L48-57, L133-141 : contenu de dialogue en `Column` sans défilement : à 160 % ou en paysage, texte coupé (L47-66 : paragraphe + liste déroulante).
- [Détail] (1) L197-221 : liste de fiches historiques en liste déroulante, éléments `Text` sans coupure (« Nom — 12 matchs, 3 buts ») ; sans recherche si la liste est longue.
- [Détail] (4) L238-261 : `_confirm` est générique (« Confirmer ») pour des actions destructrices (suppression de compte).

### admin/presentation/admin_profile_actions.dart
- [Détail] (3) L19-29 : « Valider ce compte » / « Refuser et supprimer » sans nom de la personne dans l'étiquette (lecteur d'écran) ; « Refuser et supprimer » en `TextButton` rouge pâle au même rang que le bouton principal, sans confirmation par nom (la confirmation est dans la carte).

### admin/presentation/admin_profile_policy.dart — rien à signaler (lu en entier, pas d'écran)

### admin/presentation/admin_season_section.dart
- [Gênant] (4) L137-162 : « Nouvelle saison » : si le nom est vide, la boîte se ferme et **rien ne se passe** (L162 retourne sans message). Pas d'`autofocus`, pas d'Entrée pour valider, pas de limite de longueur, nom non rogné (`controller.text`).
- [Gênant] (2) L123-127 : « Finir la saison » (définitif) n'a ni état « en cours » ni message de réussite (la création en a un, la fin non) → l'écran change en silence.
- [À vérifier] (2) L161 : `controller.dispose()` juste après la fermeture de la boîte : la boîte joue encore son animation de sortie avec ce contrôleur → possible erreur « contrôleur utilisé après libération » (surtout en mode debug).
- [Détail] (3) L59-65 : texte d'aide en `bodySmall` gris secondaire.

### admin/presentation/admin_menu_page.dart — rien à signaler (lu en entier : simple redirection vers `AdminPage`)

### admin/presentation/club_kits_page.dart
- [Gênant] (4) L56-139 : tout se modifie en local (couleurs, modèle, archivage, ajout) et n'est enregistré que par le bouton **tout en bas** (L217). Aucun indicateur « modifications non enregistrées », pas de confirmation en quittant → perte de saisie facile. Pas de barre « Enregistrer » collée en bas.
- [Gênant] (4) L112-119 : erreurs de validation (« Donne un nom à chaque maillot ») en bulle ; la carte fautive n'est ni signalée ni atteinte par défilement.
- [Gênant] (2) L90-101, L189 : le bouton dit « Supprimer ce maillot » mais ça **archive** (réversible, restauration dans un bloc replié L200) et n'est appliqué qu'à l'enregistrement ; aucun retour. → « Archiver » + « Annuler » dans la bulle.
- [Gênant] (3) L410-428 : pastilles de couleur de 32 × 32 px (cible < 44), sans retour au toucher (le `Container` coloré recouvre l'ondulation de l'`InkWell`), nom lu = code hexadécimal (« Couleur du maillot #1A4AC0 ») donc inutilisable au lecteur d'écran ; en plus `Semantics` + `InkWell` font deux nœuds.
- [Détail] (3) L420-425 : sélection portée uniquement par l'épaisseur du contour (3 px) ; les couleurs sombres (#1B1F2A, #000000) se voient mal sur fond sombre.
- [Détail] (3) L264-281 : mini maillots (54 × 62) + légendes « Joueurs » / « Gardien » sans libellé accessible (`KitJersey` : à vérifier).
- [Détail] (3) L452-465 : deux listes « Modèle du maillot » (joueurs et gardien) avec le même libellé.
- [Détail] (2) L58-88 : après « Ajouter un maillot », la page ne défile pas vers le nouveau maillot ni ne met le focus sur son nom.
- [Détail] (4) L288-298 : `maxLength` avec compteur masqué : la frappe est coupée sans explication.

### admin/presentation/opponent_stadium_library_page.dart
- [Gênant] (4) L86-123 : la feuille d'édition se ferme **avant** l'envoi (`Navigator.pop`) ; si l'envoi échoue (nom en double, réseau), la saisie est perdue et seule une bulle d'erreur apparaît → garder la feuille ouverte tant que l'enregistrement n'a pas réussi.
- [Gênant] (2) L42-46, L105, L156 : après chaque ajout/modification/suppression, `_load` remplace toute la liste par un spinner → la liste clignote et la position de défilement est perdue.
- [Gênant] (2) L160-169 : **toute** erreur de suppression affiche « Cette équipe possède un historique de matchs » ; une panne réseau est présentée à tort comme cela.
- [Détail] (2) L221-227 : « Aucune équipe trouvée. » identique pour bibliothèque vide / recherche sans résultat ; pas de bouton d'ajout dans l'état vide.
- [Détail] (1) L229 : `...items.map` construit tout d'un coup (liste non paresseuse) ; recherche sans accents (L76 `toLowerCase`) et sans bouton « effacer » (L191-198).
- [Détail] (4) L366-405 : pas de `textInputAction` entre les champs ; message « Nom trop court » (L377) → « Écris au moins 2 caractères ».
- [Détail] (3) L233-300 : la ligne entière ouvre l'éditeur sans indication (pas de chevron), en plus du menu ⋮ (bon : étiquette « Actions pour X »).

### admin/presentation/admin_notification_page.dart
- [Gênant] (2) L130-135 : page en erreur : message seul, **pas de « Réessayer »**.
- [Gênant] (1) L54-61 : la boîte de confirmation affiche titre + message (300 caractères) + **liste de tous les destinataires** dans un `Text` sans défilement → sur un petit écran la fin (donc la liste) est coupée.
- [Détail] (4) L38-48 : validations en bulle (pas sous les champs) ; pas de `textInputAction` du titre vers le message.
- [Détail] (2) L77 : `setState` après `await showDialog` sans `mounted`.
- [Détail] (4) L209-228 : bouton « Tout le monde / Aucun » dont l'étiquette change selon l'état → ambigu (« Aucun » = état ou action ?). Message d'information sur la livraison placé **sous** le bouton Envoyer (L271) alors qu'il devrait précéder.
- [Détail] (3) L127 : titre « Notification » (singulier, ambigu avec la liste de notifications reçues) → « Envoyer une notification ».

### admin/presentation/club_referral_section.dart
- [Gênant] (2) L18-19 : erreur = phrase sans « Réessayer ».
- [Détail] (2) L20-21 : si le code est vide, toute la section disparaît sans explication.
- [Détail] (2) L94-95 : `Share.share` sans gestion d'échec (le partage web n'existe pas sur tous les navigateurs de bureau). À vérifier à l'écran.
- [Détail] (4) L148 : « En essai : compte dès son premier paiement » : formulation peu claire.

### admin/presentation/club_subscription_page.dart
- [Gênant] (2) L44-46 : la page affiche « Merci ! Paiement reçu » puis ne relit l'abonnement qu'**une fois** après 4 s ; si la confirmation Stripe est plus lente, la carte reste rouge (« essai terminé ») sous un bandeau vert → boucler la relecture quelques fois ou parler de « paiement en cours de confirmation ».
- [Détail] (2) L76 : `onRefresh: () async => _reload()` rend la main tout de suite : le cercle de rafraîchissement disparaît avant que les données soient là.
- [Détail] (2) L66-72 : bandeau « Paiement reçu » probablement ré-affiché à chaque rechargement tant que `?paiement=merci` reste dans l'adresse. À vérifier.
- [Détail] (3) L82-106 : bandeau sans `liveRegion` (non annoncé).

### admin/presentation/club_subscription_section.dart
- [Gênant] (2) L23-24, L36 : erreurs en simple texte, sans « Réessayer ».
- [Détail] (2) L25-26, L37-38 : abonnement/espace `null` → rien n'est affiché, sans message.
- [Détail] (3) L42-45 : barre d'espace photos sans `semanticsLabel` (le lecteur d'écran n'annonce pas « 62 % ») ; alerte « presque plein » en texte brut non mis en valeur (L51-55).
- [Détail] (1) L130-139 : toute la carte devient rouge dès qu'un renouvellement approche, texte compris.
- [Détail] (4) L164 : « −5 % » avec espace normal (le « % » peut passer à la ligne) alors que L65 de club_referral_section utilise l'espace insécable.

### admin/presentation/club_season_tile.dart
- [Gênant] (4) L107-128 : même défaut que admin_season_section : nom vide = fermeture silencieuse ; pas d'Entrée pour valider ; pas d'autofocus.
- [Gênant] (2) L88-100 : « Finir la saison » (définitif) sans état « en cours » ni message de réussite.
- [Détail] (2) L38-52 : deux écrans différents pour la même action (ici : sans navigation ni message à la fin ; admin_page : navigation vers /players) → incohérent.
- [Détail] (3) L22-27 : « Appuyer pour réessayer » (sur PWA bureau : « Cliquer »).

### admin/presentation/card_payment_button.dart
- [Détail] (2) L61-74 : « Activer mon année offerte » : engagement sans confirmation.
- [À vérifier] (2) L47-59 : sur le web, `_self` remplace la page ; au retour arrière du navigateur l'état « Ouverture du paiement… » (bouton grisé) pourrait rester affiché (page restaurée).

---

## platform/presentation

### platform/presentation/platform_control_page.dart
- [Bloquant] (2) L56-61, L186-196 (+ L63-72) : toutes les minutes, au retour d'onglet, à chaque perte de focus de la fenêtre et au clic sur « Actualiser », la page entière est **remplacée par un cercle de chargement** (`invalidate` + `when` sans garder l'ancienne valeur) : défilement perdu, fiche club refermée sur le haut, et tout champ en cours de saisie dans une zone non-boîte (recherche club, etc.) est détruit. Les boîtes de dialogue (paiement…) survivent mais pas la page derrière. → garder les données affichées pendant l'actualisation (`skipLoadingOnReload: true`) et ne pas masquer l'écran pour `inactive`.
- [Gênant] (3) L64-72, L186-187 : « Vérification de l'accès… » (texte seul, sans cercle) s'affiche dès que l'application perd le premier plan, y compris un simple changement d'onglet pour copier une référence de virement → le contenu disparaît puis revient avec un rechargement.
- [Gênant] (2) L774-783, L95-101 : « Retour à la liste » ramène à la liste des Clubs même quand on est venu de la Caisse ou de « À faire » ; et la navigation est un simple état interne → **bouton Retour du navigateur / d'Android = quitte le poste de contrôle** au lieu de revenir à l'écran précédent.
- [Gênant] (2) L245-299 : le défilement est conservé d'un écran à l'autre (même `SingleChildScrollView` avec la même clé) : ouvrir un club depuis le bas d'une longue liste affiche la fiche déjà défilée, sans voir son titre. → remettre le défilement en haut au changement de section/club.
- [Gênant] (1) L636-649 : le passage tableau (≥ 860 px) est décidé sur la largeur, pas sur la taille du texte : à 160 % les 7 colonnes sont tronquées avec « … » (L670, L730) ; mêmes textes tronqués sans info-bulle ni lecture possible (parrainé par…).
- [Détail] (1) L929-955 : chiffres des cartes en 30 px fixe, sans coupure : un montant long (« 12 345,00 € ») se casse en plein mot à 160 %. À vérifier à l'écran.
- [Détail] (3) L260-262, L1053 : titres de page/section sans `Semantics(header: true)` ; barres du graphique (L1103-1122) accessibles seulement par info-bulle (pas au clavier).
- [Détail] (1) L116-139 : barre du haut 80 px fixe avec textes 13 px et 20 px : à vérifier à 160 %.
- [Détail] (2) L580 : la recherche reconstruit toute la page à chaque lettre (tableau complet) ; pas de bouton « effacer » ni de « Réinitialiser le filtre » quand rien ne correspond (L630-631 dit « recherche » alors que ça peut être le filtre).
- [Détail] (4) L351-353, L405, L436, L447, L457, L476… : « club(s) », « exécution(s) », « suspendu(s) » : pluriels bricolés, visibles par le gestionnaire. Vocabulaire différent côté club (« essai gratuit ») et ici (« mois gratuit », L372, L405).
- [Détail] (3) L192 : `CircularProgressIndicator` brut au lieu du `PfProgressIndicator` utilisé partout ailleurs.
- [Détail] (1) L243-299, L643-648 : tout le tableau des clubs est construit d'un coup (`Column`, pas de liste paresseuse).
- [Détail] (3) L216 : aucun libellé « Revenir à l'app du club » (`automaticallyImplyLeading:false`) : un compte gestionnaire n'a que « Se déconnecter » pour quitter.

### platform/presentation/platform_billing_panel.dart
- [Gênant] (2) L577-596, L225-236 (même défaut dans toutes les boîtes) : la boîte peut être fermée **pendant l'enregistrement** (clic à côté / Échap, rien ne la protège) : l'action aboutit côté serveur mais plus aucun message ni rafraîchissement (le résultat n'est lu que si la boîte est encore là, `if (mounted)` L588). → `barrierDismissible: false` / `PopScope(canPop: !saving)`.
- [Gênant] (4) L577-638 : erreurs de validation en bas du contenu défilant, sous un long formulaire (paiement : 6 champs) : sur téléphone, le message est hors écran, le bouton « Enregistrer » semble ne rien faire. Déjà connu en nombre, mais touche ici 5 formulaires financiers.
- [Gênant] (4) L117-118, L130 : `formatEuros(billing.basePriceCents ?? 0)` : prix **inconnu affiché « 0,00 € »** alors que la page affirme « une mesure manquante n'est jamais remplacée par zéro » (platform_control_page L291). Même chose avec `amountDueCents ?? 0`.
- [Gênant] (2) L330, L235, L255, L275, L290 : après une action, `_refreshClub(ref, …)` utilise le `ref` d'un widget qui a pu être détruit par l'actualisation automatique (voir platform_control_page) → erreur « ref utilisé après libération » : le paiement est enregistré mais la bulle de confirmation n'apparaît pas ; pour Suspendre/Rouvrir (L332-334) un faux message d'erreur peut s'afficher alors que l'action a réussi. À vérifier à l'écran (Riverpod 2.6).
- [Gênant] (2) L317-321 : « Suspendre » (bloque tous les membres du club) est un bouton plein standard, pas rouge ; pas d'état « en cours » ni protection contre le double clic.
- [Détail] (2) L230, L983 : `7900` (79 €) pré-rempli en dur comme montant du paiement/tarif quand le prix est inconnu → risque de saisir un faux montant.
- [Détail] (4) L707-715, L922-930, L1017-1026 : champ de montant sans `inputFormatters`, sans `textInputAction` ; pas d'`autofocus`. Remboursement par carte (L868-869) pré-rempli au maximum, un seul clic (L913 « Rembourser la carte ») pour une action Stripe irréversible.
- [Détail] (3) L350-365 : copie (icône) sans confirmation « Copié » ; `launchUrl(link)` non attendu (aucune erreur si pas de client mail) ; `SelectableText` en sous-titre : un appui sur le texte ouvre la sélection, pas le mailto/tél (à vérifier) ; L528-538 : infobulles identiques sur chaque ligne (« Reçu Stripe », « Rembourser ») sans l'identité du paiement ; `Uri.parse(receiptUrl)` non protégé (L531).
- [Détail] (1) L945 : liste « Comment » : `'Virement (déjà fait de ton côté)'` dans un menu non étiré : débordement possible sur téléphone étroit. À vérifier.
- [Détail] (4) L742-746 : bouton date (« Reçu le … ») ressemble à un bouton d'action, pas à un champ ; pas de zone de saisie du jour.

### platform/presentation/platform_cash_section.dart
- [Détail] (2) L98-103 : « Période suivante » reste actif au-delà de la période en cours (affiche un mois vide futur).
- [Détail] (2) L188-193, L278-288 : export (CSV) sans message de réussite, sans état « en cours » ; L337-347 : téléchargement d'avoir sans état « en cours » (le premier clic charge la bibliothèque PDF : plusieurs secondes sans retour).
- [Détail] (2) L264-269, L272-274 : lignes du registre cliquables (ouvrent la fiche club) sans chevron/indication ; `Uri.parse(receiptUrl)` non protégé.
- [Détail] (4) L328 : `buyerName ?? ''` → ligne qui commence par « · remboursé le… » si le nom manque.
- [Détail] (1) L199-204, L320 : registre et avoirs non paginés (toute l'année en `Column`).
- [Détail] (3) L389 : `fontSize: 26` fixe, déjà plus petit que le 30 de la page parente (cartes de chiffres dupliquées avec des tailles différentes).

### platform/presentation/platform_alerts_panel.dart
- [Gênant] (2) L94-98, L166-180 : « Traitée » ferme une alerte de litige/impayé en un appui, sans confirmation ni « Annuler », et sans état « en cours ». Libellé ambigu (action ou état ?) → « Marquer comme traitée » + bulle avec « Annuler ».
- [Détail] (1) L80-99 : sur mobile, le bouton « Traitée » à droite d'un texte de 3-4 lignes (avec phrase répétée « À traiter dans le tableau de bord Stripe… », L91) comprime le texte.
- [Détail] (4) L109 : message d'erreur brut de Stripe (probablement en anglais) affiché tel quel.
- [Détail] (3) L133-136 : lignes cliquables sans chevron.

### platform/presentation/platform_settings_section.dart
- [Gênant] (4) L149-161 : la boîte « Offre » a un seul message global : « Valeurs invalides : parrainage entre 1 et 100 %, plafond au moins égal, essai de 0 à 365 jours » → on ne sait pas quel champ est faux. Message en bas du contenu (L236-241).
- [Gênant] (2) L90-103 : aucun message « Offre enregistrée » après modification (qui change le tarif des nouveaux clubs) ; `ref.invalidate` après un `await` d'un widget possiblement détruit.
- [Gênant] (2) L280-281 : état Stripe « indisponible » sans bouton « Réessayer » (les autres cartes en ont un). Idem L73-76 (billing/platform_invoices_section) pour les coordonnées.
- [Détail] (2) L283-299 : mode « réel / test » écrit en texte neutre ; un mode test devrait être mis en évidence. Erreur Stripe brute (`lastFailureType`, `lastFailureError`, L295-296).
- [Détail] (4) L302-306 : « voir docs/STRIPE.md » : fichier du dépôt, inaccessible depuis l'application.
- [Détail] (4) L75-81 : conditions « publiées » (79 €, −5 %…) écrites en dur dans l'écran : fausses dès que l'offre change.
- [Détail] (4) L193-229 : pas de `inputFormatters` (chiffres), pas de `textInputAction`, bouton « Enregistrer » sans état « en cours » (le libellé change, ok).

---

## billing/presentation

### billing/presentation/platform_invoices_section.dart
- [Gênant] (2) L153-156, L221-234 : « Émettre les factures prêtes » **numérote définitivement** des factures (obligation légale, irréversible) en un seul appui, sans confirmation ni nombre annoncé, ni état « en cours ».
- [Gênant] (1) L278-308 : jusqu'à 3 boutons-icônes en `trailing` (≈ 144 px) dans une `ListTile` : sur téléphone étroit, le texte (club, montant, état) est écrasé ; à 160 % il devient illisible.
- [Gênant] (2) L248-257, L297-301 : « Aperçu » / « Télécharger » : le premier clic charge la bibliothèque PDF sans aucun retour ; l'utilisateur recommence et déclenche plusieurs partages. Pas de bulle de réussite.
- [Détail] (3) L297-307 : trois icônes sans texte ; « Écarter » avec une icône de corbeille (suggère une suppression) ; infobulles invisibles au toucher.
- [Détail] (2) L313-345 : la confirmation « Écarter » (action définitive) n'est pas rouge ; pas de message de réussite ; `_refresh(ref)` même en cas d'échec.
- [Détail] (4) L375-400 : seul le SIRET est contrôlé ; e-mail non vérifié ; bouton « Enregistrer » sans état « en cours » ; boîte fermable pendant l'envoi (voir platform_billing_panel).
- [Détail] (4) L204 : `buyerName ?? ''` → « · émise le… » en tête si absent.
- [Détail] (1) L146-147, L196-212 : listes non paresseuses.

### billing/presentation/invoice_download.dart — rien à signaler (lu en entier, pas d'écran ; le manque de retour d'attente vient des appelants)
- [À vérifier] (2) L20-25 : `Share.shareXFiles` : sur navigateur de bureau, vérifier que le fichier se **télécharge** vraiment (sinon l'échec affiche « La facture n'a pas pu être préparée »).

### billing/presentation/club_invoices_list.dart
- [Gênant] (2) L25-26 : erreur sans « Réessayer ».
- [Détail] (2) L46-51 : téléchargement sans état « en cours » (voir ci-dessus).
- [Détail] (3) L46-49 : infobulle « Télécharger la facture » identique sur chaque ligne (ajouter le numéro).

---

## club / feature_flags / home / weather

### club/presentation/club_configuration_status_banner.dart
- [Gênant] (2) L9-30, L76 : pendant les 3 s avant l'affichage du bandeau, les fonctions du club sont déjà masquées (sans message) ; ensuite le bandeau « Les réglages du club sont indisponibles » n'explique pas ce qui manque.
- [Détail] (1) L76-99 : bandeau inséré dans la mise en page : il décale tout le contenu à son apparition/disparition ; pas de `liveRegion` ; aucun retour pendant « Réessayer ».

### club/presentation/club_rules_sync.dart — rien à signaler (lu en entier, pas d'écran)

### club/presentation/club_suspended_page.dart
- [Gênant] (2) L54-58 : « J'ai payé : actualiser » ne montre aucun retour (ni cercle ni message « pas encore reçu ») : si le paiement n'est pas arrivé, rien ne change visiblement.
- [Gênant] (3) L22-81 : aucune action « Se déconnecter » / « Changer de club » sur cette page (à vérifier selon `PfAppBar`) : un membre non-admin ne peut rien faire d'autre que lire.
- [Détail] (4) L61-69 : texte pour un membre non-admin : « Administrateur du club : écris-nous… » → suggère de contacter l'éditeur au lieu de prévenir son administrateur.

### club/presentation/club_identity_sync.dart — rien à signaler (lu en entier, pas d'écran)

### feature_flags/presentation/feature_flags_controller.dart
- [À vérifier] (2) L196-203, L231-235 : en cas d'échec, les réglages « gestion sportive » basculent sur « coupé » **sans bandeau ni « Réessayer »** (le bandeau de club_configuration_status_banner ne surveille ni ce contrôleur ni la gestion sportive) → les blocs « effectif / composition » disparaissent sans explication. À confirmer à l'écran (réseau coupé).
- Pas d'écran, reste du fichier : rien à signaler.

### home/presentation/home_next_match_card.dart
- [Détail] (3) L53-67 : cloche et crayon à 40 px (`actionExtent`, calendar_scoreline.dart:456) : cible < 44.
- [Détail] (3) L129-134 : toute la carte est cliquable sans indication ni libellé accessible (« Ouvrir la composition de … »).
- [Détail] (2) L43-46 : la cloche n'apparaît qu'après chargement (`valueOrNull`), erreur avalée, décalage de mise en page.
- [À vérifier] (3) L63-66 : crayon de l'admin teinté `cardBorder` : contraste selon le type de match.

### weather/presentation/match_weather_card.dart
- [Gênant] (1) L96-183 : à 160 % de texte, colonne de gauche (température `maxLines:1`, sans ellipsis, L112-123) et de droite (libellés « Humidité », « Rafales » réduits à « Hum… », L207-224 ; valeurs sans gestion de débordement) → informations coupées. À vérifier à l'écran.
- [Détail] (2) L34-37 : chargement et erreur masqués (`valueOrNull` + `SizedBox.shrink`) : la carte apparaît d'un coup et décale la page ; aucune mention « météo indisponible » ; aucune heure de mise à jour de la prévision (prévision J-6 peu fiable).
- [Détail] (3) L70-82 et L106-110 : la même icône météo deux fois (en-tête 18 px + 36 px).
- [Détail] (1) L133, L144, L212, L221 : tailles 12-12,5 px figées.

---

## Liste des fichiers lus en entier (31/31)
admin/presentation : club_settings_page, admin_profile_policy, admin_page, club_referral_section, admin_notification_page, club_subscription_page, club_season_tile, admin_season_section, admin_menu_page, club_kits_page, card_payment_button, admin_profiles_section_v2, opponent_stadium_library_page, admin_profile_dialogs, admin_profile_actions, club_subscription_section.
platform/presentation : platform_billing_panel, platform_alerts_panel, platform_control_page, platform_cash_section, platform_settings_section.
billing/presentation : platform_invoices_section, invoice_download, club_invoices_list.
club/presentation : club_configuration_status_banner, club_rules_sync, club_suspended_page, club_identity_sync.
feature_flags/presentation : feature_flags_controller. home/presentation : home_next_match_card. weather/presentation : match_weather_card.

## Fichiers non lus ou lus en partie
Aucun dans la liste. Non lus (hors liste, utilisés par ces écrans, donc jugés « à vérifier ») : `KitJersey`, `PfAppBar`, `PfProgressIndicator`, `CalendarCard*`, `MatchAvailabilitySelector`, `PlayerAvatar`, `member_contact_dialog`, `humanizeError`, `formatEuros`, `ledgerToCsv`. Rien n'a été exécuté ni rendu : tout ce qui touche au rendu est marqué « À vérifier ».

## Top 5 des motifs répétés
1. **Boîtes de dialogue d'enregistrement fermables pendant l'envoi + erreur en bas du contenu** (platform_billing_panel ×5, platform_settings ×1, platform_invoices ×2) : action réussie mais aucun message, ou erreur hors écran.
2. **Pas de « Réessayer » dans les états d'erreur** (admin_page saison/effectif, notification, parrainage, abonnement, factures club, Stripe, coordonnées éditeur) alors que d'autres écrans en ont.
3. **Actions longues ou définitives sans retour d'attente ni confirmation adaptée** : fin de saison, émission des factures (numérotation légale), « Traitée » sur alertes, téléchargements PDF (chargement différé sans cercle), droits Admin.
4. **Perte de saisie / pas d'avertissement** : maillots (tout en bas), prénom en ligne, feuille « équipes » fermée avant envoi, nom de saison vide qui ferme la boîte en silence.
5. **Accessibilité des boutons répétés** : « Modifier » ×4, « Télécharger la facture », « Reçu Stripe » sans nom de la ligne ; pastilles 32 px ; sélection par la couleur seule (onglets Validés/En attente, puces de rôle).

## Bons points notables
- Poste de contrôle : tableau/liste selon la largeur, graphique avec libellé accessible, textes honnêtes (« Non mesuré » au lieu de 0), `requestId` contre le double remboursement, motif obligatoire pour une période offerte.
- Réglages du club : recherche sans accents, dialogue d'information par option, sections repliables, confirmations bien formulées pour le code d'invitation.
- Feuille « Équipes & stades » : `viewInsets` gérés, étiquette « Actions pour <équipe> » sur le menu ⋮, message clair avant suppression.
- Fin de saison : texte explicite + bouton rouge ; paiement : libellé avec le montant, `messenger` capturé avant l'`await`, jamais d'écriture sans confirmation pour le retrait de compte.
- Page « Accès suspendu » : défilable, `SafeArea`, largeur maxi lisible.

## Comptage
Bloquant 1 · Gênant 56 · Détail 92 · À vérifier 6 (comptage des lignes de constat).
