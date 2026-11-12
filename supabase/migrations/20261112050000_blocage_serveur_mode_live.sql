-- Mode live désactivé : le serveur le refuse aussi.
--
-- Jusqu'ici, un club qui coupait le mode live le voyait seulement disparaître
-- de l'application. Le serveur refuse maintenant d'ouvrir un live, d'y
-- enregistrer un événement (but, composition…) ou d'abonner un joueur aux
-- alertes de but quand le club a désactivé la fonction. Un live déjà ouvert
-- peut toujours être terminé : seules les créations sont bloquées.

create function private.guard_live_mode_module() returns trigger
language plpgsql
set search_path to ''
as $$
begin
  if not private.club_module_enabled('live_mode') then
    raise exception 'Le mode live est désactivé pour ce club.'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

revoke all on function private.guard_live_mode_module() from public, anon;

create trigger guard_live_mode_module
before insert on public.match_live_sessions
for each row execute function private.guard_live_mode_module();

create trigger guard_live_mode_module
before insert on public.match_live_events
for each row execute function private.guard_live_mode_module();

create trigger guard_live_mode_module
before insert on public.match_live_notification_subscriptions
for each row execute function private.guard_live_mode_module();
