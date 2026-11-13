import {
  createManageUserHandler,
  type ManageUserDependencies,
} from "./handler.ts";

function assertEquals(actual: unknown, expected: unknown): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}

const CLUB_A = "a1000000-0000-0000-0000-000000000001";
const CLUB_B = "b1000000-0000-0000-0000-000000000001";
const ADMIN = "a2000000-0000-0000-0000-000000000001";
const TARGET = "a2000000-0000-0000-0000-000000000002";

// Le vrai handler HTTP est exécuté ; seuls Auth et les réponses de la base
// sont simulés. Les traces prouvent qu'aucune opération privilégiée n'a été
// déclenchée après un refus (pas seulement qu'une fonction booléenne est fausse).
function fixture() {
  const events: string[] = [];
  const state = {
    jwtValid: true,
    caller: { id: ADMIN, club_id: CLUB_A, role: "admin", status: "active" },
    profileError: null as unknown,
    permissionData: true as unknown,
    permissionError: null as unknown,
    targetClub: CLUB_A,
    targetRole: "pronostiqueur",
    targetStatus: "active",
    adminCount: 2,
    memberCount: 1,
    profileDeleted: false,
  };

  function query() {
    const filters: Record<string, unknown> = {};
    const excluded: Record<string, unknown> = {};
    let deleting = false;
    const result: Record<string, unknown> = {
      select: () => result,
      eq: (key: string, value: unknown) => {
        filters[key] = value;
        return result;
      },
      neq: (key: string, value: unknown) => {
        excluded[key] = value;
        return result;
      },
      single: () => {
        events.push("db.lookupCaller");
        assertEquals(filters.id, ADMIN);
        return Promise.resolve({
          data: state.caller,
          error: state.profileError,
        });
      },
      maybeSingle: () => {
        events.push("db.lookupTarget");
        const matches = filters.id === TARGET &&
          filters.club_id === state.targetClub;
        return Promise.resolve({
          data: state.profileDeleted
            ? null
            : matches
            ? { id: TARGET, role: state.targetRole, status: state.targetStatus }
            : null,
          error: null,
        });
      },
      delete: () => {
        deleting = true;
        return result;
      },
      then: (
        resolve: (value: unknown) => unknown,
        reject: (reason: unknown) => unknown,
      ) => {
        if (deleting) {
          events.push("db.deleteProfile");
          assertEquals(filters.id, ADMIN);
          state.profileDeleted = true;
          return Promise.resolve({ data: null, error: null }).then(
            resolve,
            reject,
          );
        }
        assertEquals(filters.club_id, CLUB_A);
        const count = excluded.id ? state.memberCount : state.adminCount;
        return Promise.resolve({ count, error: null }).then(resolve, reject);
      },
    };
    return result;
  }

  const makeClient = (_url: string, key: string, options: {
    global?: { headers?: Record<string, string> };
  }) => {
    if (key === "anon-test") {
      assertEquals(
        options.global?.headers?.Authorization,
        "Bearer verified-token",
      );
      return {
        auth: {
          getUser: (token: string) => {
            events.push("auth.verify");
            assertEquals(token, "verified-token");
            return Promise.resolve({
              data: { user: state.jwtValid ? { id: ADMIN } : null },
              error: state.jwtValid ? null : new Error("expired"),
            });
          },
        },
        rpc: (name: string) => {
          events.push("permission.check");
          assertEquals(name, "is_admin");
          return Promise.resolve({
            data: state.permissionData,
            error: state.permissionError,
          });
        },
      };
    }
    assertEquals(key, "service-test");
    if (options.global) {
      assertEquals(options.global.headers?.["x-club-id"], CLUB_A);
    }
    return {
      from: (table: string) => {
        assertEquals(table, "profiles");
        return query();
      },
      rpc: (name: string, args: unknown) => {
        events.push("db.prepareDeletion");
        assertEquals(name, "prepare_profile_for_hard_deletion");
        assertEquals(args, { p_profile_id: ADMIN });
        return Promise.resolve({ error: null });
      },
      auth: {
        admin: {
          getUserById: (id: string) => {
            events.push("auth.lookupTarget");
            assertEquals(id, TARGET);
            return Promise.resolve({
              data: { user: { email: "member@example.invalid" } },
              error: null,
            });
          },
          generateLink: () => {
            events.push("auth.generateLink");
            return Promise.resolve({
              data: {
                properties: {
                  action_link:
                    "https://auth.example.invalid/verify?token=one-use-token",
                },
              },
              error: null,
            });
          },
          deleteUser: (id: string) => {
            events.push("auth.deleteUser");
            assertEquals(id, ADMIN);
            return Promise.resolve({ error: null });
          },
        },
      },
    };
  };

  const env: Record<string, string> = {
    SUPABASE_URL: "https://database.example.invalid",
    SUPABASE_ANON_KEY: "anon-test",
    SUPABASE_SERVICE_ROLE_KEY: "service-test",
    PUBLIC_APP_URL: "https://app.example.invalid/",
  };
  const handler = createManageUserHandler({
    createClient:
      makeClient as unknown as ManageUserDependencies["createClient"],
    getEnv: (name) => env[name],
  });
  const request = (body: Record<string, unknown>) =>
    handler(
      new Request(
        "https://edge.example.invalid/manage-user",
        {
          method: "POST",
          headers: {
            Authorization: "Bearer verified-token",
            "Content-Type": "application/json",
          },
          body: JSON.stringify(body),
        },
      ),
    );
  return { events, state, handler, request };
}

