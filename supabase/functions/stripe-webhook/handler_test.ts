import { createStripeWebhookHandler } from "./handler.ts";
import { stripeSignatureFor, verifyStripeSignature } from "./signature.ts";

function assertEquals(actual: unknown, expected: unknown): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}

const SECRET = "whsec_test_secret";
const NOW = 1_800_000_000;

function fixture(rpcError: unknown = null) {
  const calls: unknown[] = [];
  const handler = createStripeWebhookHandler({
    // deno-lint-ignore no-explicit-any
    createClient: ((_url: string, key: string) => ({
      rpc: (name: string, args: unknown) => {
        calls.push({ key, name, args });
        return Promise.resolve({ data: { already_recorded: false }, error: rpcError });
      },
    })) as any,
    getEnv: (name) =>
      ({
        STRIPE_WEBHOOK_SECRET: SECRET,
        SUPABASE_URL: "https://example.supabase.co",
        SUPABASE_SERVICE_ROLE_KEY: "service-key",
      })[name],
    nowSeconds: () => NOW,
  });
  return { handler, calls };
}

async function signedRequest(
  event: unknown,
  { timestamp = NOW, secret = SECRET } = {},
): Promise<Request> {
  const body = JSON.stringify(event);
  const signature = await stripeSignatureFor(secret, String(timestamp), body);
  return new Request("https://example.test", {
    method: "POST",
    headers: { "Stripe-Signature": `t=${timestamp},v1=${signature}` },
    body,
  });
}

const paidEvent = {
  type: "checkout.session.completed",
  data: {
    object: {
      id: "cs_test_1",
      client_reference_id: "11111111-1111-1111-1111-111111111111",
      payment_status: "paid",
      amount_total: 7505,
      currency: "eur",
    },
  },
};

Deno.test("un paiement signé est enregistré avec la clé serveur", async () => {
  const { handler, calls } = fixture();
  const response = await handler(await signedRequest(paidEvent));
  assertEquals(response.status, 200);
  assertEquals(calls, [{
    key: "service-key",
    name: "stripe_record_card_payment",
    args: {
      p_checkout_id: "11111111-1111-1111-1111-111111111111",
      p_session_id: "cs_test_1",
      p_amount_cents: 7505,
      p_currency: "eur",
    },
  }]);
});

Deno.test("une signature fausse ne déclenche rien", async () => {
  const { handler, calls } = fixture();
  const response = await handler(
    await signedRequest(paidEvent, { secret: "whsec_autre" }),
  );
  assertEquals(response.status, 400);
  assertEquals(calls, []);
});

Deno.test("un événement trop ancien (rejeu) est refusé", async () => {
  const { handler, calls } = fixture();
  const response = await handler(
    await signedRequest(paidEvent, { timestamp: NOW - 3600 }),
  );
  assertEquals(response.status, 400);
  assertEquals(calls, []);
});

Deno.test("sans en-tête de signature, rien n'est enregistré", async () => {
  const { handler, calls } = fixture();
  const response = await handler(
    new Request("https://example.test", {
      method: "POST",
      body: JSON.stringify(paidEvent),
    }),
  );
  assertEquals(response.status, 400);
  assertEquals(calls, []);
});

Deno.test("un paiement pas encore réglé attend", async () => {
  const { handler, calls } = fixture();
  const event = structuredClone(paidEvent);
  event.data.object.payment_status = "unpaid";
  const response = await handler(await signedRequest(event));
  assertEquals(response.status, 200);
  assertEquals(calls, []);
});

Deno.test("les autres événements sont ignorés", async () => {
  const { handler, calls } = fixture();
  const response = await handler(
    await signedRequest({ type: "customer.created", data: { object: {} } }),
  );
  assertEquals(response.status, 200);
  assertEquals(calls, []);
});

Deno.test("un refus de la base renvoie une erreur pour que Stripe relance", async () => {
  const { handler } = fixture({ code: "22023", message: "Montant différent" });
  const response = await handler(await signedRequest(paidEvent));
  assertEquals(response.status, 500);
});

Deno.test("plusieurs signatures v1 : une seule valide suffit", async () => {
  const body = "{}";
  const good = await stripeSignatureFor(SECRET, String(NOW), body);
  assertEquals(
    await verifyStripeSignature(body, `t=${NOW},v1=deadbeef,v1=${good}`, SECRET, NOW),
    true,
  );
});
