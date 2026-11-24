export const MAX_PUSH_DELIVERY_ATTEMPTS = 2;

/// Combien de temps le service de notification garde un message pour un
/// appareil injoignable.
///
/// Passé ce délai, le message est jeté et rien ne le rattrape : le destinataire
/// ne saura jamais qu'on a cherché à le joindre. Notre journal, lui, continue
/// d'afficher un envoi réussi, parce que le service l'avait bien accepté.
///
/// Une heure était trop court. Un téléphone éteint, en avion, dans le métro ou
/// simplement hors réseau au mauvais moment perdait définitivement l'ouverture
/// des disponibilités — constaté le 15 septembre 2026 sur un joueur qui avait
/// reçu sans problème celle de la semaine précédente.
///
/// Vingt-quatre heures couvrent une nuit et une journée de travail. Aucune de
/// nos notifications n'est urgente à la minute : la plus serrée prévient d'un
/// match le lendemain, et les relances de disponibilité se répètent à J-3 et
/// J-1. Au-delà d'une journée, un message deviendrait trompeur plutôt
/// qu'utile.
export const PUSH_DELIVERY_TTL_SECONDS = 86_400;

export type PushFailureClass = "expired" | "retryable" | "permanent";

export type PushDeliveryOutcome<T> =
  | {
    success: true;
    value: T;
    attempts: number;
    statusCode: number | null;
  }
  | {
    success: false;
    error: unknown;
    attempts: number;
    statusCode: number | null;
    failureClass: PushFailureClass;
  };

export function readPushStatusCode(error: unknown): number | null {
  if (typeof error !== "object" || error === null) return null;
  const statusCode = (error as { statusCode?: unknown }).statusCode;
  return typeof statusCode === "number" && Number.isFinite(statusCode)
    ? statusCode
    : null;
}

/// Abonnement créé avec une autre clé d'envoi que celle du serveur. Apple
/// répond 400 `{"reason":"VapidPkHashMismatch"}`, Google 403 « … do not
/// correspond to the credentials used to create the subscriptions ». Ce
/// refus est définitif pour ce point d'envoi : le téléphone doit se
/// réabonner, ce qu'il fait seul à la prochaine ouverture de l'appli. Le
/// garder faisait échouer chaque envoi suivant (39 échecs en une semaine,
/// novembre 2026).
export function isSubscriptionKeyMismatch(
  statusCode: number | null,
  body: unknown,
): boolean {
  if (typeof body !== "string") return false;
  if (statusCode === 400) return body.includes("VapidPkHashMismatch");
  if (statusCode === 403) {
    return /do not correspond to the credentials used to create the subscriptions/i
      .test(body);
  }
  return false;
}

function readPushBody(error: unknown): unknown {
  return typeof error === "object" && error !== null
    ? (error as { body?: unknown }).body
    : undefined;
}

export function classifyPushFailure(
  statusCode: number | null,
  body?: unknown,
): PushFailureClass {
  if (statusCode === 404 || statusCode === 410) return "expired";
  if (isSubscriptionKeyMismatch(statusCode, body)) return "expired";

  if (
    statusCode === null ||
    statusCode === 408 ||
    statusCode === 425 ||
    statusCode === 429 ||
    statusCode >= 500
  ) {
    return "retryable";
  }

  return "permanent";
}

export function pushRetryDelayMs(completedAttempts: number): number {
  const normalizedAttempts = Math.max(1, Math.floor(completedAttempts));
  return Math.min(250 * 2 ** (normalizedAttempts - 1), 2_000);
}

