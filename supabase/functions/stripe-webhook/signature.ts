// Vérification de la signature des événements Stripe (en-tête
// Stripe-Signature : « t=horodatage,v1=signature »), sans dépendance.
// https://docs.stripe.com/webhooks#verify-manually

const encoder = new TextEncoder();

function toHex(bytes: ArrayBuffer): string {
  return [...new Uint8Array(bytes)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function constantTimeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

export async function stripeSignatureFor(
  secret: string,
  timestamp: string,
  payload: string,
): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(`${timestamp}.${payload}`),
  );
  return toHex(signature);
}

/// Vrai si l'en-tête est signé avec le secret et date de moins de
/// [toleranceSeconds] (protection contre le rejeu).
export async function verifyStripeSignature(
  payload: string,
  header: string | null,
  secret: string,
  nowSeconds: number,
  toleranceSeconds = 300,
): Promise<boolean> {
  if (!header || !secret) return false;
  let timestamp = "";
  const signatures: string[] = [];
  for (const part of header.split(",")) {
    const [key, value] = part.trim().split("=", 2);
    if (key === "t") timestamp = value ?? "";
    if (key === "v1" && value) signatures.push(value);
  }
  const time = Number(timestamp);
  if (!timestamp || !Number.isFinite(time) || signatures.length === 0) {
    return false;
  }
  if (Math.abs(nowSeconds - time) > toleranceSeconds) return false;
  const expected = await stripeSignatureFor(secret, timestamp, payload);
  return signatures.some((candidate) => constantTimeEqual(candidate, expected));
}
