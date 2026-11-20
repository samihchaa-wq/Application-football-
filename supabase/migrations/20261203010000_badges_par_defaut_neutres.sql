-- Badges proposés aux nouveaux clubs : un jeu neutre.
--
-- Les badges manuels importés d'AS Grinta (20261121000000) étaient copiés tels
-- quels dans chaque nouveau club : blagues internes (« Voy a marcar »,
-- « La línea amarilla ! », « C'est dans l'élan »), doublons des badges de
-- base (« Le Boucher » = « Penalty concédé », « Le Malchanceux » = « Contre
-- son camp », « Le Plongeur » = « Penalty obtenu », un second « Gardien d'un
-- soir »), badges moqueurs (« La glissade », « Mal échauffé ») et descriptions
-- vides affichées « Custom ». Pour un club qui découvre l'application, cela
-- faisait amateur et pouvait passer pour de la moquerie entre membres.
--
-- Cette migration ne touche QUE les modèles des futurs clubs
-- (private.badge_templates). Les clubs existants gardent leurs badges, leurs
-- images et les badges déjà attribués : leurs administrateurs peuvent les
-- modifier ou les supprimer eux-mêmes.

-- 1. Retirés des modèles : blagues internes, doublons et badges moqueurs.
delete from private.badge_templates
where code in (
  'custom_la_glissade_1790198393809',
  'custom_la_ligna_amarilla_1790198849385',
  'custom_mal_chauff_1790198442991',
  'custom_c_est_dans_l_lan_1790726366134',
  'custom_voy_a_marcar_1790725466122',
  'custom_gardien_d_un_soir_1790198294777',
  'custom_le_malchanceux_1790198253832',
  'custom_le_boucher_1790198376585',
  'custom_le_plongeur_1790198344854'
);

-- 2. Gardés mais renommés ou complétés.
--    « Tête de Boli » cite une personne réelle.
update private.badge_templates
set name = 'Tête du défenseur'
where code = 'custom_t_te_de_boli_1790694926988';

--    Description vide affichée « Custom » dans l'application.
update private.badge_templates
set description = 'Sauver sur la ligne un but qui semblait tout fait.'
where code = 'custom_sauvetage_in_extremis_1790725531858'
  and description = '';

--    Icône neutre pour le rôle de coach (l'ancienne visait une personne).
update private.badge_templates
set emoji = '📋'
where code = 'role_coach';

-- 3. L'icône calendrier s'affiche avec une date en anglais (« JULY 17 ») sur
--    la plupart des téléphones : les badges de matchs joués prennent une
--    chaussure de foot.
update private.badge_templates
set emoji = '👟'
where emoji = '📅'
  and metric in ('matches_played', 'matches_played_season');
