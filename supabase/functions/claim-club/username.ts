// Choix de l'identifiant de connexion d'un nouveau compte (prénom + initiale).
// Copie identique dans register-account et claim-club : chaque fonction est
// déployée avec ses propres fichiers.

/// Premier identifiant libre : `base`, puis `base2`, `base3`… Renvoie une
/// chaîne vide seulement si 10 000 homonymes existent déjà.
export function firstFreeUsername(
  base: string,
  taken: Array<string | null | undefined>,
): string {
  const used = new Set(
    taken.filter((name): name is string => !!name).map((name) =>
      name.toLowerCase()
    ),
  );
  for (let suffix = 1; suffix <= 10000; suffix++) {
    const candidate = suffix === 1 ? base : `${base}${suffix}`;
    if (!used.has(candidate)) return candidate;
  }
  return "";
}