function assertNoPrivilegedAction(events: string[]): void {
  assertEquals(
    events.filter((event) =>
      [
        "db.lookupTarget",
        "db.prepareDeletion",
        "db.deleteProfile",
        "auth.lookupTarget",
        "auth.generateLink",
        "auth.deleteUser",
      ].includes(event)
    ),
    [],
  );
}

Deno.test("manage-user : JWT expiré refusé avant toute lecture privilégiée", async () => {
  const f = fixture();
  f.state.jwtValid = false;
  assertEquals(
    (await f.request({ action: "reset-password", userId: TARGET })).status,
    401,
  );
  assertEquals(f.events, ["auth.verify"]);
});

Deno.test("manage-user : joueur refusé malgré un rôle et un club falsifiés dans le corps", async () => {
  const f = fixture();
  f.state.caller.role = "pronostiqueur";
  assertEquals(
    (await f.request({
      action: "reset-password",
      userId: TARGET,
      role: "admin",
      club_id: CLUB_B,
    })).status,
    403,
  );
  assertNoPrivilegedAction(f.events);
  assertEquals(f.events.includes("permission.check"), false);
});

for (const status of ["pending", "archived"]) {
  Deno.test(`manage-user : administrateur ${status} refusé`, async () => {
    const f = fixture();
    f.state.caller.status = status;
    assertEquals(
      (await f.request({ action: "delete", userId: TARGET })).status,
      403,
    );
    assertNoPrivilegedAction(f.events);
  });
}

for (const action of ["reset-password", "delete"]) {
  Deno.test(`manage-user : club suspendu, ${action} refusé sans effet`, async () => {
    const f = fixture();
    f.state.permissionData = false;
    assertEquals((await f.request({ action, userId: TARGET })).status, 403);
    assertEquals(f.events.includes("permission.check"), true);
    assertNoPrivilegedAction(f.events);
  });
}

for (const data of [null, "true", { allowed: true }]) {
  Deno.test(`manage-user : permission inattendue ${JSON.stringify(data)} refusée`, async () => {
    const f = fixture();
    f.state.permissionData = data;
    assertEquals(
      (await f.request({ action: "reset-password", userId: TARGET })).status,
      403,
    );
    assertNoPrivilegedAction(f.events);
  });
}

Deno.test("manage-user : erreur SQL refusée même avec data=true", async () => {
  const f = fixture();
  f.state.permissionError = { code: "permission_lookup_failed" };
  assertEquals(
    (await f.request({ action: "reset-password", userId: TARGET })).status,
    403,
  );
  assertNoPrivilegedAction(f.events);
});

Deno.test("manage-user : admin actif, réinitialisation de son club conservée", async () => {
  const f = fixture();
  const response = await f.request({
    action: "reset-password",
    userId: TARGET,
  });
  assertEquals(response.status, 200);
  assertEquals(await response.json(), {
    reset: true,
    resetLink:
      "https://app.example.invalid/#/auth/new-password?recovery=1&token_hash=one-use-token",
  });
  assertEquals(
    f.events.indexOf("permission.check") <
      f.events.indexOf("auth.generateLink"),
    true,
  );
});

for (const action of ["reset-password", "delete"]) {
  Deno.test(`manage-user : admin A ne peut pas ${action} un compte B`, async () => {
    const f = fixture();
    f.state.targetClub = CLUB_B;
    assertEquals(
      (await f.request({ action, userId: TARGET, club_id: CLUB_B })).status,
      404,
    );
    assertEquals(f.events.includes("auth.generateLink"), false);
    assertEquals(f.events.includes("auth.deleteUser"), false);
    assertEquals(f.events.includes("db.prepareDeletion"), false);
  });
}

Deno.test("manage-user : même JWT, suspension prise en compte à la requête suivante", async () => {
  const f = fixture();
  assertEquals(
    (await f.request({ action: "reset-password", userId: TARGET })).status,
    200,
  );
  f.state.permissionData = false;
  assertEquals(
    (await f.request({ action: "reset-password", userId: TARGET })).status,
    403,
  );
  assertEquals(
    f.events.filter((event) => event === "permission.check").length,
    2,
  );
  assertEquals(
    f.events.filter((event) => event === "auth.generateLink").length,
    1,
  );
});

for (const role of ["admin", "pronostiqueur"]) {
  Deno.test(`manage-user : ${role} d'un club suspendu peut demander son propre effacement`, async () => {
    const f = fixture();
    f.state.caller.role = role;
    f.state.permissionData = false;
    // Même un userId malveillant ne permet pas de désigner une autre personne.
    const response = await f.request({ action: "delete-self", userId: TARGET });
    assertEquals(response.status, 200);
    assertEquals(await response.json(), { deleted: true });
    assertEquals(f.state.profileDeleted, true);
    assertEquals(f.events.includes("permission.check"), false);
    assertEquals(f.events.includes("auth.deleteUser"), true);
  });
}

Deno.test("manage-user : dernier admin protégé aussi dans un club suspendu", async () => {
  const f = fixture();
  f.state.permissionData = false;
  f.state.adminCount = 1;
  assertEquals((await f.request({ action: "delete-self" })).status, 409);
  assertNoPrivilegedAction(f.events);
});

Deno.test("manage-user : profil introuvable ne donne aucun droit admin", async () => {
  const f = fixture();
  f.state.profileError = { code: "profile_not_found" };
  assertEquals(
    (await f.request({ action: "reset-password", userId: TARGET })).status,
    403,
  );
  assertNoPrivilegedAction(f.events);
});
