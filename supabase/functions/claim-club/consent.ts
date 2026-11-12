// Consentement donné à l'inscription : version des CGU et de la politique de
// confidentialité acceptée, et déclaration d'âge (en France, un mineur de
// moins de 15 ans ne peut s'inscrire qu'avec l'accord d'un parent).
//
// Les versions acceptées sont fixées ici, côté serveur : une version envoyée
// par le client n'est enregistrée que si elle correspond exactement aux
// textes publiés. Elles doivent rester identiques à `legalVersion` et
// `clubContractVersion` de lib/features/legal/domain/legal_documents.dart
// (vérifié par tool/tests/test_commercial_legal_versions.py).
//
// Ce fichier est recopié à l'identique dans supabase/functions/claim-club/.

/** Version publiée des CGU et de la politique de confidentialité. */
export const CURRENT_TERMS_VERSION = "2026-11-12";

/** Version publiée des conditions d'abonnement et de l'accord sur les données. */
export const CURRENT_CLUB_CONTRACT_VERSION = "2026-11-12";

export type AgeConfirmation = "15_or_more" | "parental_consent";

export type Consent = {
  termsVersion: string;
  ageConfirmation: AgeConfirmation;
};

/**
 * Le consentement lu dans la requête, ou `null` s'il manque, est invalide ou
 * porte sur une autre version que les textes publiés.
 */
export function parseConsent(body: Record<string, unknown>): Consent | null {
  const termsVersion = String(body.acceptedTermsVersion ?? "").trim();
  const ageConfirmation = String(body.ageConfirmation ?? "").trim();
  if (termsVersion !== CURRENT_TERMS_VERSION) return null;
  if (ageConfirmation !== "15_or_more" && ageConfirmation !== "parental_consent") {
    return null;
  }
  return { termsVersion, ageConfirmation };
}

/**
 * Création d'un club : version du contrat du club (conditions d'abonnement et
 * accord sur le traitement des données des membres) acceptée par la personne
 * qui crée le club. Seule la version publiée est acceptée : toute autre valeur
 * (ancienne, future, absente) donne `null`.
 */
export function parseClubContractVersion(
  body: Record<string, unknown>,
): string | null {
  const version = String(body.acceptedClubContractVersion ?? "").trim();
  return version === CURRENT_CLUB_CONTRACT_VERSION ? version : null;
}
