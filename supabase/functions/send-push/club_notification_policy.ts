/// Types de notification que le club a coupés dans ses réglages.
///
/// La base donne la liste dans `internal_push_config().disabled_kinds`
/// (voir private.club_disabled_notification_kinds). Un type coupé ne part pas
/// et n'est pas rangé dans la cloche. Le test d'envoi et les messages écrits à
/// la main par un administrateur ne sont jamais coupés : ils n'ont pas de type
/// propre (« test », ou « custom » sans log_kind).
const NEVER_DISABLED = new Set(["test", "custom"]);

export function disabledNotificationKinds(config: unknown): Set<string> {
  if (typeof config !== "object" || config === null) return new Set();
  const kinds = (config as { disabled_kinds?: unknown }).disabled_kinds;
  if (!Array.isArray(kinds)) return new Set();
  return new Set(
    kinds.filter((kind): kind is string =>
      typeof kind === "string" && kind.trim() !== ""
    ).map((kind) => kind.trim()),
  );
}

export function isNotificationKindDisabled(
  disabled: Set<string>,
  kind: unknown,
): boolean {
  if (typeof kind !== "string") return false;
  const normalized = kind.trim();
  if (!normalized || NEVER_DISABLED.has(normalized)) return false;
  return disabled.has(normalized);
}
