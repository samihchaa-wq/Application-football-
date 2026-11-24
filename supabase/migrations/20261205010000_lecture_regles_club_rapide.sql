-- Lecture des règles du club en une seule requête.
--
-- get_club_rules() est appelée à chaque ouverture de l'appli (1 300 appels
-- par jour en production pour un seul club) et prenait 89 ms en moyenne :
-- pour chacune des 68 règles, private.club_rule() relisait le club courant,
-- cherchait la valeur du club puis reparcourait tout le catalogue pour la
-- valeur par défaut. Le résultat est identique (même clés, même ordre,
-- valeur du club sinon valeur par défaut) ; la clé primaire (club_id, key)
-- garantit au plus une valeur par règle.
-- CREATE OR REPLACE conserve propriétaire (club_scope), droits et search_path.

create or replace function public.get_club_rules()
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $function$
declare
  v_club_id uuid;
begin
  if not (select private.is_active_profile()) then
    return '[]'::jsonb;
  end if;

  v_club_id := (select private.current_club_id());

  return coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'key', catalogue.key,
        'label', catalogue.label,
        'description', catalogue.description,
        'unit', catalogue.unit,
        'group', catalogue.group_label,
        'default', catalogue.default_value,
        'min', catalogue.min_value,
        'max', catalogue.max_value,
        'value', coalesce(rule.value, catalogue.default_value)
      )
      order by catalogue.sort_order
    )
    from private.club_rule_catalogue() catalogue
    left join private.club_rules rule
      on rule.key = catalogue.key
     and rule.club_id = v_club_id
  ), '[]'::jsonb);
end;
$function$;
