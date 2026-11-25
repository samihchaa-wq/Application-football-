import { createStripeCheckoutHandler } from "./handler.ts";

function assertEquals(actual: unknown, expected: unknown): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}

const ENV: Record<string, string> = {
  SUPABASE_URL: "https://example.supabase.co",
  SUPABASE_ANON_KEY: "anon-key",
  STRIPE_SECRET_KEY: "sk_test_x",
  PUBLIC_APP_URL: "https://app.example.test/",
};

function fixture({
  rpc = {
    data: {
      checkout_id: "c-1",
      club_id: "club-1",
      club_name: "FC Tests",
      amount_cents: 7505,
      created_at_epoch: 1_800_000_000,
    },
    error: null,
  } as { data: unknown; error: unknown },
  stripe = { status: 200, body: { id: "cs_1", url: "https://checkout.stripe.com/c/cs_1" } },
  env = ENV,
} = {}) {
  const events: Record<string, unknown>[] = [];
  const handler = createStripeCheckoutHandler({
    // deno-lint-ignore no-explicit-any
    createClient: ((_url: string, key: string, options: any) => ({
      rpc: (name: string) => {
        events.push({
          rpc: name,
          key,
          auth: options?.global?.headers?.Authorization,
        });
        return Promise.resolve(rpc);
      },
    })) as any,
    getEnv: (name) => env[name],
    fetch: ((url: string, init: RequestInit) => {
      events.push({
        stripe: url,
        auth: (init.headers as Record<string, string>).Authorization,
        idempotency: (init.headers as Record<string, string>)["Idempotency-Key"],
        body: Object.fromEntries(new URLSearchParams(String(init.body))),
      });
      return Promise.resolve(
        new Response(JSON.stringify(stripe.body), { status: stripe.status }),
      );
    }) as typeof fetch,
  });
  return { handler, events };
}

function request(auth: string | null = "Bearer user-jwt"): Request {
  return new Request("https://example.test", {
    method: "POST",
    headers: auth ? { Authorization: auth } : {},
  });
}

Deno.test("ouvre une session Stripe du montant calculé par la base", async () => {
  const { handler, events } = fixture();
  const response = await handler(request());
  assertEquals(response.status, 200);
  assertEquals(await response.json(), {
    url: "https://checkout.stripe.com/c/cs_1",
    amount_cents: 7505,
  });
  // La base est appelée au nom de l'administrateur, jamais en service_role.
  assertEquals(events[0], {
    rpc: "admin_prepare_card_payment",
    key: "anon-key",
    auth: "Bearer user-jwt",
  });
  const stripe = events[1] as { body: Record<string, string> };
  assertEquals(stripe.body["line_items[0][price_data][unit_amount]"], "7505");
  assertEquals(stripe.body["line_items[0][price_data][currency]"], "eur");
  assertEquals(stripe.body.client_reference_id, "c-1");
  assertEquals(
    stripe.body.success_url,
    "https://app.example.test/#/admin/abonnement?paiement=merci",
  );
  assertEquals((events[1] as { idempotency: string }).idempotency, "checkout-c-1");
  // La page expire 32 min après la création du paiement.
  assertEquals(stripe.body.expires_at, String(1_800_000_000 + 32 * 60));
});

Deno.test("deux appels pour le même paiement envoient des paramètres identiques", async () => {
  const first = fixture();
  const second = fixture();
  await first.handler(request());
  await new Promise((resolve) => setTimeout(resolve, 1100));
  await second.handler(request());
  // Mêmes paramètres + même clé d'idempotence : Stripe renvoie la même page.
  assertEquals(
    (second.events[1] as { body: unknown }).body,
    (first.events[1] as { body: unknown }).body,
  );
  assertEquals(
    (second.events[1] as { idempotency: string }).idempotency,
    (first.events[1] as { idempotency: string }).idempotency,
  );
});

Deno.test("base ancienne sans heure de création : expiration depuis maintenant", async () => {
  const { handler, events } = fixture({
    rpc: {
      data: { checkout_id: "c-1", club_id: "club-1", club_name: "FC", amount_cents: 7505 },
      error: null,
    },
  });
  const before = Math.floor(Date.now() / 1000);
  await handler(request());
  const expiresAt = Number(
    (events[1] as { body: Record<string, string> }).body.expires_at,
  );
  if (expiresAt < before + 32 * 60 || expiresAt > before + 32 * 60 + 5) {
    throw new Error(`expires_at inattendu : ${expiresAt}`);
  }
});

Deno.test("sans connexion, rien n'est demandé", async () => {
  const { handler, events } = fixture();
  const response = await handler(request(null));
  assertEquals(response.status, 401);
  assertEquals(events, []);
});

Deno.test("un non-administrateur est refusé sans appel à Stripe", async () => {
  const { handler, events } = fixture({
    rpc: { data: null, error: { code: "42501", message: "Réservé" } },
  });
  const response = await handler(request());
  assertEquals(response.status, 403);
  assertEquals(events.length, 1);
});

Deno.test("rien à payer : message de la base, pas de session", async () => {
  const { handler, events } = fixture({
    rpc: {
      data: null,
      error: { code: "22023", message: "Rien à payer : active ton année offerte." },
    },
  });
  const response = await handler(request());
  assertEquals(response.status, 409);
  assertEquals((await response.json()).error, "Rien à payer : active ton année offerte.");
  assertEquals(events.length, 1);
});

Deno.test("sans clé Stripe configurée : indisponible, sans appel", async () => {
  const { handler, events } = fixture({
    env: { ...ENV, STRIPE_SECRET_KEY: "" },
  });
  const response = await handler(request());
  assertEquals(response.status, 503);
  assertEquals(events, []);
});

Deno.test("un refus de Stripe est signalé", async () => {
  const { handler } = fixture({ stripe: { status: 400, body: { error: {} } } as never });
  const response = await handler(request());
  assertEquals(response.status, 502);
});

Deno.test("un montant sous 0,50 € est refusé avant Stripe", async () => {
  const { handler, events } = fixture({
    rpc: {
      data: {
        checkout_id: "c-1",
        club_id: "club-1",
        club_name: "FC Tests",
        amount_cents: 49,
        created_at_epoch: 1_800_000_000,
      },
      error: null,
    },
  });
  const response = await handler(request());
  assertEquals(response.status, 500);
  assertEquals(events.length, 1); // seulement l'appel à la base, rien vers Stripe
});
