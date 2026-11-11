/// Textes légaux de l'application : mentions légales, conditions générales
/// d'utilisation et politique de confidentialité.
///
/// Les passages entre crochets [ … ] sont à compléter par l'éditeur avant
/// l'ouverture à un premier club. Toute modification de fond des CGU ou de
/// la politique de confidentialité doit faire changer [legalVersion] : les
/// membres seront alors invités à accepter la nouvelle version.
library;

/// Version des CGU et de la politique de confidentialité acceptée à
/// l'inscription. Format AAAA-MM-JJ.
const String legalVersion = '2026-11-12';

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

const String _editorName = '[Nom et prénom de l’éditeur, ou raison sociale]';
const String _editorAddress = '[Adresse postale de l’éditeur]';
const String _editorEmail = '[Adresse e-mail de contact]';
const String _editorSiret = '[Numéro SIRET, une fois l’entreprise créée]';

const LegalDocument legalNotice = LegalDocument(
  slug: 'mentions',
  title: 'Mentions légales',
  sections: [
    LegalSection('Éditeur', [
      '$_editorName\n$_editorAddress\nContact : $_editorEmail\n$_editorSiret',
      'Directeur de la publication : $_editorName.',
    ]),
    LegalSection('Hébergement', [
      'Données et comptes : Supabase Inc., hébergement des données dans '
          'l’Union européenne [région à confirmer lors de la création de la '
          'base, Paris recommandé].',
      'Site de l’application : GitHub Pages, GitHub Inc., 88 Colin P. Kelly '
          'Jr. Street, San Francisco, CA 94107, États-Unis.',
    ]),
    LegalSection('Signaler un contenu', [
      'Pour signaler un contenu illicite ou demander son retrait, écris à '
          '$_editorEmail en indiquant le club, la page et le contenu concernés.',
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
          'direct, statistiques, pronostics, badges et notifications.',
      'Les présentes conditions s’appliquent à toute personne qui crée un '
          'compte, qu’elle soit membre ou administrateur d’un club.',
    ]),
    LegalSection('2. Compte et accès', [
      'Un compte est rattaché à un seul club. On le crée avec le code '
          'd’invitation du club ; un administrateur du club valide ensuite '
          'l’inscription. La personne qui crée un club en devient '
          'l’administrateur.',
      'Chacun est responsable de la confidentialité de son mot de passe et '
          'des actions faites depuis son compte.',
      'Les mineurs de moins de 15 ans ne peuvent s’inscrire qu’avec l’accord '
          'd’un titulaire de l’autorité parentale.',
    ]),
    LegalSection('3. Rôle des administrateurs de club', [
      'Les administrateurs valident les membres, gèrent l’effectif, les '
          'matchs et les réglages du club. Ils s’engagent à n’ajouter que des '
          'personnes qui l’acceptent et à ne publier une photo qu’avec '
          'l’accord de la personne photographiée (ou de ses parents pour un '
          'mineur).',
    ]),
    LegalSection('4. Comportement', [
      'Sont interdits : les propos injurieux, discriminatoires ou '
          'harcelants, l’usurpation d’identité, la publication de contenus '
          'dont on n’a pas les droits, et toute tentative d’accéder aux '
          'données d’un autre club ou d’un autre membre.',
      'L’éditeur peut suspendre un compte ou un club qui ne respecte pas ces '
          'règles, après avoir prévenu ses administrateurs sauf urgence.',
    ]),
    LegalSection('5. Abonnement du club', [
      'Chaque nouveau club bénéficie d’un essai gratuit de 30 jours, sans '
          'engagement et sans moyen de paiement.',
      'Au-delà, l’utilisation est soumise à un abonnement annuel payé par le '
          'club, calculé selon le nombre de joueurs de l’effectif de la saison '
          '(tarif indiqué dans les réglages du club, [10 € TTC] par joueur et '
          'par an au lancement). Les membres n’ont rien à payer.',
      'Sans abonnement à la fin de l’essai, ou en cas d’impayé, l’éditeur '
          'peut suspendre l’accès du club après l’avoir prévenu. Les données '
          'sont conservées pendant [6 mois] après la suspension, puis '
          'supprimées.',
      'Le club peut arrêter son abonnement à tout moment ; il reste actif '
          'jusqu’à la fin de la période payée.',
    ]),
    LegalSection('6. Disponibilité et responsabilité', [
      'L’éditeur fait de son mieux pour que l’application fonctionne en '
          'permanence, sans pouvoir le garantir : maintenances, pannes de '
          'l’hébergeur ou du réseau peuvent l’interrompre.',
      'L’application est un outil d’organisation. Les informations saisies '
          '(scores, statistiques, compositions) relèvent de la responsabilité '
          'des clubs et de leurs membres.',
    ]),
    LegalSection('7. Données personnelles', [
      'Le traitement des données est décrit dans la politique de '
          'confidentialité, accessible depuis l’application.',
    ]),
    LegalSection('8. Modification et droit applicable', [
      'Ces conditions peuvent évoluer. En cas de changement important, chaque '
          'membre est invité à accepter la nouvelle version lors de sa '
          'prochaine connexion.',
      'Les présentes conditions sont soumises au droit français. En cas de '
          'litige, une solution amiable sera recherchée avant toute action.',
    ]),
  ],
);

