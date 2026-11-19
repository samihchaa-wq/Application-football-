// Reçoit les événements de Stripe. Seule une signature valide (secret du
// point de terminaison) déclenche un enregistrement ; chaque effet passe par
// une fonction de la base réservée à service_role et idempotente.
//
// Événements traités :
//   * checkout.session.completed / async_payment_succeeded : paiement de
//     l'abonnement, puis frais Stripe et reçu (au mieux) ;
//   * refund.created / refund.updated : remboursement (même fait depuis le
//     tableau de bord Stripe) ;
//   * charge.dispute.* : contestation de carte, alerte pour l'éditeur.
// Chaque événement est tracé (stripe_log_event), réussi ou non.
import type {
  createClient,
  SupabaseClient,
} from "jsr:@supabase/supabase-js@2.95.0";
import { verifyStripeSignature } from "./signature.ts";

export interface StripeWebhookDependencies {
  createClient: typeof createClient;
  getEnv: (name: string) => string | undefined;
  nowSeconds: () => number;
  fetch?: typeof fetch;
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
  payment_intent?: string | null;
}

interface StripeRefund {
  id?: string;
  amount?: number;
  payment_intent?: string | null;
  reason?: string | null;
  status?: string;
}

interface StripeDispute {
  id?: string;
  amount?: number;
  payment_intent?: string | null;
  reason?: string | null;
  status?: string;
}

type StripeEvent = {
  id?: string;
  type?: string;
  livemode?: boolean;
  data?: { object?: unknown };
};

const CHECKOUT = new Set([
  "checkout.session.completed",
  "checkout.session.async_payment_succeeded",
]);
const REFUND = new Set(["refund.created", "refund.updated"]);
const DISPUTE = new Set([
  "charge.dispute.created",
  "charge.dispute.updated",
  "charge.dispute.closed",
]);

