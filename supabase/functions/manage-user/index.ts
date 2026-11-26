// Les dépendances réelles sont branchées ici ; le même handler est testé
// sans compte ni requête vers un projet Supabase distant.
import "jsr:@supabase/functions-js@2.95.0/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2.95.0";
import { readMailConfig, sendMail } from "../account-email/account_email.ts";
import { createManageUserHandler } from "./handler.ts";
import { adminPasswordResetAlertMail } from "./handler.ts";

Deno.serve(createManageUserHandler({
  createClient,
  getEnv: (name) => Deno.env.get(name),
  notifyAdminPasswordReset: async (email) => {
    // Envoi d'e-mails non configuré : pas d'alerte, la réinitialisation se
    // fait quand même.
    const mail = readMailConfig();
    if (!mail) return;
    const message = adminPasswordResetAlertMail(
      Deno.env.get("SUPPORT_EMAIL")?.trim() || mail.fromEmail,
    );
    await sendMail(mail, email, message.subject, message.text);
  },
}));
