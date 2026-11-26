import {
  assert,
  assertEquals,
  assertFalse,
} from "jsr:@std/assert@1.0.13";
import { internalCallSignature, verifyInternalCall } from "./internal_call.ts";

const CLUB = "00000000-0000-0000-0000-000000000001";

// Valeurs calculées indépendamment (HMAC-SHA256, clé « secret ») et reprises
// dans le test de la base : les deux côtés doivent signer à l'identique.
const SEND_PUSH_CLUB =
  "d3b9f952dbad38be36c72a87896de7dcd6ee179caa8a83be9a2f2f17f575d6ab";
const ACCOUNT_EMAIL_NO_CLUB =
  "3b726fad1e4fa03266cf00188067331425a5278adcd28bf4bc96ddbae6b9e606";

function request(headers: Record<string, string>): Request {
  return new Request("https://example.invalid/functions/v1/send-push", {
    method: "POST",
    headers,
  });
}

Deno.test("la signature est la même que celle calculée par la base", async () => {
  assertEquals(
    await internalCallSignature("secret", "send-push", CLUB),
    SEND_PUSH_CLUB,
  );
  assertEquals(
    await internalCallSignature("secret", "account-email", ""),
    ACCOUNT_EMAIL_NO_CLUB,
  );
});

Deno.test("une signature valide pour la fonction et le club est acceptée", async () => {
  assert(
    await verifyInternalCall(
      request({ "x-push-signature": SEND_PUSH_CLUB, "x-club-id": CLUB }),
      "secret",
      "send-push",
    ),
  );
  assert(
    await verifyInternalCall(
      request({ "x-push-signature": ACCOUNT_EMAIL_NO_CLUB }),
      "secret",
      "account-email",
    ),
  );
});

Deno.test("la signature d'un club ne vaut pas pour un autre club", async () => {
  assertFalse(
    await verifyInternalCall(
      request({
        "x-push-signature": SEND_PUSH_CLUB,
        "x-club-id": "00000000-0000-0000-0000-000000000002",
      }),
      "secret",
      "send-push",
    ),
  );
});

Deno.test("la signature d'une fonction ne vaut pas pour une autre", async () => {
  assertFalse(
    await verifyInternalCall(
      request({ "x-push-signature": SEND_PUSH_CLUB, "x-club-id": CLUB }),
      "secret",
      "account-email",
    ),
  );
});

Deno.test("le mot de passe brut seul n'est plus accepté", async () => {
  assertFalse(
    await verifyInternalCall(
      request({ "x-push-token": "secret", "x-club-id": CLUB }),
      "secret",
      "send-push",
    ),
  );
});

Deno.test("sans mot de passe configuré, rien n'est accepté", async () => {
  assertFalse(
    await verifyInternalCall(
      request({ "x-push-signature": SEND_PUSH_CLUB, "x-club-id": CLUB }),
      "",
      "send-push",
    ),
  );
});
