begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- « Homme du match » devient « Étoile du match » partout où la base produit du
-- texte (notifications, erreurs, règles, badges).

select is(
  (select count(*)
   from pg_proc p
   join pg_namespace n on n.oid = p.pronamespace
   where n.nspname in ('public', 'private')
     and p.prosrc ~* 'ommes? du match'),
  0::bigint,
  'aucune fonction de la base n’écrit plus « Homme du match »'
);

select ok(
  (select bool_or(p.prosrc like '%Étoile du match%')
   from pg_proc p
   join pg_namespace n on n.oid = p.pronamespace
   where n.nspname in ('public', 'private')),
  'les textes parlent désormais de l’« Étoile du match »'
);

select is(
  (select label from private.club_rule_catalogue() where key = 'motm_window_hours'),
  'Durée du vote de l’Étoile du match',
  'le réglage du club porte le nouveau nom'
);

select is(
  (select count(*) from private.badge_templates
   where name in ('Homme fort', 'Joueur décisif', 'Roi du match',
                  'Joueur de la saison', 'Monsieur Présent', 'Monsieur Victoire',
                  'Meilleur buteur', 'Meilleur passeur', 'Président')
      or description ~* 'ommes? du match'),
  0::bigint,
  'les modèles de badges n’ont plus de noms masculins ni « Homme du match »'
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
  'le premier palier d’Étoiles du match est renommé'
);

select * from finish();
rollback;
