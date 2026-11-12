-- Barème des pronostics réglable par club.
--
-- Jusqu'ici, le barème était le même pour tous les clubs : la cote du
-- résultat multipliée par 2 pour un score exact, par 1,5 pour le bon écart de
-- buts ou le bon nombre de buts d'une des deux équipes, par 1 pour le bon
-- vainqueur seul. Chaque club peut maintenant choisir ses multiplicateurs.
-- Sans réglage, les valeurs restent celles d'origine.
--
-- Les multiplicateurs sont enregistrés en dixièmes (20 = × 2,0), car les
-- règles du club sont des nombres entiers.
--
-- Le classement est calculé à la volée à partir de cette vue : un changement
-- de barème s'applique aussi aux matchs déjà joués de toutes les saisons. Les
-- descriptions le disent à l'administrateur.

create or replace function private.club_rule_catalogue()
returns table (
  key text,
  label text,
  description text,
  unit text,
  group_label text,
  default_value integer,
  min_value integer,
  max_value integer,
  sort_order integer
)
language sql immutable
set search_path to ''
as $$
  select * from (values
    ('features_open_days', 'Ouverture avant le match',
     'Combien de jours avant le coup d’envoi s’ouvrent les disponibilités, la composition et les pronostics.',
     'jours', 'Avant le match', 6, 1, 21, 10),
    ('features_open_hour', 'Heure d’ouverture',
     'Heure (en France) à laquelle ils s’ouvrent ce jour-là.',
     'h', 'Avant le match', 12, 0, 23, 20),
    ('prediction_close_minutes', 'Fermeture des pronostics',
     'Combien de minutes avant le coup d’envoi les pronostics se ferment (et le mode live s’ouvre).',
     'min', 'Pronostics', 15, 0, 240, 30),
    ('prediction_reminder_hour', 'Heure du rappel de pronostic',
     'Heure (en France) du rappel envoyé le jour du match à ceux qui n’ont pas pronostiqué.',
     'h', 'Pronostics', 16, 0, 23, 40),
    ('prediction_reminder_lead_minutes', 'Rappel avant un match tôt',
     'Si le match commence avant l’heure du rappel, le rappel part ce nombre de minutes avant la fermeture des pronostics.',
     'min', 'Pronostics', 60, 15, 600, 45),
    ('motm_window_hours', 'Durée du vote de l’Étoile du match',
     'Combien d’heures après le coup d’envoi le vote reste ouvert.',
     'h', 'Après le match', 24, 6, 168, 50),
    ('correction_window_hours', 'Délai de correction du résultat',
     'Combien d’heures après sa validation le résultat peut encore être corrigé.',
     'h', 'Après le match', 24, 1, 168, 60),
    ('waitlist_mode', 'Liste d’attente : qui passe en premier',
     'Quand il y a plus de disponibles que de places : par présence l’an dernier, par ordre d’arrivée, ou par choix de l’administrateur.',
     'mode', 'Liste d’attente', 0, 0, 2, 65),
    ('waitlist_cutoff_days', 'Liste d’attente : jour limite',
     'Combien de jours avant le match la liste d’attente cesse de créditer des places (0 = le jour même).',
     'jours', 'Liste d’attente', 1, 0, 7, 70),
    ('waitlist_cutoff_hour', 'Liste d’attente : heure limite',
     'Heure (en France) de ce jour limite.',
     'h', 'Liste d’attente', 12, 0, 23, 80),
    ('prediction_points_exact', 'Barème : score exact',
     'La cote du bon résultat est multipliée par ce nombre quand le score exact est trouvé. S’applique aussi aux matchs déjà joués.',
     '×', 'Barème des pronostics', 20, 0, 50, 90),
    ('prediction_points_goal_difference', 'Barème : bon écart de buts',
     'Bon vainqueur (ou match nul) avec le bon écart de buts, sans le score exact. S’applique aussi aux matchs déjà joués.',
     '×', 'Barème des pronostics', 15, 0, 50, 91),
    ('prediction_points_one_score', 'Barème : un des deux scores',
     'Bon vainqueur et le bon nombre de buts d’une des deux équipes. S’applique aussi aux matchs déjà joués.',
     '×', 'Barème des pronostics', 15, 0, 50, 92),
    ('prediction_points_winner', 'Barème : bon vainqueur seulement',
     'Bon vainqueur, sans autre précision juste. S’applique aussi aux matchs déjà joués.',
     '×', 'Barème des pronostics', 10, 0, 50, 93)
  ) as catalogue(key, label, description, unit, group_label,
                 default_value, min_value, max_value, sort_order);
$$;

-- Même calcul qu'avant, multiplicateurs lus dans les règles du club courant.
-- La vue ne montre que les pronostics du club courant (règle de cloisonnement),
-- donc les règles lues sont toujours celles du club des lignes affichées.
create or replace view public.v_match_prediction_points
with (security_invoker = 'true') as
with scale as (
  select
    private.club_rule('prediction_points_exact')::numeric / 10 as exact_score,
    private.club_rule('prediction_points_goal_difference')::numeric / 10 as goal_difference,
    private.club_rule('prediction_points_one_score')::numeric / 10 as one_score,
    private.club_rule('prediction_points_winner')::numeric / 10 as winner
)
select
  mp.id,
  mp.match_id,
  mp.profile_id,
  case
    when not mp.is_filled then 0::numeric
    when sign((mp.predicted_score_as_grinta - mp.predicted_score_adverse)::numeric)
         <> sign((m.score_as_grinta - m.score_adverse)::numeric) then 0::numeric
    else (
      case
        when m.score_as_grinta > m.score_adverse then mo.odds_victoire_as_grinta
        when m.score_as_grinta = m.score_adverse then mo.odds_nul
        else mo.odds_victoire_adverse
      end
      *
      case
        when mp.predicted_score_as_grinta = m.score_as_grinta
             and mp.predicted_score_adverse = m.score_adverse then scale.exact_score
        when (mp.predicted_score_as_grinta - mp.predicted_score_adverse)
             = (m.score_as_grinta - m.score_adverse) then scale.goal_difference
        when mp.predicted_score_as_grinta = m.score_as_grinta
             or mp.predicted_score_adverse = m.score_adverse then scale.one_score
        else scale.winner
      end
    )
  end as points
from public.match_predictions mp
join public.matches m
  on m.id = mp.match_id
 and m.status = any (array['termine'::text, 'archive'::text])
join public.match_odds mo on mo.match_id = m.id
cross join scale;
