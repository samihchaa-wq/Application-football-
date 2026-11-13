-- Saisie de l'historique des matchs par l'administrateur.
--
-- Le club d'origine avait importé tout son passé depuis une autre
-- application. Un nouveau club n'a pas cette possibilité : son administrateur
-- peut maintenant ajouter lui-même un match passé (adversaire, date, lieu,
-- score, buteurs, homme du match, composition, joueurs présents).
--
-- Ces matchs rejoignent les tables d'archives déjà lues par l'application
-- (calendrier, fiche de match archivé, fiche joueur). Après chaque ajout ou
-- suppression, les statistiques « Toutes saisons » sont recalculées à partir
-- de ces archives.
--
-- Un match d'archive est antérieur à la première saison suivie dans
-- l'application : les saisons suivies ont leurs propres matchs, et compter
-- deux fois la même période fausserait les statistiques.

-- ---------------------------------------------------------------------------
-- 1. Date limite : début de la première saison suivie dans l'application
-- ---------------------------------------------------------------------------
create function private.history_entry_cutoff()
returns date
language sql stable security definer
set search_path to ''
as $$
  -- Une saison « 2025-2026 » commence le 1er juillet 2025, comme partout
  -- ailleurs dans l'application. Sans saison, la limite est demain.
  select least(
    coalesce(
      (select make_date(min(substring(season.name from 1 for 4)::integer), 7, 1)
       from public.seasons season),
      current_date + 1
    ),
    current_date + 1
  );
$$;

-- Saison d'une date, au format « 2025-2026 ».
create function private.history_season_name(p_date date)
returns text
language sql immutable strict
set search_path to ''
as $$
  select case
    when extract(month from p_date) >= 7
      then extract(year from p_date)::integer || '-' || (extract(year from p_date)::integer + 1)
    else (extract(year from p_date)::integer - 1) || '-' || extract(year from p_date)::integer
  end;
$$;

-- ---------------------------------------------------------------------------
-- 2. Recalcul des statistiques d'archives du club courant
-- ---------------------------------------------------------------------------
create function private.rebuild_historical_statistics()
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

