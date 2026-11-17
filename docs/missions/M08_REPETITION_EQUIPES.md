# M08 — Guides équipes et contrôle préparatoire

17 novembre 2026. Référence : `0e5fa39e87f17ba466ef187ae44495a65a67de9c` (main récupéré en lecture). Suite de la PR #152, fusionnée. **Revue statique exécutée ; aucune répétition applicative ni séance terrain exécutée.**

## Décisions prises en compte

L'unité produit et commerciale est **l'équipe**, sans niveau club à créer ni facturation regroupée à promettre. Le vocabulaire technique historique `club_id` ne justifie pas un parcours « club puis équipes ». Les anciens exemples de clubs physiques dans M08_PILOTES sont remplacés pour le recrutement et les mesures par 2–3 équipes pilotes autonomes. Les codes de suivi sont EQ-A, EQ-B, EQ-C.

Tarif de référence : 100 €/équipe/an ; gratuité réservée aux pilotes selon conditions précises à arrêter. Les promotions/parrainages décrits dans `docs/changes/161-promotions-parrainage.md` ne doivent pas être présentés comme utilisables : leur description n'est pas une preuve de disponibilité. Aucun code promotionnel, paiement ni invitation émis ici.

## Guide dirigeant — brouillon prêt pour répétition

1. Ouvrez l'adresse de test fournie par le responsable du pilote. Créez votre compte personnel et votre espace **équipe**. N'ouvrez pas un second espace pour corriger une erreur : signalez-la.
2. Conservez l'identifiant affiché à l'inscription. Utilisez votre propre e-mail et confirmez-le via le lien reçu, lorsque ce parcours a été validé pour la version de test. Ne partagez pas le lien de confirmation.
3. Dans Administration, créez la saison puis préparez l'effectif. Vérifiez les dates et les modules retenus pour votre équipe.
4. Après autorisation d'ouverture, partagez l'invitation uniquement aux membres concernés. Vérifiez les inscriptions en attente et les droits de chacun. Aucun compte partagé entre responsables.
5. Programmez le premier match avec adversaire, date et heure ; vérifiez la fiche depuis un compte joueur. Contrôlez que la période de disponibilités est ouverte, puis que les réponses sont conservées.
6. Préparez effectif et composition avant la limite annoncée. Si le Live est activé, validez son récapitulatif à la fin puis vérifiez résultat et statistiques.
7. Après le match, notez ce que vous avez réussi seul et toute aide demandée. Utilisez le formulaire de retour M08 ; aucune capture contenant des informations personnelles sur GitHub.

Ne pas remettre ce guide aux pilotes avant correction ou explication des écarts ci-dessous et contrôle M03 sur la version effectivement publiée. Les titres exacts des menus pourront évoluer.

## Guide joueur — brouillon prêt pour répétition

1. Ouvrez l'invitation privée de votre équipe et créez votre compte personnel. Vérifiez l'équipe affichée avant de continuer.
2. Confirmez votre e-mail via le message reçu. Si un administrateur doit encore activer le compte, attendez cette activation : ce sont deux étapes distinctes.
3. Ouvrez le prochain match ; répondez à votre disponibilité lorsque la période est ouverte et vérifiez la réponse affichée.
4. Consultez les modules proposés ; après le match, retrouvez le résultat et le vote s'il est disponible.
5. Si vous perdez l'accès, choisissez « Mot de passe oublié ? » et utilisez l'e-mail confirmé de votre compte. Si le lien n'arrive pas ou ne fonctionne pas, contactez le canal privé convenu ; n'envoyez jamais votre mot de passe.

Installation facultative : utiliser l'ajout à l'écran d'accueil proposé par le navigateur. Le navigateur reste le recours. Les consignes iPhone/Android et les notifications doivent être vérifiées sur appareils avant diffusion.

## Contrôle exécuté et écarts à traiter

Ces constats portent sur les fichiers du SHA ci-dessus, pas sur la production. Une absence dans ce parcours n'exclut pas un chantier en cours dans une autre branche.

