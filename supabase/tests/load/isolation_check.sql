-- Vérifie, avec des centaines de clubs, qu'un membre ne voit que son club.
-- Échoue (ON_ERROR_STOP) à la première fuite.
do $check$
declare
  v_user loadtest.users;
  v_members integer := current_setting('loadtest.members')::integer;
  v_matches integer := current_setting('loadtest.matches')::integer;
  v_count bigint;
  v_other bigint;
  v_checked integer := 0;
begin
  for v_user in
    select * from loadtest.users order by random() limit 300
  loop
    perform set_config('request.jwt.claims', v_user.claims, true);
    perform set_config('role', 'authenticated', true);

    select count(*) into v_count from public.profiles;
    if v_count <> v_members then
      raise exception 'Fuite : % voit % profils au lieu de %', v_user.id, v_count, v_members;
    end if;
    select count(*) into v_count from public.matches;
    if v_count <> v_matches then
      raise exception 'Fuite : % voit % matchs au lieu de %', v_user.id, v_count, v_matches;
    end if;
    select count(*) into v_other from public.clubs where id <> v_user.club_id;
    if v_other <> 0 then
      raise exception 'Fuite : % voit % autres clubs', v_user.id, v_other;
    end if;
    select count(*) into v_other from public.match_live_sessions
    where match_id <> v_user.live_match_id;
    if v_other <> 0 then
      raise exception 'Fuite : % voit le Live de % autres clubs', v_user.id, v_other;
    end if;

    perform set_config('role', 'postgres', true);
    v_checked := v_checked + 1;
  end loop;
  raise notice 'Cloisonnement vérifié pour % membres tirés au hasard : aucune fuite.', v_checked;
end;
$check$;
