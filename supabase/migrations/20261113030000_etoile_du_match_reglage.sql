-- Le réglage « Durée du vote » reprend le nom « Étoile du match ».
--
-- 20261113000000_rappel_pronostic_match_tot.sql (fusionnée avant
-- 20261112150000_etoile_du_match.sql mais datée après) a redéfini le
-- catalogue des règles à partir d'une version antérieure au renommage : les
-- administrateurs voyaient de nouveau « Durée du vote de l’homme du match »
-- dans les réglages du club. Même catalogue, libellé corrigé.

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
     'h', 'Liste d’attente', 12, 0, 23, 80)
  ) as catalogue(key, label, description, unit, group_label,
                 default_value, min_value, max_value, sort_order);
$$;
