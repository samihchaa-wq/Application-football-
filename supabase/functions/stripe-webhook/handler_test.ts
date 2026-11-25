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

function fixture(
  rpcError: unknown = null,
  stripeApi: (url: string) => Response = () =>
    new Response(
      JSON.stringify({
        latest_charge: {
          receipt_url: "https://pay.stripe.com/receipts/r1",
          balance_transaction: { fee: 136 },
        },
      }),
    ),
) {
  const calls: unknown[] = [];
  const handler = createStripeWebhookHandler({
    fetch: ((url: string) => {
      calls.push({ stripeApi: url });
      return Promise.resolve(stripeApi(url));
    }) as typeof fetch,
    // deno-lint-ignore no-explicit-any
    createClient: ((_url: string, key: string) => ({
      rpc: (name: string, args: unknown) => {
        calls.push({ key, name, args });
        // Les traces d'événements ne sont jamais en erreur dans ces tests.
        const error = name === "stripe_log_event" ? null : rpcError;
        return Promise.resolve({ data: { already_recorded: false }, error });
      },
    })) as any,
    getEnv: (name) =>
      ({
        STRIPE_WEBHOOK_SECRET: SECRET,
        SUPABASE_URL: "https://example.supabase.co",
        SUPABASE_SERVICE_ROLE_KEY: "service-key",
        STRIPE_SECRET_KEY: "sk_test_x",
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
  id: "evt_1",
  livemode: false,
  type: "checkout.session.completed",
  data: {
    object: {
      id: "cs_test_1",
      client_reference_id: "11111111-1111-1111-1111-111111111111",
      payment_status: "paid",
      amount_total: 7505,
      currency: "eur",
      payment_intent: "pi_1",
    },
  },
};

Deno.test("un paiement signé est enregistré, puis ses frais et son reçu", async () => {
  const { handler, calls } = fixture();
  const response = await handler(await signedRequest(paidEvent));
  assertEquals(response.status, 200);
  assertEquals(calls[0], {
    key: "service-key",
    name: "stripe_record_card_payment",
    args: {
      p_checkout_id: "11111111-1111-1111-1111-111111111111",
      p_session_id: "cs_test_1",
      p_amount_cents: 7505,
      p_currency: "eur",
    },
  });
  assertEquals(
    calls[1],
    {
      stripeApi:
        "https://api.stripe.com/v1/payment_intents/pi_1?expand[]=latest_charge.balance_transaction",
    },
  );
  assertEquals(calls[2], {
    key: "service-key",
    name: "stripe_attach_card_details",
    args: {
      p_session_id: "cs_test_1",
      p_payment_intent_id: "pi_1",
      p_fee_cents: 136,
      p_receipt_url: "https://pay.stripe.com/receipts/r1",
    },
  });
  assertEquals((calls[3] as { name: string }).name, "stripe_log_event");
});

Deno.test("frais indisponibles : le paiement reste enregistré", async () => {
  const { handler, calls } = fixture(null, () => new Response("{}", { status: 500 }));
  const response = await handler(await signedRequest(paidEvent));
  assertEquals(response.status, 200);
  assertEquals((calls[2] as { args: { p_fee_cents: unknown } }).args.p_fee_cents, null);
});

Deno.test("un remboursement Stripe est enregistré", async () => {
  const { handler, calls } = fixture();
  const response = await handler(
    await signedRequest({
      id: "evt_2",
      type: "refund.created",
      data: {
        object: {
          id: "re_1",
          amount: 1000,
          payment_intent: "pi_1",
          reason: "requested_by_customer",
          status: "succeeded",
        },
      },
    }),
  );
  assertEquals(response.status, 200);
  assertEquals(calls[0], {
    key: "service-key",
    name: "stripe_record_refund",
    args: {
      p_payment_intent_id: "pi_1",
      p_refund_id: "re_1",
      p_amount_cents: 1000,
      p_reason: "requested_by_customer",
    },
  });
});

Deno.test("un remboursement échoué est ignoré", async () => {
  const { handler, calls } = fixture();
  await handler(
    await signedRequest({
      id: "evt_3",
      type: "refund.updated",
      data: { object: { id: "re_2", amount: 10, payment_intent: "pi_1", status: "failed" } },
    }),
  );
  assertEquals(
    calls.filter((call) => (call as { name?: string }).name === "stripe_record_refund"),
    [],
  );
});

Deno.test("une contestation devient une alerte", async () => {
  const { handler, calls } = fixture();
  const response = await handler(
    await signedRequest({
      id: "evt_4",
      type: "charge.dispute.created",
      data: {
        object: {
          id: "dp_1",
          amount: 7505,
          payment_intent: "pi_1",
          reason: "fraudulent",
          status: "needs_response",
        },
      },
    }),
  );
  assertEquals(response.status, 200);
  assertEquals((calls[0] as { name: string }).name, "stripe_record_dispute");
});

Deno.test("un échec est tracé pour le Gestionnaire", async () => {
  const { handler, calls } = fixture({ code: "22023", message: "Montant différent" });
  const response = await handler(await signedRequest(paidEvent));
  assertEquals(response.status, 500);
  const log = calls.find((call) => (call as { name?: string }).name === "stripe_log_event") as {
    args: { p_ok: boolean; p_error: string };
  };
  assertEquals(log.args.p_ok, false);
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
  // Seule la trace de l'événement est écrite.
  assertEquals(
    calls.map((call) => (call as { name?: string }).name),
    ["stripe_log_event"],
  );
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

Deno.test("une signature tronquée ou allongée est refusée", async () => {
  const payload = '{"id":"evt_1"}';
  const good = await stripeSignatureFor(SECRET, String(NOW), payload);
  for (const candidate of [good.slice(0, 10), good.slice(0, 63), good + "00"]) {
    const header = `t=${NOW},v1=${candidate}`;
    assertEquals(await verifyStripeSignature(payload, header, SECRET, NOW), false);
  }
  assertEquals(
    await verifyStripeSignature(payload, `t=${NOW},v1=${good}`, SECRET, NOW),
    true,
  );
});
