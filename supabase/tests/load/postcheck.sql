-- Echec explicite sur anomalie des ecritures concurrentes en environnement LOCAL.
-- Le run.sh refuse les bases distantes avant d'executer ce fichier.
do $postcheck$
declare
  v_missing int;
  v_unbalanced int;
  v_events int;
  v_operations bigint;
begin
  if not exists (select 1 from loadtest.clubs) then
    raise exception 'Aucun club de charge : verification non valable.';
  end if;
  select count(*) into v_missing
  from loadtest.clubs c
  left join public.match_live_sessions l on l.match_id = c.live_match_id
  where l.match_id is null or l.state <> 'running';

  select count(*) into v_unbalanced
  from loadtest.clubs c
  join public.match_live_sessions l on l.match_id = c.live_match_id
  where l.score_as_grinta <> 0 or l.score_adverse <> 0;

  select count(*) into v_events
  from public.match_live_events e
  join loadtest.clubs c on c.live_match_id = e.match_id;

  select count(*) into v_operations
  from private.match_live_score_commands cmd
  join loadtest.clubs c on c.live_match_id = cmd.match_id;

  if v_missing > 0 or v_unbalanced > 0 or v_events > 0 or v_operations = 0 then
    raise exception
      'Charge non valide : Live manquants=% ; scores non nuls=% ; evenements residuels=% ; commandes=%',
      v_missing, v_unbalanced, v_events, v_operations;
  end if;
  raise notice 'Charge coherente : % operations idempotentes, 0 score parasite, 0 evenement residuel.',
    v_operations;
end
$postcheck$;
