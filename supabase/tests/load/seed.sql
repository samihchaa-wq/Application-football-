-- Données fictives du test de charge : des centaines de clubs dans une même
-- base, chacun avec ses membres, sa saison, ses matchs et un Live en cours.
-- Base éphémère de test uniquement, jamais une base réelle.
--
-- Variables psql : clubs (nombre de clubs), members (membres par club),
-- matches (matchs par club).

create schema if not exists loadtest;

create table loadtest.users (
  n serial primary key,
  id uuid not null unique,
  club_id uuid not null,
  is_admin boolean not null,
  live_match_id uuid not null,
  claims text not null
);

create table loadtest.clubs (
  n serial primary key,
  id uuid not null unique,
  admin_id uuid not null,
  live_match_id uuid not null
);

-- Agit comme un membre connecté jusqu'à la fin de la transaction, comme le
-- fait le serveur d'API pour chaque requête.
create function loadtest.act_as(p_n integer) returns uuid
language plpgsql
as $$
declare
  v_user loadtest.users;
begin
  select * into v_user from loadtest.users where n = p_n;
  perform set_config('request.jwt.claims', v_user.claims, true);
  perform set_config('role', 'authenticated', true);
  return v_user.id;
end;
$$;

create function loadtest.act_as_admin(p_n integer) returns uuid
language plpgsql
as $$
declare
  v_club loadtest.clubs;
begin
  select * into v_club from loadtest.clubs where n = p_n;
  return loadtest.act_as((select n from loadtest.users where id = v_club.admin_id));
end;
$$;

-- Les noms n'acceptent que des lettres : 123 devient « bcd ».
create function loadtest.letters(p_n integer) returns text
language sql immutable
as $$
  select translate(p_n::text, '0123456789', 'abcdefghij');
$$;

grant usage on schema loadtest to authenticated;
grant select on all tables in schema loadtest to authenticated;
grant execute on all functions in schema loadtest to authenticated;

-- psql ne remplace pas ses variables à l'intérieur d'un bloc $…$ : elles
-- passent par des réglages de session.
select set_config('loadtest.clubs', :'clubs', false),
       set_config('loadtest.members', :'members', false),
       set_config('loadtest.matches', :'matches', false);

do $seed$
declare
  v_clubs integer := current_setting('loadtest.clubs')::integer;
  v_members integer := current_setting('loadtest.members')::integer;
  v_matches integer := current_setting('loadtest.matches')::integer;
  v_club uuid;
  v_season uuid;
  v_user uuid;
  v_admin uuid;
  v_player uuid;
  v_match uuid;
  v_live_match uuid;
  v_session uuid;
  v_opponent uuid;
  c integer;
  m integer;
  k integer;
begin
  for c in 1..v_clubs loop
    v_club := (public.create_club('Club de charge ' || loadtest.letters(c), 'CH' || loadtest.letters(c))).id;
    perform set_config('app.club_id', v_club::text, true);

    v_season := gen_random_uuid();
    insert into public.seasons (id, name, status) values (v_season, '2026-2027', 'open');
    insert into public.opponents (name) values ('Adversaire ' || loadtest.letters(c))
      returning id into v_opponent;

    v_admin := null;
    for m in 1..v_members loop
      v_user := gen_random_uuid();
      insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
      values (
        v_user,
        format('charge-%s-%s@example.invalid', c, m),
        jsonb_build_object('first_name', 'Joueur' || loadtest.letters(m), 'last_name', 'Club' || loadtest.letters(c)),
        jsonb_build_object('club_id', v_club)
      );
      update public.profiles
      set status = 'active', role = case when m = 1 then 'admin' else 'pronostiqueur' end
      where id = v_user;
      if m = 1 then
        v_admin := v_user;
      end if;

      insert into public.players (display_name) values ('Joueur' || loadtest.letters(m) || ' Club' || loadtest.letters(c))
        returning id into v_player;
      insert into public.season_players (
        season_id, first_name, last_name, is_goalkeeper, is_active, is_coach,
        profile_id, player_id
      )
      values (
        v_season, 'Joueur' || loadtest.letters(m), 'Club' || loadtest.letters(c), m = 2, true, m = 1,
        v_user, v_player
      );
    end loop;

    -- La moitié des matchs est jouée, l'autre à venir. Le dernier match joué
    -- est en cours de Live au moment du test.
    v_live_match := null;
    for k in 1..v_matches loop
      v_match := gen_random_uuid();
      insert into public.matches (
        id, season_id, opponent_id, match_date, match_time, location,
        planned_duration_minutes, status, score_as_grinta, score_adverse,
        created_by
      )
      values (
        v_match, v_season, v_opponent,
        current_date + (k - v_matches / 2) * 7,
        '15:00'::time,
        case when k % 2 = 0 then 'domicile' else 'exterieur' end,
        90,
        case when k < v_matches / 2 then 'termine' else 'a_venir' end,
        case when k < v_matches / 2 then k % 4 end,
        case when k < v_matches / 2 then k % 3 end,
        v_admin
      );
      if k = v_matches / 2 then
        v_live_match := v_match;
      end if;
    end loop;

    v_session := gen_random_uuid();
    insert into public.match_live_sessions (
      match_id, state, planned_duration_minutes, started_at, running_since,
      updated_by, pilot_profile_id, pilot_session_id, pilot_heartbeat_at
    )
    values (
      v_live_match, 'running', 90, now(), now(), v_admin, v_admin, v_session,
      now() + interval '1 day'
    );

    insert into loadtest.clubs (id, admin_id, live_match_id)
    values (v_club, v_admin, v_live_match);

    insert into loadtest.users (id, club_id, is_admin, live_match_id, claims)
    select
      profile.id, v_club, profile.role = 'admin', v_live_match,
      jsonb_build_object(
        'sub', profile.id, 'role', 'authenticated', 'aud', 'authenticated',
        'session_id', case when profile.id = v_admin then v_session end,
        'app_metadata', jsonb_build_object('club_id', v_club)
      )::text
    from public.profiles profile
    where profile.club_id = v_club
    order by profile.created_at, profile.id;
  end loop;

  perform set_config('app.club_id', '', true);
end;
$seed$;

analyze;

select
  (select count(*) from public.clubs) as clubs,
  (select count(*) from public.profiles) as comptes,
  (select count(*) from public.matches) as matchs,
  (select count(*) from public.badges) as badges;
