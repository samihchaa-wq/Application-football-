// Comptes inactifs : chaque nuit, la base envoie l'action « inactive-accounts »
// (jeton interne). La base fournit la liste du jour ; ici on prévient par
// e-mail, puis on supprime les comptes arrivés au bout du délai.
//
// Règle de sécurité : un avertissement n'est noté qu'une fois l'e-mail parti
// (ou tout de suite s'il n'y a pas d'adresse). Un envoi qui échoue repart la
// nuit suivante ; la suppression n'arrive qu'un mois après un avertissement
// noté. Personne n'est donc supprimé sans l'avertissement promis.

import { isValidEmail, normalizeEmail } from "./account_email.ts";

export interface InactiveAccount {
  profileId: string;
  clubId: string | null;
  action: "notify" | "delete";
  email: string | null;
  firstName: string;
  lastActivityAt: string;
  /** Date de suppression prévue, au format AAAA-MM-JJ. */
  deletionOn: string;
}

export type DeleteOutcome = "deleted" | "skipped";

export interface InactiveAccountsDeps {
  sendWarning(account: InactiveAccount, email: string): Promise<void>;
  recordNotice(account: InactiveAccount, emailed: boolean): Promise<void>;
  deleteAccount(account: InactiveAccount): Promise<DeleteOutcome>;
  log(message: string, error?: unknown): void;
}

export interface InactiveAccountsReport {
  notified: number;
  notifiedWithoutEmail: number;
  warningFailures: number;
  deleted: number;
  skipped: number;
  deleteFailures: number;
}

/** Transforme une ligne renvoyée par la base ; `null` si elle est invalide. */
export function parseInactiveAccount(
  row: Record<string, unknown>,
): InactiveAccount | null {
  const profileId = String(row.profile_id ?? "");
  const action = String(row.action ?? "");
  const deletionOn = String(row.deletion_on ?? "");
  const lastActivityAt = String(row.last_activity_at ?? "");
  if (
    !/^[0-9a-f-]{36}$/i.test(profileId) ||
    (action !== "notify" && action !== "delete") ||
    !/^\d{4}-\d{2}-\d{2}$/.test(deletionOn) ||
    !lastActivityAt
  ) {
    return null;
  }
  const email = row.email == null ? "" : normalizeEmail(String(row.email));
  return {
    profileId,
    clubId: row.club_id == null ? null : String(row.club_id),
    action,
    email: isValidEmail(email) ? email : null,
    firstName: String(row.first_name ?? "").trim().slice(0, 80),
    lastActivityAt,
    deletionOn,
  };
}

export async function runInactiveAccounts(
  accounts: InactiveAccount[],
  deps: InactiveAccountsDeps,
): Promise<InactiveAccountsReport> {
  const report: InactiveAccountsReport = {
    notified: 0,
    notifiedWithoutEmail: 0,
    warningFailures: 0,
    deleted: 0,
    skipped: 0,
    deleteFailures: 0,
  };

  for (const account of accounts) {
    if (account.action === "notify") {
      if (!account.email) {
        try {
          await deps.recordNotice(account, false);
          report.notifiedWithoutEmail += 1;
        } catch (error) {
          report.warningFailures += 1;
          deps.log("inactive-accounts notice failure", error);
        }
        continue;
      }
      try {
        await deps.sendWarning(account, account.email);
      } catch (error) {
        // Pas noté : nouvel essai la nuit suivante.
        report.warningFailures += 1;
        deps.log("inactive-accounts warning delivery failure", error);
        continue;
      }
      try {
        await deps.recordNotice(account, true);
        report.notified += 1;
      } catch (error) {
        report.warningFailures += 1;
        deps.log("inactive-accounts notice failure", error);
      }
      continue;
    }

    try {
      const outcome = await deps.deleteAccount(account);
      if (outcome === "deleted") report.deleted += 1;
      else report.skipped += 1;
    } catch (error) {
      report.deleteFailures += 1;
      deps.log("inactive-accounts deletion failure", error);
    }
  }
  return report;
}

function frenchDate(isoDate: string): string {
  const [year, month, day] = isoDate.split("-");
  return `${day}/${month}/${year}`;
}

export function inactiveAccountWarningMail(
  account: InactiveAccount,
  appUrl: string,
  contactEmail: string,
): { subject: string; text: string } {
  const hello = account.firstName ? `Bonjour ${account.firstName},` : "Bonjour,";
  return {
    subject: "Ton compte va être supprimé faute d'utilisation",
    text: [
      hello,
      "",
      "Ton compte Petit Filet n'a pas été utilisé depuis près de 3 ans.",
      `Comme prévu par notre politique de confidentialité, il sera supprimé le ${frenchDate(account.deletionOn)}, avec tes données personnelles.`,
      "",
      `Pour le garder, il suffit de te connecter avant cette date : ${appUrl}`,
      "",
      "Si tu ne fais rien, ton compte sera supprimé. Les résultats des matchs déjà joués peuvent rester dans l'historique du club, sans lien avec ton compte.",
      "",
      `Une question ? Écris-nous à ${contactEmail}.`,
    ].join("\n"),
  };
}
