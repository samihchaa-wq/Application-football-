import { createStripeRefundHandler } from "./handler.ts";

function assertEquals(actual: unknown, expected: unknown): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}

const PAYMENT = "11111111-1111-4111-8111-111111111111";
const REQUEST = "22222222-2222-4222-8222-222222222222";
const ENV: Record<string, string> = {
  SUPABASE_URL: "https://example.supabase.co",
  SUPABASE_ANON_KEY: "anon-key",
  STRIPE_SECRET_KEY: "sk_test_x",
};

type Rpc = { data: unknown; error: unknown };

function fixture({
  prepare = { data: { payment_intent_id: "pi_1", refundable_cents: 7900 }, error: null } as Rpc,
  record = { data: { credit_note_number: "AV-2026-0001" }, error: null } as Rpc,
  stripe = { status: 200, body: { id: "re_1", status: "succeeded" } as unknown },
  env = ENV,
} = {}) {
  const events: Record<string, unknown>[] = [];
  const handler = createStripeRefundHandler({
    // deno-lint-ignore no-explicit-any
    createClient: ((_url: string, key: string, options: any) => ({
      rpc: (name: string, args: unknown) => {
        events.push({
          rpc: name,
          key,
          auth: options?.global?.headers?.Authorization,
          args,
        });
        return Promise.resolve(
          name === "platform_prepare_card_refund" ? prepare : record,
        );
      },
    })) as any,
    getEnv: (name) => env[name],
    fetch: ((url: string, init: RequestInit) => {
      events.push({
        stripe: url,
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

function request(
  body: unknown = {
    payment_id: PAYMENT,
    request_id: REQUEST,
    amount_cents: 2900,
    reason: "Geste commercial",
  },
  auth: string | null = "Bearer operator-jwt",
): Request {
  return new Request("https://example.test", {
    method: "POST",
    headers: auth ? { Authorization: auth } : {},
    body: JSON.stringify(body),
  });
}

Deno.test("rembourse par Stripe puis enregistre l'avoir, au nom de l'éditeur", async () => {
  const { handler, events } = fixture();
  const response = await handler(request());
  assertEquals(response.status, 200);
  assertEquals((await response.json()).recorded, true);
  assertEquals(events[0], {
    rpc: "platform_prepare_card_refund",
    key: "anon-key",
    auth: "Bearer operator-jwt",
    args: { p_payment_id: PAYMENT, p_amount_cents: 2900 },
  });
  const stripe = events[1] as { body: Record<string, string>; idempotency: string };
  assertEquals(stripe.body.payment_intent, "pi_1");
  assertEquals(stripe.body.amount, "2900");
  assertEquals(stripe.idempotency, `refund-${REQUEST}`);
  assertEquals((events[2] as { args: { p_stripe_refund_id: string } }).args.p_stripe_refund_id, "re_1");
});

Deno.test("sans connexion, rien n'est fait", async () => {
  const { handler, events } = fixture();
  const response = await handler(request(undefined, null));
  assertEquals(response.status, 401);
  assertEquals(events, []);
});

Deno.test("une demande mal formée est refusée sans appel", async () => {
  const { handler, events } = fixture();
  const response = await handler(
    request({ payment_id: "x", request_id: REQUEST, amount_cents: 10 }),
  );
  assertEquals(response.status, 400);
  assertEquals(events, []);
});

Deno.test("un non-éditeur est refusé avant Stripe", async () => {
  const { handler, events } = fixture({
    prepare: { data: null, error: { code: "42501", message: "Réservé" } },
  });
  const response = await handler(request());
  assertEquals(response.status, 403);
  assertEquals(events.length, 1);
});

Deno.test("un montant trop élevé est refusé avant Stripe", async () => {
  const { handler, events } = fixture({
    prepare: { data: null, error: { code: "22023", message: "Montant à rembourser invalide." } },
  });
  const response = await handler(request());
  assertEquals(response.status, 409);
  assertEquals(events.length, 1);
});

Deno.test("un refus de Stripe n'enregistre rien", async () => {
  const { handler, events } = fixture({ stripe: { status: 400, body: { error: {} } } });
  const response = await handler(request());
  assertEquals(response.status, 502);
  assertEquals(events.length, 2);
});

Deno.test("Stripe a remboursé mais l'enregistrement échoue : signalé, sans erreur", async () => {
  const { handler } = fixture({ record: { data: null, error: { code: "XX000" } } });
  const response = await handler(request());
  assertEquals(response.status, 200);
  assertEquals((await response.json()).recorded, false);
});
