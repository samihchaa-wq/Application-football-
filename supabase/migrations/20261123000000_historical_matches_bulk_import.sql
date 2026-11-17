-- Préserve les informations de lieu inconnues au lieu de supposer
-- domicile. Les anciennes rencontres gardent leur valeur existante.
alter table public.historical_match_scores
  alter column is_home drop not null;

-- Le formulaire manuel conserve ses règles ; seul l'import administrateur
-- peut ajouter dans une saison déjà suivie et garder domicile/type inconnus.
-- Les recalculs sont mutualisés pour ne pas exécuter 350 fois des
-- statistiques globales.
create or replace function public.admin_add_historical_match(p_match jsonb)
returns uuid
language plpgsql security definer
set search_path to ''
as $$
declare
  v_id uuid := gen_random_uuid();
  v_opponent_name text := btrim(regexp_replace(coalesce(p_match ->> 'opponent', ''), '\s+', ' ', 'g'));
  v_opponent_id uuid;
  v_date date;
  v_time time;
  v_score_for integer;
  v_score_against integer;
  v_match_type text := case
    when current_setting('app.historical_import_bulk', true) = 'yes'
      then nullif(p_match ->> 'match_type', '')
    else coalesce(nullif(p_match ->> 'match_type', ''), 'championnat')
  end;
  v_is_home boolean := case
    when current_setting('app.historical_import_bulk', true) = 'yes'
      then (p_match ->> 'is_home')::boolean
    else coalesce((p_match ->> 'is_home')::boolean, true)
  end;
  v_address text := nullif(btrim(coalesce(p_match ->> 'address', '')), '');
  v_formation text := nullif(btrim(coalesce(p_match ->> 'formation', '')), '');
  v_field jsonb := '[]'::jsonb;
  v_bench jsonb := '[]'::jsonb;
  v_present jsonb := '[]'::jsonb;
  v_scorers jsonb := '[]'::jsonb;
  v_motm jsonb := '[]'::jsonb;
  v_entry jsonb;
  v_name text;
  v_goals integer;
  v_scorer_goals integer := 0;
  v_x numeric;
  v_y numeric;
