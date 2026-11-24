// E-mails de compte : confirmer une adresse, et retrouver son compte par
// e-mail quand on a perdu son mot de passe.
//
// Cinq actions :
// - request-confirmation (compte connecté) : envoie un lien de confirmation ;
// - confirm (sans compte) : valide le lien reçu ;
// - request-reset (sans compte) : envoie, à l'adresse confirmée d'un compte, un
//   lien pour choisir un nouveau mot de passe ;
// - subscription-reminder (base seulement, jeton interne x-push-token) :
//   prévient les administrateurs d'un club que l'abonnement arrive à échéance ;
// - inactive-accounts (base seulement, jeton interne x-push-token) : prévient
//   les comptes inutilisés depuis près de 3 ans et supprime ceux qui ont été
//   prévenus depuis au moins un mois (voir inactive_accounts.ts).
//
// La réponse à request-reset est toujours la même : elle ne révèle pas si
// l'adresse existe.
import "jsr:@supabase/functions-js@2.95.0/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2.95.0";
import {
  confirmationLink,
  confirmationMail,
  isValidEmail,
  normalizeEmail,
  randomToken,
  readMailConfig,
  recoveryMail,
  sendMail,
  sha256Hex,
} from "./account_email.ts";
import {
  type DeleteOutcome,
  type InactiveAccount,
  inactiveAccountWarningMail,
  parseInactiveAccount,
  runInactiveAccounts,
} from "./inactive_accounts.ts";
import {
  parseSubscriptionReminder,
  subscriptionReminderMail,
} from "./subscription_reminder.ts";

const MAX_BODY_BYTES = 2_048;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const jsonHeaders = { ...corsHeaders, "Content-Type": "application/json" };

class RequestBodyTooLargeError extends Error {
  constructor() {
    super("Request body exceeds the allowed size");
    this.name = "RequestBodyTooLargeError";
  }
}

function jsonResponse(
  body: unknown,
  status = 200,
  extraHeaders: Record<string, string> = {},
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...jsonHeaders, ...extraHeaders },
  });
}

async function readBoundedJson<T>(req: Request, maxBytes: number): Promise<T> {
  const declaredLength = Number(req.headers.get("content-length") ?? "0");
  if (Number.isFinite(declaredLength) && declaredLength > maxBytes) {
    throw new RequestBodyTooLargeError();
  }
  if (!req.body) {
    throw new SyntaxError("Request body is empty");
  }

  const reader = req.body.getReader();
  const decoder = new TextDecoder();
  let totalBytes = 0;
  let json = "";

  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      if (!value) continue;

      totalBytes += value.byteLength;
      if (totalBytes > maxBytes) {
        await reader.cancel();
        throw new RequestBodyTooLargeError();
      }
      json += decoder.decode(value, { stream: true });
    }
    json += decoder.decode();
  } finally {
    reader.releaseLock();
  }

  return JSON.parse(json) as T;
}

/** Comparaison en temps constant de deux secrets. */
async function secretsEqual(a: string, b: string): Promise<boolean> {
  const [left, right] = await Promise.all([sha256Hex(a), sha256Hex(b)]);
  let diff = left.length ^ right.length;
  for (let i = 0; i < Math.min(left.length, right.length); i++) {
    diff |= left.charCodeAt(i) ^ right.charCodeAt(i);
  }
  return diff === 0 && a.length > 0;
}

/// Laisse une tâche se terminer après l'envoi de la réponse. Sur Supabase,
/// EdgeRuntime.waitUntil garde la fonction active jusqu'à la fin de la
/// tâche ; ailleurs (Deno seul, tests), la tâche continue simplement.
function runAfterResponse(task: Promise<void>): void {
  const runtime = (globalThis as {
    EdgeRuntime?: { waitUntil?: (promise: Promise<unknown>) => void };
  }).EdgeRuntime;
  if (typeof runtime?.waitUntil === "function") runtime.waitUntil(task);
}

