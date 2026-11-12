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

-- 1. Fonctions de la base qui écrivent « Homme du match » dans un texte vu
--    par les membres. Liste explicite, établie à partir des migrations :
--      - private.admin_cancel_match_motm_vote : message d'erreur ;
--      - private.club_rule_catalogue : nom du réglage « Durée du vote… » ;
--      - private.guard_motm_module : message quand la fonction est coupée ;
--      - private.match_motm_result_notification_payloads : notifications de
--        résultat du vote ;
--      - public.internal_push_dispatch : « Pense à voter pour… » ;
--      - public.send_test_push_kind : notifications de test.
--    Les autres fonctions où le terme n'apparaît que dans un commentaire ne
--    sont pas touchées.
--
--    Chaque fonction est réécrite à l'identique, seul le terme change. La
--    migration s'arrête (et rien n'est appliqué) si une fonction manque, si
--    elle ne contient pas le terme attendu, si le texte contient encore le
--    terme après réécriture, ou si signature, propriétaire, droits, mode
--    SECURITY DEFINER ou réglages changent.
do $$
declare
  v_signature text;
  v_oid regprocedure;
  v_before record;
  v_after record;
  v_def text;
  v_new_def text;
begin
  foreach v_signature in array array[
    'private.admin_cancel_match_motm_vote(uuid, text)',
    'private.club_rule_catalogue()',
    'private.guard_motm_module()',
    'private.match_motm_result_notification_payloads(uuid)',
    'public.internal_push_dispatch(text, uuid)',
    'public.send_test_push_kind(text)'
  ] loop
    v_oid := to_regprocedure(v_signature);
    if v_oid is null then
      raise exception 'Étoile du match : fonction introuvable %', v_signature;
    end if;

    select p.proowner, p.proacl::text as acl, p.prosecdef, p.proconfig::text as config,
           pg_get_function_identity_arguments(p.oid) as args,
           pg_get_function_result(p.oid) as result,
           pg_temp.etoile(p.prosrc) as expected_src
    into v_before
    from pg_proc p where p.oid = v_oid;

    v_def := pg_get_functiondef(v_oid);
    if v_def !~* 'ommes? du match' then
      raise exception 'Étoile du match : % ne contient pas le terme attendu', v_signature;
    end if;
    v_new_def := pg_temp.etoile(v_def);
    if v_new_def ~* 'ommes? du match' then
      raise exception 'Étoile du match : remplacement incomplet dans %', v_signature;
    end if;

    execute v_new_def;

    select p.proowner, p.proacl::text as acl, p.prosecdef, p.proconfig::text as config,
           pg_get_function_identity_arguments(p.oid) as args,
           pg_get_function_result(p.oid) as result,
           p.prosrc as expected_src
    into v_after
    from pg_proc p where p.oid = v_oid;

    -- Même signature, propriétaire, droits, mode et réglages ; corps égal à
    -- l'ancien corps avec le seul terme remplacé.
    if v_after is distinct from v_before then
      raise exception 'Étoile du match : réécriture inattendue de %', v_signature;
    end if;
  end loop;
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
