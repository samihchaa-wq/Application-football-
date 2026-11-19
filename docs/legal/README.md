# Textes légaux et conformité

Mis à jour le 12/11/2026. Le dossier complet destiné à Samih (risques,
actions, questions pour le juriste) est un document Claude :
https://claude.ai/artifact/XvLJNHydxiczd434c3eLrx

## Où sont les textes

`lib/features/legal/domain/legal_documents.dart` contient les cinq textes,
affichés à `/legal/<slug>` sans connexion :

| Slug | Texte | Accepté par |
| --- | --- | --- |
| `mentions` | Mentions légales | — |
| `cgu` | Conditions générales d'utilisation | chaque membre, à l'inscription |
| `confidentialite` | Politique de confidentialité | chaque membre, à l'inscription |
| `cgv` | Conditions d'abonnement des clubs | la personne qui crée le club |
| `donnees-club` | Accord sur le traitement des données (art. 28 RGPD) | la personne qui crée le club |

Les passages `[ … ]` sont à compléter : nom, adresse, e-mail, téléphone et
SIREN de l'éditeur, médiateur de la consommation.

**Pas de relecture par un juriste pour l'instant (décision de l'éditeur du
19/11/2026, faute de budget).** Les choix ci-dessous ont été tranchés à partir
des textes officiels et des conditions des prestataires. Ils réduisent le
risque mais ne remplacent pas un avis professionnel : en faire relire au
moins les conditions d'abonnement dès que possible.

## Décisions prises le 19/11/2026

