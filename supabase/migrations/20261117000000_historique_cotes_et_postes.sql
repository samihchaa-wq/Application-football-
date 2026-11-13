-- Les matchs d'historique saisis par l'administrateur nourrissent maintenant
-- aussi les cotes des matchs déjà au calendrier et la simulation de
-- composition.
--
-- Avant :
--   * les cotes d'un match déjà créé ne bougeaient pas quand on ajoutait ou
--     supprimait un match d'historique : seule la saisie d'un score d'un
--     match de l'application les recalculait ;
--   * « Simuler composition » ne lisait les postes que dans les matchs joués
--     dans l'application : les compositions de l'historique, pourtant
--     enregistrées, étaient ignorées.

-- ---------------------------------------------------------------------------
-- 1. Cotes : recalcul des matchs à venir après toute modification de
--    l'historique (une fois par opération, même pour un ajout groupé)
-- ---------------------------------------------------------------------------
create function private.recalculate_upcoming_odds_after_history_change()
returns trigger
language plpgsql security definer
set search_path to ''
as $$
begin
  perform public.recalculate_upcoming_match_odds_v4();
  return null;
end;
$$;

alter function private.recalculate_upcoming_odds_after_history_change() owner to club_scope;
revoke all on function private.recalculate_upcoming_odds_after_history_change()
  from public, anon, authenticated;
grant execute on function private.recalculate_upcoming_odds_after_history_change()
  to club_scope, service_role;

create trigger recalculate_upcoming_odds_after_history_change
after insert or update or delete on public.historical_match_scores
for each statement
execute function private.recalculate_upcoming_odds_after_history_change();

-- ---------------------------------------------------------------------------
-- 2. Postes : l'historique des postes réunit les matchs de l'application et
--    les compositions des matchs d'historique (titulaires placés).
--
--    Les deux sources ne se recouvrent pas : un match d'historique est
--    toujours antérieur à la première saison suivie dans l'application.
--    Les coordonnées d'historique sont en pourcentage (0 à 100), celles de
--    l'application entre 0 et 1.
-- ---------------------------------------------------------------------------
create or replace function private.get_player_position_history(p_since timestamp with time zone)
returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_result jsonb;
begin
  perform private.require_sports_management_enabled();
  if not private.is_admin() then
    raise exception 'Active administrator role required' using errcode = '42501';
  end if;

  with app_positions as (
    select
      identity.player_id,
      entry.x::numeric as x,
      entry.y::numeric as y,
      match.kickoff_at
    from public.match_composition_entries entry
    join public.matches match on match.id = entry.match_id
    join public.match_sport_participants participant
      on participant.id = entry.participant_id
    left join public.season_players season_player
      on season_player.id = participant.season_player_id
    left join public.guest_players guest
      on guest.id = participant.guest_player_id
    cross join lateral (
      select coalesce(season_player.player_id, guest.player_id) as player_id
    ) identity
    where match.status in ('termine', 'archive')
      and match.kickoff_at >= p_since
      and entry.zone = 'field'::public.sport_composition_zone
      and entry.x is not null
      and entry.y is not null
      and identity.player_id is not null
  ),
  history_positions as (
    select
      hmp.player_id,
      round(least(greatest(hmp.x_pct, 0), 100) / 100.0, 6) as x,
      round(least(greatest(hmp.y_pct, 0), 100) / 100.0, 6) as y,
      ((score.match_date + coalesce(score.match_time, time '12:00'))
        at time zone 'Europe/Paris') as kickoff_at
    from public.historical_match_players hmp
    join public.historical_match_scores score on score.id = hmp.match_id
    where hmp.is_starter
      and hmp.x_pct is not null
      and hmp.y_pct is not null
      and hmp.player_id is not null
  ),
  all_positions as (
    select * from app_positions
    union all
    select * from history_positions where kickoff_at >= p_since
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'player_id', position.player_id,
        'x', position.x,
        'y', position.y,
        'kickoff_at', position.kickoff_at
      )
    ),
    '[]'::jsonb
  )
  into v_result
  from all_positions position;

  return v_result;
end;
$$;
