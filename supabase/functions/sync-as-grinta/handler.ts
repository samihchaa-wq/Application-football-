// Miroir à sens unique : AS Grinta (application d'origine) -> club AS Grinta de
// Petit Filet. Temporaire, jusqu'à la bascule des joueurs : voir
// docs/COPIE_AS_GRINTA.md pour l'arrêter.
//
// - Lit AS Grinta en lecture seule (API REST, clé de service) : rien n'est
//   jamais écrit dans AS Grinta.
// - N'écrit que les lignes du club cible (colonne club_id) : les autres clubs
//   ne sont jamais touchés.
// - Une seule transaction : tout passe ou rien ne change.
// - Un échec ouvre une alerte dans « À faire » du Poste de contrôle
//   (private.payment_alerts, type sync_failed) : la tâche planifiée, elle,
//   affiche « succeeded » même quand la fonction répond 500.
//
// Secret attendu : AS_GRINTA_SERVICE_KEY. SUPABASE_DB_URL, SUPABASE_URL et
// SUPABASE_SERVICE_ROLE_KEY sont fournis par Supabase. Le reste est fixé dans
// logic.ts.
import postgres from "npm:postgres@3.4.4";
import {
  ALERT_CLUB_NAME,
  ALERT_KEY,
  ALERT_KIND,
  AS_GRINTA_URL,
  asGrintaBadgePath,
  BADGE_BUCKET,
  copiedBadgePath,
  failureMessage,
  photoFolder,
  PROFILE_PHOTO_BUCKET,
  REPLACE_TABLES,
  resolveProfilePhoto,
  rewriteBadgeRow,
  type Row,
  TABLES,
  TARGET_CLUB_ID,
  TARGET_USERNAME_DOMAIN,
} from "./logic.ts";


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

type Sql = postgres.Sql;
type Tx = postgres.TransactionSql;

/** Dépendances extérieures, remplaçables dans les tests. */
export type SyncDeps = {
  env: (name: string) => string | undefined;
  fetch: typeof fetch;
  /** Empreinte SHA-256 du jeton attendu (fixée dans index.ts). Absente : tout est refusé. */
  tokenSha256?: string;
};

const defaultDeps: SyncDeps = {
  env: (name) => Deno.env.get(name),
  fetch: (...args) => fetch(...args),
};
// Une seule copie à la fois (verrou SQL) : une variable de module suffit.
let deps = defaultDeps;

