import { assertEquals } from "jsr:@std/assert@1";
import { handleSync } from "./handler.ts";

// Aucun appel réseau ni base : le refus arrive avant.
const noNetwork = () => Promise.reject(new Error("réseau interdit dans ce test"));
const env = () => undefined;

Deno.test("seul POST est accepté", async () => {
  const response = await handleSync(new Request("http://local/", { method: "GET" }), {
    env, fetch: noNetwork, tokenSha256: "x",
  });
  assertEquals(response.status, 405);
});

Deno.test("sans empreinte de jeton configurée, tout est refusé", async () => {
  const response = await handleSync(
    new Request("http://local/", { method: "POST", headers: { "x-sync-token": "" } }),
    { env, fetch: noNetwork },
  );
  assertEquals(response.status, 403);
});

Deno.test("un mauvais jeton est refusé", async () => {
  const response = await handleSync(
    new Request("http://local/", { method: "POST", headers: { "x-sync-token": "faux" } }),
    { env, fetch: noNetwork, tokenSha256: "0".repeat(64) },
  );
  assertEquals(response.status, 403);
});
