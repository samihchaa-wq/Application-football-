// Identifiants proposés à l'inscription, dans l'ordre d'essai.
//
// Les identifiants sont uniques dans toute l'application (ils servent
// d'adresse de connexion), pas seulement dans un club. Avec plusieurs
// centaines de clubs, plus de 20 « Thomas M. » deviennent probables : après
// les 20 suffixes simples (thomasm, thomasm2… thomasm20), on essaie des
// suffixes à trois chiffres tirés au hasard plutôt que d'échouer.
export const SIMPLE_SUFFIXES = 20;
export const RANDOM_ATTEMPTS = 30;
export const MAX_USERNAME_BASE_LENGTH = 27;

export function usernameCandidates(
  base: string,
  random: () => number = Math.random,
): string[] {
  const root = base.slice(0, MAX_USERNAME_BASE_LENGTH);
  const candidates: string[] = [];
  for (let suffix = 1; suffix <= SIMPLE_SUFFIXES; suffix++) {
    candidates.push(suffix === 1 ? root : `${root}${suffix}`);
  }
  for (let attempt = 0; attempt < RANDOM_ATTEMPTS; attempt++) {
    const number = 100 + Math.floor(random() * 900);
    const candidate = `${root}${number}`;
    if (!candidates.includes(candidate)) candidates.push(candidate);
  }
  return candidates;
}
