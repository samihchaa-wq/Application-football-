-- « Homme du match » devient « Étoile du match » (choix du fil direction
-- artistique) : le terme convient aux équipes masculines, féminines et mixtes.
-- Les badges dont le nom est explicitement masculin sont renommés.
--
-- Rien ne change dans le fonctionnement : seuls les textes affichés ou envoyés
-- (notifications, messages d'erreur, nom des réglages, badges) changent. Les
-- noms techniques (motm, man_of_the_match, hdm) restent.

create function pg_temp.etoile(p_text text) returns text
language sql immutable
as $$
  select replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(p_text, 'tu as été élu co-Homme du match', 'tu es co-Étoile du match'), 'tu as été élu Homme du match', 'tu es l’Étoile du match'), 'ont été élus co-Hommes du match', 'sont les co-Étoiles du match'), 'a été élu Homme du match', 'est l’Étoile du match'), 'Aucun Homme du match collectif n’est attribué', 'Aucune Étoile du match collective n’est attribuée'), 'Co-Hommes du match', 'Co-Étoiles du match'), 'Co-Homme du match', 'Co-Étoile du match'), 'Le vote Homme du match', 'Le vote de l’Étoile du match'), 'le vote Homme du match', 'le vote de l’Étoile du match'), 'Votes Homme du match', 'Votes de l’Étoile du match'), 'Vote Homme du match', 'Vote de l’Étoile du match'), 'vote Homme du match', 'vote de l’Étoile du match'), 'Résultat Homme du match', 'Résultat de l’Étoile du match'), 'Scrutin Homme du match', 'Scrutin de l’Étoile du match'), 'l’Homme du match', 'l’Étoile du match'), 'l''Homme du match', 'l''Étoile du match'), 'L’Homme du match', 'L’Étoile du match'), 'l’homme du match', 'l’Étoile du match'), 'l''homme du match', 'l''Étoile du match'), 'd''homme du match', 'd''Étoile du match'), 'd’homme du match', 'd’Étoile du match'), 'élu homme du match', 'élu Étoile du match'), 'hommes du match', 'Étoiles du match'), 'Homme du match', 'Étoile du match'), 'homme du match', 'Étoile du match');
$$;

-- 1. Fonctions de la base dont le texte parle de l'« Homme du match »
--    (notifications de vote et de résultat, notifications de test, messages
--    d'erreur, catalogue des règles du club). Chaque fonction est réécrite à
--    l'identique, seul le terme change ; propriétaire, droits et réglages sont
--    conservés par CREATE OR REPLACE.
do $$
declare
  v_fn record;
  v_def text;
  v_count integer := 0;
begin
  for v_fn in
    select p.oid, p.oid::regprocedure as signature
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('public', 'private')
      and p.prokind = 'f'
      and p.prosrc ~* 'ommes? du match'
      and not exists (
        select 1 from pg_depend d
        where d.objid = p.oid and d.deptype = 'e'
      )
  loop
    v_def := pg_get_functiondef(v_fn.oid);
    execute pg_temp.etoile(v_def);
    v_count := v_count + 1;
  end loop;
  raise notice 'Étoile du match : % fonction(s) réécrite(s).', v_count;
end;
$$;

-- 2. Badges : modèles des nouveaux clubs, puis clubs existants, sauf si le
--    club a lui-même renommé le badge ou changé sa description.
create temporary table badge_gender_renames (
  code text primary key,
  old_name text not null,
  new_name text not null
) on commit drop;

insert into badge_gender_renames (code, old_name, new_name) values
  ('mvp__10', 'Homme fort', 'Étoile montante'),
  ('mvp__20', 'Joueur décisif', 'Étoile confirmée'),
  ('mvp__30', 'Roi du match', 'Supernova'),
  ('title_mvp_king__1', 'Joueur de la saison', 'Étoile de la saison'),
  ('title_most_present__1', 'Monsieur Présent', 'Fidèle au poste'),
  ('title_best_winrate__1', 'Monsieur Victoire', 'Porte-bonheur'),
  ('title_top_scorer__1', 'Meilleur buteur', 'Machine à buts'),
  ('title_top_assists__1', 'Meilleur passeur', 'Baguette magique'),
  ('role_president', 'Président', 'Présidence');

update public.badges b
set name = r.new_name
from badge_gender_renames r
where b.code = r.code and b.name = r.old_name;

update public.badges b
set description = pg_temp.etoile(t.description)
from private.badge_templates t
where b.code = t.code
  and b.description = t.description
  and t.description ~* 'ommes? du match';

update private.badge_templates t
set name = r.new_name
from badge_gender_renames r
where t.code = r.code and t.name = r.old_name;

update private.badge_templates
set description = pg_temp.etoile(description)
where description ~* 'ommes? du match';

update public.badges
set name = pg_temp.etoile(name)
where name ~* 'ommes? du match';

update private.badge_templates
set name = pg_temp.etoile(name)
where name ~* 'ommes? du match';
