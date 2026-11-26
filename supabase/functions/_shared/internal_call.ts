// Vérifie qu'un appel vient bien de la base, pour une seule fonction et un
// seul club.
//
// La base signe chaque appel interne (en-tête `x-push-signature`) : HMAC-SHA256
// du texte « fonction|club » avec le mot de passe interne comme clé. Le même
// calcul est fait par private.internal_call_signature (migration
// 20261208000000_jeton_interne_signe_par_usage_et_club.sql). Une signature
// interceptée ne permet donc pas d'appeler une autre fonction, ni de viser un
// autre club. Le mot de passe brut (`x-push-token`) n'est plus accepté seul.

const textEncoder = new TextEncoder();

function toHex(bytes: Uint8Array): string {
  return Array.from(bytes, (byte) => byte.toString(16).padStart(2, "0")).join(
    "",
  );
}

export async function internalCallSignature(
  token: string,
  functionName: string,
  clubId: string,
): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    textEncoder.encode(token),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    textEncoder.encode(`${functionName}|${clubId}`),
  );
  return toHex(new Uint8Array(signature));
}

async function sha256(value: string): Promise<Uint8Array> {
  return new Uint8Array(
    await crypto.subtle.digest("SHA-256", textEncoder.encode(value)),
  );
}

// Comparaison en temps constant : on compare les empreintes des deux valeurs,
// pour que la durée ne révèle rien de la signature attendue.
async function constantTimeEqual(a: string, b: string): Promise<boolean> {
  const [left, right] = await Promise.all([sha256(a), sha256(b)]);
  let difference = 0;
  for (let index = 0; index < left.length; index += 1) {
    difference |= left[index] ^ right[index];
  }
  return difference === 0;
}

/**
 * Vrai si la requête porte une signature valide pour `functionName` et pour
 * le club de son en-tête `x-club-id` (vide quand l'appel ne vise aucun club).
 */
export async function verifyInternalCall(
  req: Request,
  token: string,
  functionName: string,
): Promise<boolean> {
  const signature = req.headers.get("x-push-signature")?.trim().toLowerCase() ??
    "";
  if (!token || !signature) return false;
  const clubId = req.headers.get("x-club-id")?.trim() ?? "";
  const expected = await internalCallSignature(token, functionName, clubId);
  return constantTimeEqual(signature, expected);
}
