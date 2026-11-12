/// Textes légaux de l'application : mentions légales, conditions générales
/// d'utilisation (membres), politique de confidentialité, conditions
/// d'abonnement (clubs) et accord sur le traitement des données (clubs).
///
/// Les passages entre crochets [ … ] sont à compléter par l'éditeur avant
/// l'ouverture à un premier club. Ces textes sont des projets : ils doivent
/// être relus par un professionnel du droit avant toute commercialisation
/// (voir docs/legal/README.md).
///
/// Toute modification de fond des CGU ou de la politique de confidentialité
/// doit faire changer [legalVersion] ; toute modification de fond des
/// conditions d'abonnement ou de l'accord sur les données doit faire changer
/// [clubContractVersion].
library;

/// Version des CGU et de la politique de confidentialité acceptée à
/// l'inscription. Format AAAA-MM-JJ.
const String legalVersion = '2026-11-12';

/// Version des conditions d'abonnement et de l'accord sur les données,
/// acceptée par la personne qui crée un club. Format AAAA-MM-JJ.
const String clubContractVersion = '2026-11-12';

class LegalSection {
  const LegalSection(this.title, this.paragraphs);

  final String title;
  final List<String> paragraphs;
}

class LegalDocument {
  const LegalDocument({
    required this.slug,
    required this.title,
    required this.sections,
  });

  /// Dernier segment de l'adresse : `/legal/<slug>`.
  final String slug;
  final String title;
  final List<LegalSection> sections;
}

// ---------------------------------------------------------------------------
// Coordonnées de l'éditeur : à compléter une fois l'entreprise créée.
// ---------------------------------------------------------------------------

const String _editorName =
    '[Prénom NOM], entrepreneur individuel (micro-entreprise)';
const String _editorShortName = '[Prénom NOM]';
const String _editorAddress = '[Adresse postale de l’éditeur]';
const String _editorEmail = '[adresse e-mail de contact]';
const String _editorSiret = 'SIRET : [numéro, une fois l’entreprise créée]';
const String _vatMention = 'TVA non applicable, article 293 B du CGI';
const String _dataRetentionAfterEnd = '6 mois';

const LegalDocument legalNotice = LegalDocument(
  slug: 'mentions',
  title: 'Mentions légales',
  sections: [
    LegalSection('Éditeur', [
      '$_editorName\n$_editorAddress\nContact : $_editorEmail\n$_editorSiret\n'
          '$_vatMention.',
      'Directeur de la publication : $_editorShortName.',
    ]),
    LegalSection('Hébergement', [
      'Données et comptes : Supabase Inc. [adresse postale à recopier depuis '
          'supabase.com/privacy]. Les données sont stockées dans un centre de '
          'données situé à Paris (Union européenne).',
      'Site de l’application : GitHub Pages, GitHub Inc., 88 Colin P. Kelly '
          'Jr. Street, San Francisco, CA 94107, États-Unis.',
    ]),
    LegalSection('Propriété intellectuelle', [
      'L’application, son code, son nom, ses visuels et ses badges '
          'appartiennent à l’éditeur ou sont utilisés avec l’autorisation de '
          'leurs auteurs. Toute reproduction sans accord écrit est interdite.',
      'Les logos, photos et contenus ajoutés par les clubs et leurs membres '
          'restent la propriété de leurs auteurs.',
    ]),
    LegalSection('Signaler un contenu illicite', [
      'Écris à $_editorEmail en indiquant : le club et la page concernés, le '
          'contenu en cause, pourquoi tu le juges illicite, ton nom et ton '
          'adresse e-mail, et une phrase confirmant que ton signalement est '
          'fait de bonne foi.',
      'L’éditeur accuse réception, examine le signalement rapidement et '
          'informe de sa décision la personne qui a signalé comme celle qui a '
          'publié, avec ses raisons. Cette adresse est aussi le point de '
          'contact unique pour les autorités et les utilisateurs.',
    ]),
  ],
);