async function readSource(table: string, order: string[]): Promise<Row[]> {
  const base = AS_GRINTA_URL.replace(/\/$/, "");
  const key = deps.env("AS_GRINTA_SERVICE_KEY")!;
  const rows: Row[] = [];
  const page = 1000;
  for (let offset = 0;; offset += page) {
    const orderParam = order.length ? `&order=${order.join(",")}` : "";
    const response = await deps.fetch(
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

// Recopie dans badge-images de Petit Filet les images de badge encore
// hébergées par AS Grinta (bloquées par la CSP de l'appli). Une image déjà
// recopiée n'est jamais retéléchargée. Un échec n'arrête pas la copie : le
// badge garde son ancienne URL et la copie suivante réessaie.
async function mirrorBadgeImages(tx: Tx, rows: Row[], notes: string[]): Promise<Set<string>> {
  const targets = new Map<string, string>();
  for (const row of rows) {
    const source = asGrintaBadgePath(row.image_url);
    if (source) targets.set(copiedBadgePath(source), source);
  }
  if (targets.size === 0) return new Set();
  const present = (await tx.unsafe(
    `select name from storage.objects where bucket_id = $1 and name = any($2::text[])`,
    [BADGE_BUCKET, [...targets.keys()]],
  ) as unknown as Row[]).map((r) => r.name as string);
  const copied = new Set(present);
  const projectUrl = deps.env("SUPABASE_URL")!.replace(/\/$/, "");
  const serviceKey = deps.env("SUPABASE_SERVICE_ROLE_KEY")!;
  const encode = (path: string) => path.split("/").map(encodeURIComponent).join("/");
  let uploaded = 0;
  for (const [target, source] of targets) {
    if (copied.has(target)) continue;
    try {
      const download = await deps.fetch(
        `${AS_GRINTA_URL}/storage/v1/object/public/${BADGE_BUCKET}/${encode(source)}`,
      );
      if (!download.ok) throw new Error(`téléchargement ${download.status}`);
      const upload = await deps.fetch(
        `${projectUrl}/storage/v1/object/${BADGE_BUCKET}/${encode(target)}`,
        {
          method: "POST",
          headers: {
            apikey: serviceKey,
            Authorization: `Bearer ${serviceKey}`,
            "Content-Type": download.headers.get("content-type") ?? "image/jpeg",
            "Cache-Control": "max-age=31536000",
            "x-upsert": "false",
          },
          body: await download.arrayBuffer(),
        },
      );
      // 409 : déjà présent (copie concurrente), c'est bon aussi.
      if (!upload.ok && upload.status !== 409) throw new Error(`envoi ${upload.status}`);
      await upload.body?.cancel();
      copied.add(target);
      uploaded++;
    } catch (error) {
      notes.push(`image ${source} non recopiée (${error instanceof Error ? error.message : error})`);
    }
  }
  if (uploaded) notes.push(`${uploaded} image(s) de badge recopiée(s)`);
  return copied;
}

// Remplace les chemins photo introuvables dans Petit Filet (voir
// resolveProfilePhoto).
async function fixProfilePhotos(tx: Tx, rows: Row[]) {
  const folders = [...new Set(rows.map((r) => photoFolder(r.photo_url)).filter(Boolean))] as string[];
  const objects = folders.length
    ? (await tx.unsafe(
      `select name from storage.objects
        where bucket_id = $1 and split_part(name, '/', 1) = any($2::text[])
        order by created_at desc, name desc`,
      [PROFILE_PHOTO_BUCKET, folders],
    ) as unknown as Row[]).map((r) => r.name as string)
    : [];
  const existing = new Set(objects);
  const byFolder = new Map<string, string[]>();
  for (const name of objects) {
    const folder = photoFolder(name)!;
    byFolder.set(folder, [...(byFolder.get(folder) ?? []), name]);
  }
  for (const row of rows) {
    if ("photo_url" in row) row.photo_url = resolveProfilePhoto(row.photo_url, existing, byFolder);
  }
}

// Empreinte des lignes du club, pour savoir si un remplacement complet a
// réellement changé quelque chose.
async function clubFingerprint(tx: Tx, table: string, pk: string[], clubId: string) {
  const order = (pk.length ? pk : ["club_id"]).map((c) => `t.${q(c)}`).join(",");
  const [{ fingerprint }] = await tx.unsafe(
    `select coalesce(md5(string_agg(to_jsonb(t)::text, ',' order by ${order})), '') as fingerprint
       from public.${q(table)} t where t.club_id = $1`,
    [clubId],
  ) as unknown as Row[];
  return fingerprint as string;
}

// Les lignes sont insérées avec leurs id d'origine : le compteur de la table
// ne bouge pas, et le prochain ajout fait par l'appli reprenait un id déjà
// pris (« duplicate key ... _pkey »). On recale chaque compteur au-delà du
// plus grand id présent, sans jamais le faire reculer.
async function resetSequences(tx: Tx, table: string) {
  const sequences = await tx.unsafe(
    `select a.attname as col, pg_get_serial_sequence(format('public.%I', $1::text), a.attname) as seq
       from pg_attribute a
      where a.attrelid = format('public.%I', $1::text)::regclass
        and a.attnum > 0 and not a.attisdropped
        and pg_get_serial_sequence(format('public.%I', $1::text), a.attname) is not null`,
    [table],
  ) as unknown as Row[];
  for (const { col, seq } of sequences) {
    await tx.unsafe(
      `select setval($1::regclass,
                     greatest(coalesce(max(t.${q(col as string)}), 0),
                              coalesce(pg_sequence_last_value($1::regclass), 0),
                              1))
         from public.${q(table)} t`,
      [seq as string],
    );
  }
}

async function recordFailure(sql: Sql, error: unknown) {
  const message = failureMessage(error);
  const insert = (kind: string) =>
    sql`insert into private.payment_alerts (kind, stripe_object_id, club_name, message)
        values (${kind}, ${ALERT_KEY}, ${ALERT_CLUB_NAME}, ${message})
        on conflict (stripe_object_id) do update
          set kind = excluded.kind, message = excluded.message, club_name = excluded.club_name,
              updated_at = now(), resolved_at = null, resolved_by = null`;
  try {
    await insert(ALERT_KIND);
  } catch {
    // Migration de l'alerte pas encore appliquée : type générique.
    try {
      await insert("other");
    } catch (inner) {
      console.error("sync-as-grinta: alerte impossible", inner);
    }
  }
}

export async function handleSync(req: Request, override?: Partial<SyncDeps>): Promise<Response> {
  deps = { ...defaultDeps, ...override };
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  const expected = deps.tokenSha256;
  if (!expected || (await sha256(req.headers.get("x-sync-token") ?? "")) !== expected) {
    return json({ error: "Forbidden" }, 403);
  }
  const clubId = TARGET_CLUB_ID;
  const domain = TARGET_USERNAME_DOMAIN;
  if (!deps.env("AS_GRINTA_SERVICE_KEY")) {
    return json({ error: "Configuration incomplète." }, 500);
  }

  const started = Date.now();
  const sql = postgres(deps.env("SUPABASE_DB_URL")!, { max: 1, prepare: false });
  const report: Record<string, string> = {};
  const notes: string[] = [];
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

        let rows = await readSource(table, pk.filter((c) => c !== "club_id"));
        for (const row of rows) {
          row.club_id = clubId;
          if (table === "profiles" && typeof row.username === "string") {
            row.email = `${row.username.toLowerCase()}@${domain}`;
          }
        }
        if (table === "profiles") await fixProfilePhotos(tx, rows);
        if (table === "badges") {
          const copied = await mirrorBadgeImages(tx, rows, notes);
          const projectUrl = deps.env("SUPABASE_URL")!;
          rows = rows.map((row) => rewriteBadgeRow(row, projectUrl, copied));
        }

        const cols = rows.length
          ? Object.keys(rows[0]).filter((c) => targetColumns.has(c))
          : [];
        const list = cols.map(q).join(",");
        let changed = 0;

        if (pk.length === 0 || REPLACE_TABLES.has(table)) {
          // Remplacement complet du club : évite les collisions de
          // contraintes uniques quand des lignes échangent une valeur.
          const before = await clubFingerprint(tx, table, pk, clubId);
          await tx.unsafe(`delete from public.${q(table)} where club_id = $1`, [clubId]);
          for (let i = 0; i < rows.length; i += 500) {
            await tx.unsafe(
              `insert into public.${q(table)} (${list})
               select ${list} from jsonb_populate_recordset(null::public.${q(table)}, $1::text::jsonb)`,
              [JSON.stringify(rows.slice(i, i + 500))],
            );
          }
          if (pk.length && before !== await clubFingerprint(tx, table, pk, clubId)) changed = 1;
        } else {
          const pkList = pk.map(q).join(",");
          const dataCols = cols.filter((c) => !pk.includes(c));
          for (let i = 0; i < rows.length; i += 500) {
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
        await resetSequences(tx, table);
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
    return json({ result, changes, seconds: (Date.now() - started) / 1000, tables: report, notes });
  } catch (error) {
    await recordFailure(sql, error);
    return json({ error: error instanceof Error ? error.message : String(error), report }, 500);
  } finally {
    await sql.end({ timeout: 5 });
  }
}