function requestOrigin(req: Request): string {
  const forwarded = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim();
  return (
    req.headers.get("cf-connecting-ip")?.trim() ||
    forwarded ||
    req.headers.get("x-real-ip")?.trim() ||
    "unknown"
  ).slice(0, 128);
}

function scannerSafeRecoveryLink(
  actionLink: string,
  publicAppUrl: string,
): string {
  const actionUrl = new URL(actionLink);
  // Dans l'action_link Supabase, `token` est déjà l'empreinte attendue par
  // POST /verify. Ne jamais exposer l'action_link lui-même : les robots
  // d'aperçu des messageries suivent les GET et consomment les liens à usage
  // unique avant la personne.
  const tokenHash = actionUrl.searchParams.get("token");
  if (!tokenHash) {
    throw new Error("Recovery action link has no token hash");
  }
  const appRoute = new URLSearchParams({
    recovery: "1",
    token_hash: tokenHash,
  });
  const base = publicAppUrl.endsWith("/") ? publicAppUrl : `${publicAppUrl}/`;
  return `${base}#/auth/new-password?${appRoute.toString()}`;
}

// Mêmes étapes qu'une suppression demandée par le membre lui-même
// (manage-user, action delete-self).
async function deleteInactiveAccount(
  supabaseUrl: string,
  serviceRoleKey: string,
  account: InactiveAccount,
): Promise<DeleteOutcome> {
  const headers: Record<string, string> = account.clubId
    ? { "x-club-id": account.clubId }
    : {};
  const scoped = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers },
  });
  const profileId = account.profileId;

  // Le dernier administrateur d'un club qui a d'autres membres n'est pas
  // supprimé : plus personne ne pourrait gérer le club. Il reste dans la
  // liste et l'éditeur le voit dans les journaux.
  if (account.clubId) {
    const { data: profile, error: profileError } = await scoped
      .from("profiles")
      .select("role,status")
      .eq("id", profileId)
      .maybeSingle();
    if (profileError) throw profileError;
    if (!profile) return "deleted";
    if (profile.role === "admin" && profile.status === "active") {
      const { count: adminCount, error: adminError } = await scoped
        .from("profiles")
        .select("id", { count: "exact", head: true })
        .eq("role", "admin")
        .eq("status", "active")
        .eq("club_id", account.clubId);
      if (adminError) throw adminError;
      const { count: memberCount, error: memberError } = await scoped
        .from("profiles")
        .select("id", { count: "exact", head: true })
        .eq("club_id", account.clubId)
        .neq("id", profileId);
      if (memberError) throw memberError;
      if ((adminCount ?? 0) <= 1 && (memberCount ?? 0) > 0) {
        console.warn(
          "inactive-accounts: dernier administrateur conservé",
          account.clubId,
        );
        return "skipped";
      }
    }
  }

  const { error: prepareError } = await scoped.rpc(
    "prepare_profile_for_hard_deletion",
    { p_profile_id: profileId },
  );
  if (prepareError) throw prepareError;
  const { error: authDeleteError } = await scoped.auth.admin.deleteUser(
    profileId,
    false,
  );
  if (
    authDeleteError &&
    !(authDeleteError.status === 404 ||
      /not.?found/i.test(authDeleteError.message ?? ""))
  ) {
    throw authDeleteError;
  }
  const { error: profileDeleteError } = await scoped
    .from("profiles")
    .delete()
    .eq("id", profileId);
  if (profileDeleteError) throw profileDeleteError;
  return "deleted";
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  let body: Record<string, unknown>;
  try {
    body = await readBoundedJson<Record<string, unknown>>(req, MAX_BODY_BYTES);
  } catch (error) {
    if (error instanceof RequestBodyTooLargeError) {
      return jsonResponse({ error: "Requête trop volumineuse." }, 413);
    }
    return jsonResponse({ error: "Requête invalide." }, 400);
  }

  const action = String(body.action ?? "");
  if (
    ![
      "request-confirmation",
      "confirm",
      "request-reset",
      "subscription-reminder",
      "inactive-accounts",
    ].includes(action)
  ) {
    return jsonResponse({ error: "Action inconnue." }, 400);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const publicAppUrl = Deno.env.get("PUBLIC_APP_URL")?.trim();
    if (!supabaseUrl || !serviceRoleKey || !anonKey || !publicAppUrl) {
      throw new Error("Missing server configuration");
    }
    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    if (action === "confirm") {
      const token = String(body.token ?? "").trim();
      if (!/^[A-Za-z0-9_-]{20,128}$/.test(token)) {
        return jsonResponse({ confirmed: false });
      }
      const { data, error } = await admin.rpc("confirm_contact_email", {
        p_token_hash: await sha256Hex(token),
      });
      if (error) throw error;
      return jsonResponse({ confirmed: data === true });
    }

    // Les deux autres actions envoient un e-mail : le service d'envoi doit
    // être branché, sinon on le dit franchement plutôt que de faire croire
    // qu'un message est parti.
    const mail = readMailConfig();
    if (!mail) {
      return jsonResponse(
        { error: "L’envoi d’e-mails n’est pas encore configuré." },
        503,
      );
    }

    if (action === "subscription-reminder") {
      // Seule la base connaît le jeton interne : personne d'autre ne peut
      // faire envoyer cet e-mail.
      const { data: config, error: configError } = await admin.rpc(
        "internal_push_config",
      );
      if (configError || !config?.token) {
        throw configError ?? new Error("Missing internal token");
      }
      const token = req.headers.get("x-push-token") ?? "";
      if (!(await secretsEqual(token, String(config.token)))) {
        return jsonResponse({ error: "Non autorisé." }, 401);
      }
      const reminder = parseSubscriptionReminder(body);
      if (!reminder) {
        return jsonResponse({ error: "Requête invalide." }, 400);
      }
      const contact = Deno.env.get("SUPPORT_EMAIL")?.trim() || mail.fromEmail;
      const message = subscriptionReminderMail(reminder, contact, publicAppUrl);
      let sent = 0;
      for (const recipient of reminder.recipients) {
        try {
          await sendMail(mail, recipient, message.subject, message.text);
          sent += 1;
        } catch (error) {
          console.error("account-email reminder delivery failure", error);
        }
      }
      return jsonResponse({ sent });
    }

    if (action === "inactive-accounts") {
      const { data: config, error: configError } = await admin.rpc(
        "internal_push_config",
      );
      if (configError || !config?.token) {
        throw configError ?? new Error("Missing internal token");
      }
      const token = req.headers.get("x-push-token") ?? "";
      if (!(await secretsEqual(token, String(config.token)))) {
        return jsonResponse({ error: "Non autorisé." }, 401);
      }

      const { data: rows, error: listError } = await admin.rpc(
        "internal_inactive_accounts",
      );
      if (listError) throw listError;
      const accounts = ((rows ?? []) as Record<string, unknown>[])
        .map(parseInactiveAccount)
        .filter((account): account is InactiveAccount => account !== null);

      const contact = Deno.env.get("SUPPORT_EMAIL")?.trim() || mail.fromEmail;
      const report = await runInactiveAccounts(accounts, {
        sendWarning: async (account, email) => {
          const message = inactiveAccountWarningMail(
            account,
            publicAppUrl,
            contact,
          );
          await sendMail(mail, email, message.subject, message.text);
        },
        recordNotice: async (account, emailed) => {
          const { error } = await admin.rpc("internal_record_inactive_notice", {
            p_profile_id: account.profileId,
            p_activity_at: account.lastActivityAt,
            p_emailed: emailed,
          });
          if (error) throw error;
        },
        deleteAccount: (account) =>
          deleteInactiveAccount(supabaseUrl, serviceRoleKey, account),
        log: (message, error) => console.error(message, error),
      });
      console.log("inactive-accounts", JSON.stringify(report));
      return jsonResponse(report);
    }

    if (action === "request-confirmation") {
      const authHeader = req.headers.get("Authorization");
      if (!authHeader?.startsWith("Bearer ")) {
        return jsonResponse({ error: "Connexion requise." }, 401);
      }
      const callerClient = createClient(supabaseUrl, anonKey, {
        global: { headers: { Authorization: authHeader } },
      });
      const accessToken = authHeader.slice("Bearer ".length);
      const { data: userData, error: userError } =
        await callerClient.auth.getUser(accessToken);
      if (userError || !userData.user) {
        return jsonResponse({ error: "Connexion requise." }, 401);
      }

      const email = normalizeEmail(body.email);
      if (!isValidEmail(email)) {
        return jsonResponse({ error: "Adresse e-mail invalide." }, 400);
      }

      const { data: allowed, error: limitError } = await admin.rpc(
        "consume_email_rate_limit",
        {
          p_origin_hash: await sha256Hex(requestOrigin(req)),
          p_email_hash: await sha256Hex(email),
        },
      );
      if (limitError) throw limitError;
      if (allowed !== true) {
        return jsonResponse(
          { error: "Trop de demandes. Réessaie plus tard." },
          429,
          { "Retry-After": "3600" },
        );
      }

      const token = randomToken();
      const { data: shouldSend, error: requestError } = await admin.rpc(
        "request_contact_email",
        {
          p_profile_id: userData.user.id,
          p_email: email,
          p_token_hash: await sha256Hex(token),
        },
      );
      if (requestError) throw requestError;
      if (shouldSend === true) {
        const message = confirmationMail(
          confirmationLink(publicAppUrl, token),
        );
        await sendMail(mail, email, message.subject, message.text);
      }
      // Même réponse que l'adresse soit libre ou déjà prise.
      return jsonResponse({ sent: true });
    }

    // request-reset
    const email = normalizeEmail(body.email);
    if (!isValidEmail(email)) {
      return jsonResponse({ error: "Adresse e-mail invalide." }, 400);
    }
    const { data: allowed, error: limitError } = await admin.rpc(
      "consume_email_rate_limit",
      {
        p_origin_hash: await sha256Hex(requestOrigin(req)),
        p_email_hash: await sha256Hex(email),
      },
    );
    if (limitError) throw limitError;
    if (allowed !== true) {
      return jsonResponse(
        { error: "Trop de demandes. Réessaie plus tard." },
        429,
        { "Retry-After": "3600" },
      );
    }

    // Recherche du compte, lien et envoi après la réponse : sinon le temps de
    // réponse (7 ms pour une adresse inconnue, 50 à 70 ms et plus pour un
    // compte, mesuré en local) révélait quelles adresses ont un compte.
    runAfterResponse(
      (async () => {
        const { data: found, error: lookupError } = await admin.rpc(
          "profile_for_recovery_email",
          { p_email: email },
        );
        if (lookupError) throw lookupError;
        const account = Array.isArray(found) ? found[0] : null;
        if (!account?.auth_email) return;
        const { data: linkData, error: linkError } =
          await admin.auth.admin.generateLink({
            type: "recovery",
            email: account.auth_email,
            options: { redirectTo: publicAppUrl },
          });
        if (linkError) throw linkError;
        const message = recoveryMail(
          scannerSafeRecoveryLink(linkData.properties.action_link, publicAppUrl),
        );
        await sendMail(mail, email, message.subject, message.text);
      })().catch((error) => {
        // Un échec ici ne doit pas se voir de l'extérieur : il distinguerait
        // une adresse connue d'une adresse inconnue.
        console.error("account-email reset delivery failure", error);
      }),
    );
    return jsonResponse({ sent: true });
  } catch (error) {
    console.error("account-email failure", error);
    return jsonResponse(
      { error: "La demande n’a pas pu être traitée. Réessaie plus tard." },
      500,
    );
  }
});
