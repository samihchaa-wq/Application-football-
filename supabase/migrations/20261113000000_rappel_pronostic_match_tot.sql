-- Rappel de pronostic : un match en début de journée reçoit aussi son rappel.
--
-- Le rappel part le jour du match à l'heure réglée par le club (16 h par
-- défaut). Pour un match qui commence avant cette heure, les pronostics sont
-- déjà fermés : personne ne recevait jamais de rappel. Le rappel part
-- désormais au plus tard un certain nombre de minutes avant la fermeture
-- des pronostics (60 par défaut) ; pour un match du soir rien ne change.
-- Catalogue repris de 20261112132000_vote_homme_du_match_minimum.sql ; seule
-- la règle prediction_reminder_lead_minutes est ajoutée.

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
    ('motm_window_hours', 'Durée du vote de l’homme du match',
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
     'h', 'Liste d’attente', 12, 0, 23, 80)
  ) as catalogue(key, label, description, unit, group_label,
                 default_value, min_value, max_value, sort_order);
$$;

create or replace function private.match_prediction_notification_at(p_kickoff_at timestamp with time zone)
returns timestamp with time zone
language sql stable strict
set search_path to ''
as $$
  select least(
    (
      ((p_kickoff_at at time zone 'Europe/Paris')::date
        + make_interval(hours => private.club_rule('prediction_reminder_hour')))
      at time zone 'Europe/Paris'
    ),
    private.match_prediction_closes_at(p_kickoff_at)
      - make_interval(mins => private.club_rule('prediction_reminder_lead_minutes'))
  );
$$;
