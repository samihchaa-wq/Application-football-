import { parseConsent } from "./consent.ts";

function assertEquals(actual: unknown, expected: unknown, message?: string) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      message ?? `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}

Deno.test("accepte une version et une déclaration d'âge valides", () => {
  assertEquals(
    parseConsent({ acceptedTermsVersion: "2026-11-12", ageConfirmation: "15_or_more" }),
    { termsVersion: "2026-11-12", ageConfirmation: "15_or_more" },
  );
  assertEquals(
    parseConsent({ acceptedTermsVersion: " 2026-11-12 ", ageConfirmation: "parental_consent" }),
    { termsVersion: "2026-11-12", ageConfirmation: "parental_consent" },
  );
});

Deno.test("refuse une inscription sans consentement", () => {
  for (const body of [
    {},
    { acceptedTermsVersion: "2026-11-12" },
    { ageConfirmation: "15_or_more" },
    { acceptedTermsVersion: "oui", ageConfirmation: "15_or_more" },
    { acceptedTermsVersion: "2026-11-12", ageConfirmation: "moins_de_15" },
  ]) {
    assertEquals(parseConsent(body), null, JSON.stringify(body));
  }
});
