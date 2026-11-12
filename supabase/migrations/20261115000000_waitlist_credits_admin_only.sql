-- Petit Filet: les compteurs +1 de liste d'attente sont exclusivement manuels.
-- Décision propriétaire du 13/11/2026, issue #68.
--
-- Ne pas toucher aux valeurs historiques, aux classements existants ni aux
-- décisions de convocation. Les admins conservent les boutons +/- et la RPC
-- public.admin_set_waitlist_manual_count, qui tient le journal d'audit.
--
-- Le +1 automatique se déclenchait via cron, mais aussi via les lectures
-- de liste, les changements de date/statut d'un match et la finalisation
-- administrative : neutraliser seulement cron serait insuffisant.
--
-- Ces signatures sont préservées pour ne pas casser les appels existants,
-- qui deviennent sans effet. Les autorisations et propriétaires existants
-- sont conservés par CREATE OR REPLACE FUNCTION.

do $migration$
begin
  if exists (
    select 1 from cron.job where jobname = 'waitlist-credit'
  ) then
    perform cron.unschedule('waitlist-credit');
  end if;
end
$migration$;

-- Point unique d'attribution (appelé aussi depuis la lecture admin).
create or replace function private.finalize_match_waitlist_turns_internal(
  p_match_id uuid,
  p_force boolean default false
)
returns integer
language plpgsql security definer
set search_path to ''
as $function$
begin
  -- Jamais de modification automatique du compteur, du journal ni du rang.
  return 0;
end;
$function$;

-- Empêcher le rattrapage automatique des anciens matchs en lecture.
create or replace function private.finalize_due_waitlist_turns_for_season(
  p_season_id uuid
)
returns integer
language plpgsql security definer
set search_path to ''
as $function$
begin
  return 0;
end;
$function$;

-- Même un appel direct ou une tâche replanifiée reste sans effet.
create or replace function private.process_due_waitlist_credits()
returns integer
language plpgsql security definer
set search_path to ''
as $function$
begin
  return 0;
end;
$function$;

-- Annulation, report, quota élargi : ne jamais enlever un +1 décidé par admin.
create or replace function private.void_match_waitlist_credits(p_match_id uuid)
returns integer
language plpgsql security definer
set search_path to ''
as $function$
begin
  return 0;
end;
$function$;
