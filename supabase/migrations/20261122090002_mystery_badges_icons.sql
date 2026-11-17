-- Replaces the generic 🏅 fallback of the 23 AS Grinta mystery badges
-- with 23 contextual illustrations. Catalog definitions/awards stay intact.
-- Must run AFTER 20261121000000_import_as_grinta_mystery_badges.sql.
-- Only the default emoji is updated: never overwrite a club's edits or
-- previously uploaded artwork. Only Petit Filet, never AS Grinta.
begin;

create temporary table mystery_badge_icons (
  code text primary key,
  emoji text not null
) on commit drop;

insert into mystery_badge_icons (code, emoji) values
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

update private.badge_templates b
set emoji = icons.emoji
from mystery_badge_icons icons
where b.code = icons.code
  and b.emoji = '🏅'
  and b.image_url is null;

update public.badges b
set emoji = icons.emoji
from mystery_badge_icons icons
where b.code = icons.code
  and b.emoji = '🏅'
  and b.image_url is null;

commit;
