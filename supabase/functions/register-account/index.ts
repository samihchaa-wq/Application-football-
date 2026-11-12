// Inscription publique. Deux parcours :
// - rejoindre un club avec son code d'invitation : le compte reste en attente
//   de validation par un administrateur du club ;
// - créer un club : le demandeur en devient le premier administrateur.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2.95.0";
import {
  confirmationLink,
  confirmationMail,
  isValidEmail,
  normalizeEmail,
  randomToken,
  readMailConfig,
  sendMail,
  sha256Hex,
} from "./account_email.ts";
import { parseConsent } from "./consent.ts";
import { usernameCandidates } from "./username_candidates.ts";
import { validatePassword } from "./password_policy.ts";

const USERNAME_DOMAIN = Deno.env.get("USERNAME_DOMAIN")?.trim() ||
  "comptes.club-app.local";
const INVITE_CODE_PATTERN = /^[A-Z2-9]{8}$/;
const MAX_BODY_BYTES = 4_096;

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

function normalizeName(value: string): string {
  return value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]/g, "");
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

  const firstName = String(body.firstName ?? "").trim();
  const lastName = String(body.lastName ?? "").trim();
  const password = String(body.password ?? "");
  const mode = body.mode === "create" ? "create" : "join";
  const inviteCode = String(body.inviteCode ?? "")
    .trim()
    .toUpperCase()
    .replace(/[\s-]/g, "");
  const clubName = String(body.clubName ?? "").trim().replace(/\s+/g, " ");
  const clubShortName = String(body.clubShortName ?? "").trim();
  // Facultative : sert à confirmer l'identité et à retrouver le compte par
  // e-mail en cas de mot de passe perdu.
  const contactEmail = normalizeEmail(body.email);

  // Les requêtes manifestement invalides ne consomment pas le quota partagé.
  if (
    firstName.length < 2 ||
    firstName.length > 50 ||
    lastName.length < 2 ||
    lastName.length > 50 ||
    /[\u0000-\u001f\u007f]/.test(firstName + lastName)
  ) {
    return jsonResponse({ error: "Prénom ou nom invalide." }, 400);
  }
  if (mode === "join" && !INVITE_CODE_PATTERN.test(inviteCode)) {
    return jsonResponse(
      { error: "Code d’invitation invalide. Demande-le à ton club." },
      400,
    );
  }
  if (
    mode === "create" &&
    (clubName.length < 2 ||
      clubName.length > 80 ||
      clubShortName.length > 12 ||
      /[\u0000-\u001f\u007f]/.test(clubName + clubShortName))
  ) {
    return jsonResponse({ error: "Nom du club invalide." }, 400);
  }
  if (contactEmail && !isValidEmail(contactEmail)) {
    return jsonResponse({ error: "Adresse e-mail invalide." }, 400);
  }
  const consent = parseConsent(body);
  if (!consent) {
    return jsonResponse(
      {
        error:
          "Accepte les conditions d’utilisation et indique ton âge pour créer ton compte.",
      },
      400,
    );
  }
  const passwordError = validatePassword(password);
  if (passwordError) {
    return jsonResponse({ error: passwordError }, 400);
  }

  const normalizedFirst = normalizeName(firstName);
  const normalizedInitial = normalizeName(lastName).slice(0, 1);
  if (!normalizedFirst || !normalizedInitial) {
    return jsonResponse({ error: "Prénom ou nom invalide." }, 400);
  }

  let newUserId: string | null = null;
  let createdClubId: string | null = null;
  let admin: ReturnType<typeof createClient> | null = null;

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error("Missing server configuration");
    }

    admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const originHash = await sha256Hex(requestOrigin(req));
    const { data: allowed, error: rateLimitError } = await admin.rpc(
      "consume_registration_rate_limit",
      { p_origin_hash: originHash },
    );
    if (rateLimitError) throw rateLimitError;
    if (allowed !== true) {
      return jsonResponse(
        { error: "Trop de tentatives. Réessaie plus tard." },
        429,
        { "Retry-After": "3600" },
      );
    }

    // Le club est fixé ici, côté serveur : jamais choisi par le client
    // autrement que par un code d'invitation valide.
    let club: { id: string; name: string };
    if (mode === "create") {
      const { data: createdClub, error: clubError } = await admin.rpc(
        "create_club",
        {
          p_name: clubName,
          p_short_name: clubShortName || null,
        },
      );
      if (clubError) throw clubError;
      club = { id: createdClub.id, name: createdClub.name };
      createdClubId = club.id;
    } else {
      const { data: found, error: lookupError } = await admin.rpc(
        "club_for_invite_code",
        { p_code: inviteCode },
      );
      if (lookupError) throw lookupError;
      const match = Array.isArray(found) ? found[0] : null;
      if (!match) {
        return jsonResponse(
          { error: "Code d’invitation inconnu. Vérifie-le avec ton club." },
          404,
        );
      }
      club = { id: match.id, name: match.name };
    }

    const base = `${normalizedFirst}${normalizedInitial}`;
    let username = "";
    for (const candidate of usernameCandidates(base)) {
      const { data: existing, error: existsError } = await admin
        .from("profiles")
        .select("id")
        .eq("username", candidate)
        .maybeSingle();
      if (existsError) throw existsError;
      if (!existing) {
        username = candidate;
        break;
      }
    }
    if (!username) {
      if (createdClubId) {
        await admin.rpc("discard_empty_club", { p_club_id: createdClubId });
        createdClubId = null;
      }
      return jsonResponse(
        { error: "Impossible de générer un identifiant disponible." },
        409,
      );
    }

    const { data: created, error: createError } =
      await admin.auth.admin.createUser({
        email: `${username}@${USERNAME_DOMAIN}`,
        password,
        email_confirm: true,
        user_metadata: {
          first_name: firstName,
          last_name: lastName,
        },
        // Lu par le déclencheur d'inscription ; non modifiable par le compte.
        app_metadata: { club_id: club.id },
      });
    if (createError) throw createError;
    newUserId = created.user?.id ?? null;
    if (!newUserId) throw new Error("Account creation returned no user id");

    // Les automatismes de la base rangent ce qu'ils écrivent dans le club
    // annoncé par cet en-tête, que seule la clé de service peut fournir.
    const scoped = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
      global: { headers: { "x-club-id": club.id } },
    });

    const { error: updateError } = await scoped
      .from("profiles")
      .update({
        username,
        terms_version: consent.termsVersion,
        terms_accepted_at: new Date().toISOString(),
        age_confirmation: consent.ageConfirmation,
        updated_at: new Date().toISOString(),
      })
      .eq("id", newUserId)
      .eq("club_id", club.id);
    if (updateError) throw updateError;

    if (mode === "create") {
      const { error: founderError } = await scoped.rpc("promote_club_founder", {
        p_club_id: club.id,
        p_profile_id: newUserId,
      });
      if (founderError) throw founderError;
    }

    // Le compte est créé : l'envoi du lien de confirmation est un plus. S'il
    // échoue, l'inscription reste réussie et l'adresse pourra être confirmée
    // plus tard depuis le profil.
    let emailConfirmationSent = false;
    const publicAppUrl = Deno.env.get("PUBLIC_APP_URL")?.trim();
    const mail = readMailConfig();
    if (contactEmail && mail && publicAppUrl) {
      try {
        const token = randomToken();
        const { data: shouldSend, error: emailError } = await admin.rpc(
          "request_contact_email",
          {
            p_profile_id: newUserId,
            p_email: contactEmail,
            p_token_hash: await sha256Hex(token),
          },
        );
        if (emailError) throw emailError;
        if (shouldSend === true) {
          const message = confirmationMail(
            confirmationLink(publicAppUrl, token),
          );
          await sendMail(mail, contactEmail, message.subject, message.text);
          emailConfirmationSent = true;
        }
      } catch (emailFailure) {
        console.error("register-account confirmation mail failure", emailFailure);
      }
    }

    return jsonResponse({
      username,
      clubName: club.name,
      status: mode === "create" ? "active" : "pending",
      emailConfirmationSent,
    });
  } catch (error) {
    console.error("register-account failure", error);

    if (newUserId && admin) {
      const { error: cleanupError } = await admin.auth.admin.deleteUser(
        newUserId,
        false,
      );
      if (cleanupError) {
        console.error("register-account cleanup failure", cleanupError);
      }
    }
    if (createdClubId && admin) {
      const { error: clubCleanupError } = await admin.rpc(
        "discard_empty_club",
        { p_club_id: createdClubId },
      );
      if (clubCleanupError) {
        console.error("register-account club cleanup failure", clubCleanupError);
      }
    }

    return jsonResponse(
      { error: "La création du compte a échoué. Réessaie plus tard." },
      400,
    );
  }
});
