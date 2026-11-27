// Point d'entrée de la copie AS Grinta : la logique est dans handler.ts.
import "jsr:@supabase/functions-js@2.95.0/edge-runtime.d.ts";
import { handleSync } from "./handler.ts";

Deno.serve((req: Request) => handleSync(req));
