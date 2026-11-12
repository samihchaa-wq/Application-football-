import { isDuplicateError, reserveUsername } from "./username.ts";

function assertEquals(actual: unknown, expected: unknown) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

/// Base simulée : identifiants déjà pris + calcul du premier libre, comme
/// public.internal_next_free_username.
function fakeBase(base: string, taken: string[]) {
  const names = new Set(taken);
  const nextFree = (skip: string[]) => {
    const used = new Set([...names, ...skip]);
    for (let n = 1; ; n++) {
      const candidate = n === 1 ? base : `${base}${n}`;
      if (!used.has(candidate)) return Promise.resolve(candidate);
    }
  };
  return { names, nextFree };
}

Deno.test("le premier compte garde l'identifiant sans numéro", async () => {
  const db = fakeBase("thomasd", []);
  const name = await reserveUsername(db.nextFree, (c) => {
    db.names.add(c);
    return Promise.resolve("ok");
  });
  assertEquals(name, "thomasd");
});

Deno.test("une collision simultanée passe au numéro suivant", async () => {
  const db = fakeBase("thomasd", ["thomasd", "thomasd2"]);
  const attempts: string[] = [];
  const name = await reserveUsername(db.nextFree, (c) => {
    attempts.push(c);
    // Une autre inscription vient de prendre « thomasd3 » sans que son profil
    // soit encore visible : la base refuse.
    if (c === "thomasd3") return Promise.resolve("taken");
    db.names.add(c);
    return Promise.resolve("ok");
  });
  assertEquals(attempts, ["thomasd3", "thomasd4"]);
  assertEquals(name, "thomasd4");
});

Deno.test("des collisions répétées finissent par un refus propre", async () => {
  const db = fakeBase("thomasd", []);
  const name = await reserveUsername(db.nextFree, () => Promise.resolve("taken"), 3);
  assertEquals(name, "");
});

Deno.test("reconnaît les erreurs de doublon", () => {
  assertEquals(isDuplicateError({ code: "email_exists", message: "x" }), true);
  assertEquals(isDuplicateError({ code: "23505", message: "x" }), true);
  assertEquals(
    isDuplicateError({ message: "A user with this email address has already been registered" }),
    true,
  );
  assertEquals(isDuplicateError({ code: "42501", message: "permission denied" }), false);
  assertEquals(isDuplicateError(null), false);
});
