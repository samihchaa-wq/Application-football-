// E-mail « L'abonnement arrive à échéance », envoyé aux administrateurs d'un
// club 10 jours avant l'échéance (fin d'essai ou fin d'année payée). Demandé
// uniquement par la base (tâche planifiée), avec le jeton interne.

import { isValidEmail, normalizeEmail } from "./account_email.ts";

export const MAX_REMINDER_RECIPIENTS = 20;

export interface SubscriptionReminder {
  recipients: string[];
  clubName: string;
  trial: boolean;
  dueOn: string;
  amountCents: number;
}

/** Lit et valide la demande ; `null` si elle est incomplète ou invalide. */
export function parseSubscriptionReminder(
  body: Record<string, unknown>,
): SubscriptionReminder | null {
  const raw = Array.isArray(body.recipients) ? body.recipients : [];
  const recipients = [...new Set(raw.map(normalizeEmail))]
    .filter(isValidEmail)
    .slice(0, MAX_REMINDER_RECIPIENTS);
  const clubName = String(body.club_name ?? "").trim().slice(0, 120);
  const dueOn = String(body.due_on ?? "").trim();
  const amountCents = Number(body.amount_cents);
  if (
    recipients.length === 0 ||
    !clubName ||
    !/^\d{2}\/\d{2}\/\d{4}$/.test(dueOn) ||
    !Number.isInteger(amountCents) ||
    amountCents < 0 ||
    amountCents > 1_000_000
  ) {
    return null;
  }
  return { recipients, clubName, trial: body.trial === true, dueOn, amountCents };
}

function euros(cents: number): string {
  const value = cents / 100;
  return Number.isInteger(value)
    ? `${value} €`
    : `${value.toFixed(2).replace(".", ",")} €`;
}

export function subscriptionReminderMail(
  reminder: SubscriptionReminder,
  contactEmail: string,
  appUrl = "",
): { subject: string; text: string } {
  const what = reminder.trial
    ? `L'essai gratuit de ${reminder.clubName} sur Petit Filet se termine le ${reminder.dueOn}.`
    : `L'abonnement de ${reminder.clubName} à Petit Filet arrive à échéance le ${reminder.dueOn}.`;
  const base = appUrl.trim().replace(/\/+$/, "");
  const payLink = base ? `${base}/#/admin/abonnement` : "";
  return {
    subject: "L'abonnement arrive à échéance",
    text: [
      "Bonjour,",
      "",
      what,
      "",
      `Pour continuer à utiliser l'application, il reste à régler l'abonnement annuel du club : ${euros(reminder.amountCents)}.`,
      payLink
        ? `Le plus simple : payer par carte depuis l'application, écran Abonnement : ${payLink}`
        : "Le plus simple : payer par carte depuis l'application, écran Abonnement.",
      `Tu préfères un virement ou un chèque ? Écris-nous à ${contactEmail}.`,
      "",
      `Sans paiement à cette date, l'accès du club sera suspendu. Les données sont conservées et l'accès revient dès le paiement enregistré.`,
      "",
      "Tu reçois ce message parce que tu es administrateur de ce club.",
    ].join("\n"),
  };
}
