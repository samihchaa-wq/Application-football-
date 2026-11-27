// Essai de bout en bout de la copie sur une base Postgres jetable, sans
// réseau : AS Grinta et le stockage sont simulés. Ne tourne que si
// SYNC_TEST_DB_URL est fourni (base locale vide, superutilisateur), par
// exemple :
//   docker run -d --name sync-pg -e POSTGRES_PASSWORD=pg -p 55432:5432 postgres:17
//   SYNC_TEST_DB_URL=postgres://postgres:pg@127.0.0.1:55432/postgres \
//     deno test -A supabase/functions/sync-as-grinta/handler_db_test.ts
import { assert, assertEquals } from "jsr:@std/assert@1";
import postgres from "npm:postgres@3.4.4";
import { handleSync, type SyncDeps } from "./handler.ts";
import { AS_GRINTA_URL, TABLES, TARGET_CLUB_ID } from "./logic.ts";

const DB_URL = Deno.env.get("SYNC_TEST_DB_URL");
const CLUB = TARGET_CLUB_ID;
const OTHER_CLUB = "00000000-0000-0000-0000-0000000000aa";
const SEASON = "00000000-0000-0000-0000-000000000001";
const [A, B, C] = ["a", "b", "c"].map((x) => `00000000-0000-0000-0000-00000000000${x}`);
const P1 = "00000000-0000-0000-0000-0000000000f1";
const P2 = "00000000-0000-0000-0000-0000000000f2";
const PROJECT = "https://petitfilet.test";
const TOKEN = "jeton-de-test";

