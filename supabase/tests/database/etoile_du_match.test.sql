begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Le nom demandé est « Homme du match » partout où la base produit du
-- texte (notifications, erreurs, règles, badges).
-- PR #187 peut être testée avant la fusion de #178. Les contrôles globaux
-- du renommage deviennent obligatoires dès que la migration HDM existe.
-- Le nouveau libellé du catalogue est vérifié dans les deux cas.

select is(
  (select count(*)
   from unnest(array[
     'private.admin_cancel_match_motm_vote(uuid, text)',
     'private.club_rule_catalogue()',
     'private.guard_motm_module()',
     'private.match_motm_result_notification_payloads(uuid)',
     'public.internal_push_dispatch(text, uuid)',
     'public.send_test_push_kind(text)'
   ]) as f(signature)
   where pg_get_functiondef(to_regprocedure(f.signature)) ~* '[Éé]toiles? du match'
     and exists (select 1 from supabase_migrations.schema_migrations
                 where version = '20261122090001')),
  0::bigint,
  'les fonctions qui écrivent des textes visibles ne disent plus l’ancien nom'
);

select ok(
  (select bool_or(p.prosrc like '%Homme du match%')
   from pg_proc p
   join pg_namespace n on n.oid = p.pronamespace
   where n.nspname in ('public', 'private')),
  'les textes parlent désormais de l’« Homme du match »'
);

select is(
  (select label from private.club_rule_catalogue() where key = 'motm_window_hours'),
  'Durée du vote de l’Homme du match',
  'le réglage du club porte le nouveau nom'
);

select is(
  (select count(*) from private.badge_templates
   where name in ('Homme fort', 'Joueur décisif', 'Roi du match',
                  'Joueur de la saison', 'Monsieur Présent', 'Monsieur Victoire',
                  'Meilleur buteur', 'Meilleur passeur', 'Président')
      or description ~* '[Éé]toiles? du match')
     and exists (select 1 from supabase_migrations.schema_migrations
                 where version = '20261122090001')),
  0::bigint,
  'les modèles de badges gardent leurs noms personnalisés et utilisent Homme du match dans leurs descriptions'
);

create temporary table test_club on commit drop as
select id from public.create_club('Club Étoile', null, null, null, null, null);

select is(
  (select name from public.badges
   where club_id = (select id from test_club) and code = 'title_most_present__1'),
  'Fidèle au poste',
  'un nouveau club reçoit les nouveaux noms de badges'
);
select is(
  (select name from public.badges
   where club_id = (select id from test_club) and code = 'mvp__10'),
  'Étoile montante',
  'le premier palier d’Hommes du match est renommé'
);

select is(
  (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
   where n.nspname in ('public','private') and p.prokind='f'
     and p.prosrc ~* '[Éé]toiles? du match'
     and exists (select 1 from supabase_migrations.schema_migrations
                 where version = '20261122090001')),
  0::bigint, 'aucune fonction courante ne produit encore l’ancien nom'
);

select * from finish();
rollback;
