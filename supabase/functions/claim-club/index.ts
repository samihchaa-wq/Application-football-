// Rattacher à un club un compte déjà connecté (par exemple via Facebook) qui
// n'en a pas encore : rejoindre avec un code d'invitation, ou créer un club.
// Le club n'est jamais choisi par le client autrement que par un code valide.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2.95.0";
import { parseConsent } from "./consent.ts";

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

async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return jsonResponse({ error: "Connexion requise." }, 401);
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
  const mode = body.mode === "create" ? "create" : "join";
  const inviteCode = String(body.inviteCode ?? "")
    .trim()
    .toUpperCase()
    .replace(/[\s-]/g, "");
  const clubName = String(body.clubName ?? "").trim().replace(/\s+/g, " ");
  const clubShortName = String(body.clubShortName ?? "").trim();

  if (
    firstName.length < 2 ||
    firstName.length > 50 ||
    lastName.length < 2 ||
    lastName.length > 50 ||
    /[\u0000-\u001f\u007f]/.test(firstName + lastName)
  ) {
    return jsonResponse({ error: "Prénom ou nom invalide." }, 400);
  }
  const consent = parseConsent(body);
  if (!consent) {
    return jsonResponse(
      {
        error:
          "Accepte les conditions d’utilisation et indique ton âge pour continuer.",
      },
      400,
    );
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

  const normalizedFirst = normalizeName(firstName);
  const normalizedInitial = normalizeName(lastName).slice(0, 1);
  if (!normalizedFirst || !normalizedInitial) {
    return jsonResponse({ error: "Prénom ou nom invalide." }, 400);
  }

  let userId: string | null = null;
  let clubAssigned = false;
  let createdClubId: string | null = null;
  let admin: ReturnType<typeof createClient> | null = null;

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !anonKey || !serviceRoleKey) {
      throw new Error("Missing server configuration");
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
    userId = userData.user.id;

    admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    // Un compte qui a déjà un profil ne change jamais de club par ici.
    const { data: existingProfile, error: profileError } = await admin
      .from("profiles")
      .select("id")
      .eq("id", userId)
      .maybeSingle();
    if (profileError) throw profileError;
    if (existingProfile) {
      return jsonResponse({ error: "Ce compte appartient déjà à un club." }, 409);
    }

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

    let club: { id: string; name: string };
    if (mode === "create") {
      const { data: createdClub, error: clubError } = await admin.rpc(
        "create_club",
        { p_name: clubName, p_short_name: clubShortName || null },
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

    const base = `${normalizedFirst}${normalizedInitial}`.slice(0, 27);
    let username = "";
    for (let suffix = 1; suffix <= 20; suffix++) {
      const candidate = suffix === 1 ? base : `${base}${suffix}`;
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

    // Le club est inscrit dans la zone réservée au serveur : le déclencheur
    // de la base crée alors le profil dans ce club.
    const { error: assignError } = await admin.auth.admin.updateUserById(
      userId,
      {
        user_metadata: { first_name: firstName, last_name: lastName },
        app_metadata: { club_id: club.id },
      },
    );
    if (assignError) throw assignError;
    clubAssigned = true;

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
      .eq("id", userId)
      .eq("club_id", club.id);
    if (updateError) throw updateError;

    if (mode === "create") {
      const { error: founderError } = await scoped.rpc("promote_club_founder", {
        p_club_id: club.id,
        p_profile_id: userId,
      });
      if (founderError) throw founderError;
    }

    return jsonResponse({
      username,
      clubName: club.name,
      status: mode === "create" ? "active" : "pending",
    });
  } catch (error) {
    console.error("claim-club failure", error);

    if (createdClubId && admin) {
      const { error: clubCleanupError } = await admin.rpc(
        "discard_empty_club",
        { p_club_id: createdClubId },
      );
      if (clubCleanupError) {
        console.error("claim-club club cleanup failure", clubCleanupError);
      }
    }
    if (clubAssigned && userId && admin) {
      const { error: resetError } = await admin.auth.admin.updateUserById(
        userId,
        { app_metadata: { club_id: null } },
      );
      if (resetError) console.error("claim-club reset failure", resetError);
    }

    return jsonResponse(
      { error: "Le rattachement au club a échoué. Réessaie plus tard." },
      400,
    );
  }
});
