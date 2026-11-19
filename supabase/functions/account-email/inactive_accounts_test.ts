import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "jsr:@std/assert@1";
import {
  type InactiveAccount,
  type InactiveAccountsDeps,
  inactiveAccountWarningMail,
  parseInactiveAccount,
  runInactiveAccounts,
} from "./inactive_accounts.ts";

function account(overrides: Partial<InactiveAccount> = {}): InactiveAccount {
  return {
    profileId: "11111111-1111-1111-1111-111111111111",
    clubId: "22222222-2222-2222-2222-222222222222",
    action: "notify",
    email: "joueur@club.fr",
    firstName: "Léa",
    lastActivityAt: "2023-12-01T10:00:00Z",
    deletionOn: "2026-12-19",
    ...overrides,
  };
}

function fakeDeps(options: {
  failSend?: boolean;
  deleteOutcome?: "deleted" | "skipped" | "throw";
} = {}) {
  const calls: string[] = [];
  const deps: InactiveAccountsDeps = {
    sendWarning: async (a, email) => {
      calls.push(`send:${a.profileId}:${email}`);
      if (options.failSend) throw new Error("Brevo indisponible");
    },
    recordNotice: async (a, emailed) => {
      calls.push(`record:${a.profileId}:${emailed}`);
    },
    deleteAccount: async (a) => {
      calls.push(`delete:${a.profileId}`);
      if (options.deleteOutcome === "throw") throw new Error("échec");
      return options.deleteOutcome ?? "deleted";
    },
    log: () => {},
  };
  return { deps, calls };
}

Deno.test("prévient par e-mail puis note l'avertissement", async () => {
  const { deps, calls } = fakeDeps();
  const report = await runInactiveAccounts([account()], deps);
  assertEquals(calls, [
    "send:11111111-1111-1111-1111-111111111111:joueur@club.fr",
    "record:11111111-1111-1111-1111-111111111111:true",
  ]);
  assertEquals(report.notified, 1);
});

Deno.test("un e-mail qui échoue n'est pas noté : nouvel essai la nuit suivante", async () => {
  const { deps, calls } = fakeDeps({ failSend: true });
  const report = await runInactiveAccounts([account()], deps);
  assertEquals(calls.filter((c) => c.startsWith("record")), []);
  assertEquals(report.warningFailures, 1);
  assertEquals(report.notified, 0);
});

Deno.test("sans adresse, l'avertissement est noté sans envoi", async () => {
  const { deps, calls } = fakeDeps();
  const report = await runInactiveAccounts([account({ email: null })], deps);
  assertEquals(calls, ["record:11111111-1111-1111-1111-111111111111:false"]);
  assertEquals(report.notifiedWithoutEmail, 1);
});

Deno.test("supprime les comptes arrivés au bout du délai, sans e-mail", async () => {
  const { deps, calls } = fakeDeps();
  const report = await runInactiveAccounts([account({ action: "delete" })], deps);
  assertEquals(calls, ["delete:11111111-1111-1111-1111-111111111111"]);
  assertEquals(report.deleted, 1);
});

Deno.test("une suppression refusée ou en échec n'arrête pas les autres", async () => {
  const skipped = fakeDeps({ deleteOutcome: "skipped" });
  const skippedReport = await runInactiveAccounts(
    [account({ action: "delete" })],
    skipped.deps,
  );
  assertEquals(skippedReport.skipped, 1);

  const failing = fakeDeps({ deleteOutcome: "throw" });
  const report = await runInactiveAccounts(
    [
      account({ action: "delete" }),
      account({ profileId: "33333333-3333-3333-3333-333333333333" }),
    ],
    failing.deps,
  );
  assertEquals(report.deleteFailures, 1);
  assertEquals(report.notified, 1);
});

Deno.test("lit une ligne de la base et rejette une ligne invalide", () => {
  const parsed = parseInactiveAccount({
    profile_id: "11111111-1111-1111-1111-111111111111",
    club_id: null,
    action: "notify",
    email: " Joueur@Club.FR ",
    first_name: "Léa",
    last_activity_at: "2023-12-01T10:00:00+00:00",
    deletion_on: "2026-12-19",
  });
  assert(parsed);
  assertEquals(parsed.email, "joueur@club.fr");
  assertEquals(parsed.clubId, null);

  assertEquals(
    parseInactiveAccount({ ...parsed, profile_id: "x", action: "notify" }),
    null,
  );
  assertEquals(
    parseInactiveAccount({
      profile_id: "11111111-1111-1111-1111-111111111111",
      action: "wipe",
      last_activity_at: "2023-12-01",
      deletion_on: "2026-12-19",
    }),
    null,
  );
  const noEmail = parseInactiveAccount({
    profile_id: "11111111-1111-1111-1111-111111111111",
    action: "delete",
    email: "pas-une-adresse",
    last_activity_at: "2023-12-01",
    deletion_on: "2026-12-19",
  });
  assertEquals(noEmail?.email, null);
});

Deno.test("l'e-mail donne la date de suppression et le moyen de garder le compte", () => {
  const mail = inactiveAccountWarningMail(
    account(),
    "https://app.example/",
    "contact@example.fr",
  );
  assertStringIncludes(mail.text, "Bonjour Léa,");
  assertStringIncludes(mail.text, "19/12/2026");
  assertStringIncludes(mail.text, "te connecter avant cette date");
  assertStringIncludes(mail.text, "https://app.example/");
  assertStringIncludes(mail.text, "contact@example.fr");
});
