-- Compteurs exclusivement manuels : delta atomique, geste rejouable sans
-- double crédit, classement renvoyé par le serveur et modes appliqués aussitôt.
-- Aucun compteur existant ni ancien journal n'est modifié par la migration.

create unique index sport_waitlist_manual_request_uidx
on private.sport_admin_audit_log (club_id, (metadata ->> 'request_id'))
where action = 'set_waitlist_manual_count' and metadata ? 'request_id';

create function private.change_waitlist_manual_count(
  p_season_player_id uuid,
  p_count integer,
  p_delta integer,
  p_request_id uuid
)
returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_actor uuid := (select private.uid());
  v_club uuid := (select private.current_club_id());
  v_season_id uuid;
  v_old integer;
  v_new bigint;
  v_previous record;
begin
  if not private.is_admin() then
    raise exception 'Active administrator role required' using errcode = '42501';
  end if;
  if p_delta is null then
    if p_count is null or p_count < 0 or p_request_id is not null then
      raise exception 'Invalid count' using errcode = '22023';
    end if;
  elsif p_delta not in (-1, 1) or p_count is not null or p_request_id is null then
    raise exception 'Invalid count adjustment' using errcode = '22023';
  end if;

  select e.season_id into v_season_id
  from public.sport_waitlist_entries e
  where e.season_player_id = p_season_player_id and e.club_id = v_club;
  if not found then
    raise exception 'Waitlist entry not found' using errcode = 'P0002';
  end if;

  -- Même ordre pour les anciens clients et les nouveaux : saison, puis
  -- compteur. Deux corrections de joueurs distincts ne se verrouillent pas
  -- mutuellement pendant le reclassement de toute la saison.
  perform 1 from public.seasons where id = v_season_id for update;

  if p_request_id is not null then
    select log.actor_profile_id, log.metadata into v_previous
    from private.sport_admin_audit_log log
    where log.club_id = v_club
      and log.action = 'set_waitlist_manual_count'
      and log.metadata ->> 'request_id' = p_request_id::text;
    if found then
      if v_previous.actor_profile_id <> v_actor
         or v_previous.metadata ->> 'season_player_id' <> p_season_player_id::text
         or (v_previous.metadata ->> 'delta')::integer <> p_delta then
        raise exception 'Adjustment identifier already used' using errcode = '22023';
      end if;
      return private.sport_waitlist_payload(v_season_id);
    end if;
  end if;

  select e.manual_waitlist_count into v_old
  from public.sport_waitlist_entries e
  where e.season_player_id = p_season_player_id and e.club_id = v_club
  for update;
  if not found then
    raise exception 'Waitlist entry not found' using errcode = 'P0002';
  end if;

  v_new := case when p_delta is null then p_count::bigint
                else v_old::bigint + p_delta end;
  if v_new < 0 or v_new > 2147483647 then
    raise exception 'Le compteur ne peut pas être négatif ou dépasser sa limite.'
      using errcode = '22023';
  end if;

  if v_old is distinct from v_new then
    update public.sport_waitlist_entries
    set manual_waitlist_count = v_new::integer,
        updated_at = now(), updated_by = v_actor
    where season_player_id = p_season_player_id and club_id = v_club;

    insert into private.sport_admin_audit_log (
      action, actor_profile_id, metadata
    ) values (
      'set_waitlist_manual_count', v_actor,
      jsonb_build_object('season_player_id', p_season_player_id,
        'old_count', v_old, 'new_count', v_new)
      || case when p_request_id is null then '{}'::jsonb
         else jsonb_build_object('request_id', p_request_id, 'delta', p_delta) end
    );

    perform private.rebuild_sport_waitlist_order(v_season_id, v_actor);
    perform private.rebalance_upcoming_waitlist_matches(v_season_id);
  end if;
  return private.sport_waitlist_payload(v_season_id);
end;
$$;

alter function private.change_waitlist_manual_count(uuid, integer, integer, uuid)
  owner to club_scope;
revoke all on function private.change_waitlist_manual_count(uuid, integer, integer, uuid)
  from public, anon, authenticated, service_role;

-- Compatibilité des clients déjà installés : la signature de correction
-- absolue reste disponible, avec les mêmes contrôles et le même journal.
create or replace function public.admin_set_waitlist_manual_count(
  p_season_player_id uuid, p_count integer
)
returns void
language plpgsql security definer
set search_path to ''
as $$
begin
  if not private.is_admin() then
    raise exception 'Active administrator role required' using errcode = '42501';
  end if;
  perform private.change_waitlist_manual_count(p_season_player_id, p_count, null, null);
end;
$$;

create function public.admin_adjust_waitlist_manual_count(
  p_season_player_id uuid, p_delta integer, p_request_id uuid
)
returns jsonb
language plpgsql security definer
set search_path to ''
as $$
begin
  if not private.is_admin() then
    raise exception 'Active administrator role required' using errcode = '42501';
  end if;
  if p_delta is null or p_request_id is null then
    raise exception 'Invalid count adjustment' using errcode = '22023';
  end if;
  return private.change_waitlist_manual_count(p_season_player_id, null, p_delta, p_request_id);
end;
$$;

alter function public.admin_set_waitlist_manual_count(uuid, integer) owner to club_scope;
alter function public.admin_adjust_waitlist_manual_count(uuid, integer, uuid) owner to club_scope;
revoke all on function public.admin_set_waitlist_manual_count(uuid, integer) from public, anon;
revoke all on function public.admin_adjust_waitlist_manual_count(uuid, integer, uuid) from public, anon;
grant execute on function public.admin_set_waitlist_manual_count(uuid, integer) to authenticated, service_role;
grant execute on function public.admin_adjust_waitlist_manual_count(uuid, integer, uuid) to authenticated, service_role;

create function private.rebalance_waitlists_after_mode_change()
returns trigger
language plpgsql security definer
set search_path to ''
as $$
declare
  v_row jsonb := case when tg_op = 'DELETE' then to_jsonb(old) else to_jsonb(new) end;
  v_old integer := case when tg_op = 'INSERT' then 0 else old.value end;
  v_new integer := case when tg_op = 'DELETE' then 0 else new.value end;
  v_season record;
begin
  if v_row ->> 'key' <> 'waitlist_mode' or v_old = v_new
     or not private.is_feature_enabled('sports_management') then
    return null;
  end if;
  -- Le helper garde le gel avant match et ne réinitialise aucun choix admin.
  for v_season in
    select distinct s.id from public.seasons s
    join public.matches m on m.season_id = s.id
    where s.club_id = (v_row ->> 'club_id')::uuid
      and m.status = 'a_venir'
      and now() < private.match_prediction_closes_at(m.kickoff_at)
    order by s.id
  loop
    perform 1 from public.seasons where id = v_season.id for update;
    perform private.rebalance_upcoming_waitlist_matches(v_season.id);
  end loop;
  return null;
end;
$$;

alter function private.rebalance_waitlists_after_mode_change() owner to club_scope;
revoke all on function private.rebalance_waitlists_after_mode_change()
  from public, anon, authenticated, service_role;

create trigger trg_rebalance_waitlists_after_mode_change
after insert or update or delete on private.club_rules
for each row execute function private.rebalance_waitlists_after_mode_change();
