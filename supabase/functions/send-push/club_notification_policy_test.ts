import {
  disabledNotificationKinds,
  isNotificationKindDisabled,
} from "./club_notification_policy.ts";

function assertEquals<T>(actual: T, expected: T): void {
  if (!Object.is(actual, expected)) {
    throw new Error(`attendu ${String(expected)}, obtenu ${String(actual)}`);
  }
}

Deno.test("sans réglage du club, aucun type n'est coupé", () => {
  const disabled = disabledNotificationKinds({ token: "x" });
  assertEquals(disabled.size, 0);
  assertEquals(isNotificationKindDisabled(disabled, "live_goal_us"), false);
});

Deno.test("un type coupé par le club n'est plus envoyé", () => {
  const disabled = disabledNotificationKinds({
    disabled_kinds: ["live_goal_us", "live_goal_them", 3, "", null],
  });
  assertEquals(disabled.size, 2);
  assertEquals(isNotificationKindDisabled(disabled, "live_goal_us"), true);
  assertEquals(isNotificationKindDisabled(disabled, "live_kickoff"), false);
  assertEquals(isNotificationKindDisabled(disabled, undefined), false);
});

Deno.test("le test d'envoi et les messages libres ne sont jamais coupés", () => {
  const disabled = disabledNotificationKinds({
    disabled_kinds: ["test", "custom"],
  });
  assertEquals(isNotificationKindDisabled(disabled, "test"), false);
  assertEquals(isNotificationKindDisabled(disabled, "custom"), false);
});

Deno.test("une configuration illisible ne coupe rien", () => {
  assertEquals(disabledNotificationKinds(null).size, 0);
  assertEquals(disabledNotificationKinds({ disabled_kinds: "live" }).size, 0);
});
