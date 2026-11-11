begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

select is(
  (select count(*) from private.badge_templates
   where name in ('Mobutu', 'Traître', 'Soulier d’or', 'Ballon d’or',
                  'Passe d’or', 'El Presidente')
      or description ~* 'grinta'),
  0::bigint,
  'le catalogue de badges ne contient ni nom propre au club d’origine ni récompense protégée'
);

select is(
  (select count(*) from private.badge_templates where image_url is not null),
  0::bigint,
  'aucun badge du catalogue ne dépend d’une image fournie'
);

select is(
  (select name from private.badge_templates where code = 'title_top_scorer__1'),
  'Meilleur buteur',
  'les titres de saison ont des noms neutres'
);

select * from finish();
rollback;
