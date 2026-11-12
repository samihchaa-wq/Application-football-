import {
  CURRENT_CLUB_CONTRACT_VERSION,
  CURRENT_TERMS_VERSION,
  parseClubContractVersion,
  parseConsent,
} from "./consent.ts";
import * as claimClub from "../claim-club/consent.ts";

function assertEquals(actual: unknown, expected: unknown, message?: string) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      message ?? `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}

// Les deux parcours (inscription avec mot de passe, et rattachement d'un
// compte Facebook) doivent appliquer exactement les mêmes règles.
const parcours = [
  { name: "register-account", parseConsent, parseClubContractVersion },
  {
    name: "claim-club",
    parseConsent: claimClub.parseConsent,
    parseClubContractVersion: claimClub.parseClubContractVersion,
  },
];

Deno.test("les deux parcours publient les mêmes versions", () => {
  assertEquals(claimClub.CURRENT_TERMS_VERSION, CURRENT_TERMS_VERSION);
  assertEquals(claimClub.CURRENT_CLUB_CONTRACT_VERSION, CURRENT_CLUB_CONTRACT_VERSION);
});

for (const p of parcours) {
  Deno.test(`${p.name} : accepte la version publiée et une déclaration d'âge`, () => {
    assertEquals(
      p.parseConsent({ acceptedTermsVersion: CURRENT_TERMS_VERSION, ageConfirmation: "15_or_more" }),
      { termsVersion: CURRENT_TERMS_VERSION, ageConfirmation: "15_or_more" },
    );
    assertEquals(
      p.parseConsent({
        acceptedTermsVersion: ` ${CURRENT_TERMS_VERSION} `,
        ageConfirmation: "parental_consent",
      }),
      { termsVersion: CURRENT_TERMS_VERSION, ageConfirmation: "parental_consent" },
    );
  });

  Deno.test(`${p.name} : refuse une inscription sans consentement valide`, () => {
    for (const body of [
      {},
      { acceptedTermsVersion: CURRENT_TERMS_VERSION },
      { ageConfirmation: "15_or_more" },
      { acceptedTermsVersion: "oui", ageConfirmation: "15_or_more" },
      { acceptedTermsVersion: CURRENT_TERMS_VERSION, ageConfirmation: "moins_de_15" },
      // Version ancienne ou future : pas celle des textes publiés.
      { acceptedTermsVersion: "2000-01-01", ageConfirmation: "15_or_more" },
      { acceptedTermsVersion: "2099-12-31", ageConfirmation: "15_or_more" },
    ]) {
      assertEquals(p.parseConsent(body), null, JSON.stringify(body));
    }
  });

  Deno.test(`${p.name} : n'enregistre que la version publiée du contrat club`, () => {
    assertEquals(
      p.parseClubContractVersion({ acceptedClubContractVersion: CURRENT_CLUB_CONTRACT_VERSION }),
      CURRENT_CLUB_CONTRACT_VERSION,
    );
    for (const body of [
      {},
      { acceptedClubContractVersion: "" },
      { acceptedClubContractVersion: "oui" },
      { acceptedClubContractVersion: "2000-01-01" },
      { acceptedClubContractVersion: "2099-12-31" },
    ]) {
      assertEquals(p.parseClubContractVersion(body), null, JSON.stringify(body));
    }
  });
}
