-- Read-only pgTAP checks after importing AS Grinta's documented
-- mystery badges. Counts are per club (including future club templates).
begin;
set local search_path = public, extensions, pg_catalog;
select no_plan();

select is(
  (select count(*) from private.badge_templates
   where code in ('custom_au_four_et_au_moulin_1790198470375',
    'custom_remontada_1790198113800',
    'custom_clutch_1790198314443',
    'custom_une_deux_1790776876558',
    'custom_la_boucle_est_boucl_e_1790777176295',
    'custom_pr_cher_dans_le_d_sert_1790777232253',
    'custom_minimum_syndical_1790777345623',
    'custom_rira_bien_qui_rira_le_dernier_1790778180908',
    'custom_jamais_2_sans_3_1790777301116',
    'custom_doubl_hdm_1790772063214',
    'custom_tripl_chrono_1790937793669',
    'custom_la_glissade_1790198393809',
    'custom_r_galade_1790198505439',
    'custom_la_ligna_amarilla_1790198849385',
    'custom_mal_chauff_1790198442991',
    'custom_c_est_dans_l_lan_1790726366134',
    'custom_voy_a_marcar_1790725466122',
    'custom_t_te_de_boli_1790694926988',
    'custom_gardien_d_un_soir_1790198294777',
    'custom_sauvetage_in_extremis_1790725531858',
    'custom_le_malchanceux_1790198253832',
    'custom_le_boucher_1790198376585',
    'custom_le_plongeur_1790198344854')),
  14::bigint,
  '14 of the 23 imported badges stay templates for new clubs (20261203010000 removed jokes, duplicates and mocking badges)'
);

select is(
  (select count(*) from private.badge_templates
   where code in ('custom_la_glissade_1790198393809',
    'custom_la_ligna_amarilla_1790198849385',
    'custom_mal_chauff_1790198442991',
    'custom_c_est_dans_l_lan_1790726366134',
    'custom_voy_a_marcar_1790725466122',
    'custom_gardien_d_un_soir_1790198294777',
    'custom_le_malchanceux_1790198253832',
    'custom_le_boucher_1790198376585',
    'custom_le_plongeur_1790198344854')),
  0::bigint,
  'New clubs no longer receive AS Grinta inside jokes, duplicates or mocking badges'
);

select ok(
  exists (select 1 from private.badge_templates
          where code = 'custom_t_te_de_boli_1790694926988'
            and name = 'Tête du défenseur')
  and not exists (select 1 from private.badge_templates
                  where kind = 'custom' and btrim(description) = ''),
  'Kept templates carry a neutral name and a real description'
);

select is(
  (select count(*) from private.badge_templates
   where code in ('custom_au_four_et_au_moulin_1790198470375',
    'custom_remontada_1790198113800',
    'custom_clutch_1790198314443',
    'custom_une_deux_1790776876558',
    'custom_la_boucle_est_boucl_e_1790777176295',
    'custom_pr_cher_dans_le_d_sert_1790777232253',
    'custom_minimum_syndical_1790777345623',
    'custom_rira_bien_qui_rira_le_dernier_1790778180908',
    'custom_jamais_2_sans_3_1790777301116',
    'custom_doubl_hdm_1790772063214',
    'custom_tripl_chrono_1790937793669',
    'custom_la_glissade_1790198393809',
    'custom_r_galade_1790198505439',
    'custom_la_ligna_amarilla_1790198849385',
    'custom_mal_chauff_1790198442991',
    'custom_c_est_dans_l_lan_1790726366134',
    'custom_voy_a_marcar_1790725466122',
    'custom_t_te_de_boli_1790694926988',
    'custom_gardien_d_un_soir_1790198294777',
    'custom_sauvetage_in_extremis_1790725531858',
    'custom_le_malchanceux_1790198253832',
    'custom_le_boucher_1790198376585',
    'custom_le_plongeur_1790198344854')
     and auto_rule is not null),
  11::bigint,
  'All 11 automatic badge rules are retained'
);

