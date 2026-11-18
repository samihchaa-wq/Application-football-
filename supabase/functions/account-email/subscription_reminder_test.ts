import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "jsr:@std/assert@1";
import {
  MAX_REMINDER_RECIPIENTS,
  parseSubscriptionReminder,
  subscriptionReminderMail,
} from "./subscription_reminder.ts";

const valid = {
  recipients: ["Admin@Club.fr", "admin@club.fr", "coach@club.fr"],
  club_name: "FC Démo",
  trial: false,
  due_on: "30/11/2026",
  amount_cents: 7900,
};

Deno.test("lit une demande valide et dédoublonne les adresses", () => {
  const reminder = parseSubscriptionReminder(valid);
  assert(reminder);
  assertEquals(reminder.recipients, ["admin@club.fr", "coach@club.fr"]);
  assertEquals(reminder.clubName, "FC Démo");
  assertEquals(reminder.dueOn, "30/11/2026");
});

Deno.test("ignore les adresses invalides, refuse s'il n'en reste aucune", () => {
  assertEquals(
    parseSubscriptionReminder({ ...valid, recipients: ["pas-une-adresse", 3] }),
    null,
  );
  assertEquals(parseSubscriptionReminder({ ...valid, recipients: undefined }), null);
  const reminder = parseSubscriptionReminder({
    ...valid,
    recipients: ["pas-une-adresse", "ok@club.fr"],
  });
  assertEquals(reminder?.recipients, ["ok@club.fr"]);
});

Deno.test("refuse une date, un montant ou un club invalides", () => {
  assertEquals(parseSubscriptionReminder({ ...valid, due_on: "2026-11-30" }), null);
  assertEquals(parseSubscriptionReminder({ ...valid, amount_cents: -1 }), null);
  assertEquals(parseSubscriptionReminder({ ...valid, amount_cents: 79.5 }), null);
  assertEquals(parseSubscriptionReminder({ ...valid, club_name: "  " }), null);
});

Deno.test("limite le nombre de destinataires", () => {
  const many = Array.from({ length: 50 }, (_, i) => `a${i}@club.fr`);
  const reminder = parseSubscriptionReminder({ ...valid, recipients: many });
  assertEquals(reminder?.recipients.length, MAX_REMINDER_RECIPIENTS);
});

Deno.test("e-mail de fin d'année : objet, date, prix et contact", () => {
  const reminder = parseSubscriptionReminder(valid)!;
  const mail = subscriptionReminderMail(reminder, "contact@petitfilet.fr");
  assertEquals(mail.subject, "L'abonnement arrive à échéance");
  assertStringIncludes(mail.text, "FC Démo à Petit Filet arrive à échéance le 30/11/2026");
  assertStringIncludes(mail.text, "79 €");
  assertStringIncludes(mail.text, "contact@petitfilet.fr");
  assertStringIncludes(mail.text, "suspendu");
});

Deno.test("e-mail de fin d'essai : parle de l'essai gratuit", () => {
  const reminder = parseSubscriptionReminder({ ...valid, trial: true })!;
  const mail = subscriptionReminderMail(reminder, "contact@petitfilet.fr");
  assertStringIncludes(mail.text, "L'essai gratuit de FC Démo sur Petit Filet se termine le 30/11/2026");
});
