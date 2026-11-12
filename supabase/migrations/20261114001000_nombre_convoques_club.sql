-- M02 / C06-D11 : quota habituel de convoqués pour le club courant.
-- Ne change pas les quotas déjà personnalisés match par match.
-- (Reprise de la PR 43, renumérotée après les migrations déjà appliquées.)
create function public.admin_set_club_usual_squad_size(p_size integer)
returns integer
language plpgsql security definer
set search_path to ''
as $$
declare
  v_saved integer;
begin
  if not (select private.is_admin()) then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;
  if p_size is null or p_size < 1 or p_size > 30 then
    raise exception 'Nombre de convoqués invalide (1 à 30).'
      using errcode = '22023';
  end if;

  update private.app_feature_flags
  set config = jsonb_set(config, '{usual_squad_size}', to_jsonb(p_size), true),
      updated_at = clock_timestamp(),
      updated_by = (select private.uid())
  where club_id = (select private.current_club_id())
    and key = 'sports_management'
  returning (config ->> 'usual_squad_size')::integer into v_saved;

  if not found then
    raise exception 'Réglage sportif du club introuvable.' using errcode = 'P0002';
  end if;

  -- Le déclencheur trg_signal_feature_flag_change existant émet
  -- l'événement Realtime destiné aux autres appareils du même club.
  return v_saved;
end;
$$;

alter function public.admin_set_club_usual_squad_size(integer) owner to club_scope;
revoke all on function public.admin_set_club_usual_squad_size(integer)
  from public, anon;
grant execute on function public.admin_set_club_usual_squad_size(integer)
  to authenticated, service_role, club_scope;