| Sujet | Décision | Pourquoi |
| --- | --- | --- |
| Rôles RGPD | Le club est responsable des données de ses membres, l'éditeur est son sous-traitant ; l'éditeur reste responsable des comptes, de la sécurité, des journaux et de la facturation | Schéma habituel d'un logiciel en ligne vendu à une structure qui décide de l'utiliser et de qui elle inscrit |
| Qualité du club | Une association est traitée comme un **non-professionnel** | Le code de la consommation (art. L212-2) étend la protection contre les clauses abusives aux non-professionnels |
| Limite de responsabilité | **Supprimée** (droit commun : dommages directs et prévisibles) | Une clause qui réduit le droit à réparation est interdite face à un non-professionnel (art. R212-1, 6°) |
| Pénalités de retard et indemnité de 40 € | **Supprimées** | Réservées aux dettes entre professionnels (code de commerce) |
| Médiateur de la consommation | **Pas d'adhésion pour l'instant** (décision de l'éditeur), aucune clause dans les CGU | Les clubs payants sont des associations, non concernées. Les membres sont des particuliers liés par les CGU, mais à titre gratuit : la loi (art. L612-1) ne dit pas clairement si un service gratuit est visé. **Risque accepté** : amende possible si un membre se plaint aux autorités. Coût pour s'en protéger : environ 40 à 85 € par an ou pour 3 ans |
| Mentions légales | Ajout du téléphone et de l'e-mail de l'éditeur, du SIREN, et du téléphone des hébergeurs | Liste officielle (entreprendre.service-public.fr, fiche F37351) |
| Hébergement du site | **Cloudflare Pages** (déjà utilisé par la publication commerciale), et non GitHub Pages | Les conditions de GitHub Pages interdisent un service commercial ; celles de Cloudflare interdisent seulement de collecter des numéros de carte bancaire sur un site gratuit (aucun ici) |
| Transferts hors UE | Supabase : Singapour et États-Unis, clauses contractuelles types | Page « Data residency and transfers » de Supabase |
| Historique après suppression | Le nom du joueur **reste** dans les matchs passés, **raccourci automatiquement** (« Yves D. ») à la suppression du compte ; « Ancien joueur » sur demande (page admin « Anciens joueurs ») | C'est ce que fait réellement la base (table `players`) ; l'ancien texte laissait croire le contraire. « Yves D. » reste identifiable dans un club : « Ancien joueur » si la personne insiste |
| E-mail | **Obligatoire** à l'inscription (rejoindre ou créer un club) | Récupération du compte et avertissement avant suppression pour inactivité. Les comptes créés par un administrateur peuvent ne pas en avoir |
| Suivi des e-mails | Ouvertures comptées **anonymement** (`contactPixelTrackingConsent: false` à chaque envoi) + option « Anonymous email tracking » à activer dans Brevo | La CNIL dispense de consentement un comptage global servant à vérifier la délivrabilité |
| Connexion Facebook | Retirée des textes | Désactivée ; à remettre dans la politique (et Meta dans les prestataires) le jour où elle est activée |
| Durées | 3 ans sans connexion pour un compte, 3 ans après la fin de l'abonnement pour un club | Couvre l'arrêt d'une ou deux saisons |
| Parrainage | Clause ajoutée aux conditions d'abonnement | Le programme existait sans aucune règle écrite |
| Mineurs | Déclaration cochée à l'inscription (15 ans ou plus, ou accord parental) | Pratique courante ; aucune vérification d'identité n'est exigée par la loi |
| Droit de rétractation | Aucun | Les clubs sont des personnes morales : pas de droit de rétractation pour un achat en ligne |

## À faire avant d'ouvrir au public

- Compléter les crochets : nom, adresse du domicile, numéro de téléphone
  personnel, SIREN (choix de l'éditeur : coordonnées personnelles).
- Outil des noms construit (migration `20261129010000`) : raccourci
  automatique à la suppression d'un compte, page « Anciens joueurs » pour les
  administrateurs. Limite connue : l'historique des notifications (gardé
  90 jours) peut encore contenir l'ancien nom jusqu'à son effacement.
- Vérifier que le compte technique `00000000-0000-0000-0000-000000000001`
  existe dans la base commerciale : sans lui, toute suppression de compte
  échoue (déjà le cas avant cette branche).
- ~~Brevo : suivi anonyme des e-mails~~ — activé par l'éditeur le 19/11/2026.
- Accessibilité : les micro-entreprises qui fournissent des services sont
  exemptées par la directive européenne sur l'accessibilité ; vérifier la
  transposition française (loi n° 2023-171) si l'activité grandit.

## Versions et preuves

- `legalVersion` (CGU + confidentialité) est enregistrée dans
  `profiles.terms_version` / `terms_accepted_at`, avec la déclaration d'âge.
- `clubContractVersion` (CGV + accord sur les données) est enregistrée dans
  `public.club_contract_acceptances` par les fonctions `register-account` et
  `claim-club`. Une création de club sans cette acceptation est refusée.
- Les fonctions serveur n'acceptent **que** la version publiée
  (`CURRENT_TERMS_VERSION` / `CURRENT_CLUB_CONTRACT_VERSION` dans
  `supabase/functions/*/consent.ts`) : une version ancienne, future ou
  inventée par une requête forgée est refusée. Ces constantes doivent rester
  égales à celles du fichier Dart (test `tool/tests/test_commercial_legal_versions.py`).
- Archive des textes : le texte exact d'une version est celui du fichier Dart
  dans l'historique Git à cette date. Avant la commercialisation, exporter
  aussi chaque version publiée en PDF horodaté, conservé hors du dépôt.
- La case « j'ai le pouvoir d'engager le club » est une déclaration : elle ne
  vérifie pas le pouvoir de représentation. Pour un club payant, faire signer
  ou confirmer le bon de commande par le président ou le trésorier.
- Changer la version à chaque modification de fond, **dans les trois
  fichiers**. À la connexion suivante, tout membre dont la version acceptée
  est plus ancienne (ou absente : compte créé par un administrateur, compte
  antérieur à l'enregistrement de l'accord) voit l'écran « Les conditions ont
  changé » (`/auth/accept-terms`). Il accepte (nouvelle version, date et
  déclaration d'âge enregistrées par `accept_terms`), se déconnecte ou
  supprime son compte. Rien d'autre de l'appli n'est accessible avant.

## Promesses des textes pas encore tenues par l'appli (19/11/2026)

À construire ou régler **avant l'ouverture au public**, sinon les textes
annoncent quelque chose de faux :

- **Comptes inactifs** : construit le 19/11/2026, **pas encore déployé ni
  testé en conditions réelles**. Chaque nuit, la base repère les comptes
  inutilisés depuis 3 ans moins un mois (une session restée ouverte compte
  comme une utilisation) ; la fonction `account-email` envoie l'e-mail
  d'avertissement, puis supprime un mois plus tard, avec les mêmes étapes
  qu'une suppression demandée par le membre. Rien ne se passe tant que
  l'envoi d'e-mails n'est pas configuré. Le dernier administrateur d'un club
  qui a d'autres membres n'est pas supprimé (il reste signalé dans les
  journaux de la fonction). Les comptes sans adresse e-mail sont supprimés
  sans avertissement possible : les textes le disent.
- **Traceur d'ouverture des e-mails** : Brevo peut suivre l'ouverture des
  e-mails envoyés. Les textes n'en parlent pas : désactiver ce suivi dans le
  compte Brevo (sinon il faudrait un consentement et une mention).
- **Connexion Facebook** : désactivée aujourd'hui. Les textes la mentionnent
  « quand cette option est proposée ». Vérifier, à l'activation, que Facebook
  ne transmet que l'identifiant, le nom et l'e-mail.
- **Médiateur de la consommation** : question au juriste. La loi l'impose
  pour un contrat avec un consommateur, même gratuit ; il est payant.

## Règles de conception à garder

- Ne pas stocker de données de santé. Le motif d'absence est libre :
  l'appli demande de ne pas y mettre de détail médical.
- Aucun cookie publicitaire ni outil de mesure d'audience : sinon un bandeau
  de consentement devient obligatoire.
- Tout nouveau prestataire qui reçoit des données personnelles doit être
  ajouté à la politique de confidentialité **et** à l'accord sur les données
  (les clubs doivent être prévenus 30 jours avant).
- Vidéo/photo du stade (`assets/composition/`) et icône
  `assets/images/icons/assist_boot.png` : origine et licence inconnues, à
  vérifier ou remplacer avant tout usage commercial.