begin
  if not (select private.is_admin()) then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;
  if p_match is null or jsonb_typeof(p_match) <> 'object' then
    raise exception 'Match manquant.' using errcode = '22023';
  end if;

  -- Affiche
  if char_length(v_opponent_name) < 2 or char_length(v_opponent_name) > 100 then
    raise exception 'Indique le nom de l’adversaire (2 à 100 caractères).' using errcode = '22023';
  end if;
  begin
    v_date := (p_match ->> 'date')::date;
    v_time := nullif(p_match ->> 'time', '')::time;
    v_score_for := (p_match ->> 'score_for')::integer;
    v_score_against := (p_match ->> 'score_against')::integer;
  exception when others then
    raise exception 'Date, heure ou score illisible.' using errcode = '22023';
  end;
  if v_date is null then
    raise exception 'Indique la date du match.' using errcode = '22023';
  end if;
  if v_date > current_date then
    raise exception 'Un match à venir ne peut pas être ajouté à l’historique.' using errcode = '22023';
  end if;
  if v_date >= private.history_entry_cutoff()
     and current_setting('app.historical_import_bulk', true) is distinct from 'yes' then
    raise exception 'Ce match appartient à une saison suivie dans l’application : il se saisit depuis le calendrier.'
      using errcode = '22023';
  end if;
  if v_score_for is null or v_score_against is null
     or v_score_for not between 0 and 99 or v_score_against not between 0 and 99 then
    raise exception 'Indique le score (0 à 99).' using errcode = '22023';
  end if;
  if v_match_type is not null and v_match_type not in ('championnat', 'amical') then
    raise exception 'Type de match inconnu.' using errcode = '22023';
  end if;
  if v_address is not null and char_length(v_address) > 200 then
    raise exception 'Le lieu est trop long.' using errcode = '22023';
  end if;

  -- Adversaire : réutilisé s'il existe déjà sous ce nom.
  select opponent.id into v_opponent_id
  from public.opponents opponent
  where lower(btrim(opponent.name)) = lower(v_opponent_name)
  order by opponent.created_at
  limit 1;
  if v_opponent_id is null then
    insert into public.opponents (name) values (v_opponent_name)
    returning id into v_opponent_id;
  end if;

  -- Composition : titulaires placés sur le terrain.
  for v_entry in select * from jsonb_array_elements(coalesce(p_match -> 'starters', '[]'::jsonb)) loop
    v_name := private.history_entry_name(v_entry);
    v_x := least(greatest(coalesce((v_entry ->> 'x_pct')::numeric, 50), 0), 100);
    v_y := least(greatest(coalesce((v_entry ->> 'y_pct')::numeric, 50), 0), 100);
    v_field := v_field || jsonb_build_array(jsonb_build_object(
      'name', v_name,
      'is_gk', coalesce((v_entry ->> 'is_gk')::boolean, false),
      'x_pct', v_x,
      'y_pct', v_y,
      'position_code', nullif(v_entry ->> 'position_code', ''),
      'position_label', nullif(v_entry ->> 'position_label', '')
    ));
    v_present := v_present || to_jsonb(v_name);
  end loop;

  for v_entry in select * from jsonb_array_elements(coalesce(p_match -> 'bench', '[]'::jsonb)) loop
    v_name := private.history_entry_name(v_entry);
    v_bench := v_bench || to_jsonb(v_name);
    v_present := v_present || to_jsonb(v_name);
  end loop;

  -- Effectif : les présents qui ne figurent pas dans la composition.
  for v_entry in select * from jsonb_array_elements(coalesce(p_match -> 'present', '[]'::jsonb)) loop
    v_name := private.history_entry_name(v_entry);
    v_present := v_present || to_jsonb(v_name);
  end loop;

  for v_entry in select * from jsonb_array_elements(coalesce(p_match -> 'scorers', '[]'::jsonb)) loop
    v_name := private.history_entry_name(v_entry);
    v_goals := coalesce((v_entry ->> 'goals')::integer, 1);
    if v_goals not between 1 and 99 then
      raise exception 'Nombre de buts invalide pour « % ».', v_name using errcode = '22023';
    end if;
    v_scorer_goals := v_scorer_goals + v_goals;
    v_scorers := v_scorers || jsonb_build_array(jsonb_build_object('name', v_name, 'goals', v_goals));
    v_present := v_present || to_jsonb(v_name);
  end loop;
  if v_scorer_goals > v_score_for then
    raise exception 'Les buteurs totalisent % buts pour un score de %.', v_scorer_goals, v_score_for
      using errcode = '22023';
  end if;

  for v_entry in select * from jsonb_array_elements(coalesce(p_match -> 'motm', '[]'::jsonb)) loop
    v_name := private.history_entry_name(v_entry);
    v_motm := v_motm || to_jsonb(v_name);
    v_present := v_present || to_jsonb(v_name);
  end loop;

  -- Une seule fois chaque nom dans la liste des présents.
  select coalesce(jsonb_agg(distinct name), '[]'::jsonb) into v_present
  from jsonb_array_elements_text(v_present) as present(name);

  insert into public.historical_match_scores (
    id, opponent_id, match_date, score_as_grinta, score_adverse,
    is_home, match_time, address, match_type
  ) values (
    v_id, v_opponent_id, v_date, v_score_for, v_score_against,
    v_is_home, v_time, v_address, v_match_type
  );

  -- Les joueurs du match sont reliés à leur fiche par le déclencheur des
  -- archives (historical_match_players).
  insert into public.historical_match_details (
    match_id, formation, field_players, bench_players, present_names, scorers, motm_names
  ) values (
    v_id, case when jsonb_array_length(v_field) > 0 then v_formation end,
    v_field, v_bench, v_present, v_scorers, v_motm
  );

  if current_setting('app.historical_import_bulk', true) is distinct from 'yes' then
    perform private.rebuild_historical_statistics();
  end if;
  return v_id;
end;
$$;

create or replace function private.rebuild_historical_statistics()
returns void
language plpgsql security definer
set search_path to ''
as $$
declare
  v_previous_season text;
  v_through_season text;
