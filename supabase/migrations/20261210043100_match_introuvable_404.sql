-- Lien vers un match inexistant : le compteur de pronostics levait « Match not
-- found » avec le code P0002, que l'API renvoie en erreur 500 (panne). Le code
-- PT404 la renvoie en 404 : l'appli affiche « Ce match n'existe plus » au lieu
-- d'un écran « Réessayer ». Seul le code d'erreur change ; mêmes contrôles
-- (profil actif, cloisonnement par club) que la migration 20261204000000.

create or replace function public.match_prediction_participant_count(p_match_id uuid)
returns integer
language plpgsql
stable
security definer
set search_path to ''
as $function$
begin
  if not public.is_active_profile() then
    raise exception 'Active profile required' using errcode = '42501';
  end if;
  if p_match_id is null then
    raise exception 'Match id is required' using errcode = '22023';
  end if;
  if not exists (
    select 1 from public.matches m
    where m.id = p_match_id and m.club_id = private.current_club_id()
  ) then
    raise exception 'Match not found' using errcode = 'PT404';
  end if;
  return (
    select count(*)::integer
    from public.match_predictions mp
    where mp.match_id = p_match_id and mp.is_filled
  );
end;
$function$;
