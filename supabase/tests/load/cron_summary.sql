-- Résumé des durées mesurées par cron_timing.sql. Une tâche absente a été
-- arrêtée au bout de 120 s.
select job, schedule, ms, error from loadtest.cron_timing order by ms desc;

select string_agg(jobname, ', ') as taches_arretees_apres_120_s
from cron.job
where jobname not like 'purge-%'
  and jobname not in (select job from loadtest.cron_timing);

-- Charge cumulée : temps de base consommé chaque minute par les tâches
-- planifiées, en pourcentage d'un cœur de processeur.
select round(sum(
  ms * case
    when schedule = '5 seconds' then 12
    when schedule = '* * * * *' then 1
    when schedule like '*/5 %' then 0.2
    when schedule like '*/15 %' then 1.0 / 15
    else 0
  end
) / 600, 1) as pourcentage_d_un_coeur_par_minute
from loadtest.cron_timing;
