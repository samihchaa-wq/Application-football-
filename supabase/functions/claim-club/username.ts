// Choix de l'identifiant de connexion d'un nouveau compte (prénom + initiale).
// Copie identique dans register-account et claim-club : chaque fonction est
// déployée avec ses propres fichiers.
//
// La base calcule le premier identifiant libre (public.internal_next_free_username)
// et garantit l'unicité. Si deux inscriptions simultanées obtiennent le même
// identifiant, la seconde est refusée par la base : on redemande alors un
// identifiant en signalant celui qui vient d'échouer.

export type ReserveOutcome = "ok" | "taken";

/// Réserve un identifiant : demande le premier libre à la base (`nextFree`),
/// tente de l'utiliser (`attempt`) et recommence avec le suivant si la base
/// signale qu'il vient d'être pris. Renvoie l'identifiant retenu, ou une
/// chaîne vide après `maxAttempts` collisions (ou si la base n'en propose pas).
export async function reserveUsername(
  nextFree: (skip: string[]) => Promise<string | null>,
  attempt: (candidate: string) => Promise<ReserveOutcome>,
  maxAttempts = 5,
): Promise<string> {
  const skip: string[] = [];
  for (let i = 0; i < maxAttempts; i++) {
    const candidate = await nextFree(skip);
    if (!candidate || skip.includes(candidate)) return "";
    if (await attempt(candidate) === "ok") return candidate;
    skip.push(candidate);
  }
  return "";
}

/// Vrai si l'erreur signale qu'un identifiant (adresse de connexion ou
/// pseudo) existe déjà.
export function isDuplicateError(error: unknown): boolean {
  if (!error || typeof error !== "object") return false;
  const { code, message } = error as { code?: unknown; message?: unknown };
  if (code === "email_exists" || code === "23505" || code === "user_already_exists") {
    return true;
  }
  return typeof message === "string" &&
    /already (been )?registered|already exists|duplicate key/i.test(message);
}
