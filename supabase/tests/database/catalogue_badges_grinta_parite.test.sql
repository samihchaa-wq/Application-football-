-- Catalog parity checks against the current, versioned AS Grinta seed.
-- No player data and no production access to the original app are needed.
-- Run after the 20261121000000 import and 20261122090002 icon migration.
begin;
set local search_path = public, extensions, pg_catalog;
select no_plan();

create temporary table expected_original_badges (code text primary key) on commit drop;
insert into expected_original_badges (code) values
    ('matches_played_season__15'),
    ('matches_played_season__20'),
    ('matches_played_season__25'),
    ('matches_played_season__30'),
    ('matches_played__50'),
    ('matches_played__100'),
    ('matches_played__150'),
    ('matches_played__200'),
    ('goals_season__5'),
    ('goals_season__10'),
    ('goals_season__20'),
    ('goals_season__30'),
    ('goals__25'),
    ('goals__50'),
    ('goals__75'),
    ('goals__100'),
    ('wins_season__10'),
    ('wins_season__15'),
    ('wins_season__20'),
    ('wins_season__25'),
    ('wins__50'),
    ('wins__100'),
    ('wins__150'),
    ('wins__200'),
    ('clean_sheets_season__3'),
    ('clean_sheets_season__5'),
    ('clean_sheets_season__7'),
    ('clean_sheets_season__10'),
    ('clean_sheets__10'),
    ('clean_sheets__20'),
    ('clean_sheets__30'),
    ('clean_sheets__50'),
    ('mvp__10'),
    ('mvp__20'),
    ('mvp__30'),
    ('mvp__50'),
    ('max_match_goals__3'),
    ('max_match_goals__4'),
    ('max_match_goals__5'),
    ('title_most_present__1'),
    ('title_top_scorer__1'),
    ('title_best_winrate__1'),
    ('title_mvp_king__1'),
    ('title_best_pred_player__1'),
    ('title_best_pred_match__1'),
    ('title_best_pred_overall__1'),
    ('bet_against_grinta__1'),
    ('exploit_remplace_gardien'),
    ('exploit_penalty_provoque'),
    ('exploit_penalty_subi'),
    ('exploit_but_vainqueur_tardif'),
    ('exploit_csc'),
    ('role_president'),
    ('role_coach');

select is(
  (select count(*) from expected_original_badges),
  54::bigint, '54 distinct badges in the versioned AS Grinta seed'
);

select ok(
  not exists (
    select 1 from expected_original_badges e
    where not exists (select 1 from private.badge_templates t where t.code=e.code)
  ),
  'All 54 badges from the current original seed exist as future-club templates'
);

select ok(
  not exists (
    select 1 from public.clubs c
    cross join expected_original_badges e
    where not exists (
      select 1 from public.badges b where b.club_id=c.id and b.code=e.code
    )
  ),
  'All clubs have every badge from the current original seed'
);

create temporary table expected_mystery_icons (
  code text primary key, emoji text not null
) on commit drop;
insert into expected_mystery_icons (code, emoji) values
    ('custom_au_four_et_au_moulin_1790198470375', '👨‍🍳'),
    ('custom_remontada_1790198113800', '🔥'),
    ('custom_clutch_1790198314443', '⏱️'),
    ('custom_une_deux_1790776876558', '🔁'),
    ('custom_la_boucle_est_boucl_e_1790777176295', '🔄'),
    ('custom_pr_cher_dans_le_d_sert_1790777232253', '🏜️'),
    ('custom_minimum_syndical_1790777345623', '☝️'),
    ('custom_rira_bien_qui_rira_le_dernier_1790778180908', '😏'),
    ('custom_jamais_2_sans_3_1790777301116', '🎯'),
    ('custom_doubl_hdm_1790772063214', '🌟'),
    ('custom_tripl_chrono_1790937793669', '⏳'),
    ('custom_la_glissade_1790198393809', '🧊'),
    ('custom_r_galade_1790198505439', '🤸'),
    ('custom_la_ligna_amarilla_1790198849385', '🗣️'),
    ('custom_mal_chauff_1790198442991', '🩹'),
    ('custom_c_est_dans_l_lan_1790726366134', '💥'),
    ('custom_voy_a_marcar_1790725466122', '📣'),
    ('custom_t_te_de_boli_1790694926988', '🧠'),
    ('custom_gardien_d_un_soir_1790198294777', '🧤'),
    ('custom_sauvetage_in_extremis_1790725531858', '🛟'),
    ('custom_le_malchanceux_1790198253832', '🙈'),
    ('custom_le_boucher_1790198376585', '🪓'),
    ('custom_le_plongeur_1790198344854', '🤿');

select is(
  (select count(*) from expected_mystery_icons), 23::bigint,
  'All 23 versioned mystery badges have a contextual icon'
);

select is(
  (select count(distinct emoji) from expected_mystery_icons), 23::bigint,
  'The 23 contextual mystery illustrations are distinct'
);

select ok(
  not exists (
    select 1 from expected_mystery_icons e
    where not exists (
      select 1 from private.badge_templates t
      where t.code=e.code and (t.emoji <> '🏅' or t.image_url is not null)
    )
  ),
  'Every known mystery template has its intended illustration or custom art'
);

select ok(
  not exists (
    select 1 from public.clubs c
    cross join expected_mystery_icons e
    where not exists (
      select 1 from public.badges b where b.club_id=c.id and b.code=e.code
        and (b.emoji <> '🏅' or b.image_url is not null)
    )
  ),
  'Every club has its contextual mystery illustrations or custom artwork'
);

select * from finish();
rollback;
