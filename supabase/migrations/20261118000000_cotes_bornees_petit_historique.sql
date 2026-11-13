-- Cotes bornées quand le club a peu de matchs.
--
-- Problème constaté à l'écran (Club Test A, 13/11/2026) : un club dont tout
-- l'historique est une seule victoire obtenait des cotes de 1,00 (victoire)
-- et 1 000 001,18 (défaite). La forme vaut alors 100 % de victoires et, sans
-- confrontation contre l'adversaire, la probabilité de gagner était bornée à
-- 0,999999 : quasiment l'infini pour la défaite et le nul. Tout nouveau club
-- tombe dans ce cas après sa première victoire (ou sa première défaite).
--
-- Correction : la probabilité est bornée entre 10 % et 90 %. Pire cas :
-- environ 1,24 / 9,33 / 11,20. Un club qui a un vrai historique (cas
-- d'AS Grinta) reste dans cette plage : ses cotes ne changent pas.
-- Seule la ligne de bornage change par rapport à 20261116020000.

create or replace function public.calculate_match_odds_v5(p_opponent_id uuid, p_reference_date date)
returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_ref date := coalesce(p_reference_date, current_date);
  v_h_v numeric := 0;
  v_h_d numeric := 0;
  v_form_v numeric := 0;
  v_form_d numeric := 0;
  v_q_forme numeric;
  v_q numeric;
  v_cote_v_prov numeric;
  v_cote_d_prov numeric;
  v_cote_n_prov numeric;
  v_u_v numeric;
  v_u_n numeric;
  v_u_d numeric;
  v_s numeric;
  v_p_v numeric;
  v_p_n numeric;
  v_p_d numeric;
  -- Réglages du club (valeurs d'origine par défaut : 900 j, 180 j, × 1,5).
  v_h2h_days numeric := private.club_rule('odds_h2h_memory_days')::numeric;
  v_form_days numeric := private.club_rule('odds_form_memory_days')::numeric;
  v_draw_factor numeric := private.club_rule('odds_draw_factor')::numeric / 10;
begin
  if not exists (select 1 from public.opponents where id = p_opponent_id) then
    raise exception 'Adversaire introuvable';
  end if;

  -- Club sans cotes : chaque issue vaut 1, le barème seul fait les points.
  if private.club_rule('odds_mode') = 1 then
    return jsonb_build_object(
      'win', 1.00, 'draw', 1.00, 'loss', 1.00,
      'probability_win', round(1.0 / 3, 6),
      'probability_draw', round(1.0 / 3, 6),
      'probability_loss', round(1.0 / 3, 6),
      'model_version', 'club_without_odds'
    );
  end if;

  with all_results as (
    select m.id, m.opponent_id, m.match_date,
      m.score_as_grinta, m.score_adverse
    from public.matches m
    where m.status = 'termine'
      and m.score_as_grinta is not null
      and m.score_adverse is not null
    union all
    select h.id, h.opponent_id, h.match_date,
      h.score_as_grinta::integer, h.score_adverse::integer
    from public.historical_match_scores h
  ), h2h as (
    select
      case
        when r.score_as_grinta > r.score_adverse then 'V'
        when r.score_as_grinta = r.score_adverse then 'N'
        else 'D'
      end as result,
      row_number() over (
        order by r.match_date desc, r.id desc
      ) as rang,
      greatest(0, (v_ref - r.match_date))::numeric as age
    from all_results r
    where r.opponent_id = p_opponent_id
      and r.match_date < v_ref
  ), weighted as (
    select result,
      case
        when rang <= 5 then
          (array[1.0, 0.95, 0.90, 0.85, 0.80])[rang::int]
            * power(0.5::numeric, age / v_h2h_days)
        else
          0.35 * power(0.75::numeric, (rang - 6)::numeric)
            * power(0.5::numeric, age / v_h2h_days)
      end as poids
    from h2h
  )
  select
    coalesce(sum(poids) filter (where result = 'V'), 0),
    coalesce(sum(poids) filter (where result = 'D'), 0)
  into v_h_v, v_h_d
  from weighted;

  with all_results as (
    select m.id, m.match_date, m.score_as_grinta, m.score_adverse
    from public.matches m
    where m.status = 'termine'
      and m.score_as_grinta is not null
      and m.score_adverse is not null
    union all
    select h.id, h.match_date,
      h.score_as_grinta::integer, h.score_adverse::integer
    from public.historical_match_scores h
  ), form as (
    select
      case
        when r.score_as_grinta > r.score_adverse then 'V'
        when r.score_as_grinta = r.score_adverse then 'N'
        else 'D'
      end as result,
      power(
        0.5::numeric,
        greatest(0, (v_ref - r.match_date))::numeric / v_form_days
      ) as poids
    from all_results r
    where r.match_date < v_ref
  )
  select
    coalesce(sum(poids) filter (where result = 'V'), 0),
    coalesce(sum(poids) filter (where result = 'D'), 0)
  into v_form_v, v_form_d
  from form;

  if (v_form_v + v_form_d) = 0 then
    v_q_forme := 0.50;
  else
    v_q_forme := v_form_v / (v_form_v + v_form_d);
  end if;

  v_q := (1.0 * v_q_forme + v_h_v) / (1.0 + v_h_v + v_h_d);
  v_q := least(0.90, greatest(0.10, v_q));

  v_cote_v_prov := 1.0 / v_q;
  v_cote_d_prov := 1.0 / (1.0 - v_q);
  v_cote_n_prov := ((v_cote_v_prov + v_cote_d_prov) / 2.0) * v_draw_factor;

  v_u_v := 1.0 / v_cote_v_prov;
  v_u_n := 1.0 / v_cote_n_prov;
  v_u_d := 1.0 / v_cote_d_prov;
  v_s := v_u_v + v_u_n + v_u_d;
  v_p_v := v_u_v / v_s;
  v_p_n := v_u_n / v_s;
  v_p_d := v_u_d / v_s;

  return jsonb_build_object(
    'win', round(1.0 / v_p_v, 2),
    'draw', round(1.0 / v_p_n, 2),
    'loss', round(1.0 / v_p_d, 2),
    'probability_win', round(v_p_v, 6),
    'probability_draw', round(v_p_n, 6),
    'probability_loss', round(v_p_d, 6),
    'q_decisive', round(v_q, 6),
    'q_form', round(v_q_forme, 6),
    'h2h_win_weight', round(v_h_v, 6),
    'h2h_loss_weight', round(v_h_d, 6),
    'model_version', 'compact_history_v6'
  );
end;
$$;


-- Les matchs à venir de chaque club reprennent des cotes raisonnables.
do $$
declare
  v_club record;
begin
  for v_club in select id from public.clubs loop
    perform set_config('app.club_id', v_club.id::text, true);
    perform public.recalculate_upcoming_match_odds_v4();
  end loop;
  perform set_config('app.club_id', '', true);
end;
$$;
