-- Durée de chaque tâche planifiée avec tous les clubs fictifs. Une tâche qui
-- tourne chaque minute doit finir bien avant la minute suivante.
create temporary table cron_timing (
  job text, schedule text, ms numeric, error text
);

do $timing$
declare
  v_job record;
  v_start timestamptz;
  v_error text;
begin
  for v_job in
    select jobname, schedule, command from cron.job
    where jobname not like 'purge-%'
    order by jobname
  loop
    v_error := null;
    v_start := clock_timestamp();
    begin
      execute v_job.command;
    exception when others then
      v_error := sqlerrm;
    end;
    insert into cron_timing
    values (
      v_job.jobname, v_job.schedule,
      round(extract(epoch from clock_timestamp() - v_start) * 1000, 1),
      v_error
    );
  end loop;
end;
$timing$;

select job, schedule, ms, error from cron_timing order by ms desc;

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
from cron_timing;
