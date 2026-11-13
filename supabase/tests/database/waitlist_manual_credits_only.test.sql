begin;
set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Le cron attribue les +1 uniquement aux matchs passes depuis l activation.
select ok(
  exists (select 1 from cron.job where jobname = 'waitlist-credit'),
  'Le cron de credit automatique a ete reactive'
);

-- Sans match eligible, le cron ne produit rien. Lecture, annulation et
-- fausse ID ne doivent jamais ajouter ou retirer de credit.
select is(
  private.process_due_waitlist_credits(),
  0,
  'Le traitement cron ne credite rien sans match eligible'
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
  'Un identifiant de match inexistant ne peut etre force'
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
  'La fonction de credit conserve son proprietaire'
);

select * from finish();
rollback;
