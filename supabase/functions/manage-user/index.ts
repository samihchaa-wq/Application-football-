// Les dépendances réelles sont branchées ici ; le même handler est testé
// sans compte ni requête vers un projet Supabase distant.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2.95.0";
import { createManageUserHandler } from "./handler.ts";

Deno.serve(createManageUserHandler({
  createClient,
  getEnv: (name) => Deno.env.get(name),
}));
