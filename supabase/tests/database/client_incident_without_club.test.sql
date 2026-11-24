begin;

-- Un compte connecté sans club (inscription non terminée, compte de
-- l'éditeur) signalait ses erreurs d'appli : l'écriture était refusée par la
-- règle de cloisonnement (12 refus en une journée en production, 23/11/2026).
-- Le signalement est maintenant ignoré sans erreur.
set local search_path = public, extensions, pg_catalog;
select plan(4);

insert into auth.users (id, email)
values ('1d000000-0000-0000-0000-000000000001', 'sans-club@example.invalid');
-- Une base locale rattache un nouveau compte au club par défaut ; la
-- production, non. On retire ce profil pour reproduire le compte sans club.
delete from public.profiles where id = '1d000000-0000-0000-0000-000000000001';

select is(
  (select count(*) from public.profiles
   where id = '1d000000-0000-0000-0000-000000000001'),
  0::bigint,
  'le compte de test n’est rattaché à aucun club'
);

select set_config(
  'request.jwt.claims',
  '{"sub":"1d000000-0000-0000-0000-000000000001","role":"authenticated","aud":"authenticated"}',
  true
);
set local role authenticated;

select lives_ok(
  $$select public.log_client_incident('incident-sans-club', 'test', 'test', '0')$$,
  'un compte sans club peut signaler une erreur sans provoquer de refus'
);

reset role;

select is(
  (select count(*) from private.client_incident_log
   where reference = 'incident-sans-club'),
  0::bigint,
  'le signalement d’un compte sans club n’est rattaché à aucun club'
);

select ok(
  (select p.prosecdef and pg_get_userbyid(p.proowner) = 'club_scope'
   from pg_proc p
   where p.oid = 'public.log_client_incident(text,text,text,text)'::regprocedure),
  'la fonction garde son propriétaire cloisonné'
);

select * from finish();
rollback;
