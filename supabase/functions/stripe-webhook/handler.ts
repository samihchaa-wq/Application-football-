// Reçoit les confirmations de Stripe. Seule une signature valide (secret du
// point de terminaison) déclenche un enregistrement ; l'effet passe par
// stripe_record_card_payment(), réservée à service_role et idempotente.
import type { createClient } from "jsr:@supabase/supabase-js@2.95.0";
import { verifyStripeSignature } from "./signature.ts";

export interface StripeWebhookDependencies {
  createClient: typeof createClient;
  getEnv: (name: string) => string | undefined;
  nowSeconds: () => number;
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

interface CheckoutSession {
  id?: string;
  client_reference_id?: string | null;
  payment_status?: string;
  amount_total?: number | null;
  currency?: string | null;
}

const HANDLED = new Set([
  "checkout.session.completed",
  "checkout.session.async_payment_succeeded",
]);

export function createStripeWebhookHandler({
  createClient,
  getEnv,
  nowSeconds,
}: StripeWebhookDependencies): (req: Request) => Promise<Response> {
  return async (req: Request) => {
    if (req.method !== "POST") {
      return jsonResponse({ error: "Method not allowed" }, 405);
    }
    const contentLength = Number(req.headers.get("content-length") ?? "0");
    if (contentLength > 262_144) {
      return jsonResponse({ error: "Request body too large" }, 413);
    }
    const webhookSecret = getEnv("STRIPE_WEBHOOK_SECRET")?.trim();
    const supabaseUrl = getEnv("SUPABASE_URL");
    const serviceRoleKey = getEnv("SUPABASE_SERVICE_ROLE_KEY");
    if (!webhookSecret || !supabaseUrl || !serviceRoleKey) {
      console.error("stripe-webhook: configuration incomplète");
      return jsonResponse({ error: "Not configured" }, 503);
    }

    const payload = await req.text();
    const signed = await verifyStripeSignature(
      payload,
      req.headers.get("Stripe-Signature"),
      webhookSecret,
      nowSeconds(),
    );
    if (!signed) {
      return jsonResponse({ error: "Invalid signature" }, 400);
    }

    let event: { type?: string; data?: { object?: CheckoutSession } };
    try {
      event = JSON.parse(payload);
    } catch {
      return jsonResponse({ error: "Invalid payload" }, 400);
    }
    if (!event.type || !HANDLED.has(event.type)) {
      return jsonResponse({ received: true, ignored: true });
    }
    const session = event.data?.object;
    // Paiement différé (virement SEPA…) : on attend async_payment_succeeded.
    if (session?.payment_status !== "paid") {
      return jsonResponse({ received: true, pending: true });
    }
    if (
      !session.id || !session.client_reference_id ||
      !Number.isInteger(session.amount_total) || !session.currency
    ) {
      console.error("stripe-webhook: session incomplète", session?.id);
      return jsonResponse({ error: "Incomplete session" }, 400);
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await admin.rpc("stripe_record_card_payment", {
      p_checkout_id: session.client_reference_id,
      p_session_id: session.id,
      p_amount_cents: session.amount_total,
      p_currency: session.currency,
    });
    if (error) {
      // Stripe relance pendant plusieurs jours et prévient l'éditeur.
      console.error("stripe-webhook: enregistrement refusé", session.id, error);
      return jsonResponse({ error: "Payment not recorded" }, 500);
    }
    return jsonResponse({ received: true, result: data });
  };
}