export function createStripeWebhookHandler({
  createClient,
  getEnv,
  nowSeconds,
  fetch,
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

    let event: StripeEvent;
    try {
      event = JSON.parse(payload);
    } catch {
      return jsonResponse({ error: "Invalid payload" }, 400);
    }
    const type = event.type ?? "";
    if (!CHECKOUT.has(type) && !REFUND.has(type) && !DISPUTE.has(type)) {
      return jsonResponse({ received: true, ignored: true });
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const object = event.data?.object;
    const outcome = CHECKOUT.has(type)
      ? await handleCheckout(admin, object as CheckoutSession, {
        fetch,
        stripeKey: getEnv("STRIPE_SECRET_KEY")?.trim(),
      })
      : REFUND.has(type)
      ? await handleRefund(admin, object as StripeRefund)
      : await handleDispute(admin, object as StripeDispute);

    if (outcome.error) {
      console.error("stripe-webhook:", type, outcome.error);
    }
    if (event.id) {
      // Trace pour le Gestionnaire : un échec de traçage ne change rien au
      // traitement de l'événement.
      await admin.rpc("stripe_log_event", {
        p_event_id: event.id,
        p_type: type,
        p_livemode: event.livemode === true,
        p_ok: outcome.error === undefined,
        p_error: outcome.error ?? null,
      });
    }
    return jsonResponse(outcome.body, outcome.status);
  };
}

// Fonctions appelées après la vérification de la signature (plus haut).

/// Frais Stripe et reçu d'un paiement, lus après coup. Null si indisponible :
/// le paiement reste enregistré sans ces détails.
async function cardDetails(
  fetcher: typeof fetch | undefined,
  stripeKey: string | undefined,
  paymentIntentId: string,
): Promise<{ fee: number | null; receipt: string | null }> {
  if (!fetcher || !stripeKey) return { fee: null, receipt: null };
  try {
    const url = `https://api.stripe.com/v1/payment_intents/${
      encodeURIComponent(paymentIntentId)
    }?expand[]=latest_charge.balance_transaction`;
    const response = await fetcher(url, {
      headers: { Authorization: `Bearer ${stripeKey}` },
    });
    if (!response.ok) return { fee: null, receipt: null };
    const intent = await response.json() as {
      latest_charge?: {
        receipt_url?: string;
        balance_transaction?: { fee?: number } | string | null;
      } | string | null;
    };
    const charge = typeof intent.latest_charge === "object"
      ? intent.latest_charge
      : null;
    const balance = charge && typeof charge.balance_transaction === "object"
      ? charge.balance_transaction
      : null;
    return {
      fee: Number.isInteger(balance?.fee) ? balance!.fee! : null,
      receipt: typeof charge?.receipt_url === "string"
        ? charge.receipt_url
        : null,
    };
  } catch {
    return { fee: null, receipt: null };
  }
}

async function handleCheckout(
  admin: SupabaseClient,
  session: CheckoutSession | undefined,
  deps: { fetch?: typeof fetch; stripeKey?: string },
): Promise<{ status: number; body: unknown; error?: string }> {
  // Paiement différé (virement SEPA…) : on attend async_payment_succeeded.
  if (session?.payment_status !== "paid") {
    return { status: 200, body: { received: true, pending: true } };
  }
  if (
    !session.id || !session.client_reference_id ||
    !Number.isInteger(session.amount_total) || !session.currency
  ) {
    return {
      status: 400,
      body: { error: "Incomplete session" },
      error: "Session incomplète",
    };
  }
  const { data, error } = await admin.rpc("stripe_record_card_payment", {
    p_checkout_id: session.client_reference_id,
    p_session_id: session.id,
    p_amount_cents: session.amount_total,
    p_currency: session.currency,
  });
  if (error) {
    // Stripe relance pendant plusieurs jours et prévient l'éditeur.
    return {
      status: 500,
      body: { error: "Payment not recorded" },
      error: `Paiement non enregistré : ${error.message ?? "erreur"}`,
    };
  }
  if (session.payment_intent) {
    const details = await cardDetails(
      deps.fetch,
      deps.stripeKey,
      session.payment_intent,
    );
    await admin.rpc("stripe_attach_card_details", {
      p_session_id: session.id,
      p_payment_intent_id: session.payment_intent,
      p_fee_cents: details.fee,
      p_receipt_url: details.receipt,
    });
  }
  return { status: 200, body: { received: true, result: data } };
}

async function handleRefund(
  admin: SupabaseClient,
  refund: StripeRefund | undefined,
): Promise<{ status: number; body: unknown; error?: string }> {
  // Un remboursement échoué ou annulé ne compte pas.
  if (
    !refund?.id || !refund.payment_intent || !Number.isInteger(refund.amount) ||
    refund.status === "failed" || refund.status === "canceled"
  ) {
    return { status: 200, body: { received: true, ignored: true } };
  }
  const { data, error } = await admin.rpc("stripe_record_refund", {
    p_payment_intent_id: refund.payment_intent,
    p_refund_id: refund.id,
    p_amount_cents: refund.amount,
    p_reason: refund.reason ?? null,
  });
  if (error) {
    return {
      status: 500,
      body: { error: "Refund not recorded" },
      error: `Remboursement non enregistré : ${error.message ?? "erreur"}`,
    };
  }
  return { status: 200, body: { received: true, result: data } };
}

async function handleDispute(
  admin: SupabaseClient,
  dispute: StripeDispute | undefined,
): Promise<{ status: number; body: unknown; error?: string }> {
  if (!dispute?.id) {
    return { status: 200, body: { received: true, ignored: true } };
  }
  const { error } = await admin.rpc("stripe_record_dispute", {
    p_dispute_id: dispute.id,
    p_payment_intent_id: dispute.payment_intent ?? null,
    p_amount_cents: Number.isInteger(dispute.amount) ? dispute.amount : null,
    p_reason: dispute.reason ?? null,
    p_status: dispute.status ?? null,
  });
  if (error) {
    return {
      status: 500,
      body: { error: "Dispute not recorded" },
      error: `Contestation non enregistrée : ${error.message ?? "erreur"}`,
    };
  }
  return { status: 200, body: { received: true } };
}
