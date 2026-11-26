// Remboursement d'un paiement par carte, demandé par l'éditeur depuis le
// Gestionnaire.
//
// La base vérifie d'abord, au nom de l'éditeur (son jeton), qu'il est bien
// éditeur et que le montant est remboursable (platform_prepare_card_refund).
// Stripe rembourse, puis la base enregistre le remboursement et son avoir
// (platform_record_refund). Si cette dernière étape échoue, l'événement
// refund.created de Stripe l'enregistre quand même (stripe-webhook).
import type { createClient } from "jsr:@supabase/supabase-js@2.95.0";
import {
  readBoundedJson,
  RequestBodyTooLargeError,
} from "../send-push/request_security.ts";

export interface StripeRefundDependencies {
  createClient: typeof createClient;
  getEnv: (name: string) => string | undefined;
  fetch: typeof fetch;
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const jsonHeaders = { ...corsHeaders, "Content-Type": "application/json" };

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function createStripeRefundHandler({
  createClient,
  getEnv,
  fetch,
}: StripeRefundDependencies): (req: Request) => Promise<Response> {
  return async (req: Request) => {
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
    const contentLength = Number(req.headers.get("content-length") ?? "0");
    if (contentLength > 4096) {
      return jsonResponse({ error: "Request body too large" }, 413);
    }

    // L'en-tête de taille peut mentir (envoi fractionné) : le corps est lu
    // par morceaux et coupé au-delà de la limite.
    let body: Record<string, unknown>;
    try {
      body = await readBoundedJson<Record<string, unknown>>(req, 4096);
    } catch (error) {
      if (error instanceof RequestBodyTooLargeError) {
        return jsonResponse({ error: "Request body too large" }, 413);
      }
      return jsonResponse({ error: "Demande illisible." }, 400);
    }
    if (body === null || typeof body !== "object" || Array.isArray(body)) {
      return jsonResponse({ error: "Demande illisible." }, 400);
    }
    const paymentId = String(body.payment_id ?? "");
    const requestId = String(body.request_id ?? "");
    const amount = body.amount_cents;
    const reason = typeof body.reason === "string"
      ? body.reason.trim().slice(0, 300)
      : "";
    if (
      !UUID.test(paymentId) || !UUID.test(requestId) ||
      !Number.isInteger(amount) || (amount as number) < 1
    ) {
      return jsonResponse({ error: "Demande de remboursement invalide." }, 400);
    }

    const supabaseUrl = getEnv("SUPABASE_URL");
    const anonKey = getEnv("SUPABASE_ANON_KEY");
    const stripeKey = getEnv("STRIPE_SECRET_KEY")?.trim();
    if (!supabaseUrl || !anonKey || !stripeKey) {
      console.error("stripe-refund: configuration incomplète");
      return jsonResponse(
        { error: "Le remboursement par carte n’est pas disponible." },
        503,
      );
    }

    // Au nom de l'éditeur : la base vérifie son droit et le montant.
    const caller = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const prepared = await caller.rpc("platform_prepare_card_refund", {
      p_payment_id: paymentId,
      p_amount_cents: amount,
    });
    if (prepared.error) {
      const code = (prepared.error as { code?: string }).code;
      const status = code === "42501" ? 403 : code === "22023" ? 409 : 500;
      return jsonResponse(
        {
          error: status === 500
            ? "Le remboursement n’a pas pu être préparé."
            : prepared.error.message,
        },
        status,
      );
    }
    const paymentIntent = (prepared.data as { payment_intent_id?: string } | null)
      ?.payment_intent_id;
    if (!paymentIntent) {
      return jsonResponse(
        { error: "Le remboursement n’a pas pu être préparé." },
        500,
      );
    }

    const form = new URLSearchParams({
      payment_intent: paymentIntent,
      amount: String(amount),
      reason: "requested_by_customer",
      "metadata[payment_id]": paymentId,
      "metadata[reason]": reason,
    });
    const response = await fetch("https://api.stripe.com/v1/refunds", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${stripeKey}`,
        "Content-Type": "application/x-www-form-urlencoded",
        // Un double appui ne rembourse pas deux fois.
        "Idempotency-Key": `refund-${requestId}`,
      },
      body: form.toString(),
    });
    const refund = await response.json().catch(() => null) as
      | { id?: string; status?: string }
      | null;
    if (!response.ok || !refund?.id) {
      console.error("stripe-refund: Stripe a refusé", response.status);
      return jsonResponse(
        { error: "Stripe a refusé le remboursement." },
        502,
      );
    }

    const recorded = await caller.rpc("platform_record_refund", {
      p_payment_id: paymentId,
      p_amount_cents: amount,
      p_method: "carte",
      p_reason: reason || "Remboursement par carte",
      p_stripe_refund_id: refund.id,
    });
    if (recorded.error) {
      // Stripe a remboursé : l'événement refund.created l'enregistrera.
      console.error("stripe-refund: enregistrement différé", recorded.error);
      return jsonResponse({
        refunded: true,
        recorded: false,
        stripe_status: refund.status ?? null,
      });
    }
    return jsonResponse({
      refunded: true,
      recorded: true,
      stripe_status: refund.status ?? null,
      result: recorded.data,
    });
  };
}
