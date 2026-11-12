import {
  RANDOM_ATTEMPTS,
  SIMPLE_SUFFIXES,
  usernameCandidates,
} from "./username_candidates.ts";

function assert(condition: boolean, message: string): void {
  if (!condition) throw new Error(message);
}

Deno.test("les 20 premiers essais gardent les suffixes simples", () => {
  const candidates = usernameCandidates("thomasm");
  assert(candidates[0] === "thomasm", "premier essai sans suffixe");
  assert(candidates[1] === "thomasm2", "deuxième essai : 2");
  assert(candidates[SIMPLE_SUFFIXES - 1] === "thomasm20", "vingtième : 20");
});

Deno.test("au-delà de 20 homonymes, des suffixes à trois chiffres", () => {
  const candidates = usernameCandidates("thomasm");
  assert(
    candidates.length > SIMPLE_SUFFIXES,
    "des essais supplémentaires existent",
  );
  for (const candidate of candidates.slice(SIMPLE_SUFFIXES)) {
    assert(/^thomasm[1-9][0-9]{2}$/.test(candidate), candidate);
  }
  assert(
    candidates.length <= SIMPLE_SUFFIXES + RANDOM_ATTEMPTS,
    "nombre d'essais borné",
  );
});

Deno.test("aucun doublon, même avec un tirage qui se répète", () => {
  const candidates = usernameCandidates("lucasb", () => 0.5);
  assert(new Set(candidates).size === candidates.length, "pas de doublon");
});

Deno.test("la base est tronquée à 27 caractères", () => {
  const candidates = usernameCandidates("a".repeat(40));
  assert(candidates[0].length === 27, "base tronquée");
});