begin
  -- La saison précédant la première saison suivie dans l'application.
  select (min(substring(season.name from 1 for 4)::integer) - 1)
         || '-' || min(substring(season.name from 1 for 4)::integer)
    into v_previous_season
  from public.seasons season;

  delete from public.historical_player_statistics
  where club_id = (select private.current_club_id());

  -- Une ligne par joueur et par période : toutes les archives, puis la
  -- seule saison précédant l'application.
  with match_row as (
    select score.id, score.match_date,
      score.score_as_grinta as goals_for,
      score.score_adverse as goals_against,
      private.history_season_name(score.match_date) as season_name
    from public.historical_match_scores score
  ),
  scope_row as (
    select 'all_time'::text as scope, null::text as season_name
    union all
    select 'previous', v_previous_season where v_previous_season is not null
  ),
  identity as (
    select player.id as player_id,
      coalesce(
        (select nullif(btrim(concat_ws(' ', sp.first_name, nullif(sp.last_name, ''))), '')
         from public.season_players sp
         where sp.player_id = player.id
         order by sp.joined_at desc limit 1),
        nullif(btrim(player.display_name), '')
      ) as full_name,
      (select sp.is_goalkeeper from public.season_players sp
       where sp.player_id = player.id
       order by sp.joined_at desc limit 1) as roster_goalkeeper,
      (select profile.id from public.profiles profile
       where profile.player_id = player.id
       order by profile.created_at limit 1) as profile_id
    from public.players player
  ),
  per_player as (
    select scope.scope, scope.season_name, hmp.player_id,
      coalesce(max(identity.full_name), min(hmp.source_name)) as player_name,
      coalesce(bool_or(identity.roster_goalkeeper), bool_or(hmp.is_goalkeeper), false) as is_goalkeeper,
      max(identity.profile_id::text)::uuid as profile_id,
      count(*)::integer as matches_played,
      count(*) filter (where m.goals_for > m.goals_against)::integer as wins,
      count(*) filter (where m.goals_for = m.goals_against)::integer as draws,
      count(*) filter (where m.goals_for < m.goals_against)::integer as losses,
      coalesce(sum(hmp.goals), 0)::integer as goals,
      count(*) filter (where hmp.is_motm)::integer as hdm,
      count(*) filter (where m.goals_against = 0 and coalesce(hmp.is_goalkeeper, false))::integer as keeper_clean_sheets,
      count(*) filter (where m.goals_against = 0)::integer as team_clean_sheets
    from public.historical_match_players hmp
    join match_row m on m.id = hmp.match_id
    join scope_row scope
      on scope.season_name is null or scope.season_name = m.season_name
    left join identity on identity.player_id = hmp.player_id
    group by scope.scope, scope.season_name, hmp.player_id
  ),
  named as (
    select per_player.*,
      -- Deux joueurs du même nom : le second est distingué, la ligne de
      -- statistiques exige un nom unique par période.
      case when row_number() over (
        partition by scope, lower(btrim(player_name)) order by matches_played desc, player_id
      ) = 1 then player_name
      else player_name || ' (' || row_number() over (
        partition by scope, lower(btrim(player_name)) order by matches_played desc, player_id
      ) || ')' end as unique_name
    from per_player
  )
  insert into public.historical_player_statistics (
    scope, season_name, display_rank, player_name, is_goalkeeper,
    matches_played, wins, draws, losses, goals, hdm, clean_sheets,
    team_clean_sheets, profile_id, player_id, source_label
  )
  select scope, season_name,
    rank() over (
      partition by scope, is_goalkeeper
      order by case when is_goalkeeper then keeper_clean_sheets else goals end desc
    )::integer,
    unique_name, is_goalkeeper,
    matches_played, wins, draws, losses, goals, hdm,
    case when is_goalkeeper then keeper_clean_sheets else 0 end,
    team_clean_sheets, profile_id, player_id, 'saisie_administrateur'
  from named;

  -- Bilan d'équipe des archives : sert de point de départ aux statistiques
  -- « Toutes saisons », complété ensuite par les saisons de l'application.
  delete from public.historical_team_statistics
  where club_id = (select private.current_club_id());

  select private.history_season_name(max(score.match_date))
    into v_through_season
  from public.historical_match_scores score;

  if v_through_season is null then
    return;
  end if;

  -- Le référentiel toutes saisons doit inclure aussi les matchs de
  -- l'application pendant une saison où l'on a importé des archives.
  -- La période de référence reste la veille de la première saison suivie.
  if v_previous_season is not null
     and v_through_season > v_previous_season then
    v_through_season := v_previous_season;
  end if;

  with ordered as (
    select score.id, score.match_date,
      score.score_as_grinta - score.score_adverse as margin,
      case
        when score.score_as_grinta > score.score_adverse then 'V'
        when score.score_as_grinta = score.score_adverse then 'N'
        else 'D'
      end as result,
      row_number() over (order by score.match_date, score.match_time nulls first, score.id) as seq
    from public.historical_match_scores score
  ),
  kinds as (
    select kind, ordered.*,
      case kind
        when 'win' then result = 'V'
        when 'unbeaten' then result in ('V', 'N')
        when 'loss' then result = 'D'
        else result in ('N', 'D')
      end as qualifies
    from ordered
    cross join (values ('win'), ('unbeaten'), ('loss'), ('winless')) as k(kind)
  ),
  islands as (
    select kind, match_date,
      seq - row_number() over (partition by kind order by seq) as island
    from kinds
    where qualifies
  ),
  streaks as (
    select kind, count(*)::integer as streak_length,
      min(match_date) as start_date, max(match_date) as end_date,
      row_number() over (
        partition by kind order by count(*) desc, max(match_date) desc
      ) as streak_rank
    from islands
    group by kind, island
  ),
  best as (
    select kind, streak_length, start_date, end_date
    from streaks where streak_rank = 1
  ),
  recent as (
    select coalesce(array_agg(result order by seq), array[]::text[]) as results
    from (select result, seq from ordered order by seq desc limit 6) last_six
  ),
  margins as (
    select coalesce(jsonb_object_agg(margin::text, cnt order by margin), '{}'::jsonb) as distribution
    from (select margin, count(*)::integer as cnt from ordered group by margin) m
  )
  insert into public.historical_team_statistics (
    scope, through_season, matches_played, wins, draws, losses,
    goals_for, goals_against,
    best_win_streak, best_win_start, best_win_end,
    best_unbeaten_streak, best_unbeaten_start, best_unbeaten_end,
    worst_loss_streak, worst_loss_start, worst_loss_end,
    worst_winless_streak, worst_winless_start, worst_winless_end,
    recent_results, score_margin_distribution, updated_at
  )
  select 'all_time', v_through_season,
    count(*)::integer,
    count(*) filter (where score.score_as_grinta > score.score_adverse)::integer,
    count(*) filter (where score.score_as_grinta = score.score_adverse)::integer,
    count(*) filter (where score.score_as_grinta < score.score_adverse)::integer,
    coalesce(sum(score.score_as_grinta), 0)::integer,
    coalesce(sum(score.score_adverse), 0)::integer,
    coalesce((select streak_length from best where kind = 'win'), 0),
    (select start_date from best where kind = 'win'),
    (select end_date from best where kind = 'win'),
    coalesce((select streak_length from best where kind = 'unbeaten'), 0),
    (select start_date from best where kind = 'unbeaten'),
    (select end_date from best where kind = 'unbeaten'),
    coalesce((select streak_length from best where kind = 'loss'), 0),
    (select start_date from best where kind = 'loss'),
    (select end_date from best where kind = 'loss'),
    coalesce((select streak_length from best where kind = 'winless'), 0),
    (select start_date from best where kind = 'winless'),
    (select end_date from best where kind = 'winless'),
    (select results from recent),
    (select distribution from margins),
    now()
  from public.historical_match_scores score;
