// Règles pures de la copie AS Grinta, testées sans réseau ni base
// (logic_test.ts). index.ts ne fait que les appliquer.

export type Row = Record<string, unknown>;

// Ordre sans importance (contrôles de clés désactivés pendant la copie).
// Exclus volontairement : abonnements et journaux push, liens d'agenda,
// historique d'envoi des rappels, météo (recalculée), signaux de rafraîchissement.
export const TABLES = [
  "players", "player_aliases", "seasons", "opponents", "profiles",
  "season_players", "season_player_kit_photos", "guest_players", "matches",
  "match_odds", "match_predictions", "match_player_stats", "match_attendance",
  "match_man_of_match", "season_awards", "badges", "profile_badges",
  "badge_inbox_state", "profile_badge_seen", "match_sport_workflows",
  "match_sport_participants", "match_sport_participant_events",
  "sport_waitlist_entries", "match_compositions", "match_composition_entries",
  "match_composition_publications", "match_internal_compositions",
  "match_internal_composition_entries", "match_sport_finalizations",
  "match_sport_finalization_versions", "match_sport_motm_elections",
  "match_sport_motm_votes", "match_sport_motm_results",
  "match_sport_goal_actions", "match_live_sessions", "match_live_events",
  "match_live_notification_subscriptions", "historical_match_scores",
  "historical_match_details", "historical_match_players",
  "historical_player_name_links", "historical_player_statistics",
  "historical_team_statistics", "historical_unscored_match_contributions",
  "club_events", "calendar_match_tombstones", "player_unavailabilities",
  "season_wrapped",
];

// Tables recopiées en « tout effacer puis tout réinsérer » au lieu de mise à
// jour ligne par ligne. sport_waitlist_entries a une contrainte unique
// (saison, position) : quand deux joueurs échangent leur rang (ajout en fin
// de liste, renumérotation au coup d'envoi), la mise à jour ligne par ligne
// heurte la contrainte et toute la copie échouait.
export const REPLACE_TABLES = new Set(["sport_waitlist_entries"]);

export const AS_GRINTA_URL = "https://ovzijmqrnsgcmryinkfa.supabase.co";
export const TARGET_CLUB_ID = "d309a2dd-5060-42e1-9d07-a2153a5f2519";
export const TARGET_USERNAME_DOMAIN = "comptes.club-app.local";

// Clé unique de l'alerte « copie en échec » dans private.payment_alerts : une
// seule alerte ouverte, rouverte et mise à jour à chaque nouvel échec.
export const ALERT_KEY = "sync-as-grinta";
export const ALERT_KIND = "sync_failed";
export const ALERT_CLUB_NAME = "AS Grinta";

export const BADGE_BUCKET = "badge-images";
export const PROFILE_PHOTO_BUCKET = "profile-photos";
// Les images de badge recopiées sont rangées à part pour ne jamais écraser
// une image d'un autre club (mêmes noms « custom/<horodatage> »).
export const BADGE_COPY_PREFIX = "as-grinta/";

const BADGE_MARKER = `/storage/v1/object/public/${BADGE_BUCKET}/`;

/** Chemin de l'objet dans badge-images d'une URL publique AS Grinta, sinon null. */
export function asGrintaBadgePath(imageUrl: unknown): string | null {
  if (typeof imageUrl !== "string") return null;
  let url: URL;
  try {
    url = new URL(imageUrl.trim());
  } catch {
    return null;
  }
  if (url.origin !== AS_GRINTA_URL) return null;
  const index = url.pathname.indexOf(BADGE_MARKER);
  if (index < 0) return null;
  const path = decodeURIComponent(url.pathname.slice(index + BADGE_MARKER.length));
  if (!path || path.split("/").some((part) => part === "" || part === "." || part === "..")) {
    return null;
  }
  return path;
}

/** Chemin de la copie dans le bucket de Petit Filet. */
export function copiedBadgePath(sourcePath: string): string {
  return `${BADGE_COPY_PREFIX}${sourcePath}`;
}

/** URL publique encodée d'un objet de badge-images d'un projet. */
export function publicBadgeUrl(projectUrl: string, path: string): string {
  const encoded = path.split("/").map(encodeURIComponent).join("/");
  return `${projectUrl.replace(/\/$/, "")}${BADGE_MARKER}${encoded}`;
}

/**
 * Réécrit image_url vers Petit Filet quand la copie de l'image existe.
 * Sinon l'URL d'origine est gardée (rien n'empire, et la prochaine copie
 * réessaiera de recopier le fichier).
 */
export function rewriteBadgeRow(row: Row, projectUrl: string, copied: Set<string>): Row {
  const source = asGrintaBadgePath(row.image_url);
  if (!source) return row;
  const target = copiedBadgePath(source);
  if (!copied.has(target)) return row;
  return { ...row, image_url: publicBadgeUrl(projectUrl, target) };
}

/**
 * Photo de profil à garder pour un profil recopié.
 *
 * AS Grinta enregistre « <dossier>/avatar_<n>.png », mais ces fichiers
 * n'existent pas dans Petit Filet : seuls des « avatar_player_<m>.png »
 * (autre numéro) y sont. Règle : le chemin source s'il existe dans Petit
 * Filet ; sinon la photo la plus récente du même dossier ; sinon aucune
 * photo (initiales), pour ne plus demander un fichier introuvable.
 *
 * `folders` : pour chaque dossier, ses objets du plus récent au plus ancien.
 */
export function resolveProfilePhoto(
  photoUrl: unknown,
  existing: Set<string>,
  folders: Map<string, string[]>,
): string | null {
  if (typeof photoUrl !== "string" || photoUrl.trim() === "") return null;
  const path = photoUrl.trim().replace(/^\/+/, "");
  if (existing.has(path)) return path;
  const slash = path.lastIndexOf("/");
  if (slash <= 0) return null;
  const candidates = (folders.get(path.slice(0, slash)) ?? [])
    .filter((name) => /\/avatar_[^/]+\.(png|jpe?g|webp)$/i.test(name));
  return candidates[0] ?? null;
}

/** Dossier (premier segment) d'un chemin photo, ou null. */
export function photoFolder(photoUrl: unknown): string | null {
  if (typeof photoUrl !== "string") return null;
  const path = photoUrl.trim().replace(/^\/+/, "");
  const slash = path.lastIndexOf("/");
  return slash > 0 ? path.slice(0, slash) : null;
}

/** Message d'alerte lisible par l'éditeur, borné à 500 caractères (contrainte SQL). */
export function failureMessage(error: unknown): string {
  const detail = error instanceof Error ? error.message : String(error);
  return `La copie automatique AS Grinta a échoué : ${detail}`.slice(0, 500);
}
