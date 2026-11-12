import { firstFreeUsername } from "./username.ts";

function assertEquals(actual: unknown, expected: unknown) {
  if (actual !== expected) {
    throw new Error(`Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

Deno.test("le premier compte garde l'identifiant sans numéro", () => {
  assertEquals(firstFreeUsername("thomasd", []), "thomasd");
});

Deno.test("les homonymes reçoivent le premier numéro libre", () => {
  assertEquals(firstFreeUsername("thomasd", ["thomasd"]), "thomasd2");
  assertEquals(
    firstFreeUsername("thomasd", ["thomasd", "thomasd2", "thomasd4"]),
    "thomasd3",
  );
  assertEquals(firstFreeUsername("thomasd", ["ThomasD", null]), "thomasd2");
});

Deno.test("plus de 20 homonymes ne bloquent plus l'inscription", () => {
  const taken = ["thomasd"];
  for (let i = 2; i <= 250; i++) taken.push(`thomasd${i}`);
  assertEquals(firstFreeUsername("thomasd", taken), "thomasd251");
});