export async function executePushDelivery<T>(
  operation: () => Promise<T>,
  options: {
    maxAttempts?: number;
    sleep?: (milliseconds: number) => Promise<void>;
  } = {},
): Promise<PushDeliveryOutcome<T>> {
  const maxAttempts = Math.max(
    1,
    Math.floor(options.maxAttempts ?? MAX_PUSH_DELIVERY_ATTEMPTS),
  );
  const sleep = options.sleep ?? ((milliseconds: number) =>
    new Promise<void>((resolve) => setTimeout(resolve, milliseconds)));

  let attempts = 0;

  while (attempts < maxAttempts) {
    attempts += 1;
    try {
      const value = await operation();
      const statusCode = typeof value === "object" && value !== null
        ? readPushStatusCode(value)
        : null;
      return { success: true, value, attempts, statusCode };
    } catch (error) {
      const statusCode = readPushStatusCode(error);
      const failureClass = classifyPushFailure(statusCode, readPushBody(error));

      if (failureClass === "retryable" && attempts < maxAttempts) {
        await sleep(pushRetryDelayMs(attempts));
        continue;
      }

      return {
        success: false,
        error,
        attempts,
        statusCode,
        failureClass,
      };
    }
  }

  throw new Error("push delivery retry loop ended unexpectedly");
}


/// Vérifie les clés que le navigateur remet pour le chiffrement Web Push.
///
/// p256dh est une clé publique P-256 non compressée (65 octets, préfixe 04).
/// auth est un secret de 16 octets. Les valeurs invalides ne peuvent jamais
/// être délivrées : supprimer cet abonnement évite des échecs répétés.
/// Ne jamais journaliser les valeurs des clés ni les points d'accès complets.
function pushKeyBytes(encoded: string): Uint8Array | null {
  if (
    typeof encoded !== "string" ||
    !/^[A-Za-z0-9_-]+={0,2}$/.test(encoded)
  ) return null;
  const normal = encoded.replaceAll("-", "+").replaceAll("_", "/");
  if (normal.length % 4 === 1) return null;
  try {
    const raw = atob(normal.padEnd(Math.ceil(normal.length / 4) * 4, "="));
    return Uint8Array.from(raw, (char) => char.charCodeAt(0));
  } catch {
    return null;
  }
}

export function invalidPushSubscriptionReason(
  subscription: { p256dh: string; auth: string },
): string | null {
  const dh = pushKeyBytes(subscription.p256dh);
  if (dh === null || dh.length !== 65 || dh[0] !== 4) {
    return "Invalid Web Push p256dh key";
  }
  const auth = pushKeyBytes(subscription.auth);
  if (auth === null || auth.length !== 16) {
    return "Invalid Web Push auth secret";
  }
  return null;
}

/// Une subscription malformée est irrécupérable : retourner une erreur
/// « expired » sans envoyer au service push ni effectuer de nouvelle tentative.
/// L'appelant utilise déjà ce statut pour retirer les endpoints périmés.
/// Les erreurs réseau temporaires, elles, continuent d'être réessayées.
export async function executeValidatedPushDelivery<T>(
  subscription: { p256dh: string; auth: string },
  operation: () => Promise<T>,
): Promise<PushDeliveryOutcome<T>> {
  const reason = invalidPushSubscriptionReason(subscription);
  if (reason !== null) {
    return {
      success: false,
      error: new Error(reason),
      attempts: 0,
      statusCode: null,
      failureClass: "expired",
    };
  }
  return executePushDelivery(operation);
}

/// Message d'erreur journalisé pour un envoi refusé, avec la raison donnée par
/// le service du téléphone quand il en renvoie une. Apple répond par exemple
/// `{"reason":"BadJwtToken"}` : sans ce corps, « Received unexpected response
/// code » ne permettait pas de savoir pourquoi les iPhone refusaient.
export function describePushError(error: unknown): string {
  const message = error instanceof Error ? error.message : String(error);
  const body = typeof error === "object" && error !== null
    ? (error as { body?: unknown }).body
    : undefined;
  const reason = typeof body === "string"
    ? body.replace(/\s+/g, " ").trim()
    : "";
  const text = reason && !message.includes(reason)
    ? `${message} · réponse du service : ${reason}`
    : message;
  return text.slice(0, 500);
}
