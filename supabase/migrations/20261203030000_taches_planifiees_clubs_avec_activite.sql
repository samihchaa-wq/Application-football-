-- Tâches planifiées : ne parcourir que les clubs qui ont du travail à faire.
--
-- Pourquoi : chaque minute, les tâches de rappel et de clôture parcourent TOUS
-- les clubs actifs, même ceux sans match proche ni vote ouvert. Estimation de
-- l'analyse du 18/11/2026 : mur vers 300 clubs (un cœur entier) à 900 clubs
-- (une tâche dépasse 60 s). Un club sans match proche ne produit rien.
--
-- Ce que fait la migration :
--   * private.club_has_scheduled_work(club) : vrai si le club a un match à
--     venir dans les 21 prochains jours (ou en retard, non clôturé), un match
--     terminé depuis moins de 3 jours, un Live en cours, un vote Homme du match
--     en préparation ou ouvert, ou des abonnés Live non servis ;
--   * private.run_for_each_busy_club(sql) : comme run_for_each_club, mais saute
--     les clubs sans travail ;
--   * seules les tâches pilotées par les matchs passent sur ce parcours.
--     badge-unlock-notifications et process-season-wrapped-jobs gardent le
--     parcours complet (leur travail ne dépend pas d'un match proche).
--
-- Rien n'est supprimé. Retour arrière : replanifier les 6 tâches avec
-- private.run_for_each_club (voir le bas du fichier).
-- NON APPLIQUÉE : à appliquer seulement avec l'accord du propriétaire.

create or replace function private.club_has_scheduled_work(p_club_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    exists (
      select 1 from public.matches m
      where m.club_id = p_club_id
        and m.status = 'a_venir'
        and m.match_date <= (current_date + 21)
    )
    or exists (
      select 1 from public.matches m
      where m.club_id = p_club_id
        and m.status = 'termine'
        and m.match_date >= (current_date - 3)
    )
    or exists (
      select 1 from public.match_live_sessions s
      where s.club_id = p_club_id
        and s.state in ('running', 'paused', 'halftime')
    )
    or exists (
      select 1 from public.match_sport_motm_elections e
      where e.club_id = p_club_id
        and e.state in ('draft', 'open')
    )
    or exists (
      select 1 from public.match_live_notification_subscriptions n
      where n.club_id = p_club_id
        and n.completed_at is null
    );
$$;

revoke all on function private.club_has_scheduled_work(uuid) from public, anon, authenticated;

create or replace function private.run_for_each_busy_club(p_sql text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_club uuid;
begin
  for v_club in
    select club.id
    from public.clubs club
    where club.status = 'active'
      and private.club_has_scheduled_work(club.id)
    order by club.created_at
  loop
    begin
      perform set_config('app.club_id', v_club::text, true);
      execute p_sql;
    exception when others then
      raise warning 'Traitement planifié en échec pour le club %: % (%)',
        v_club, sqlerrm, sqlstate;
    end;
  end loop;
  perform set_config('app.club_id', '', true);
end;
$$;

revoke all on function private.run_for_each_busy_club(text) from public, anon, authenticated;

-- Replanification : même nom et même rythme, seul le parcours change.
select cron.schedule('prediction-j5-reminders', '* * * * *',
  'select private.run_for_each_busy_club(''select public.push_prediction_j5_notifications()'');');
select cron.schedule('sports-availability-reminders', '* * * * *',
  'select private.run_for_each_busy_club(''select private.process_sport_availability_notifications(now())'');');
select cron.schedule('sports-motm-jobs', '* * * * *',
  'select private.run_for_each_busy_club(''select private.process_match_motm_jobs(now())'');');
select cron.schedule('finish-due-internal-matches', '* * * * *',
  'select private.run_for_each_busy_club(''select private.finish_due_internal_matches(now())'');');
select cron.schedule('live-match-notification-dispatch', '5 seconds',
  'select private.run_for_each_busy_club(''select private.process_due_match_live_notifications(50)'');');
select cron.schedule('match-weather-refresh', '*/15 * * * *',
  'select private.run_for_each_busy_club(''select private.request_match_weather_refresh(null)'');');

-- Retour arrière (à exécuter à la main si besoin) : même appels avec
-- private.run_for_each_club à la place de private.run_for_each_busy_club.
