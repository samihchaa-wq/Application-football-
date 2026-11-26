begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Les appels internes de la base portent une signature propre à la fonction
-- appelée et au club (20261208000000_jeton_interne_signe_par_usage_et_club.sql).
-- Les valeurs attendues sont les mêmes que dans
-- supabase/functions/_shared/internal_call_test.ts.

select is(
  private.internal_call_signature('secret', 'send-push', '00000000-0000-0000-0000-000000000001'),
  'd3b9f952dbad38be36c72a87896de7dcd6ee179caa8a83be9a2f2f17f575d6ab',
  'la base signe comme les fonctions serveur (fonction + club)'
);

select is(
  private.internal_call_signature('secret', 'account-email', null),
  '3b726fad1e4fa03266cf00188067331425a5278adcd28bf4bc96ddbae6b9e606',
  'la base signe comme les fonctions serveur (sans club)'
);

select isnt(
  private.internal_call_signature('secret', 'send-push', '00000000-0000-0000-0000-000000000001'),
  private.internal_call_signature('secret', 'send-push', '00000000-0000-0000-0000-000000000002'),
  'deux clubs n''ont pas la même signature'
);

select isnt(
  private.internal_call_signature('secret', 'send-push', null),
  private.internal_call_signature('secret', 'account-email', null),
  'deux fonctions n''ont pas la même signature'
);

-- Appel sortant réel : la signature remplace le mot de passe brut.
select private.http_post(
  url := 'http://127.0.0.1:9/functions/v1/send-push',
  body := '{"kind":"test"}'::jsonb,
  headers := jsonb_build_object(
    'Content-Type', 'application/json',
    'x-push-token', 'secret',
    'x-club-id', '00000000-0000-0000-0000-000000000001'
  )
);

select is(
  (select headers ->> 'x-push-signature' from net.http_request_queue
   where url = 'http://127.0.0.1:9/functions/v1/send-push' order by id desc limit 1),
  'd3b9f952dbad38be36c72a87896de7dcd6ee179caa8a83be9a2f2f17f575d6ab',
  'un appel interne vers une fonction serveur porte sa signature'
);

select ok(
  (select not (headers ? 'x-push-token') from net.http_request_queue
   where url = 'http://127.0.0.1:9/functions/v1/send-push' order by id desc limit 1),
  'le mot de passe interne brut n''est plus transmis'
);

-- Sans mot de passe interne, aucune signature n'est inventée.
select private.http_post(
  url := 'http://127.0.0.1:9/functions/v1/calendar-feed',
  body := '{}'::jsonb,
  headers := jsonb_build_object('Content-Type', 'application/json')
);

select ok(
  not exists (
    select 1 from net.http_request_queue
    where url = 'http://127.0.0.1:9/functions/v1/calendar-feed'
      and headers ? 'x-push-signature'
  ),
  'un appel sans mot de passe interne ne porte pas de signature'
);

select * from finish();
rollback;
