-- Décision propriétaire : Homme du match dans tous les textes du produit.
-- Migration additive placée après les anciennes migrations de catalogue.
-- Aucun identifiant motm/hdm/man_of_the_match ni résultat sportif ne change.
create function pg_temp.hdm_label(p_text text) returns text
language sql immutable strict as $label$
  select replace(replace(replace(replace(replace(replace(replace(replace(p_text,
    'Aucune Étoile du match collective', 'Aucun Homme du match collectif'),
    'ÉTOILES DU MATCH', 'HOMMES DU MATCH'),
    'ÉTOILE DU MATCH', 'HOMME DU MATCH'),
    'Étoiles du match', 'Hommes du match'),
    'Étoile du match', 'Homme du match'),
    'étoiles du match', 'hommes du match'),
    'étoile du match', 'homme du match'),
    'Étoile : notification', 'Homme du match : notification');
$label$;

-- CREATE OR REPLACE conserve les OID et ACL. Vérifier aussi propriétaire,
-- attributs de sécurité et corps attendu après chaque réécriture.
do $rename$
declare
  f record;
  before_row record;
  after_row record;
begin
  for f in
    select p.oid, pg_get_functiondef(p.oid) as definition
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('public', 'private') and p.prokind = 'f'
      and (p.prosrc ~* '[Éé]toiles? du match' or p.prosrc like '%Étoile : notification%')
  loop
    select proowner, proacl::text, prosecdef, proconfig::text,
           pg_temp.hdm_label(prosrc) as source
    into before_row from pg_proc where oid = f.oid;
    execute pg_temp.hdm_label(f.definition);
    select proowner, proacl::text, prosecdef, proconfig::text, prosrc as source
    into after_row from pg_proc where oid = f.oid;
    if before_row is distinct from after_row then
      raise exception 'Homme du match : attributs modifiés pour %', f.oid;
    end if;
  end loop;
end;
$rename$;

-- Textes déjà stockés : badges actuels et modèles des prochaines équipes.
update public.badges set name = pg_temp.hdm_label(name),
  description = pg_temp.hdm_label(description)
where name ~* '[Éé]toiles? du match' or description ~* '[Éé]toiles? du match';
update private.badge_templates set name = pg_temp.hdm_label(name),
  description = pg_temp.hdm_label(description)
where name ~* '[Éé]toiles? du match' or description ~* '[Éé]toiles? du match';

-- Historique visible des notifications système uniquement : ne pas réécrire
-- les messages libres des administrateurs. Aucun nouvel envoi n'est déclenché.
update private.notification_history set title = pg_temp.hdm_label(title),
  body = pg_temp.hdm_label(body)
where kind in ('motm_open', 'motm_result_general', 'motm_result_winner')
  and (title ~* '[Éé]toiles? du match' or body ~* '[Éé]toiles? du match');
