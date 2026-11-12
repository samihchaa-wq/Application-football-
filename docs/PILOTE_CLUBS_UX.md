# Mission 08 — Clubs pilotes et expérience utilisateur

> **Statut : protocole proposé, non exécuté — 12/11/2026.**  
> Responsable : fil 08. Ce document prépare les essais en conditions réelles ; il ne constitue **ni** un résultat de test utilisateur, **ni** une autorisation de publication, **ni** un feu vert commercial.
>
> **Invariants :** ne jamais intervenir sur le dépôt ni la base AS Grinta d'origine ; aucune écriture sur Supabase commercial sans accord explicite ; aucun contact, recrutement, compte réel, collecte de données réelles, dépense ou campagne sans accord ; tests préparatoires avec identités fictives ; données isolées par club.

## 0. Sources examinées et constat vérifié

- Dépôt commercial `samihchaa-wq/Application-football-`, branche `main` ; `docs/HANDOFF.md`, `docs/COMMERCIAL_LAUNCH_CHECKLIST.md`, `README.md`, `AGENTS.md`.
- Audit fonctionnel du fil 1 : **PR #25 ouverte** au moment du constat, `docs/AUDIT_FONCTIONNALITES.md` consulté sur `claude/project-thread-isgvly` (pas encore dans `main`). **Ne pas substituer ce document à l'audit du fil 1.**
- Publication d'essai à deux clubs fictifs : **PR #24 ouverte** (pas fusionnée), donc ne pas considérer GitHub Pages comme publiquement utilisable du seul fait du code de la PR.
- Lecture de code : `lib/features/auth/presentation/auth_register_page.dart`, `choose_club_page.dart`, `auth_sign_in_page.dart`, `lib/app/router/auth_redirect.dart`, `lib/features/admin/presentation/admin_page.dart`, `admin_season_section.dart`, `club_settings_page.dart`, `lib/features/matches/presentation/calendar_entry_form_page.dart`, `match_form_page.dart`, `lib/features/club/data/club_repository.dart`.
- Supabase **commercial uniquement** (`jvxkhgdopslctpcjrhzw`) : lecture de la structure et requêtes `SELECT` agrégées. Le 12/11/2026 : **0 club, 0 profil, 0 saison, 0 joueur, 0 match, 0 abonnement** ; les tables publiques observées ont RLS activée. Dernière migration enregistrée : `20261112050000`. **8 Edge Functions au statut ACTIVE**, dont `register-account`, `claim-club`, `claim-account`, `send-push`. `ACTIVE` ne prouve ni la configuration Auth/SMTP/VAPID ni le fonctionnement bout en bout.
- **Aucune création de compte, aucun envoi d'e-mail ou de notification, aucun test de navigation réelle, aucune modification SQL, aucune mesure UX réelle.** Les validations techniques restent aux fils 3 et 4.

## 1. Choix recommandé pour la phase pilote

### 1.1 Périmètre de départ

**Commencer petit : deux clubs de test fictifs, puis trois équipes volontaires réellement indépendantes d'AS Grinta, par paliers.**

- **Préparatoire sans utilisateur réel :** clubs fictifs A et B, chacun avec **1 administrateur et 6 à 8 comptes joueurs fictifs**, plus une session membre « en attente ». Ce sont des objectifs de test, pas des comptes déjà créés. Création autorisée uniquement après feu vert explicite pour écrire en base commerciale.
- **Pilote réel : 3 équipes distinctes** de **15 à 30 membres** chacune, **1 administrateur principal + 1 suppléant** si possible ; idéalement équipes loisirs adultes au football à 11, avec un calendrier d'au moins **2 rencontres pendant le test**. Au total, environ 45 à 90 joueurs potentiels, non encore recrutés.
- **Diversité recherchée :** (A) équipe loisirs autonome à l'aise avec le numérique ; (B) équipe vétérans/amateurs à organisation régulière ; (C) équipe où l'administrateur est moins à l'aise avec la technique. Tous dans le fuseau Europe/Paris pour cette première étape ; pas de mineurs durant la première vague, en attendant validation spécifique du fil 7.
- **Limiter volontairement la première vague** aux équipes uniques et au football à 11 : plusieurs équipes dans un même club et formats 5/7/8 ne sont pas encore garantis (audit fil 1). Ne pas vendre cette limitation comme une capacité déjà disponible.
- **Durée indicative : 6 à 7 semaines de travail pilote après prérequis :** semaine 1 préparation fictive et garde-fous, semaine 2 club réel A, semaines 3–4 ouverture progressive B puis C, semaines 5–6 utilisation autonome sur les matchs, semaine 7 bilan et arbitrage si les calendriers le nécessitent. Reporter si les clubs n'ont pas eu deux rencontres effectives.

