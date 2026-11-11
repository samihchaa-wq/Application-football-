// Outils d'envoi des e-mails de compte : liens à usage unique et envoi par un
// service d'e-mail transactionnel.
//
// Ce fichier existe en deux exemplaires identiques (account-email et
// register-account) : chaque fonction est déployée seule. Un test de contrat
// vérifie qu'ils restent identiques.

const DEFAULT_MAIL_API_URL = "https://api.brevo.com/v3/smtp/email";

export interface MailConfig {
  apiUrl: string;
  apiKey: string;
  fromEmail: string;
  fromName: string;
}

/** Lit la configuration d'envoi ; `null` tant que le service n'est pas branché. */
export function readMailConfig(): MailConfig | null {
  const apiKey = Deno.env.get("MAIL_API_KEY")?.trim();
  const fromEmail = Deno.env.get("MAIL_FROM_EMAIL")?.trim();
  if (!apiKey || !fromEmail) return null;
  return {
    apiUrl: Deno.env.get("MAIL_API_URL")?.trim() || DEFAULT_MAIL_API_URL,
    apiKey,
    fromEmail,
    fromName: Deno.env.get("MAIL_FROM_NAME")?.trim() || "Club",
  };
}

/** Jeton aléatoire de 256 bits, lisible dans une adresse web. */
export function randomToken(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

export async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

export const EMAIL_PATTERN = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

export function normalizeEmail(value: unknown): string {
  return String(value ?? "").trim().toLowerCase();
}

export function isValidEmail(email: string): boolean {
  return email.length <= 254 && EMAIL_PATTERN.test(email);
}

/** Envoie un e-mail texte. Lève une erreur si le service refuse. */
export async function sendMail(
  config: MailConfig,
  to: string,
  subject: string,
  text: string,
): Promise<void> {
  const response = await fetch(config.apiUrl, {
    method: "POST",
    headers: {
      "api-key": config.apiKey,
      "content-type": "application/json",
      accept: "application/json",
    },
    body: JSON.stringify({
      sender: { name: config.fromName, email: config.fromEmail },
      to: [{ email: to }],
      subject,
      textContent: text,
    }),
    signal: AbortSignal.timeout(10_000),
  });
  if (!response.ok) {
    throw new Error(`Mail service refused the message (${response.status})`);
  }
}

/** Le jeton reste dans le fragment de l'adresse : jamais envoyé au serveur web. */
export function confirmationLink(publicAppUrl: string, token: string): string {
  const base = publicAppUrl.endsWith("/") ? publicAppUrl : `${publicAppUrl}/`;
  return `${base}#/auth/confirm-email?token=${encodeURIComponent(token)}`;
}

export function confirmationMail(link: string): { subject: string; text: string } {
  return {
    subject: "Confirme ton adresse e-mail",
    text: [
      "Bonjour,",
      "",
      "Pour confirmer cette adresse e-mail sur ton compte, ouvre ce lien :",
      link,
      "",
      "Il est valable 24 heures et ne sert qu'une fois.",
      "Une fois l'adresse confirmée, tu pourras retrouver ton compte par e-mail si tu perds ton mot de passe.",
      "",
      "Si tu n'es pas à l'origine de cette demande, ignore simplement ce message.",
    ].join("\n"),
  };
}

export function recoveryMail(link: string): { subject: string; text: string } {
  return {
    subject: "Retrouve l'accès à ton compte",
    text: [
      "Bonjour,",
      "",
      "Tu as demandé à retrouver l'accès à ton compte. Ouvre ce lien pour choisir un nouveau mot de passe :",
      link,
      "",
      "Il ne sert qu'une fois. Si tu n'es pas à l'origine de cette demande, ignore ce message : ton mot de passe actuel reste valable.",
    ].join("\n"),
  };
}
