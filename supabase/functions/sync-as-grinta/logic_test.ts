import { assertEquals } from "jsr:@std/assert@1";
import {
  AS_GRINTA_URL,
  asGrintaBadgePath,
  copiedBadgePath,
  failureMessage,
  photoFolder,
  publicBadgeUrl,
  REPLACE_TABLES,
  resolveProfilePhoto,
  rewriteBadgeRow,
  TABLES,
} from "./logic.ts";

const OLD = `${AS_GRINTA_URL}/storage/v1/object/public/badge-images/custom/1786749574029.jpg`;
const NEW_PROJECT = "https://jvxkhgdopslctpcjrhzw.supabase.co";

Deno.test("la liste d'attente est recopiée en remplacement complet", () => {
  // Échanger deux rangs heurtait la contrainte unique (saison, position).
  assertEquals(REPLACE_TABLES.has("sport_waitlist_entries"), true);
  for (const table of REPLACE_TABLES) assertEquals(TABLES.includes(table), true);
});

Deno.test("chemin d'image de badge AS Grinta", () => {
  assertEquals(asGrintaBadgePath(OLD), "custom/1786749574029.jpg");
  assertEquals(
    asGrintaBadgePath(`${AS_GRINTA_URL}/storage/v1/object/public/badge-images/custom/a%20b.png`),
    "custom/a b.png",
  );
  // Déjà sur Petit Filet, autre hôte, autre seau, chemin piégé : rien à faire.
  assertEquals(asGrintaBadgePath(publicBadgeUrl(NEW_PROJECT, "as-grinta/custom/1.jpg")), null);
  assertEquals(asGrintaBadgePath("https://exemple.test/storage/v1/object/public/badge-images/x.png"), null);
  assertEquals(asGrintaBadgePath(`${AS_GRINTA_URL}/storage/v1/object/public/autre/x.png`), null);
  // Les « .. » sont résolus par l'analyse de l'URL : on reste dans le seau.
  assertEquals(asGrintaBadgePath(`${AS_GRINTA_URL}/storage/v1/object/public/badge-images/a/%2E%2E/x.png`), "x.png");
  assertEquals(asGrintaBadgePath(`${AS_GRINTA_URL}/storage/v1/object/public/badge-images/`), null);
  assertEquals(asGrintaBadgePath(null), null);
  assertEquals(asGrintaBadgePath("pas une url"), null);
});

Deno.test("le badge pointe vers Petit Filet seulement quand l'image y est recopiée", () => {
  const row = { id: "b1", image_url: OLD };
  const target = copiedBadgePath("custom/1786749574029.jpg");
  assertEquals(target, "as-grinta/custom/1786749574029.jpg");
  assertEquals(rewriteBadgeRow(row, NEW_PROJECT, new Set()), row);
  assertEquals(
    rewriteBadgeRow(row, NEW_PROJECT, new Set([target])).image_url,
    `${NEW_PROJECT}/storage/v1/object/public/badge-images/as-grinta/custom/1786749574029.jpg`,
  );
  // La réécriture est stable : une deuxième copie ne change plus rien.
  const once = rewriteBadgeRow(row, NEW_PROJECT, new Set([target]));
  assertEquals(rewriteBadgeRow(once, NEW_PROJECT, new Set([target])), once);
  // L'URL produite passe le contrôle serveur des images de badge.
  assertEquals(
    (once.image_url as string).includes("/storage/v1/object/public/badge-images/"),
    true,
  );
});

Deno.test("photo de profil : chemin existant gardé", () => {
  const existing = new Set(["p1/avatar_1.png"]);
  assertEquals(resolveProfilePhoto("p1/avatar_1.png", existing, new Map()), "p1/avatar_1.png");
  assertEquals(resolveProfilePhoto("/p1/avatar_1.png", existing, new Map()), "p1/avatar_1.png");
});

Deno.test("photo de profil : fichier introuvable remplacé par la photo du dossier", () => {
  // Cas réel du 27/11 : avatar_<n> en base, avatar_player_<m> dans le stockage.
  const folders = new Map([["p1", ["p1/avatar_player_1794.png", "p1/avatar_player_1700.png"]]]);
  const existing = new Set(folders.get("p1"));
  assertEquals(resolveProfilePhoto("p1/avatar_1793.png", existing, folders), "p1/avatar_player_1794.png");
});

Deno.test("photo de profil : aucun fichier, aucune photo (initiales)", () => {
  assertEquals(resolveProfilePhoto("p2/avatar_1.png", new Set(), new Map()), null);
  assertEquals(resolveProfilePhoto("avatar_1.png", new Set(), new Map()), null);
  assertEquals(resolveProfilePhoto(null, new Set(), new Map()), null);
  assertEquals(resolveProfilePhoto("  ", new Set(), new Map()), null);
  // Un fichier qui n'est pas une photo n'est jamais choisi.
  const folders = new Map([["p3", ["p3/notes.txt"]]]);
  assertEquals(resolveProfilePhoto("p3/avatar_1.png", new Set(folders.get("p3")), folders), null);
});

Deno.test("dossier d'une photo", () => {
  assertEquals(photoFolder("p1/avatar_1.png"), "p1");
  assertEquals(photoFolder("season/p1/avatar_1.png"), "season/p1");
  assertEquals(photoFolder("avatar_1.png"), null);
  assertEquals(photoFolder(undefined), null);
});

Deno.test("message d'alerte borné à 500 caractères", () => {
  const message = failureMessage(new Error("duplicate key value violates unique constraint"));
  assertEquals(message.startsWith("La copie automatique AS Grinta a échoué : duplicate key"), true);
  assertEquals(failureMessage("x".repeat(2000)).length, 500);
});