end;
$$;

create or replace function private.recalculate_upcoming_odds_after_history_change()
returns trigger
language plpgsql security definer
set search_path to ''
as $$
begin
  if current_setting('app.historical_import_bulk', true) = 'yes' then
    return null;
  end if;
  perform public.recalculate_upcoming_match_odds_v4();
  return null;
end;
$$;

-- Import atomique d'archives Petit Filet v1 (réservé à l'admin de l'équipe).
-- Lot complet dans une seule transaction ; aucun accès à AS Grinta original.
-- Le droit de la fonction reste limité au rôle club_scope comme la saisie manuelle.
create function public.admin_import_historical_matches(p_document jsonb)
returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_rows jsonb;
  v_row jsonb;
  v_date date;
  v_opponent text;
  v_key text;
  v_seen jsonb := '{}'::jsonb;
  v_signature text;
  v_current_club uuid;
  v_existing record;
  v_modern record;
  v_imported integer := 0;
  v_skipped integer := 0;
begin
  if not (select private.is_admin()) then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;
  if p_document is null or jsonb_typeof(p_document) <> 'object'
     or p_document ->> 'format' is distinct from 'petit-filet-historique'
     or p_document ->> 'version' is distinct from '1'
     or jsonb_typeof(p_document -> 'matches') is distinct from 'array' then
    raise exception 'Format d’historique incorrect : Petit Filet v1 requis.'
      using errcode = '22023';
  end if;
  v_rows := p_document -> 'matches';
  if jsonb_array_length(v_rows) < 1 or jsonb_array_length(v_rows) > 400 then
    raise exception 'Un fichier doit contenir de 1 à 400 matchs.'
      using errcode = '22023';
  end if;
  v_current_club := (select private.current_club_id());
  if v_current_club is null then
    raise exception 'Équipe introuvable.' using errcode = '42501';
  end if;

  -- Empêche deux imports concurrents du même club de créer le même match.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_current_club::text || ':history-import', 0)
  );

  perform set_config('app.historical_import_bulk', 'yes', true);
  for v_row in select value from jsonb_array_elements(v_rows) loop
    if jsonb_typeof(v_row) <> 'object' then
      raise exception 'Une ligne de match est invalide.' using errcode = '22023';
    end if;
    if jsonb_typeof(v_row -> 'score_for') is distinct from 'number'
       or jsonb_typeof(v_row -> 'score_against') is distinct from 'number'
       or (v_row ? 'is_home'
           and jsonb_typeof(v_row -> 'is_home') <> 'boolean')
       or (v_row ? 'match_type'
           and v_row ->> 'match_type' not in ('amical', 'championnat')) then
      raise exception 'Date, score ou propriété optionnelle invalide.'
        using errcode = '22023';
    end if;
    begin
      v_date := (v_row ->> 'date')::date;
    exception when others then
      raise exception 'Date illisible dans le document.' using errcode = '22023';
    end;
    if v_date is null or v_date > current_date then
      raise exception 'Match hors de la période historique autorisée.' using errcode = '22023';
    end if;
    v_opponent := btrim(regexp_replace(coalesce(v_row ->> 'opponent', ''), '\s+', ' ', 'g'));
    if char_length(v_opponent) < 2 or char_length(v_opponent) > 100 then
      raise exception 'Nom d’adversaire invalide.' using errcode = '22023';
    end if;
    v_key := v_date::text || '|' || lower(v_opponent);
    v_signature := (v_row ->> 'score_for') || '/' ||
                   (v_row ->> 'score_against') || '/' ||
                   coalesce(v_row ->> 'is_home', '?') || '/' ||
                   coalesce(v_row ->> 'match_type', '?');
    if v_seen ? v_key then
      if v_seen ->> v_key is distinct from v_signature then
        raise exception 'Deux matchs contradictoires le même jour contre %.',
          v_opponent using errcode = '22023';
      end if;
      v_skipped := v_skipped + 1;
      continue;
    end if;
    v_seen := v_seen || jsonb_build_object(v_key, v_signature);

    select score.score_as_grinta, score.score_adverse, score.is_home,
           score.match_type
      into v_existing
    from public.historical_match_scores score
    join public.opponents opponent on opponent.id = score.opponent_id
    where score.club_id = v_current_club
      and opponent.club_id = v_current_club
      and score.match_date = v_date
      and lower(btrim(opponent.name)) = lower(v_opponent)
    limit 1;
    if found then
      if v_existing.score_as_grinta = (v_row ->> 'score_for')::integer
         and v_existing.score_adverse = (v_row ->> 'score_against')::integer
         and (not (v_row ? 'is_home') or
              v_existing.is_home is not distinct from (v_row ->> 'is_home')::boolean)
         and (not (v_row ? 'match_type') or
              v_existing.match_type is not distinct from v_row ->> 'match_type') then
        v_skipped := v_skipped + 1;
        continue;
      end if;
      raise exception 'Match déjà présent avec des valeurs différentes : % contre %.',
        v_date, v_opponent using errcode = '22023';
    end if;

    -- Même saison déjà suivie : une rencontre moderne prime sur
    -- l'import. Un match identique est ignoré ; un conflit bloque tout.
    select m.score_as_grinta, m.score_adverse, m.location,
           m.match_type, m.status
      into v_modern
    from public.matches m
    join public.opponents opponent on opponent.id = m.opponent_id
    where m.club_id = v_current_club
      and opponent.club_id = v_current_club
      and m.match_date = v_date
      and lower(btrim(opponent.name)) = lower(v_opponent)
    limit 1;
    if found then
      if v_modern.status in ('termine', 'archive')
         and v_modern.score_as_grinta = (v_row ->> 'score_for')::integer
         and v_modern.score_adverse = (v_row ->> 'score_against')::integer
         and (not (v_row ? 'is_home') or
              (v_modern.location = 'domicile') = (v_row ->> 'is_home')::boolean)
         and (not (v_row ? 'match_type') or
              v_modern.match_type = v_row ->> 'match_type') then
        v_skipped := v_skipped + 1;
        continue;
      end if;
      raise exception 'Match déjà présent dans le calendrier de Petit Filet : % contre %.',
        v_date, v_opponent using errcode = '22023';
    end if;

    -- Réutilise exactement les validations et les liens joueur de la saisie.
    perform public.admin_add_historical_match(v_row);
    v_imported := v_imported + 1;
  end loop;
  perform set_config('app.historical_import_bulk', '', true);
  if v_imported > 0 then
    perform private.rebuild_historical_statistics();
    perform public.recalculate_upcoming_match_odds_v4();
  end if;
  return jsonb_build_object('imported', v_imported, 'skipped', v_skipped);
end;
$$;

alter function public.admin_import_historical_matches(jsonb) owner to club_scope;
revoke all on function public.admin_import_historical_matches(jsonb)
  from public, anon, authenticated;
grant execute on function public.admin_import_historical_matches(jsonb)
  to authenticated, service_role, club_scope;
