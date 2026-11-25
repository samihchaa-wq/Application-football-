// Ouvre une session de paiement Stripe (Checkout) pour l'abonnement du club.
//
// Le montant n'est jamais fourni par l'appli : la base le calcule et le fige
// (réduction de parrainage comprise) dans admin_prepare_card_payment(),
// appelée avec le jeton de l'administrateur. Aucune clé de service ici.
import type { createClient } from "jsr:@supabase/supabase-js@2.95.0";

export interface StripeCheckoutDependencies {
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

interface PreparedPayment {
  checkout_id: string;
  club_id: string;
  club_name: string;
  amount_cents: number;
  // Heure de création du paiement (secondes) ; absente d'une ancienne base.
  created_at_epoch?: number;
}

// La page de paiement expire 32 minutes après la création du paiement. La base
// réutilise un paiement en attente pendant 30 minutes seulement : une page
// ouverte ne reste donc pas payable à côté d'une nouvelle (Stripe exige au
// moins 30 minutes de validité à la création).
const CHECKOUT_LIFETIME_SECONDS = 32 * 60;

export function createStripeCheckoutHandler({
  createClient,
  getEnv,
  fetch,
}: StripeCheckoutDependencies): (req: Request) => Promise<Response> {
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

    const supabaseUrl = getEnv("SUPABASE_URL");
    const anonKey = getEnv("SUPABASE_ANON_KEY");
    const stripeKey = getEnv("STRIPE_SECRET_KEY")?.trim();
    const publicAppUrl = getEnv("PUBLIC_APP_URL")?.trim().replace(/\/+$/, "");
    if (!supabaseUrl || !anonKey || !stripeKey || !publicAppUrl) {
      console.error("stripe-checkout: configuration incomplète");
      return jsonResponse(
        { error: "Le paiement par carte n’est pas encore disponible." },
        503,
      );
    }

    // Appel au nom de l'administrateur : la base vérifie son rôle et son club.
    const caller = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await caller.rpc("admin_prepare_card_payment");
    if (error) {
      const code = (error as { code?: string }).code;
      const status = code === "42501" ? 403 : code === "22023" ? 409 : 500;
      if (status === 500) console.error("stripe-checkout: préparation", error);
      return jsonResponse(
        {
          error: status === 500
            ? "Le paiement n’a pas pu être préparé."
            : (error as { message?: string }).message,
        },
        status,
      );
    }
    const prepared = data as PreparedPayment | null;
    if (
      !prepared?.checkout_id ||
      !Number.isInteger(prepared.amount_cents) ||
      prepared.amount_cents < 50
    ) {
      return jsonResponse({ error: "Le paiement n’a pas pu être préparé." }, 500);
    }

    const returnUrl = `${publicAppUrl}/#/admin/abonnement`;
    // Dérivée de la création du paiement (et non de l'heure de l'appel) : un
    // appel répété pour le même paiement envoie des paramètres identiques et
    // Stripe renvoie la même page grâce à la clé d'idempotence.
    const createdAt = Number.isInteger(prepared.created_at_epoch)
      ? prepared.created_at_epoch!
      : Math.floor(Date.now() / 1000);
    const form = new URLSearchParams({
      mode: "payment",
      locale: "fr",
      expires_at: String(createdAt + CHECKOUT_LIFETIME_SECONDS),
      client_reference_id: prepared.checkout_id,
      success_url: `${returnUrl}?paiement=merci`,
      cancel_url: `${returnUrl}?paiement=annule`,
      "line_items[0][quantity]": "1",
      "line_items[0][price_data][currency]": "eur",
      "line_items[0][price_data][unit_amount]": String(prepared.amount_cents),
      "line_items[0][price_data][product_data][name]":
        `Abonnement annuel PetitFilet – ${prepared.club_name}`.slice(0, 250),
      "metadata[checkout_id]": prepared.checkout_id,
      "metadata[club_id]": prepared.club_id,
      "payment_intent_data[metadata][checkout_id]": prepared.checkout_id,
      "payment_intent_data[metadata][club_id]": prepared.club_id,
    });

    const response = await fetch("https://api.stripe.com/v1/checkout/sessions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${stripeKey}`,
        "Content-Type": "application/x-www-form-urlencoded",
        // Un double appui renvoie la même session : la base réutilise le
        // paiement en attente, donc la même clé et les mêmes paramètres.
        "Idempotency-Key": `checkout-${prepared.checkout_id}`,
      },
      body: form.toString(),
    });
    const session = await response.json().catch(() => null) as
      | { url?: string; id?: string }
      | null;
    if (!response.ok || !session?.url) {
      console.error("stripe-checkout: Stripe a refusé la session", response.status);
      return jsonResponse(
        { error: "Le paiement par carte est indisponible pour le moment." },
        502,
      );
    }
    return jsonResponse({ url: session.url, amount_cents: prepared.amount_cents });
  };
}
