begin;
set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Décision finale : aucun +1 automatique, seul l'admin corrige un compteur.
-- La tâche ne doit plus être planifiée (et pas seulement inoffensive).
select ok(
  not exists (select 1 from cron.job where jobname = 'waitlist-credit'),
  'Le cron automatique de credits a ete supprime'
);

-- Défense en profondeur : même un appel direct ne peut plus attribuer de +1.
select is(
  private.process_due_waitlist_credits(),
  0,
  'Le traitement historique du cron est un no-op'
);
select is(
  private.finalize_due_waitlist_turns_for_season(
    '00000000-0000-0000-0000-000000000000'::uuid
  ),
  0,
  'La lecture ne rattrape pas de credits'
);
select is(
  private.finalize_match_waitlist_turns_internal(
    '00000000-0000-0000-0000-000000000000'::uuid, true
  ),
  0,
  'La finalisation forcee ne credite jamais'
);
select is(
  private.void_match_waitlist_credits(
    '00000000-0000-0000-0000-000000000000'::uuid
  ),
  0,
  'Annulation et report ne retirent aucun credit'
);

-- L'API de correction administrative reste disponible et isolee.
select ok(
  to_regprocedure('public.admin_set_waitlist_manual_count(uuid,integer)')
    is not null,
  'La RPC administrative de correction manuelle est preservee'
);
select ok(
  not has_function_privilege(
    'authenticated',
    'private.finalize_match_waitlist_turns_internal(uuid,boolean)',
    'EXECUTE'
  ),
  'Un joueur ne peut pas appeler directement la finalisation privee'
);
select is(
  (select pg_get_userbyid(p.proowner)
   from pg_proc p
   where p.oid =
      'private.finalize_match_waitlist_turns_internal(uuid,boolean)'::regprocedure),
  'club_scope',
  'Le proprietaire de la fonction de finalisation est preserve'
);
select is(
  (select p.prosecdef from pg_proc p
   where p.oid='private.process_due_waitlist_credits()'::regprocedure),
  false,
  'Le coordinateur conserve le mode SECURITY INVOKER'
);

select * from finish();
rollback;