-- ---------------------------------------------------------------------------
-- 3. Ce dont le formulaire a besoin : date limite, joueurs, adversaires
-- ---------------------------------------------------------------------------
create function public.admin_get_history_entry_context()
returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
begin
  if not (select private.is_admin()) then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;

  return jsonb_build_object(
    -- Dernier jour autorisé (inclus).
    'last_allowed_date', least(private.history_entry_cutoff() - 1, current_date),
    'players', coalesce((
      select jsonb_agg(jsonb_build_object(
          'player_id', roster.player_id,
          'name', roster.full_name,
          'display_name', roster.display_name,
          'is_goalkeeper', roster.is_goalkeeper,
          'photo_url', roster.photo_url,
          'in_current_roster', roster.in_current_roster
        ) order by not roster.in_current_roster, lower(roster.display_name))
      from (
        select distinct on (sp.player_id)
          sp.player_id,
          btrim(concat_ws(' ', sp.first_name, nullif(sp.last_name, ''))) as full_name,
          coalesce(nullif(btrim(profile.surnom), ''), nullif(btrim(profile.first_name), ''),
            btrim(sp.first_name)) as display_name,
          sp.is_goalkeeper,
          coalesce(profile.photo_url, sp.photo_url) as photo_url,
          exists (
            select 1 from public.season_players current_sp
            join public.seasons season on season.id = current_sp.season_id
            where current_sp.player_id = sp.player_id
              and season.status = 'open' and current_sp.is_active
          ) as in_current_roster
        from public.season_players sp
        left join public.profiles profile on profile.id = sp.profile_id
        where not sp.is_coach
        order by sp.player_id, sp.joined_at desc
      ) roster
    ), '[]'::jsonb),
    -- Anciens joueurs déjà saisis sans compte dans l'application.
    'former_players', coalesce((
      select jsonb_agg(distinct link.source_name order by link.source_name)
      from public.historical_player_name_links link
      where not exists (
        select 1 from public.season_players sp where sp.player_id = link.player_id
      )
    ), '[]'::jsonb),
    'opponents', coalesce((
      select jsonb_agg(opponent.name order by lower(opponent.name))
      from public.opponents opponent
    ), '[]'::jsonb)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. Ajout d'un match passé
-- ---------------------------------------------------------------------------
-- Un joueur est envoyé sous la forme {"name": "...", "player_id": "..."} ;
-- player_id est absent pour un ancien joueur qui n'a pas de fiche.
create function private.history_entry_name(p_player jsonb)
returns text
language plpgsql security definer
set search_path to ''
as $$
declare
  v_name text := nullif(btrim(regexp_replace(coalesce(p_player ->> 'name', ''), '\s+', ' ', 'g')), '');
  v_player_id uuid := nullif(p_player ->> 'player_id', '')::uuid;
  v_linked uuid;
begin
  if v_name is null then
    raise exception 'Un joueur n’a pas de nom.' using errcode = '22023';
  end if;
  if char_length(v_name) > 80 then
    raise exception 'Le nom « % » est trop long.', left(v_name, 20) using errcode = '22023';
  end if;

  if v_player_id is not null then
    if not exists (select 1 from public.players player where player.id = v_player_id) then
      raise exception 'Joueur inconnu.' using errcode = '22023';
    end if;
    -- Le nom saisi désigne désormais ce joueur dans les archives.
    insert into public.historical_player_name_links (normalized_name, source_name, player_id)
    values (private.normalize_player_name(v_name), v_name, v_player_id)
    on conflict (club_id, normalized_name) do nothing;

    select link.player_id into v_linked
    from public.historical_player_name_links link
    where link.normalized_name = private.normalize_player_name(v_name);
    if v_linked is distinct from v_player_id then
      raise exception 'Deux joueurs différents portent le nom « % ». Ajoute une initiale pour les distinguer.', v_name
        using errcode = '22023';
    end if;
  end if;

  return v_name;
end;
$$;

create function public.admin_add_historical_match(p_match jsonb)
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
  v_match_type text := coalesce(nullif(p_match ->> 'match_type', ''), 'championnat');
  v_is_home boolean := coalesce((p_match ->> 'is_home')::boolean, true);
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
  if v_date >= private.history_entry_cutoff() then
    raise exception 'Ce match appartient à une saison suivie dans l’application : il se saisit depuis le calendrier.'
      using errcode = '22023';
  end if;
  if v_score_for is null or v_score_against is null
     or v_score_for not between 0 and 99 or v_score_against not between 0 and 99 then
    raise exception 'Indique le score (0 à 99).' using errcode = '22023';
  end if;
  if v_match_type not in ('championnat', 'amical') then
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

  perform private.rebuild_historical_statistics();
  return v_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- 5. Suppression d'un match d'archive (erreur de saisie)
-- ---------------------------------------------------------------------------
create function public.admin_delete_historical_match(p_match_id uuid)
returns boolean
language plpgsql security definer
set search_path to ''
as $$
begin
  if not (select private.is_admin()) then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;

  delete from public.historical_match_scores score where score.id = p_match_id;
  if not found then
    return false;
  end if;

  perform private.rebuild_historical_statistics();
  return true;
end;
$$;

-- ---------------------------------------------------------------------------
-- 6. Droits : fonctions exécutées dans le périmètre du club
-- ---------------------------------------------------------------------------
do $$
declare
  v_signature text;
begin
  foreach v_signature in array array[
    'private.history_entry_cutoff()',
    'private.rebuild_historical_statistics()',
    'private.history_entry_name(jsonb)'
  ] loop
    execute format('alter function %s owner to club_scope', v_signature);
    execute format('revoke all on function %s from public, anon, authenticated', v_signature);
    execute format('grant execute on function %s to club_scope, service_role', v_signature);
  end loop;

  foreach v_signature in array array[
    'public.admin_get_history_entry_context()',
    'public.admin_add_historical_match(jsonb)',
    'public.admin_delete_historical_match(uuid)'
  ] loop
    execute format('alter function %s owner to club_scope', v_signature);
    execute format('revoke all on function %s from public, anon', v_signature);
    execute format('grant execute on function %s to authenticated, service_role, club_scope', v_signature);
  end loop;
end;
$$;

revoke all on function private.history_season_name(date) from public, anon, authenticated;
grant execute on function private.history_season_name(date) to club_scope, service_role;
