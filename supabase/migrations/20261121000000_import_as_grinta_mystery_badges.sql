-- Restore all mystery badge codes that can be verified from the AS Grinta
-- repository's 2026-09/10 SQL migrations (23 custom badges; 11 automatic).
-- This import is catalog-only: NEVER copy player awards, user data or
-- image URLs from AS Grinta's private storage.
-- Run only against the multi-club Petit Filet database.
-- Idempotent: do not overwrite club-level badge customizations.
begin;

create temporary table imported_grinta_mystery_badges (
  code text primary key,
  name text not null,
  description text not null,
  auto_rule text
) on commit drop;

insert into imported_grinta_mystery_badges (code, name, description, auto_rule)
values
  ('custom_au_four_et_au_moulin_1790198470375', 'Au four et au moulin', 'Marquer un but et délivrer une passe décisive dans le même match.', 'goal_and_assist'),
  ('custom_remontada_1790198113800', 'Remontada', 'Gagner un match après avoir été mené de deux buts.', 'remontada'),
  ('custom_clutch_1790198314443', 'Clutch', 'Marquer le but de la victoire dans les cinq dernières minutes.', 'clutch'),
  ('custom_une_deux_1790776876558', 'Une-deux', 'Dans un même match, servir un coéquipier sur un but et être servi par ce même joueur sur un autre.', 'one_two'),
  ('custom_la_boucle_est_boucl_e_1790777176295', 'La boucle est bouclée', 'Marquer le premier et le dernier but d’un match.', 'first_and_last_goal'),
  ('custom_pr_cher_dans_le_d_sert_1790777232253', 'Prêcher dans le désert', 'Marquer au moins trois buts lors d’une défaite.', 'hat_trick_in_defeat'),
  ('custom_minimum_syndical_1790777345623', 'Minimum syndical', 'Marquer l’unique but du match et gagner.', 'lone_winning_goal'),
  ('custom_rira_bien_qui_rira_le_dernier_1790778180908', 'Rira bien qui rira le dernier', 'Encaisser le premier but, ne plus en encaisser et gagner.', 'comeback_after_first_goal'),
  ('custom_jamais_2_sans_3_1790777301116', 'Jamais 2 sans 3', 'Marquer lors de 3 matchs consécutifs.', 'three_match_scoring_streak'),
  ('custom_doubl_hdm_1790772063214', 'Doublé HDM', 'Être élu Homme du match deux matchs de suite.', 'back_to_back_motm'),
  ('custom_tripl_chrono_1790937793669', 'Triplé Chrono', 'Marquer un triplé en une mi-temps.', 'hat_trick_in_half'),
  ('custom_la_glissade_1790198393809', 'La glissade', 'Glisser et perdre le ballon.', null),
  ('custom_r_galade_1790198505439', 'Régalade', 'Marquer sur un retourné acrobatique.', null),
  ('custom_la_ligna_amarilla_1790198849385', '« La línea amarilla ! »', 'Parler la langue d’un adversaire étranger.', null),
  ('custom_mal_chauff_1790198442991', 'Mal échauffé', 'Sortir sur blessure en première mi-temps.', null),
  ('custom_c_est_dans_l_lan_1790726366134', '« C’est dans l’élan »', 'Commettre une grosse faute.', null),
  ('custom_voy_a_marcar_1790725466122', '« Voy a marcar »', '', null),
  ('custom_t_te_de_boli_1790694926988', 'Tête de Boli', 'Être défenseur, monter sur corner et marquer de la tête.', null),
  ('custom_gardien_d_un_soir_1790198294777', 'Gardien d’un soir', 'Prendre la place du gardien quand ce n’est pas son poste de prédilection.', null),
  ('custom_sauvetage_in_extremis_1790725531858', 'Sauvetage in extremis', '', null),
  ('custom_le_malchanceux_1790198253832', 'Le Malchanceux', 'Marquer contre son camp.', null),
  ('custom_le_boucher_1790198376585', 'Le Boucher', 'Commettre une faute qui donne un penalty à l’adversaire.', null),
  ('custom_le_plongeur_1790198344854', 'Le Plongeur', '', null);

-- The source application created these codes directly in its production
-- database; its seed.sql does not contain them. Use the documented final
-- wording when available, and leave undocumented descriptions empty.
-- Original custom JPEGs were stored in AS Grinta's Storage and are NOT
-- available in the commercial project. The neutral badge emblem is a
-- deliberate fallback, not a claim to have copied the artwork.
insert into private.badge_templates (
  code, name, description, emoji, family, auto, metric, threshold, sort_order,
  kind, category, image_url, color, has_star, standalone, secret, auto_rule
)
select source.code, source.name, source.description, '🏅', 'joueur', false,
  null, null, 950 + row_number() over (order by source.code),
  'custom', 'faits_de_jeu', null, '#F97316', false, false, false,
  source.auto_rule
from imported_grinta_mystery_badges source
on conflict (code) do nothing;

-- Existing clubs obtain each source badge exactly once. Never modify an
-- existing badge's name, image, automation rule or earned assignments.
insert into public.badges (
  club_id, code, name, description, emoji, family, auto, metric, threshold,
  sort_order, kind, category, image_url, color, has_star, standalone,
  secret, auto_rule
)
select club.id, template.code, template.name, template.description,
  template.emoji, template.family, template.auto, template.metric,
  template.threshold, template.sort_order, template.kind, template.category,
  template.image_url, template.color, template.has_star, template.standalone,
  template.secret, template.auto_rule
from public.clubs club
cross join private.badge_templates template
join imported_grinta_mystery_badges source on source.code = template.code
on conflict (club_id, code) do nothing;

-- Future clubs inherit these badges via private.provision_club() which
-- already copies all rows in private.badge_templates.
commit;
