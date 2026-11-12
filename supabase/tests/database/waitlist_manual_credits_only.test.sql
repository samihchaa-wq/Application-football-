begin;
set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Aucune tâche programmée ne doit attribuer un +1.
select ok(
  not exists (select 1 from cron.job where jobname = 'waitlist-credit'),
  'Le cron de credit automatique a ete supprime'
);

-- Les points d'entree historiques doivent rester apppelables mais ne jamais
-- accorder ou retirer des credits (lecture admin, cron, match annule/reporte).
select is(
  private.process_due_waitlist_credits(),
  0,
  'Le traitement cron devient sans effet'
);
select is(
  private.finalize_due_waitlist_turns_for_season(
    '00000000-0000-0000-0000-000000000000'::uuid
  ),
  0,
  'La lecture de liste ne rattrape plus les credits'
);
select is(
  private.finalize_match_waitlist_turns_internal(
    '00000000-0000-0000-0000-000000000000'::uuid, true
  ),
  0,
  'Aucun match ne peut credit automatiquement, meme en forçant'
);
select is(
  private.void_match_waitlist_credits(
    '00000000-0000-0000-0000-000000000000'::uuid
  ),
  0,
  'Une annulation ne retire plus de +1'
);

-- La commande manuelle et son controle de permissions continuent d'exister.
select ok(
  to_regprocedure('public.admin_set_waitlist_manual_count(uuid,integer)')
    is not null,
  'La RPC de credit manuel par administrateur est conservee'
);
select is(
  (select pg_get_userbyid(p.proowner)
   from pg_proc p
   where p.oid =
      'private.finalize_match_waitlist_turns_internal(uuid,boolean)'::regprocedure),
  'club_scope',
  'La fonction neutralisee conserve son proprietaire'
);

select * from finish();
rollback;