### 1.2 Portes d'entrée / montée en charge

| Porte | Conditions nécessaires | Décision |
| --- | --- | --- |
| G0 — Préparation fictive | Déploiement commercial vérifié sur URL séparée ; Auth e-mail/redirections vérifiées ; obligations légales adaptées aux tests ; fil 4 confirme l'absence de connexion aux bases d'origine | Autoriser **uniquement** les comptes fictifs A/B après accord du propriétaire |
| G1 — Deux clubs fictifs | Parcours de bout en bout sur navigateur et PWA ; séparation A/B prouvée en REST, RPC, Storage, notifications et rôles ; aucun P0/P1 actif ; confirmation technique fils 3/4 | Demander l'accord avant le premier club réel |
| G2 — Club pilote A | Création, invitation, connexion, validation, saison, premier match, disponibilité, notifications ou alternative explicite : parcours exécuté sans intervention sur les données par l'éditeur ; retours utilisables | Ouvrir B, puis C de façon étagée |
| G3 — Bilan pilote | Au moins 2 rencontres par équipe testées ; problèmes classés ; indicateurs consolidés ; avis administrateurs recueillis ; sécurité et conformité validées | Décider : corriger et prolonger / ouvrir prudemment / refuser le lancement payant |

Aucune porte n'est réputée franchie à la rédaction du présent plan.

### 1.3 Fonctions minimales pour un vrai club test

**Indispensables :** inscription et mot de passe/récupération, création d'un club, accès administrateur, invitations, validation des profils, réglages essentiels, ouverture de saison, intégration d'un effectif, création et consultation d'un match, réponse aux disponibilités, gestion des cas d'erreur, isolation multiclub, accès mobile, mécanisme de support, textes obligatoires validés, accès et sécurité des photos et comptes.