async function sha256(text: string) {
  const bytes = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return [...new Uint8Array(bytes)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

const SPECIAL: Record<string, string> = {
  sport_waitlist_entries: `season_player_id uuid primary key, club_id uuid not null,
    season_id uuid not null, position integer not null check (position >= 1),
    unique (season_id, position)`,
  match_sport_participant_events: `id bigserial primary key, club_id uuid not null, note text`,
  player_aliases: `id serial primary key, club_id uuid not null, alias text`,
  badges: `id uuid primary key, club_id uuid not null, image_url text`,
  profiles: `id uuid primary key, club_id uuid not null, username text, email text, photo_url text`,
};

async function resetSchema(sql: postgres.Sql) {
  await sql.unsafe(`
    drop schema if exists public cascade; create schema public;
    drop schema if exists private cascade; create schema private;
    drop schema if exists storage cascade; create schema storage;
    create table storage.objects (bucket_id text, name text, created_at timestamptz default now(),
      primary key (bucket_id, name));
    create table private.payment_alerts (
      id uuid primary key default gen_random_uuid(),
      kind text not null constraint payment_alerts_kind_check
        check (kind in ('dispute', 'refund_unmatched', 'payment_failed', 'other')),
      stripe_object_id text unique, club_name text, amount_cents integer,
      message text not null check (char_length(message) <= 500),
      created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
      resolved_at timestamptz, resolved_by uuid);
    create table public.club_settings (club_id uuid primary key, home_address text);
    create table public.shared_data_change_signals (club_id uuid primary key,
      revision int default 0, profile_revision int default 0, sports_revision int default 0,
      updated_at timestamptz);
    insert into public.club_settings values ('${CLUB}', null);
    insert into public.shared_data_change_signals (club_id) values ('${CLUB}');
  `);
  for (const table of TABLES) {
    await sql.unsafe(`create table public."${table}" (${
      SPECIAL[table] ?? "id uuid primary key, club_id uuid not null"
    })`);
  }
}

// Applique la vraie migration du dépôt (compteurs + type d'alerte).
async function applyMigration(sql: postgres.Sql) {
  const path = new URL(
    "../../migrations/20261210050000_copie_as_grinta_compteurs_et_alerte.sql",
    import.meta.url,
  );
  await sql.unsafe(await Deno.readTextFile(path));
}

const OLD_BADGE = `${AS_GRINTA_URL}/storage/v1/object/public/badge-images/custom/1786.jpg`;

function makeDeps(sql: postgres.Sql, source: Record<string, unknown[]>, failTable?: string): SyncDeps {
  return {
    tokenSha256: undefined,
    env: (name) =>
      ({
        AS_GRINTA_SERVICE_KEY: "cle-source",
        SUPABASE_DB_URL: DB_URL,
        SUPABASE_URL: PROJECT,
        SUPABASE_SERVICE_ROLE_KEY: "cle-service",
      })[name],
    fetch: async (input, init) => {
      const url = new URL(String(input));
      if (url.origin === AS_GRINTA_URL && url.pathname.startsWith("/rest/v1/")) {
        const table = url.pathname.slice("/rest/v1/".length);
        if (table === failTable) return new Response("boom", { status: 500 });
        const offset = Number(url.searchParams.get("offset") ?? 0);
        return Response.json(offset === 0 ? source[table] ?? [] : []);
      }
      if (url.origin === AS_GRINTA_URL && url.pathname.includes("/badge-images/")) {
        return new Response(new Uint8Array([1, 2, 3]), { headers: { "content-type": "image/jpeg" } });
      }
      if (url.origin === PROJECT && init?.method === "POST") {
        const name = decodeURIComponent(url.pathname.split("/storage/v1/object/badge-images/")[1]);
        await sql`insert into storage.objects (bucket_id, name) values ('badge-images', ${name})`;
        return new Response("{}", { status: 200 });
      }
      return new Response("inattendu", { status: 404 });
    },
  };
}

async function run(deps: SyncDeps) {
  deps.tokenSha256 = await sha256(TOKEN);
  const response = await handleSync(
    new Request("http://local/sync", { method: "POST", headers: { "x-sync-token": TOKEN } }),
    deps,
  );
  return { status: response.status, body: await response.json() };
}

function baseSource() {
  return {
    // Rangs échangés par rapport à la cible + un nouveau joueur en fin de liste.
    sport_waitlist_entries: [
      { season_player_id: A, season_id: SEASON, position: 2 },
      { season_player_id: B, season_id: SEASON, position: 1 },
      { season_player_id: C, season_id: SEASON, position: 3 },
    ],
    match_sport_participant_events: [{ id: 1759, note: "source" }],
    player_aliases: [{ id: 622, alias: "Roman" }],
    badges: [{ id: A, image_url: OLD_BADGE }],
    profiles: [
      { id: P1, username: "Romany", photo_url: `${P1}/avatar_1793.png` },
      { id: P2, username: "Sans", photo_url: `${P2}/avatar_1.png` },
    ],
  };
}

Deno.test({
  name: "copie complète sur base locale",
  ignore: !DB_URL,
  sanitizeResources: false,
  sanitizeOps: false,
  async fn() {
    const sql = postgres(DB_URL!, { max: 2, onnotice: () => {} });
    try {
      await resetSchema(sql);
      await applyMigration(sql);
      // État cible avant copie : liste d'attente dans l'ancien ordre, compteur
      // en retard, une ligne d'un autre club, une photo « avatar_player ».
      await sql.unsafe(`
        insert into public.sport_waitlist_entries values
          ('${A}', '${CLUB}', '${SEASON}', 1), ('${B}', '${CLUB}', '${SEASON}', 2);
        insert into public.match_sport_participant_events (club_id, note) values ('${OTHER_CLUB}', 'autre club');
        insert into storage.objects (bucket_id, name, created_at) values
          ('profile-photos', '${P1}/avatar_player_1700.png', now() - interval '2 days'),
          ('profile-photos', '${P1}/avatar_player_1794.png', now());
      `);

      const first = await run(makeDeps(sql, baseSource()));
      assertEquals(first.status, 200, JSON.stringify(first.body));
      assertEquals(first.body.result, "ok");

      // 1. Liste d'attente renumérotée : la copie passe et suit la source.
      const waitlist = await sql`select season_player_id, position from public.sport_waitlist_entries
                                  order by position`;
      assertEquals(waitlist.map((r) => r.season_player_id), [B, A, C]);

      // 2. Chaque compteur copié repart au-delà du plus grand id.
      const [{ next_event }] = await sql`select nextval('public.match_sport_participant_events_id_seq') as next_event`;
      assert(Number(next_event) > 1759);
      const [{ next_alias }] = await sql`select nextval('public.player_aliases_id_seq') as next_alias`;
      assert(Number(next_alias) > 622);
      // La ligne de l'autre club n'a pas bougé.
      const [{ others }] = await sql`select count(*)::int as others from public.match_sport_participant_events
                                      where club_id = ${OTHER_CLUB}`;
      assertEquals(others, 1);

      // 3. Badge : image recopiée et URL réécrite vers Petit Filet.
      const [badge] = await sql`select image_url from public.badges`;
      assertEquals(badge.image_url, `${PROJECT}/storage/v1/object/public/badge-images/as-grinta/custom/1786.jpg`);

      // 4. Photos : fichier du dossier si présent, sinon aucune photo.
      const photos = await sql`select id, photo_url from public.profiles order by id`;
      assertEquals(photos.map((r) => r.photo_url), [`${P1}/avatar_player_1794.png`, null]);

      // Une deuxième copie identique ne change rien (pas de rafraîchissement inutile).
      const second = await run(makeDeps(sql, baseSource()));
      assertEquals(second.status, 200);
      assertEquals(second.body.changes, 0, JSON.stringify(second.body.tables));

      // 5. Échec : réponse 500 et une seule alerte ouverte, mise à jour.
      const failed = await run(makeDeps(sql, baseSource(), "matches"));
      assertEquals(failed.status, 500);
      await run(makeDeps(sql, baseSource(), "matches"));
      const alerts = await sql`select kind, club_name, message, resolved_at from private.payment_alerts`;
      assertEquals(alerts.length, 1);
      assertEquals(alerts[0].kind, "sync_failed");
      assertEquals(alerts[0].club_name, "AS Grinta");
      assert(String(alerts[0].message).includes("Lecture de matches impossible (500)"));
      assertEquals(alerts[0].resolved_at, null);
      // L'échec n'a rien laissé à moitié écrit.
      const after = await sql`select count(*)::int as n from public.sport_waitlist_entries`;
      assertEquals(after[0].n, 3);
    } finally {
      await sql.end();
    }
  },
});