const LegalDocument privacyPolicy = LegalDocument(
  slug: 'confidentialite',
  title: 'Politique de confidentialité',
  sections: [
    LegalSection('Qui est responsable de tes données ?', [
      'L’éditeur de l’application ($_editorName, $_editorEmail) est '
          'responsable du traitement des données nécessaires au '
          'fonctionnement du service. Chaque club décide des informations '
          'sportives qu’il enregistre sur ses membres.',
    ]),
    LegalSection('Quelles données ?', [
      '• Compte : prénom, nom, identifiant de connexion, adresse e-mail si tu '
          'en ajoutes une, photo si tu en ajoutes une.',
      '• Vie du club : rôle, disponibilités et absences déclarées (avec leur '
          'motif, visible seulement par toi et les administrateurs), '
          'participations aux matchs, statistiques, pronostics, votes, badges.',
      '• Notifications : l’adresse technique d’envoi de ton navigateur et '
          'l’historique des notifications reçues.',
      '• Journaux techniques : erreurs de l’application et dates de '
          'connexion, pour la sécurité et le dépannage.',
      'Aucune donnée n’est vendue, ni utilisée pour de la publicité. '
          'L’application n’utilise pas de cookies de suivi : seul un stockage '
          'technique garde ta session ouverte.',
    ]),
    LegalSection('Pourquoi ?', [
      'Pour faire fonctionner le service que ton club utilise (exécution des '
          'conditions d’utilisation), et pour le sécuriser (intérêt '
          'légitime). L’adresse e-mail sert uniquement à te connecter, '
          'confirmer ton compte et retrouver ton mot de passe.',
    ]),
    LegalSection('Qui les voit ?', [
      'Les membres de ton club voient ton nom, ta photo et ta vie sportive '
          'dans le club. Les administrateurs de ton club voient en plus tes '
          'absences et leur motif. Aucun autre club n’a accès à tes données.',
      'Prestataires techniques : Supabase (hébergement des données dans '
          'l’Union européenne), GitHub (mise en ligne de l’application), '
          '[service d’envoi d’e-mails] et [Stripe pour le paiement des '
          'abonnements, qui ne concerne que les clubs].',
    ]),
    LegalSection('Combien de temps ?', [
      'Tant que ton compte existe. Historique des notifications : 90 jours. '
          'Journaux techniques : 7 à 90 jours selon leur type.',
      'Quand ton compte est supprimé, tes données de compte sont effacées. '
          'Les faits sportifs déjà validés (score, buteur d’un match passé) '
          'peuvent rester dans l’historique du club, sans lien avec ton '
          'compte.',
      'Si un club arrête l’application, ses données sont supprimées '
          '[6 mois] après la fin de son abonnement.',
    ]),
    LegalSection('Tes droits', [
      'Tu peux à tout moment, depuis ton profil : télécharger tes données '
          '(fichier lisible par un autre service) et supprimer ton compte.',
      'Tu peux aussi demander l’accès, la correction, l’effacement ou la '
          'limitation de tes données, ou t’opposer à un traitement, en '
          'écrivant à $_editorEmail. Réponse sous un mois.',
      'Si tu estimes que tes droits ne sont pas respectés, tu peux saisir la '
          'CNIL (cnil.fr).',
    ]),
    LegalSection('Mineurs', [
      'En France, un mineur de moins de 15 ans ne peut s’inscrire qu’avec '
          'l’accord d’un titulaire de l’autorité parentale, qui peut exercer '
          'ses droits à sa place en écrivant à $_editorEmail.',
    ]),
  ],
);

const List<LegalDocument> legalDocuments = [
  legalNotice,
  termsOfUse,
  privacyPolicy,
];

LegalDocument? legalDocumentBySlug(String slug) {
  for (final document in legalDocuments) {
    if (document.slug == slug) return document;
  }
  return null;
}
