// Miroir à sens unique : AS Grinta (application d'origine) -> club AS Grinta de
// Petit Filet. Temporaire, jusqu'à la bascule des joueurs.
//
// - Lit AS Grinta en lecture seule (API REST, clé de service) : rien n'est
//   jamais écrit dans AS Grinta.
// - N'écrit que les lignes du club cible (colonne club_id) : les autres clubs
//   ne sont jamais touchés.
// - Une seule transaction : tout passe ou rien ne change.
//
// Secret attendu : AS_GRINTA_SERVICE_KEY. SUPABASE_DB_URL est fourni par
// Supabase. Le reste est fixé ci-dessous.
import "jsr:@supabase/functions-js@2.95.0/edge-runtime.d.ts";
import postgres from "npm:postgres@3.4.4";

// Ordre sans importance (contrôles de clés désactivés pendant la copie).
// Exclus volontairement : abonnements et journaux push, liens d'agenda,
// historique d'envoi des rappels, météo (recalculée), signaux de rafraîchissement.
const TABLES = [
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

const AS_GRINTA_URL = "https://ovzijmqrnsgcmryinkfa.supabase.co";
const TARGET_CLUB_ID = "d309a2dd-5060-42e1-9d07-a2153a5f2519";
const TARGET_USERNAME_DOMAIN = "comptes.club-app.local";
// Empreinte du jeton que seule la planification interne connaît.
const TOKEN_SHA256 = "3c635888965336c32f13d08390e8875fe1fc7a4a967da386e6e5e5985a7247ba";

async function sha256(text: string) {
  const bytes = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return [...new Uint8Array(bytes)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

const q = (identifier: string) => `"${identifier.replaceAll('"', '""')}"`;

type Row = Record<string, unknown>;

async function readSource(table: string, order: string[]): Promise<Row[]> {
  const base = AS_GRINTA_URL.replace(/\/$/, "");
  const key = Deno.env.get("AS_GRINTA_SERVICE_KEY")!;
  const rows: Row[] = [];
  const page = 1000;
  for (let offset = 0;; offset += page) {
    const orderParam = order.length ? `&order=${order.join(",")}` : "";
    const response = await fetch(
      `${base}/rest/v1/${table}?select=*${orderParam}&limit=${page}&offset=${offset}`,
      { headers: { apikey: key, Authorization: `Bearer ${key}` } },
    );
    if (!response.ok) {
      throw new Error(`Lecture de ${table} impossible (${response.status}).`);
    }
    const chunk = (await response.json()) as Row[];
    rows.push(...chunk);
    if (chunk.length < page) break;
  }
  return rows;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  if ((await sha256(req.headers.get("x-sync-token") ?? "")) !== TOKEN_SHA256) {
    return json({ error: "Forbidden" }, 403);
  }
  const clubId = TARGET_CLUB_ID;
  const domain = TARGET_USERNAME_DOMAIN;
  if (!Deno.env.get("AS_GRINTA_SERVICE_KEY")) {
    return json({ error: "Configuration incomplète." }, 500);
  }

  const started = Date.now();
  const sql = postgres(Deno.env.get("SUPABASE_DB_URL")!, { max: 1, prepare: false });
  const report: Record<string, string> = {};
  let changes = 0;
  try {
    const result = await sql.begin(async (tx) => {
      const [{ locked }] = await tx`select pg_try_advisory_xact_lock(724561001) as locked`;
      if (!locked) return "déjà en cours";
      // Copie fidèle : pas de notifications, de recalculs ni de contrôles de
      // clés pendant l'écriture. Les données source sont déjà cohérentes.
      await tx.unsafe("set local session_replication_role = replica");

      for (const table of TABLES) {
        const columns = await tx.unsafe(
          `select column_name, is_identity, identity_generation, is_generated
             from information_schema.columns
            where table_schema = 'public' and table_name = $1`,
          [table],
        ) as unknown as Row[];
        const targetColumns = new Set(
          columns
            .filter((c) => c.is_generated !== "ALWAYS" && c.identity_generation !== "ALWAYS")
            .map((c) => c.column_name as string),
        );
        const pk = (await tx.unsafe(
          `select a.attname from pg_index i
             join pg_attribute a on a.attrelid = i.indrelid and a.attnum = any(i.indkey)
            where i.indrelid = ('public.' || $1)::regclass and i.indisprimary`,
          [table],
        ) as unknown as Row[]).map((r) => r.attname as string);

        const rows = await readSource(table, pk.filter((c) => c !== "club_id"));
        for (const row of rows) {
          row.club_id = clubId;
          if (table === "profiles" && typeof row.username === "string") {
            row.email = `${row.username.toLowerCase()}@${domain}`;
          }
        }

        const cols = rows.length
          ? Object.keys(rows[0]).filter((c) => targetColumns.has(c))
          : [];
        let changed = 0;

        if (pk.length === 0) {
          // Sans clé : remplacement complet du club (non compté).
          await tx.unsafe(`delete from public.${q(table)} where club_id = $1`, [clubId]);
          for (let i = 0; i < rows.length; i += 500) {
            const list = cols.map(q).join(",");
            await tx.unsafe(
              `insert into public.${q(table)} (${list})
               select ${list} from jsonb_populate_recordset(null::public.${q(table)}, $1::text::jsonb)`,
              [JSON.stringify(rows.slice(i, i + 500))],
            );
          }
        } else {
          const pkList = pk.map(q).join(",");
          const dataCols = cols.filter((c) => !pk.includes(c));
          for (let i = 0; i < rows.length; i += 500) {
            const list = cols.map(q).join(",");
            const conflict = dataCols.length
              ? `do update set ${dataCols.map((c) => `${q(c)} = excluded.${q(c)}`).join(",")}
                 where (${dataCols.map((c) => `tgt.${q(c)}::text`).join(",")})
                       is distinct from
                       (${dataCols.map((c) => `excluded.${q(c)}::text`).join(",")})`
              : "do nothing";
            const done = await tx.unsafe(
              `insert into public.${q(table)} as tgt (${list})
               select ${list} from jsonb_populate_recordset(null::public.${q(table)}, $1::text::jsonb)
               on conflict (${pkList}) ${conflict} returning 1`,
              [JSON.stringify(rows.slice(i, i + 500))],
            );
            changed += done.length;
          }
          // Lignes disparues de la source : supprimées côté club cible.
          const keep = pk.map((c) => `r.${q(c)}`).join(",");
          const gone = await tx.unsafe(
            `delete from public.${q(table)} t
              where t.club_id = $1
                and (${pk.map((c) => `t.${q(c)}`).join(",")}) not in (
                  select ${keep}
                    from jsonb_populate_recordset(null::public.${q(table)}, $2::text::jsonb) r)
              returning 1`,
            [clubId, JSON.stringify(rows)],
          );
          changed += gone.length;
        }
        changes += changed;
        report[table] = `${rows.length} lignes, ${changed} modifiées`;
      }

      // Adresse du stade : seule donnée de réglage reprise.
      const settings = await readSource("club_settings", []);
      if (settings[0]) {
        await tx`update public.club_settings
                    set home_address = ${(settings[0].home_address as string | null) ?? null}
                  where club_id = ${clubId}
                    and home_address is distinct from ${(settings[0].home_address as string | null) ?? null}`;
      }

      // Prévient les écrans ouverts qu'il y a du nouveau (les déclencheurs
      // habituels sont coupés pendant la copie).
      if (changes > 0) {
        await tx`update public.shared_data_change_signals
                    set revision = revision + 1,
                        profile_revision = profile_revision + 1,
                        sports_revision = sports_revision + 1,
                        updated_at = now()
                  where club_id = ${clubId}`;
      }
      return "ok";
    });
    return json({ result, changes, seconds: (Date.now() - started) / 1000, tables: report });
  } catch (error) {
    return json({ error: error instanceof Error ? error.message : String(error), report }, 500);
  } finally {
    await sql.end({ timeout: 5 });
  }
});