const LegalDocument termsOfUse = LegalDocument(
  slug: 'cgu',
  title: 'Conditions générales d’utilisation',
  sections: [
    LegalSection('1. Objet', [
      'L’application permet à un club de football amateur d’organiser sa vie '
          'sportive : calendrier, disponibilités, compositions, matchs en '
          'direct, statistiques, pronostics, votes, badges et notifications.',
      'Ces conditions s’appliquent à toute personne qui crée un compte, '
          'membre ou administrateur d’un club. L’abonnement payé par le club '
          'relève des conditions d’abonnement, acceptées par le club.',
    ]),
    LegalSection('2. Qui fait quoi', [
      'L’éditeur ($_editorShortName) fournit l’application et l’héberge.',
      'Le club choisit d’utiliser l’application, désigne ses administrateurs '
          'et décide des informations qu’il y enregistre sur ses membres.',
      'Les administrateurs du club valident les membres et gèrent l’effectif, '
          'les matchs et les réglages du club.',
    ]),
    LegalSection('3. Compte et accès', [
      'Un compte est rattaché à un seul club. On le crée avec le code '
          'd’invitation du club ; un administrateur valide ensuite '
          'l’inscription. La personne qui crée un club en devient '
          'administratrice.',
      'Tu t’engages à donner des informations exactes et à garder ton mot de '
          'passe secret. Tu es responsable des actions faites depuis ton '
          'compte. Si tu te connectes avec Facebook, Facebook transmet ton nom '
          'et ton adresse e-mail à l’application.',
      'L’utilisation de l’application est gratuite pour les membres.',
    ]),
    LegalSection('4. Mineurs', [
      'Un mineur de moins de 15 ans ne peut s’inscrire qu’avec l’accord d’un '
          'titulaire de l’autorité parentale. Les parents peuvent à tout moment '
          'demander la consultation, la correction ou la suppression des '
          'données de leur enfant, auprès du club ou en écrivant à '
          '$_editorEmail.',
      'Les administrateurs du club s’assurent, pour les joueurs mineurs, que '
          'les parents sont informés de l’utilisation de l’application.',
    ]),
    LegalSection('5. Photos et droit à l’image', [
      'Une photo de profil est facultative. Tu ne publies que des photos dont '
          'tu as les droits, et une photo d’une autre personne uniquement avec '
          'son accord (celui de ses parents pour un mineur).',
      'Tu gardes tes droits sur ce que tu publies. Tu autorises seulement '
          'l’affichage de ces contenus aux membres de ton club, dans '
          'l’application, tant qu’ils y restent. Ils ne sont jamais visibles '
          'par les autres clubs ni réutilisés à des fins publicitaires.',
    ]),
    LegalSection('6. Comportement', [
      'Sont interdits : les propos injurieux, discriminatoires, violents ou '
          'harcelants, l’usurpation d’identité, la publication de contenus '
          'dont on n’a pas les droits ou de données de santé d’autrui, et '
          'toute tentative d’accéder aux données d’un autre club ou d’un autre '
          'membre, ou de perturber le service.',
    ]),
    LegalSection('7. Pronostics, votes et badges', [
      'Les pronostics, votes et badges sont un jeu entre membres, sans mise '
          'ni gain d’argent. Il est interdit de s’en servir pour organiser des '
          'paris ou une loterie avec mise d’argent ou lots achetés.',
    ]),
    LegalSection('8. Signalement et modération', [
      'Tout contenu illicite ou contraire à ces conditions peut être signalé '
          'à un administrateur du club ou à l’éditeur ($_editorEmail), comme '
          'indiqué dans les mentions légales.',
      'L’éditeur peut retirer un contenu, suspendre un compte ou un club qui '
          'ne respecte pas ces conditions. Il en informe la personne concernée '
          'et les administrateurs du club avec ses raisons, sauf urgence ou '
          'obligation légale contraire. La décision peut être contestée en '
          'répondant à ce message.',
    ]),
    LegalSection('9. Disponibilité et responsabilité', [
      'L’éditeur fait de son mieux pour que l’application fonctionne en '
          'permanence et sauvegarde régulièrement les données, sans pouvoir '
          'garantir l’absence de panne : maintenance, panne de l’hébergeur ou '
          'du réseau peuvent l’interrompre.',
      'L’application est un outil d’organisation. Les informations saisies '
          '(scores, statistiques, compositions, absences) relèvent de la '
          'responsabilité des clubs et des membres qui les saisissent.',
      'Rien dans ces conditions ne limite les droits que la loi garantit aux '
          'consommateurs.',
    ]),
    LegalSection('10. Fin du compte', [
      'Tu peux supprimer ton compte à tout moment depuis ton profil. Un '
          'administrateur du club peut aussi retirer un membre du club.',
      'Si le club arrête l’application, les comptes de ses membres sont '
          'supprimés dans les conditions décrites dans la politique de '
          'confidentialité.',
    ]),
    LegalSection('11. Données personnelles', [
      'Le traitement des données est décrit dans la politique de '
          'confidentialité, accessible depuis l’application et avant '
          'l’inscription.',
    ]),
    LegalSection('12. Modification et droit applicable', [
      'Ces conditions peuvent évoluer. En cas de changement important, '
          'chaque membre en est informé et doit accepter la nouvelle version '
          'pour continuer à utiliser l’application ; il peut aussi supprimer '
          'son compte.',
      'Ces conditions sont soumises au droit français. En cas de difficulté, '
          'écris d’abord à $_editorEmail pour trouver une solution amiable. À '
          'défaut, le litige relève des tribunaux compétents selon la loi.',
    ]),
  ],
);

