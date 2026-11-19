// Les dépendances réelles sont branchées ici ; le même handler est testé
// sans compte, sans base et sans appel à Stripe.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2.95.0";
import { createStripeRefundHandler } from "./handler.ts";

Deno.serve(createStripeRefundHandler({
  createClient,
  getEnv: (name) => Deno.env.get(name),
  fetch,
}));
