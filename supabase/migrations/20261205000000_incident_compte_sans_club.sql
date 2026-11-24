-- Un compte connecté mais sans club (inscription non terminée, compte de
-- l'éditeur) signalait les erreurs de l'appli : l'écriture était refusée par
-- la règle de cloisonnement (club_id obligatoire), ce qui produisait une
-- erreur côté base à chaque signalement (12 en une journée, 23/11/2026).
-- Sans club, le signalement est maintenant ignoré sans erreur, comme pour un
-- visiteur non connecté. Rien d'autre ne change.
-- CREATE OR REPLACE conserve propriétaire (club_scope), droits et search_path.

create or replace function public.log_client_incident(
  p_reference text,
  p_operation text,
  p_error_type text,
  p_app_version text
)
returns void
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_actor uuid := (select private.uid());
  v_recent integer;
begin
  if v_actor is null then
    return;
  end if;
  if (select private.current_club_id()) is null then
    return;
  end if;
  if nullif(btrim(p_reference), '') is null then
    return;
  end if;

  select count(*)
  into v_recent
  from private.client_incident_log entry
  where entry.profile_id = v_actor
    and entry.created_at > now() - interval '1 minute';

  if v_recent >= 20 then
    return;
  end if;

  insert into private.client_incident_log (
    reference, operation, error_type, app_version, profile_id
  )
  values (
    left(btrim(p_reference), 64),
    left(coalesce(nullif(btrim(p_operation), ''), 'unknown'), 128),
    left(coalesce(nullif(btrim(p_error_type), ''), 'unknown'), 128),
    left(coalesce(nullif(btrim(p_app_version), ''), 'unknown'), 32),
    v_actor
  );
end;
$function$;
