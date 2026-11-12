// Consentement donné à l'inscription : version des CGU et de la politique de
// confidentialité acceptée, et déclaration d'âge (en France, un mineur de
// moins de 15 ans ne peut s'inscrire qu'avec l'accord d'un parent).

export type AgeConfirmation = "15_or_more" | "parental_consent";

export type Consent = {
  termsVersion: string;
  ageConfirmation: AgeConfirmation;
};

const VERSION_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

/** Le consentement lu dans la requête, ou `null` s'il manque ou est invalide. */
export function parseConsent(body: Record<string, unknown>): Consent | null {
  const termsVersion = String(body.acceptedTermsVersion ?? "").trim();
  const ageConfirmation = String(body.ageConfirmation ?? "").trim();
  if (!VERSION_PATTERN.test(termsVersion)) return null;
  if (ageConfirmation !== "15_or_more" && ageConfirmation !== "parental_consent") {
    return null;
  }
  return { termsVersion, ageConfirmation };
}

/**
 * Création d'un club : version du contrat du club (conditions d'abonnement et
 * accord sur le traitement des données des membres) acceptée par la personne
 * qui crée le club, ou `null` si elle manque ou est invalide.
 */
export function parseClubContractVersion(
  body: Record<string, unknown>,
): string | null {
  const version = String(body.acceptedClubContractVersion ?? "").trim();
  return VERSION_PATTERN.test(version) ? version : null;
}