const LegalDocument privacyPolicy = LegalDocument(
  slug: 'confidentialite',
  title: 'Politique de confidentialité',
  sections: [
    LegalSection('Qui est responsable de tes données ?', [
      'Ton club est responsable des données sur la vie du club (effectif, '
          'matchs, disponibilités, statistiques…) : c’est lui qui décide de '
          'les enregistrer. L’éditeur de l’application ($_editorShortName, '
          '$_editorEmail) les héberge et les traite pour le compte du club, '
          'selon un accord écrit conforme à l’article 28 du RGPD.',
      'L’éditeur est lui-même responsable des données nécessaires à ton '
          'compte (connexion, e-mails de confirmation), à la sécurité du '
          'service, aux journaux techniques et à la gestion des abonnements '
          'des clubs.',
    ]),
    LegalSection('Quelles données ?', [
      '• Compte : prénom, nom, identifiant de connexion, adresse e-mail si tu '
          'en ajoutes une, photo si tu en ajoutes une, ta déclaration d’âge '
          'et la date à laquelle tu as accepté les conditions.',
      '• Vie du club : rôle, disponibilités et absences déclarées, '
          'participations aux matchs, statistiques, pronostics, votes, badges.',
      '• Le motif d’une absence n’est visible que par toi et les '
          'administrateurs du club. N’y écris pas de détail médical.',
      '• Notifications : l’adresse technique d’envoi de ton navigateur et '
          'l’historique des notifications reçues.',
      '• Journaux techniques : erreurs de l’application, adresse IP et dates '
          'de connexion, pour la sécurité et le dépannage.',
      '• Connexion avec Facebook (si tu la choisis) : Facebook transmet ton '
          'nom et ton adresse e-mail.',
      'Aucune donnée n’est vendue, ni utilisée pour de la publicité ou du '
          'profilage.',
    ]),
    LegalSection('Pourquoi, et sur quelle base légale ?', [
      '• Faire fonctionner ton compte et le service : exécution des '
          'conditions d’utilisation que tu as acceptées.',
      '• Organiser la vie sportive du club : intérêt légitime du club à '
          'gérer ses activités et ses membres.',
      '• Sécuriser le service et prévenir les abus : intérêt légitime de '
          'l’éditeur.',
      '• Notifications et photo de profil : ton choix. Tu peux couper les '
          'notifications ou retirer ta photo à tout moment.',
      '• Garder la preuve de ton acceptation des conditions : obligation de '
          'preuve de l’éditeur.',
    ]),
    LegalSection('Qui les voit ?', [
      'Les membres de ton club voient ton nom, ta photo et ta vie sportive '
          'dans le club. Les administrateurs voient en plus tes absences et '
          'leur motif. Aucun autre club n’a accès à tes données. Les votes '
          'pour l’homme du match sont anonymes.',
      'L’éditeur n’accède aux données d’un club que si c’est nécessaire : '
          'assistance demandée, sécurité, obligation légale.',
      'Prestataires techniques de l’éditeur : Supabase (hébergement des '
          'données, à Paris), GitHub (mise en ligne du site), Brevo (envoi '
          'des e-mails, France), Meta (seulement si tu te connectes avec '
          'Facebook), Google (polices de caractères de secours) et le service '
          'de notifications de ton navigateur (Google, Apple ou Mozilla), qui '
          'ne voit passer que des messages chiffrés.',
    ]),
    LegalSection('Transferts hors de l’Union européenne', [
      'Tes données sont stockées à Paris. Certains prestataires sont des '
          'sociétés américaines (Supabase, GitHub, Google, Meta) : quand une '
          'donnée peut leur être accessible depuis les États-Unis, le '
          'transfert est encadré par le cadre de protection des données '
          'UE–États-Unis ou par les clauses contractuelles types de la '
          'Commission européenne.',
    ]),
    LegalSection('Combien de temps ?', [
      'Tant que ton compte existe. Historique des notifications : 90 jours. '
          'Journaux techniques : 7 à 90 jours selon leur type. Sauvegardes '
          'chiffrées : effacées au bout de 90 jours.',
      'Quand ton compte est supprimé, tes données de compte sont effacées. '
          'Les faits sportifs déjà validés (score, buteur d’un match passé) '
          'peuvent rester dans l’historique du club, sans lien avec ton '
          'compte. Tu peux demander qu’ils soient aussi anonymisés.',
      'Si ton club arrête l’application, ses données sont supprimées '
          '$_dataRetentionAfterEnd après la fin de son abonnement.',
      'La preuve de ton acceptation des conditions est gardée 5 ans après la '
          'fin de ton compte, le temps pendant lequel un litige reste possible.',
    ]),
    LegalSection('Tes droits', [
      'Depuis ton profil, tu peux à tout moment télécharger tes données '
          '(fichier lisible par un autre service) et supprimer ton compte.',
      'Tu peux aussi demander l’accès, la correction, l’effacement ou la '
          'limitation de tes données, ou t’opposer à un traitement, auprès '
          'd’un administrateur de ton club ou en écrivant à $_editorEmail. '
          'L’éditeur transmet au club les demandes qui le concernent. Réponse '
          'sous un mois.',
      'Si tu estimes que tes droits ne sont pas respectés, tu peux saisir la '
          'CNIL (cnil.fr).',
    ]),
    LegalSection('Mineurs', [
      'En France, un mineur de moins de 15 ans ne peut s’inscrire qu’avec '
          'l’accord d’un titulaire de l’autorité parentale, qui peut exercer '
          'ses droits à sa place auprès du club ou en écrivant à '
          '$_editorEmail.',
    ]),
    LegalSection('Sécurité', [
      'Connexion chiffrée, données de chaque club cloisonnées dans la base, '
          'mots de passe jamais stockés en clair, accès limités au strict '
          'nécessaire, sauvegardes chiffrées. En cas de fuite de données '
          'présentant un risque, le club et, si nécessaire, la CNIL et les '
          'personnes concernées sont prévenus.',
    ]),
    LegalSection('Cookies et stockage', [
      'L’application n’utilise ni cookie publicitaire ni outil de mesure '
          'd’audience. Elle garde seulement sur ton appareil ce qui est '
          'nécessaire à son fonctionnement (session ouverte, préférences, '
          'copie locale du calendrier) : ce stockage ne demande pas de '
          'consentement.',
    ]),
  ],
);

