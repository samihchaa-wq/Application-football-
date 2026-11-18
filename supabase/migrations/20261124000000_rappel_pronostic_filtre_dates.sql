-- Rappel de pronostic : ne regarder que les matchs proches.
--
-- La tâche `prediction-j5-reminders` passe chaque minute, club par club.
-- Elle calculait l'heure du rappel (plusieurs lectures des règles du club)
-- pour TOUS les matchs « à venir » de chaque club, donc tout le calendrier de
-- la saison, alors qu'un rappel ne peut partir que pour un match qui commence
-- dans les prochaines 24 heures. Mesurée en CI sur 200 clubs, cette seule
-- tâche prenait 6,5 s par passage sur ~6,9 s pour toutes les tâches.
--
-- Un filtre de dates simple est ajouté AVANT les calculs d'heure. Il ne change
-- pas le résultat : il ne retire que des matchs pour lesquels la condition
-- d'envoi (inchangée, plus bas) est forcément fausse.
--
-- Pourquoi le filtre est sûr (voir aussi supabase/tests/database/
-- prediction_reminder_prefilter.test.sql, qui le vérifie sur une grille
-- couvrant les changements d'heure) :
--   * le rappel ne part jamais après la fermeture des pronostics, qui ne
--     tombe jamais après le coup d'envoi : il faut donc `kickoff_at > now()` ;
--   * l'heure du rappel n'est jamais avant minuit (Paris) du jour du match :
--     le coup d'envoi est donc à moins de 24 h de `now()` (25 h un jour de
--     changement d'heure). La borne de 2 jours laisse une large marge.
-- La borne basse d'un jour est volontairement large : elle ne sert qu'à
-- garder le filtre lisible et symétrique.
--
-- Fonction reprise à l'identique de 20261112130000_fonctions_desactivees_
-- silencieuses.sql ; seules les deux lignes `m.kickoff_at > …` sont ajoutées.
-- CREATE OR REPLACE conserve propriétaire et droits.

CREATE OR REPLACE FUNCTION "public"."push_prediction_j5_notifications"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_match record;
  v_sent integer := 0;
begin
  if private.is_feature_enabled('notifications_paused')
     or not private.club_module_enabled('predictions') then
    return 0;
  end if;

  -- Le cron tourne chaque minute. La fenêtre de 10 minutes ne sert qu'à
  -- rattraper une exécution manquée : passé 16 h 10, le rappel n'est plus
  -- envoyé, et jamais après la fermeture des pronostics (T-15).
  for v_match in
    select m.id
    from public.matches m
    where m.status = 'a_venir'
      and m.match_type <> 'entre_nous'
      and m.kickoff_at is not null
      and m.kickoff_at > now() - interval '1 day'
      and m.kickoff_at < now() + interval '2 days'
      and now() >= private.match_prediction_notification_at(m.kickoff_at)
      and now() < private.match_prediction_notification_at(m.kickoff_at)
        + interval '10 minutes'
      and now() < private.match_prediction_closes_at(m.kickoff_at)
      and (m.predictions_closed_at is null or now() < m.predictions_closed_at)
    order by m.kickoff_at
  loop
    insert into public.push_notification_log(match_id, kind, sent_at)
    values (v_match.id, 'prediction_j5', now())
    on conflict do nothing;
    if found then
      perform public.internal_push_notify('prediction_j5', v_match.id);
      v_sent := v_sent + 1;
    end if;
  end loop;
  return v_sent;
end;
$$;
