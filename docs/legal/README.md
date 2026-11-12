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

Les passages `[ … ]` sont à compléter (identité de l'éditeur, SIRET, adresse
de Supabase, prix). **Ces textes sont des projets : relecture par un
professionnel du droit obligatoire avant de faire payer un club.**

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
  fichiers**. **Limite connue :**
  l'appli ne redemande pas encore l'accord après un changement de version ;
  écran à construire avant la première modification des textes.

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