**À vérifier explicitement avant l'ouverture :** fonctionnement réel de l'envoi d'e-mails, du retour à la connexion, du nom/écusson/couleurs, du partage WhatsApp, de l'installation PWA, des notifications (avec solution de repli en cas d'impossibilité technique), et des autorisations admin/joueur.

**Non obligatoire pour le tout premier match :** présentation animée de composition, récompenses, bilan de saison, statistiques historiques, toutes les variantes de maillots. Ne pas supprimer ces fonctionnalités ; les laisser dans le périmètre global du produit et les tester à mesure de leur disponibilité.

## 2. Parcours exact d'un nouveau club : état du code et points à observer

| N° | Action attendue côté administrateur ou joueur | Éléments déjà repérés dans le code | Risque UX / question d'observation |
| --- | --- | --- | --- |
| 01 | Découvrir l'URL commerciale et comprendre l'offre | Page de connexion `/auth/sign-in` avec lien « Créer mon compte » | Comprend-on qu'on peut **créer un club**, pas seulement rejoindre un club ? Lien légal et identité commerciale clairs ? |
| 02 | Choisir « Créer un club » | `/auth/register` : onglets « Rejoindre un club » / « Créer un club » | L'onglet par défaut ou le vocabulaire créent-ils une hésitation ? |
| 03 | Renseigner nom, nom court, prénom, nom, mot de passe et consentements ; e-mail facultatif | `auth_register_page.dart` ; validation de code d'invitation pour un membre | Longueur perçue, erreurs, accessibilité ; récupération du compte si e-mail absent |
| 04 | Lire, conserver son identifiant, puis se connecter | Boîte de dialogue après création ; retour `/auth/sign-in` ; identifiant + mot de passe | L'identifiant est-il compris/conservé ? Reconnexion sur un deuxième téléphone ? |
| 05 | Arriver sur un club **vide** | Club créé et créateur admin ; pas de contenu AS Grinta dans la base | L'absence de matchs, joueurs et stats est-elle bien expliquée ? Y a-t-il un « premier pas » clair ? |
| 06 | Personnaliser identité et modules | `/admin/club` : nom, logo, couleurs, code/lien, modules, règles | Découvre-t-on les réglages ? Comprend-on les paramètres sans jargon ? |
| 07 | Créer la saison | Administration → onglet Saison → « Créer une saison » | Où trouver ce bouton ? La valeur proposée de saison est-elle pertinente ? |
| 08 | Créer/compléter l'effectif et inviter les joueurs | Administration → Membres/Effectif ; bouton « Lien d'inscription » ; code de 8 caractères | Ordre « créer saison » / « inviter » compris ? Lien ouvert correctement dans les messageries ? |
| 09 | Faire accepter les comptes | Joueur s'inscrit avec code ; état « en attente » ; onglet Admin → En attente | Admin voit-il l'attente ? Joueur comprend-il qui doit valider et quoi faire ? |
| 10 | Programmer le premier match | `CalendarEntryFormPage` : saison ouverte requise, adversaire, date, heure, lieu, convocations ; type championnat/amical/entre nous | L'adversaire doit être créé ; cotes calculées ; champs et options peuvent sembler nombreux pour un premier match |
| 11 | Consulter et rejoindre la rencontre | Calendrier `/matches` et fiche match ; disponibilité et modules activés | Le match est-il immédiatement visible ? Sait-on où répondre à sa disponibilité ? |
| 12 | Recevoir informations et rappels | Notifications, préférences personnelles, agenda `.ics` | PWA installée ? Autorisations Android/iOS ? En cas de push absent, autre moyen fiable de consulter ? |
| 13 | Après la rencontre : renseigner et valider | Modules Live / compte rendu / statistiques selon activation | L'admin comprend-il comment clôturer le match sans assistance ? |

**Deux parcours alternatifs à tester :** inscription via lien direct avec code prérempli ; authentification Facebook puis écran `/auth/choose-club` pour rattacher un compte sans club (**uniquement si le fournisseur OAuth est réellement configuré**). Ne pas laisser le bouton Facebook visible au pilote si l'authentification correspondante n'est pas opérationnelle sans message adapté.

### 2.1 Frictions prioritaires à faire remonter aux autres fils

| ID | Priorité de diagnostic | Hypothèse / élément à confirmer | Fil responsable |
| --- | --- | --- | --- |
| UX-01 | P1 si constaté bloquant | Première visite d'un club vide : absence d'un parcours guidé clair de type « Créer saison → inviter effectif → programmer match » ; **hypothèse**, pas un bug constaté | 2 (parcours), 5 (micro-UX) |
| UX-02 | P1 si constaté bloquant | Création de match trop lourde pour premier usage ; nécessité de créer adversaire et de disposer des cotes | 2 / 3 |
| UX-03 | P1 si constaté bloquant | Validation manuelle des comptes : incompréhension côté joueur/admin ou délais excessifs | 2 / 3 |
| UX-04 | P1 si constaté bloquant | Auth, e-mails transactionnels, redirections et récupération de compte non encore validés sur la base commerciale | 3 / 4 |
| UX-05 | P1 si constaté bloquant | Notifications web/PWA non confirmées sur les vrais appareils ; installer l'app est nécessaire sur iPhone | 3 / 4 |
| UX-06 | P2, selon cible | Format 11, maillots fixes, nombre de convoqués et terrain par défaut encore partiellement adaptés selon PR #25 | 1 / 2 |
| UX-07 | P2, risque futur | Homonymes : identifiant global unique, plafonnement technique mentionné dans l'audit #25 | 2 |
| UX-08 | P2 | Paramètres et modules multiples : intitulés et valeurs par défaut incompris ; ne pas refondre sans observation | 5 / 2 |
| UX-09 | P0 si confirmé | Un club peut lire des données d'un autre : **aucune preuve de fuite**, scénario obligatoire de sécurité | 4 / 3 |
| UX-10 | P1 avant tout pilote réel | Offre, identité de marque, mentions légales, données et consentement adéquats à l'essai | 5 / 6 / 7 |

Les priorités ci-dessus sont des **priorités de vérification**, non des tickets de défaut confirmé. Fil 08 documente et reproduit ; les fils 2–5 corrigent selon leur périmètre.

## 3. Scénarios utilisateur (à exécuter, aucun résultat encore)

Pour chaque scénario : appareil/navigateur/OS ; rôle ; club ; préconditions ; **temps de réalisation** ; succès sans aide (oui/non) ; hésitations ; paroles spontanées (avec accord) ; captures expurgées ; ID incident. Faire réaliser sans tutoriel pour la première observation, puis proposer une aide mesurée.

| ID | Scénario / réussite attendue | Profils | Verdict |
| --- | --- | --- | --- |
| T01 | Depuis la première page, créer le club A, noter l'identifiant, se reconnecter ; club vide visible | Admin fictif A | Non exécuté |
| T02 | Reprendre une inscription interrompue, erreurs de mot de passe, email invalide, erreur réseau ; récupération sans doublon | Admin A | Non exécuté |
| T03 | Configurer logo/couleurs, copier invitation, régler un module et une règle ; changement persistant | Admin A | Non exécuté |
| T04 | Créer une saison, ajouter plusieurs membres à l'effectif, vérifier effectif et statut | Admin A | Non exécuté |
| T05 | Rejoindre par lien sur téléphone, vérifier code prérempli, attente puis approbation ; accès club après validation | Joueur A + Admin A | Non exécuté |
| T06 | Ouvrir un code erroné, expiré ou renouvelé ; message explicite, aucune affiliation indue | Joueur A | Non exécuté |
| T07 | Créer premier amical contre nouvel adversaire : date, heure, adresse, saison, cotes, enregistrement et affichage | Admin A | Non exécuté |
| T08 | Répondre présent/absent, modifier réponse, vérifier les informations de convocation | Joueurs A | Non exécuté |
| T09 | Afficher le match / agenda / module pronostic selon les activations et horaires | Joueurs A | Non exécuté |
| T10 | Tester l'installation PWA, autorisation et réception push Android puis iOS ; documenter les restrictions | Joueurs fictifs | Non exécuté |
| T11 | Clôturer première rencontre ; saisie du score et bilan / vote uniquement si fonctions activées | Admin A | Non exécuté |
| T12 | L'admin B et le joueur B essaient les routes et ID A via UI, API, Storage, RPC ; aucun accès à A | Fil 4 / 3 | Non exécuté |
| T13 | Compte en attente, refusé, supprimé, session expirée et utilisateur simple : accès admin impossible | Fil 4 / 3 | Non exécuté |
| T14 | Déconnexion / reconnexion, lien partagé, navigation retour, faible réseau et retour en ligne sans pertes | Tous | Non exécuté |
| T15 | Mobile petit écran, grands textes, contraste, clavier, accessibilité des boutons | Tous | Non exécuté |
| T16 | Deux admins simultanément : validation d'un membre et modification d'un même match ; résultat cohérent | Admin A | Non exécuté |
| T17 | Désactiver une option : les écrans et actions serveur correspondants se comportent comme prévu | Admin A / joueur A | Non exécuté |
| T18 | Joueur sans adresse e-mail : comprendre les conséquences pour la récupération de compte | Joueur fictif A | Non exécuté |

**Distinguer systématiquement :** « code présent », « test unitaire vert », « simulation », « testé réellement sur appareil », « validé par un club externe ». Aucun des cinq ne remplace automatiquement un autre.

## 4. Protocole d'observation et questions

### 4.1 À l'arrivée (3 à 5 minutes ; uniquement après consentement adapté)

1. Quel est votre rôle dans l'équipe ? Admin principal, aide-admin, joueur ?
2. Combien de membres actifs et de matchs environ organisez-vous dans une saison ? (fourchettes)
3. Comment gérez-vous aujourd'hui convocations, matchs et disponibilités ? (réponse libre)
4. Utilisez-vous plutôt Android, iPhone ou ordinateur ? Avez-vous déjà installé une PWA ?
5. Qu'aimeriez-vous impérativement réaliser sans devoir contacter le créateur de l'application ?

Ne pas demander nom de famille, adresse personnelle ou autre donnée non nécessaire au questionnaire. Associer un code aléatoire de participant/club plutôt qu'une identité dans le fichier de suivi.

### 4.2 En séance sans assistance (exemples de consignes)

**Admin :** « Vous voulez utiliser cet outil pour votre équipe. Créez votre espace, démarrez une saison, invitez un membre et planifiez un match amical. Dites-nous quand vous pensez avoir fini. »  
**Joueur :** « Ouvrez l'invitation reçue, créez votre compte, accédez au match et indiquez votre disponibilité. »  
**Admin sur mobile :** « Retrouvez les inscriptions en attente, acceptez un membre, changez l'heure du prochain match. »

L'observateur n'explique pas les boutons, note les blocages ; aide seulement si l'utilisateur ne peut plus continuer (enregistrée comme aide fournie).

### 4.3 Après usage (fin de séance puis semaines 2 et 6)

Noter de **1 = très difficile** à **5 = très facile/satisfaisant** :

1. Créer ou rejoindre l'espace club.
2. Comprendre ce qu'il fallait faire ensuite.
3. Retrouver les menus et informations nécessaires.
4. Planifier ou retrouver un match et participer.
5. Confiance dans les données et la fiabilité perçue.
6. Facilité de gestion **sans aide extérieure** (admin).
7. Quelle étape a demandé le plus d'effort ? (libre)
8. Qu'avez-vous cherché sans réussir à le trouver ? (libre)
9. Quel est **l'unique changement** qui vous aiderait le plus ? (libre)
10. Si vous deviez décider aujourd'hui, continueriez-vous à utiliser cette application pour votre équipe ? **Oui / Peut-être / Non** ; pourquoi ? Cette intention **n'est pas** une preuve de volonté de payer.

Demander également, séparément et sans engagement, si l'admin souhaiterait évaluer un abonnement payant futur ; **aucune sollicitation commerciale sans accord du propriétaire ni transparence sur les conditions**.

## 5. Collecte, incidents, suggestions et arbitrage

### 5.1 Canal de retour

Pour le pilote : un **point de contact convenu** avec l'admin (canal unique à définir avant le pilote). L'admin peut transférer un signalement provenant d'un joueur ; en cas de problème de confidentialité, orienter directement vers la procédure du fil 9 / fil 7, sans partage de comptes ni capture de données d'autres personnes.

**Modèle de signalement :** code incident ; date ; rôle (admin/joueur) ; code du club ; appareil/OS/navigateur ; fonctionnalité ; étapes exactes ; attendu / observé ; fréquence ; contournement ; impact ; pièce jointe expurgée si indispensable ; version de l'app ; consentement au rappel. Ne jamais demander mot de passe, jeton, lien d'invitation actif ou photo de pièces d'identité.

### 5.2 Tableau unique de suivi (modèle)

| ID | Source / club codé | Type | Impact | Reproductible | Statut | Fil destinataire | Validation corrective |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **EXEMPLE — NON OBSERVÉ** | PIL-A | Friction UX | P2 | À vérifier | À qualifier | 5 | Non réalisée |

Types : **BUG** (comportement incorrect), **FRICTION** (tâche réalisable mais pénible), **BESOIN RÉCURRENT** (objectif récurrent non couvert), **PRÉFÉRENCE** (choix individuel), **SÉCURITÉ** (traitement prioritaire par fil 4), **QUESTION** (documentation/aide).

**Sévérité :** P0 = fuite, mauvais club, suppression injustifiée, accès illégitime ou incident critique → arrêt du pilote concerné ; P1 = inscription/match/disponibilités/connexion impossible sans alternative acceptable ; P2 = étape difficile, contournable ; P3 = détail cosmétique. Priorité d'étude = sévérité × fréquence × étendue, pas le volume vocal des demandes.

**Workflow :** Nouveau → Qualifié → Reproduit / non reproduit → Affecté au bon fil → Correction proposée → Vérifié techniquement → Revalidé avec utilisateur → Clos, ou « Reporté, motivé ». Un besoin isolé n'entraîne pas de nouveau développement par défaut ; documenter fréquence, contexte et bénéfice avant décision.

### 5.3 Discipline de confidentialité

- Mesures agrégées au niveau club et étape, plutôt qu'un journal permanent des comportements individuels ; pas de pixels marketing, d'enregistrement de session, ni de suivi de géolocalisation.
- Retour anonyme ou pseudonyme possible ; information claire sur finalité, durée, accès et droit de retrait ; validation par le fil 7 avant collecte externe.
- Fichiers d'incidents **sans** données identifiantes si possible, captures expurgées, accès restreint, suppression programmée (proposition : détails bruts sous 90 jours après clôture, sauf obligation de conservation différente définie par fil 7).
- Ne pas publier des verbatims ou noms des clubs pilotes dans les PR sans accord.

## 6. Indicateurs et seuils de décision proposés

**Seuils proposés à confirmer avant observation**, non atteints et non mesurés à ce stade. Définir la période de mesure : première semaine pour activation ; semaines 3–6 pour fidélisation.

| Indicateur (mode de calcul) | Seuil pilote proposé | Collecte proportionnée |
| --- | --- | --- |
| **Autonomie création de club** = admin qui finit création + connexion sans aide / admins testés | 3 sur 3 ; temps cible ≤ 15 min | Observation horodatée volontaire, pas de télémétrie détaillée |
| **Première configuration autonome** = saisons + au moins 1 membre invité + premier match créé sans intervention de l'éditeur / clubs testés | 3 sur 3, avec aide écrite autorisée | Checklist admin |
| **Activation joueurs J+7** = joueurs invités ayant un compte validé / joueurs réellement invités | ≥ 80 % (en excluant les non-volontaires explicitement) | Comptages agrégés et déclarations admin |
| **Accès au premier match** = participants actifs capables de retrouver et consulter la fiche / participants observés | ≥ 90 % | Exercices utilisateurs anonymisés |
| **Participation au match** = joueurs actifs ayant répondu à leur disponibilité avant la fenêtre prévue / joueurs concernés | ≥ 75 % | Agrégat par rencontre, seulement si gestion sportive activée |
| **Problèmes graves ouverts** = nombre de P0/P1 non corrigés à G3 | 0 | Tableau incidents |
| **Problèmes signalés** = nombre P1/P2 par club/semaine, délai de résolution | Tendance décroissante ; aucun P1 persistant | Registre support |
| **Utilisation régulière** = joueurs volontaires ayant accompli une action-clé dans la semaine / joueurs activés | Cible indicative ≥ 60 % en semaines avec match | Statistiques agrégées minimales, fil 7 |
| **Satisfaction admins** = note 1–5 sur gestion autonome | Médiane ≥ 4/5 ; aucun admin bloqué durablement | 3 réponses distinctes |
| **Intention de poursuivre** = clubs répondant Oui (pas « peut-être ») / clubs pilotes | ≥ 2 clubs sur 3 **et raisons documentées** | Questionnaire de sortie |

Avec **3 clubs, les pourcentages sont très incertains**. Les chiffres orientent les décisions, ils ne prouvent pas un marché ni une capacité à payer. Comparer également les situations réelles : club à 0 membre, 1 membre, 30 membres, personne sans PWA, membre qui ne répond jamais.

## 7. Rapport de validation avant commercialisation (trame obligatoire)

### Rapport — `PILOT-REVIEW-AAAA-MM-JJ`

- **Version/commit GitHub :** [à renseigner] ; **environnement :** [à renseigner].
- **Clubs participants :** [codes uniquement] ; effectif, nombre d'admins et formats de jeu ; **accords et base juridique vérifiés :** [oui/non].
- **Dates et rencontres réellement observées :** [à renseigner] ; ne pas confondre démos et matchs.
- **Chemin complet testé :** découverte / création / identité / saison / invitations / validation / match / disponibilités / PWA / retour après match — pour chaque étape : testé sur appareil, assistance, résultat.
- **Indicateurs avec numérateur, dénominateur et période :** [tableau §6 rempli].
- **Incidents :** P0/P1/P2/P3, statut, reproductibilité, preuves corrigées, risques résiduels.
- **Sécurité (fil 4) :** séparation multiclub, secrets, RLS, Storage, notifications, sauvegarde/restauration.
- **Qualité (fil 3) :** tests automatisés, tests Android/iOS/navigateurs, difficultés connues.
- **Juridique (fil 7) :** conformité documents, données, image, consentements.
- **Exploitation (fil 9) :** canal support, traitement incidents, réponse et escalade.
- **Commercial (fil 6) :** positionnement, abonnement, prix, moyens d'encaissement, assistance promise.
- **Décision :** **GO PAYANT / GO limité (sans encaissement) / NO-GO**, datée et approuvée explicitement par le propriétaire. Pas de GO payant tant que paiement et obligations commerciales ne sont pas validés.

### Critères non négociables du GO payant

1. Aucun P0 ou P1 d'inscription, permissions, visibilité interclubs, match, notifications essentielles ou perte de données encore ouvert ; aucune fuite interclubs observée dans la couverture du plan de tests du fil 4.
2. Un administrateur extérieur crée un club, ouvre une saison, invite ses joueurs et programme son premier match avec l'aide minimale prévue ; validation sur **les 3 clubs**.
3. Au moins **2 rencontres utilisables** par club, sauf restriction explicitement décidée et documentée ; les modules optionnels annoncés comme disponibles ont été testés.
4. URL commerciale, disponibilité, récupération de comptes, politique de sauvegarde/restauration, support et canal d'incident opérationnels.
5. Feu vert technique fils 3/4, cohérence visuelle fil 5, contractualisation/paiement fil 6 et conformité fil 7, assistance fil 9.
6. Décision de lancement et tarification prises par le propriétaire, distinctes du rapport de tests. Un questionnaire positif ne déclenche **jamais** automatiquement un lancement.

## 8. Coordination et prochaines décisions

- **Fil 1 :** source des fonctionnalités, hypothèses des limitations de format et des réglages ; référence PR #25.
- **Fil 2 :** correction seulement après dossier reproductible, conserver la DA et le comportement d'AS Grinta autant que possible.
- **Fil 3 :** tests d'interface et de flux réel, comptes fictifs, régression, appareils.
- **Fil 4 :** preuve d'isolation multiclub, supervision, secrets, charge, sécurité PWA et API.
- **Fil 5 :** observer avant modifier les surfaces. Préférer un guidage bref/états vides plutôt qu'une refonte.
- **Fil 6 :** recruter des volontaires **seulement après accord** ; distinguer satisfaction et intention de payer.
- **Fil 7 :** encadrer questionnaires, collecte, droits, contrats des tests et mineurs.
- **Fil 9 :** définir signalement, escalade et assistance dès le pilote.
- **Fil 08 :** protocole UX, collecte sobre, suivi, synthèse et proposition de GO/NO-GO ; **pas** de modifications Supabase ou de correction du code fonctionnel dans ce document.

**Décisions à obtenir avant usage réel :** validation des trois profils de clubs ; autorisation explicite d'approcher les clubs ; validation de l'avis d'information aux testeurs et des documents légaux ; autorisation séparée de créer les comptes fictifs sur la base commerciale et de mettre en ligne l'environnement pilote ; confirmation de la disponibilité du canal support.

**Prochaine vérification après G0 :** faire exécuter à une personne qui ne connaît pas AS Grinta la tâche unique « créer un club, une saison et un match » sans consigne supplémentaire. C'est le premier test d'autonomie, et non une démonstration de l'éditeur.