select ok(
  not exists (
    select 1
    from public.clubs c
    cross join (select code from private.badge_templates
                where code in ('custom_au_four_et_au_moulin_1790198470375',
    'custom_remontada_1790198113800',
    'custom_clutch_1790198314443',
    'custom_une_deux_1790776876558',
    'custom_la_boucle_est_boucl_e_1790777176295',
    'custom_pr_cher_dans_le_d_sert_1790777232253',
    'custom_minimum_syndical_1790777345623',
    'custom_rira_bien_qui_rira_le_dernier_1790778180908',
    'custom_jamais_2_sans_3_1790777301116',
    'custom_doubl_hdm_1790772063214',
    'custom_tripl_chrono_1790937793669',
    'custom_la_glissade_1790198393809',
    'custom_r_galade_1790198505439',
    'custom_la_ligna_amarilla_1790198849385',
    'custom_mal_chauff_1790198442991',
    'custom_c_est_dans_l_lan_1790726366134',
    'custom_voy_a_marcar_1790725466122',
    'custom_t_te_de_boli_1790694926988',
    'custom_gardien_d_un_soir_1790198294777',
    'custom_sauvetage_in_extremis_1790725531858',
    'custom_le_malchanceux_1790198253832',
    'custom_le_boucher_1790198376585',
    'custom_le_plongeur_1790198344854')) template
    where not exists (
      select 1 from public.badges b
      where b.club_id = c.id and b.code = template.code
    )
  ),
  'Every existing club owns every imported badge'
);

select ok(
  not exists (
    select 1 from private.badge_templates
    where code in ('custom_au_four_et_au_moulin_1790198470375',
    'custom_remontada_1790198113800',
    'custom_clutch_1790198314443',
    'custom_une_deux_1790776876558',
    'custom_la_boucle_est_boucl_e_1790777176295',
    'custom_pr_cher_dans_le_d_sert_1790777232253',
    'custom_minimum_syndical_1790777345623',
    'custom_rira_bien_qui_rira_le_dernier_1790778180908',
    'custom_jamais_2_sans_3_1790777301116',
    'custom_doubl_hdm_1790772063214',
    'custom_tripl_chrono_1790937793669',
    'custom_la_glissade_1790198393809',
    'custom_r_galade_1790198505439',
    'custom_la_ligna_amarilla_1790198849385',
    'custom_mal_chauff_1790198442991',
    'custom_c_est_dans_l_lan_1790726366134',
    'custom_voy_a_marcar_1790725466122',
    'custom_t_te_de_boli_1790694926988',
    'custom_gardien_d_un_soir_1790198294777',
    'custom_sauvetage_in_extremis_1790725531858',
    'custom_le_malchanceux_1790198253832',
    'custom_le_boucher_1790198376585',
    'custom_le_plongeur_1790198344854')
      and (kind <> 'custom' or category <> 'faits_de_jeu'
           or auto or secret or metric is not null or threshold is not null)
  ),
  'Custom badges keep their mystery classification and rule-driven semantics'
);

select ok(
  not exists (
    select 1 from public.badges b
    join private.badge_templates t on t.code = b.code
    where b.code in ('custom_au_four_et_au_moulin_1790198470375',
    'custom_remontada_1790198113800',
    'custom_clutch_1790198314443',
    'custom_une_deux_1790776876558',
    'custom_la_boucle_est_boucl_e_1790777176295',
    'custom_pr_cher_dans_le_d_sert_1790777232253',
    'custom_minimum_syndical_1790777345623',
    'custom_rira_bien_qui_rira_le_dernier_1790778180908',
    'custom_jamais_2_sans_3_1790777301116',
    'custom_doubl_hdm_1790772063214',
    'custom_tripl_chrono_1790937793669',
    'custom_la_glissade_1790198393809',
    'custom_r_galade_1790198505439',
    'custom_la_ligna_amarilla_1790198849385',
    'custom_mal_chauff_1790198442991',
    'custom_c_est_dans_l_lan_1790726366134',
    'custom_voy_a_marcar_1790725466122',
    'custom_t_te_de_boli_1790694926988',
    'custom_gardien_d_un_soir_1790198294777',
    'custom_sauvetage_in_extremis_1790725531858',
    'custom_le_malchanceux_1790198253832',
    'custom_le_boucher_1790198376585',
    'custom_le_plongeur_1790198344854')
      and b.auto_rule is distinct from t.auto_rule
  ),
  'Every imported club badge has the expected automatic or manual rule'
);

select * from finish();
rollback;