| ID | Observation vérifiée dans le code | Conséquence sur l'accueil | Responsable et critère de clôture |
| --- | --- | --- | --- |
| M08-R01 | `auth_register_page.dart` affiche « Adresse e-mail (facultatif) » ; `_submit` vérifie le format seulement si la valeur est non vide | Ne pas annoncer que l'e-mail est déjà obligatoire ; récupération autonome non garantie pour chaque nouveau compte | M02/M03, chantier #160 à rapprocher : refus d'une nouvelle inscription sans e-mail, confirmation et récupération testées sans perdre les anciens comptes |
| M08-R02 | Le même formulaire demande une confirmation « 15 ans ou plus », sans champ date de naissance dans le formulaire lu | Écart avec la demande propriétaire de saisir la date de naissance ; pas de nouvelle collecte initiée par le guide | M02/M07/M03 : définir usage et conservation puis tester date requise, validité et seuil d'âge ; ne pas présenter le simple champ comme validation juridique |
| M08-R03 | `auth_register_page.dart` et `choose_club_page.dart` proposent encore « Créer un club », « Rejoindre un club » et « Nom du club » | Le guide équipe ne correspond pas encore aux libellés visibles | M05/M02 : libellés équipe cohérents, erreurs et invitations comprises ; M03 vérifie nouvel utilisateur et utilisateur connecté sans espace |
| M08-R04 | Le message de succès conserve l'identifiant, distingue `registration.isActive` et conditionne l'annonce d'e-mail à `emailConfirmationSent` | L'inscription, l'activation admin et la confirmation e-mail ne sont pas une unique étape | M03 : prouver chaque état, lien expiré, retour sans session, activation avant/après confirmation ; M07 valide l'accès permis |

Autres points retrouvés statiquement : `admin_season_section.dart` contient « Créer une saison » ; `club_settings_page.dart` contient « Membres et invitations » et la copie de lien ; `account_email_repository.dart` appelle les actions request-confirmation/confirm ; l'écran de connexion propose une récupération par adresse confirmée. **Code présent, aucun envoi e-mail ni résultat serveur vérifié ici.**

## Répétition à exécuter sans vrais participants

Environnement requis : application et backend isolés autorisés, boîte de test sans destinataire réel, deux espaces d'équipes fictives, versions client/serveur connues. Ne pas remplacer cet environnement par la production commerciale. Aucun de ces prérequis n'est déclaré disponible par ce document.

| Cas | Action et résultat à constater | Preuve à conserver | État actuel |
| --- | --- | --- | --- |
| REP-01 | Créer EQ-A avec e-mail, confirmer, retrouver identifiant et se reconnecter | SHA client/serveur, étape, résultat anonymisé | Non exécuté |
| REP-02 | Ouvrir invitation depuis session vide puis session existante sans équipe ; code conservé, équipe correcte et consentement explicite | Cas initial, équipe attendue/obtenue, absence de rattachement silencieux | Non exécuté |
| REP-03 | Joueur en attente ; activation par admin, confirmation e-mail dans les deux ordres | États avant/après et droits constatés | Non exécuté |
| REP-04 | Mot de passe oublié, lien expiré puis lien valide, reconnexion | Résultats sans conserver les liens/jetons | Non exécuté |
| REP-05 | Saison, premier match, réponse joueur enregistrée, composition et Live/clôture si activés | Actions, temps, aides, résultat persistant | Non exécuté |
| REP-06 | iPhone/Android : navigateur, installation, reconnexion ; permission notification acceptée/refusée si module disponible | Modèle générique, OS/navigateur, restrictions | Non exécuté |
| REP-07 | Retour simulé sans identité : formulaire → ticket → correction → vérification → retest | Identifiant synthétique unique et liens, temps de tri | Non exécuté |
| REP-08 | Fin d'essai refusée : restitution et accès suivant conditions convenues, aucun paiement déclenché | Contrat de test et états, vérification M07/M09 | Non exécuté |

Pour REP-07, exemple **fictif, non incident réel** : « EQ-A, joueur, impossible de retrouver le résultat après validation du Live ». Qualifier d'abord : validation réellement terminée ? bon match ? modules ? Une incompréhension va à M05 ; résultat manquant reproductible va à M02/M03. Ni bug confirmé ni ticket de production créé pour cet exemple.

Critère de réussite de la répétition : toutes les étapes essentielles réussies avec preuves ; toute aide est notée. Un développeur qui déroule le parcours ne prouve pas l'autonomie d'un bénévole : celle-ci reste à observer pendant le pilote réel.

## Transmission au chef de projet

Livré : deux guides équipe et huit cas de répétition, quatre écarts statiques documentés. Contrôles réellement exécutés : récupération de main, lecture Auth/admin et documents M00/M06/161, comparaison des libellés au kit, contrôle documentaire du diff. Aucune CI applicative revendiquée ; Flutter non trouvé dans le PATH lors de la préparation. Aucun contact, invitation, compte distant, écriture Supabase, dépense, fusion ou publication.

Prochaine action concrète : M02/M05 rapprochent R01–R04 des chantiers existants (notamment #160), M03 choisit l'environnement isolé et exécute REP-01–REP-08. M07 valide l'information et l'accès après inscription ; M06 fixe les dates/conditions de sortie avant présentation. Aucun GO terrain déduit de la fusion du kit #152.
