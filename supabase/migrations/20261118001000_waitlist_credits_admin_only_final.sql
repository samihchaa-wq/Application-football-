-- Petit Filet — règle produit validée : crédits +1 de liste d'attente
-- attribués/retirés uniquement par un administrateur.
--
-- La migration 20261115000000 désactivait déjà ces crédits mais la migration
-- 20261116000000 les a réactivés au coup d'envoi via pg_cron. Cette migration
-- corrective est postérieure aux deux et n'altère aucune ancienne migration.
--
-- PRÉSERVATION : aucun UPDATE, DELETE ou remise à zéro de compteurs existants,
-- pas de modification de rang/convocation, aucune perte d'audit ou d'archive.
-- La RPC public.admin_set_waitlist_manual_count(uuid, integer), ses contrôles
-- administrateur, son journal d'audit et son recalcul continuent de fonctionner.
--
-- Défense en profondeur : retirer le cron ET neutraliser les points d'entrée
-- internes. Une exécution manuelle résiduelle ou un ancien appel reste sans
-- effet, même si le cron est réactivé par erreur.

do $unschedule_waitlist_credits$
begin
  if exists (select 1 from cron.job where jobname = 'waitlist-credit') then
    perform cron.unschedule('waitlist-credit');
  end if;
end;
$unschedule_waitlist_credits$;

-- Point d'attribution réactivé par la migration 20261116000000.
-- Garder la signature et le propriétaire existants pour compatibilité.
create or replace function private.finalize_match_waitlist_turns_internal(
  p_match_id uuid,
  p_force boolean default false
)
returns integer
language plpgsql
security definer
set search_path to ''
as $function$
begin
  return 0;
end;
$function$;

-- Le coordinateur cron était SECURITY INVOKER depuis 20261116000000.
-- Conserver ce mode de sécurité, même neutralisé.
create or replace function private.process_due_waitlist_credits()
returns integer
language plpgsql
security invoker
set search_path to ''
as $function$
begin
  return 0;
end;
$function$;

-- Préserver explicitement le comportement de non-rattrapage introduit
-- par 20261115000000, même si d'autres chemins l'appellent encore.
create or replace function private.finalize_due_waitlist_turns_for_season(
  p_season_id uuid
)
returns integer
language plpgsql
security definer
set search_path to ''
as $function$
begin
  return 0;
end;
$function$;

-- Ne retirer aucun crédit manuel lors d'un report ou d'une annulation.
create or replace function private.void_match_waitlist_credits(p_match_id uuid)
returns integer
language plpgsql
security definer
set search_path to ''
as $function$
begin
  return 0;
end;
$function$;

-- Ces implémentations internes ne sont pas des RPC publiques.
revoke all on function private.finalize_match_waitlist_turns_internal(uuid, boolean)
  from public, anon, authenticated;
revoke all on function private.process_due_waitlist_credits()
  from public, anon, authenticated;
revoke all on function private.finalize_due_waitlist_turns_for_season(uuid)
  from public, anon, authenticated;
revoke all on function private.void_match_waitlist_credits(uuid)
  from public, anon, authenticated;