const LegalDocument clubSalesTerms = LegalDocument(
  slug: 'cgv',
  title: 'Conditions d’abonnement des clubs',
  sections: [
    LegalSection('1. Parties et objet', [
      'Ces conditions régissent l’abonnement à l’application entre '
          '$_editorName ($_editorSiret, ci-après « l’éditeur ») et le club '
          'qui l’utilise (ci-après « le club »).',
      'L’abonnement est réservé aux associations, clubs et autres personnes '
          'morales. La personne qui crée le club dans l’application déclare '
          'agir au nom du club et avoir le pouvoir de l’engager.',
      'En créant le club, elle accepte pour lui ces conditions et l’accord '
          'sur le traitement des données des membres, qui en fait partie.',
    ]),
    LegalSection('2. Essai gratuit', [
      'Chaque nouveau club bénéficie d’un essai gratuit de 30 jours, sans '
          'engagement et sans moyen de paiement. À la fin de l’essai, le club '
          'choisit de s’abonner ou non ; rien n’est facturé automatiquement.',
    ]),
    LegalSection('3. Prix', [
      'L’abonnement est annuel. Son prix dépend du nombre de joueurs de '
          'l’effectif de la saison : [10] € par joueur et par an au lancement, '
          'sauf devis particulier. Le montant exact est indiqué au club avant '
          'tout paiement. $_vatMention.',
      'Les prix peuvent évoluer pour les saisons suivantes ; le club est '
          'prévenu au moins un mois avant le renouvellement.',
    ]),
    LegalSection('4. Facturation et paiement', [
      'L’éditeur adresse une facture au club. Elle est payable sous 30 jours '
          'par virement, ou par carte ou prélèvement quand ce moyen sera '
          'proposé.',
      'En cas de retard, l’éditeur relance le club. Sans paiement 15 jours '
          'après cette relance, il peut suspendre l’accès du club. Lorsque le '
          'club agit en qualité de professionnel, des pénalités de retard au '
          'taux de trois fois l’intérêt légal et l’indemnité forfaitaire de '
          '40 € pour frais de recouvrement sont dues.',
    ]),
    LegalSection('5. Durée, renouvellement et résiliation', [
      'L’abonnement couvre une période de 12 mois à compter du paiement. Il '
          'ne se renouvelle pas tacitement : l’éditeur propose le '
          'renouvellement avant la fin de la période et le club reste libre '
          'de ne pas renouveler.',
      'Le club peut arrêter à tout moment ; l’accès reste ouvert jusqu’à la '
          'fin de la période payée, sans remboursement de la période en cours.',
      'En cas de manquement grave du club à ces conditions ou aux CGU, '
          'l’éditeur peut résilier après une mise en demeure restée sans effet '
          'pendant 15 jours.',
      'Si l’éditeur arrête le service, il prévient le club au moins 3 mois à '
          'l’avance, lui permet de récupérer ses données et rembourse la part '
          'de l’abonnement non utilisée.',
    ]),
    LegalSection('6. Engagements de l’éditeur', [
      'Fournir l’application et ses mises à jour, héberger les données dans '
          'l’Union européenne, cloisonner les données de chaque club, les '
          'sauvegarder régulièrement et répondre par e-mail aux demandes '
          'd’assistance dans un délai raisonnable.',
      'L’éditeur s’engage à une obligation de moyens : il n’offre pas de '
          'garantie de disponibilité chiffrée.',
    ]),
    LegalSection('7. Engagements du club', [
      'Utiliser l’application conformément à la loi et aux CGU, désigner des '
          'administrateurs fiables et garder leurs accès secrets.',
      'Informer ses membres (et les parents des mineurs) de l’utilisation de '
          'l’application, n’y enregistrer que des personnes qui l’acceptent, '
          'et respecter ses obligations de responsable du traitement, '
          'décrites dans l’accord sur les données.',
      'Déclarer un effectif exact pour le calcul du prix.',
    ]),
    LegalSection('8. Données du club et réversibilité', [
      'Le club reste propriétaire de ses données, de son nom et de son logo. '
          'Il autorise l’éditeur à les afficher dans l’application pour les '
          'besoins du service.',
      'Pendant l’abonnement et jusqu’à $_dataRetentionAfterEnd après sa fin, '
          'le club peut demander une copie de ses données dans un format '
          'lisible. Passé ce délai, elles sont supprimées.',
      'L’éditeur ne cite le club comme référence commerciale qu’avec son '
          'accord.',
    ]),
    LegalSection('9. Responsabilité', [
      'L’éditeur n’est responsable que des dommages directs causés par une '
          'faute prouvée de sa part. Sa responsabilité totale est limitée aux '
          'sommes payées par le club au cours des 12 derniers mois.',
      'Cette limite ne s’applique pas en cas de faute lourde ou '
          'intentionnelle, ni aux dommages corporels.',
      'Aucune des parties n’est responsable d’un manquement dû à un cas de '
          'force majeure.',
    ]),
    LegalSection('10. Modification', [
      'L’éditeur peut faire évoluer ces conditions. Toute modification '
          'importante est annoncée au club au moins un mois avant son entrée '
          'en vigueur ; s’il la refuse, le club peut résilier et être '
          'remboursé de la part non utilisée.',
    ]),
    LegalSection('11. Droit applicable et litiges', [
      'Ces conditions sont soumises au droit français. Les parties cherchent '
          'd’abord une solution amiable. À défaut, le litige est porté devant '
          'les tribunaux compétents.',
    ]),
  ],
);

