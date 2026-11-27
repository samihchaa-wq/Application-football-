// Point d'entrée de la copie AS Grinta : la logique est dans handler.ts.
import "jsr:@supabase/functions-js@2.95.0/edge-runtime.d.ts";
import { handleSync } from "./handler.ts";

// Empreinte du jeton que seule la planification interne connaît (pas le
// jeton lui-même). Gardée dans ce fichier : c'est le seul chemin autorisé
// par l'exception de .gitleaks.toml.
const TOKEN_SHA256 = "3c635888965336c32f13d08390e8875fe1fc7a4a967da386e6e5e5985a7247ba";

Deno.serve((req: Request) => handleSync(req, { tokenSha256: TOKEN_SHA256 }));
