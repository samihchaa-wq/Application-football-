-- Étendre le petit canal de révisions hérité d'AS Grinta aux réglages de
-- chaque club. Aucun paramètre privé ne transite sur ce canal : les clients
-- relisent les RPC/RLS existantes après réception d'une révision.
create function private.signal_club_configuration_change() returns trigger
language plpgsql security definer
set search_path to ''
as $$
declare
  v_row jsonb;
  v_club uuid;
begin
  -- Ne pas recharger les appareils pour une écriture sans changement réel.
  if tg_op = 'UPDATE'
     and (to_jsonb(new) - 'updated_at' - 'updated_by')
         is not distinct from (to_jsonb(old) - 'updated_at' - 'updated_by') then
    return null;
  end if;
  v_row := case when tg_op = 'DELETE' then to_jsonb(old) else to_jsonb(new) end;
  v_club := case when tg_table_name = 'clubs'
    then (v_row ->> 'id')::uuid else (v_row ->> 'club_id')::uuid end;

  -- Les suppressions en cascade d'un club ne doivent pas recréer de signal.
  if not exists (select 1 from public.clubs where id = v_club) then
    return null;
  end if;
  insert into public.feature_flag_change_signals(club_id, key, revision, updated_at)
  values (v_club, 'club_configuration', 1, clock_timestamp())
  on conflict (club_id, key) do update
  set revision = public.feature_flag_change_signals.revision + 1,
      updated_at = excluded.updated_at;
  return null;
end;
$$;

-- Propriétaire technique nécessaire : un opérateur peut modifier un autre
-- club que le sien. La cible vient exclusivement de la ligne déjà autorisée
-- et modifiée par le trigger ; cette fonction n'est pas une RPC appelable.
alter function private.signal_club_configuration_change() owner to postgres;
revoke all on function private.signal_club_configuration_change()
  from public, anon, authenticated, service_role;

create trigger trg_club_configuration_identity
after insert or update of name, short_name, primary_color, secondary_color,
  logo_path, kits, invite_code, timezone, status on public.clubs
for each row execute function private.signal_club_configuration_change();

create trigger trg_club_configuration_rules
after insert or update or delete on private.club_rules
for each row execute function private.signal_club_configuration_change();

create trigger trg_club_configuration_modules
after insert or update of enabled, config or delete on private.app_feature_flags
for each row execute function private.signal_club_configuration_change();

create trigger trg_club_configuration_settings
after insert or update or delete on public.club_settings
for each row execute function private.signal_club_configuration_change();

-- Amorce pour les clubs existants. La création des prochains clubs passe
-- par les mêmes triggers, sans tâche planifiée supplémentaire.
insert into public.feature_flag_change_signals(club_id, key, revision, updated_at)
select id, 'club_configuration', 1, clock_timestamp() from public.clubs
on conflict (club_id, key) do nothing;