const LegalDocument clubDataProcessingAgreement = LegalDocument(
  slug: 'donnees-club',
  title: 'Accord sur le traitement des données des membres',
  sections: [
    LegalSection('1. Objet et rôles', [
      'Cet accord fait partie des conditions d’abonnement. Il répond à '
          'l’article 28 du Règlement général sur la protection des données '
          '(RGPD).',
      'Pour les données de ses membres, le club est responsable du '
          'traitement et l’éditeur est son sous-traitant. Pour les données '
          'qu’il traite pour son propre compte (comptes de connexion, '
          'sécurité, journaux techniques, facturation), l’éditeur est '
          'lui-même responsable.',
    ]),
    LegalSection('2. Description du traitement', [
      '• Finalité : organiser la vie sportive du club (calendrier, '
          'disponibilités, compositions, matchs, statistiques, pronostics, '
          'votes, badges, notifications).',
      '• Opérations : hébergement, stockage, affichage aux membres du club, '
          'envoi de notifications et d’e-mails, sauvegarde, suppression.',
      '• Personnes concernées : membres, joueurs (y compris mineurs), '
          'dirigeants, entraîneurs et invités du club.',
      '• Données : identité, photo facultative, adresse e-mail facultative, '
          'rôle, vie sportive, disponibilités et absences, votes et '
          'pronostics, données techniques de notification.',
      '• Durée : celle de l’abonnement, puis $_dataRetentionAfterEnd avant '
          'suppression.',
    ]),
    LegalSection('3. Engagements de l’éditeur', [
      '• Ne traiter les données que pour fournir le service, selon les '
          'instructions du club, données par l’usage des fonctions et des '
          'réglages de l’application. Prévenir le club si une instruction lui '
          'paraît contraire à la loi.',
      '• Ne jamais vendre les données, ni les utiliser pour de la publicité '
          'ou pour son propre compte.',
      '• Garantir la confidentialité : seules les personnes qui en ont besoin '
          'y accèdent, et elles y sont tenues.',
      '• Sécurité : connexion chiffrée, cloisonnement des données de chaque '
          'club dans la base, accès limités, mots de passe jamais stockés en '
          'clair, sauvegardes chiffrées, hébergement à Paris.',
      '• Aider le club à répondre aux demandes de ses membres (outils '
          'd’export et de suppression dans l’application, et aide sur '
          'demande).',
      '• Prévenir le club sans délai, et au plus tard 48 heures après l’avoir '
          'découverte, de toute violation de données le concernant, avec les '
          'informations utiles pour qu’il puisse la déclarer à la CNIL.',
      '• Aider le club, sur demande, pour une analyse d’impact ou une '
          'consultation de la CNIL.',
      '• À la fin de l’abonnement, rendre les données au club s’il le '
          'demande, puis les supprimer, sauvegardes comprises, dans les délais '
          'prévus.',
      '• Tenir à la disposition du club les informations prouvant le respect '
          'de cet accord, et accepter un audit raisonnable, au plus une fois '
          'par an, annoncé 30 jours à l’avance, aux frais du club.',
    ]),
    LegalSection('4. Sous-traitants de l’éditeur', [
      'Le club autorise l’éditeur à faire appel aux prestataires suivants : '
          'Supabase Inc. (hébergement des données, Paris), GitHub Inc. (mise '
          'en ligne du site et sauvegardes chiffrées), Brevo / Sendinblue SAS '
          '(e-mails, France), Meta Platforms Ireland (connexion Facebook, si '
          'le membre la choisit), et les services de notification des '
          'navigateurs (Google, Apple, Mozilla).',
      'L’éditeur leur impose des obligations de protection équivalentes. Il '
          'prévient le club au moins 30 jours avant d’en ajouter ou d’en '
          'changer ; le club peut s’y opposer et, à défaut d’accord, résilier '
          'avec remboursement de la part non utilisée.',
      'Un transfert de données hors de l’Union européenne n’a lieu qu’avec '
          'les garanties prévues par le RGPD (décision d’adéquation ou clauses '
          'contractuelles types).',
    ]),
    LegalSection('5. Engagements du club', [
      '• Disposer d’une base légale pour les données qu’il enregistre et en '
          'informer ses membres ; la politique de confidentialité de '
          'l’application peut l’y aider.',
      '• Pour un mineur de moins de 15 ans, s’assurer que ses parents ont '
          'donné leur accord.',
      '• Ne pas enregistrer de données sensibles (santé, opinions, '
          'religion…) et demander aux membres de ne pas en écrire dans les '
          'motifs d’absence.',
      '• Garder secrets les accès de ses administrateurs et retirer ceux qui '
          'quittent leurs fonctions.',
      '• Tenir son propre registre des traitements.',
    ]),
  ],
);

/// Documents montrés à tous : membres et visiteurs.
const List<LegalDocument> legalDocuments = [
  legalNotice,
  termsOfUse,
  privacyPolicy,
  clubSalesTerms,
  clubDataProcessingAgreement,
];

/// Version affichée en bas d'un document.
String legalVersionOf(LegalDocument document) =>
    identical(document, clubSalesTerms) ||
            identical(document, clubDataProcessingAgreement)
        ? clubContractVersion
        : legalVersion;

LegalDocument? legalDocumentBySlug(String slug) {
  for (final document in legalDocuments) {
    if (document.slug == slug) return document;
  }
  return null;
}
