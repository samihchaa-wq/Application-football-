-- Durée d'une tâche planifiée (variable psql :job) avec tous les clubs
-- fictifs. Une tâche qui tourne chaque minute doit finir bien avant la minute
-- suivante. Le résultat est rangé dans loadtest.cron_timing.
\o /dev/null
select set_config('loadtest.job', :'job', false);
\o

do $timing$
declare
  v_job record;
  v_start timestamptz := clock_timestamp();
  v_error text;
begin
  select jobname, schedule, command into v_job
  from cron.job where jobname = current_setting('loadtest.job');
  begin
    execute v_job.command;
  exception when others then
    v_error := sqlerrm;
  end;
  insert into loadtest.cron_timing
  values (
    v_job.jobname, v_job.schedule,
    round(extract(epoch from clock_timestamp() - v_start) * 1000, 1),
    v_error
  );
end;
$timing$;
