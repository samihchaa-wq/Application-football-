begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Simulation d'une saison complète pour deux clubs de 20 joueurs chacun,
-- dans la même base. Chaque club joue 10 matchs, de bout en bout :
-- disponibilités, pronostics, convocations, composition, résultat, buteurs,
-- vote de l'Étoile du match, puis clôture de la saison (titres et bilan).
--
-- Chaque étape passe par les fonctions de l'application avec le compte qui
-- la fait dans la vraie vie (admin ou joueur). Une étape qui échoue est notée
-- dans sim_errors au lieu d'arrêter la simulation : le test liste à la fin
-- tout ce qui n'a pas marché. Seul le temps est avancé à la main (date du
-- match passée au passé), comme dans les autres tests de cycle de match.
-- La transaction est annulée à la fin.

create temporary table sim_clubs (
  label text primary key,
  id uuid not null,
  admin_id uuid not null,
  season_id uuid
) on commit drop;

create temporary table sim_players (
  club text not null,
  number integer not null,
  profile_id uuid not null,
  season_player_id uuid not null,
  primary key (club, number)
) on commit drop;

create temporary table sim_matches (
  club text not null,
  number integer not null,
  match_id uuid not null,
  goals_for integer not null,
  goals_against integer not null,
  primary key (club, number)
) on commit drop;

create temporary table sim_errors (
  id serial primary key,
  club text,
  match_number integer,
  step text,
  state text,
  message text
) on commit drop;

grant select, insert on sim_clubs, sim_players, sim_matches, sim_errors to authenticated;
grant usage on sequence sim_errors_id_seq to authenticated;

-- Passe sous l'identité d'un compte connecté (ou revient au propriétaire).
create function pg_temp.sim_as(p_profile uuid) returns void
language plpgsql as $$
begin
  if p_profile is null then
    execute 'reset role';
    return;
  end if;
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', p_profile, 'role', 'authenticated', 'aud', 'authenticated')::text,
    true
  );
  execute 'set local role authenticated';
end;
$$;

create function pg_temp.sim_note(
  p_club text, p_match integer, p_step text, p_state text, p_message text
) returns void
language sql as $$
  insert into sim_errors (club, match_number, step, state, message)
  values (p_club, p_match, p_step, p_state, left(p_message, 300));
$$;

-- ---------------------------------------------------------------------------
-- 1. Deux clubs, un administrateur et 20 joueurs chacun
-- ---------------------------------------------------------------------------
do $$
declare
  v_label text;
  v_club uuid;
  v_admin uuid;
  v_profile uuid;
  v_index integer;
begin
  foreach v_label in array array['a', 'b'] loop
    v_club := (public.create_club(
      'Simulation ' || upper(v_label), 'SIM' || upper(v_label),
      case v_label when 'a' then '#C62828' else '#2E7D32' end, '#FFFFFF',
      'Europe/Paris', null
    )).id;
    v_admin := ('5a000000-0000-0000-0000-0000000000' || v_label || '0')::uuid;

    insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
    values (
      v_admin, 'sim-admin-' || v_label || '@example.invalid',
      jsonb_build_object('first_name', 'Admin', 'last_name', 'Sim' || upper(v_label)),
      jsonb_build_object('club_id', v_club)
    );
    update public.profiles set role = 'admin', status = 'active' where id = v_admin;
    insert into sim_clubs (label, id, admin_id) values (v_label, v_club, v_admin);

    for v_index in 1..20 loop
      v_profile := ('5a000000-0000-0000-0000-' || case v_label when 'a' then '0a' else '0b' end
                    || lpad(v_index::text, 10, '0'))::uuid;
      insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
      values (
        v_profile, format('sim-%s-%s@example.invalid', v_label, v_index),
        jsonb_build_object('first_name', (array['Adrien','Bastien','Cyril','Damien','Emile','Fabien','Gael','Hugo','Ilan','Jules','Kevin','Loic','Malo','Nael','Oscar','Pablo','Quentin','Remi','Sacha','Theo'])[v_index], 'last_name', 'Sim' || upper(v_label)),
        jsonb_build_object('club_id', v_club)
      );
      update public.profiles
      set role = 'pronostiqueur', status = 'active', is_goalkeeper = (v_index = 1)
      where id = v_profile;
    end loop;

    update private.app_feature_flags
    set enabled = true, updated_at = now(), updated_by = v_admin
    where key = 'sports_management' and club_id = v_club;
  end loop;
end;
$$;

select is(
  (select count(*) from public.profiles where club_id in (select id from sim_clubs)),
  42::bigint,
  'deux clubs de 21 comptes (1 admin et 20 joueurs) sont créés'
);

-- ---------------------------------------------------------------------------
-- 2. Saison, adversaires et effectif, créés par l'administrateur
-- ---------------------------------------------------------------------------
do $$
declare
  v_club record;
  v_season uuid;
  v_index integer;
  v_profile uuid;
  v_season_player uuid;
begin
  for v_club in select * from sim_clubs order by label loop
    perform pg_temp.sim_as(v_club.admin_id);
    v_season := public.open_or_create_season('2099-2100');
    for v_index in 1..5 loop
      perform public.get_or_create_opponent(format('Adversaire %s %s', upper(v_club.label), (array['Nord','Sud','Est','Ouest','Centre'])[v_index]));
    end loop;
    perform pg_temp.sim_as(null);
    update sim_clubs set season_id = v_season where label = v_club.label;

    for v_index in 1..20 loop
      v_profile := ('5a000000-0000-0000-0000-' || case v_club.label when 'a' then '0a' else '0b' end
                    || lpad(v_index::text, 10, '0'))::uuid;
      -- Les membres actifs rejoignent la saison ouverte d'eux-mêmes ; on
      -- complète seulement leur numéro et le poste de gardien.
      select id into v_season_player from public.season_players
      where season_id = v_season and profile_id = v_profile;
      if v_season_player is null then
        v_season_player := gen_random_uuid();
        insert into public.season_players (
          id, club_id, season_id, first_name, last_name, is_goalkeeper, is_active, position, profile_id
        ) values (
          v_season_player, v_club.id, v_season, 'Remplacant', 'Sim' || upper(v_club.label),
          v_index = 1, true, v_index, v_profile
        );
      else
        update public.season_players
        set is_goalkeeper = (v_index = 1), is_active = true
        where id = v_season_player;
      end if;
      insert into sim_players values (v_club.label, v_index, v_profile, v_season_player);
    end loop;
  end loop;
end;
$$;

select is(
  (select count(*) from public.season_players
   where season_id in (select season_id from sim_clubs) and is_active
     and profile_id in (select profile_id from sim_players)),
  40::bigint,
  'chaque club a 20 joueurs actifs dans sa saison'
);
select is(
  (select count(distinct club_id) from public.opponents where club_id in (select id from sim_clubs)),
  2::bigint,
  'chaque club a ses propres adversaires'
);

-- ---------------------------------------------------------------------------
-- 3. Dix matchs par club, chacun joué de bout en bout
-- ---------------------------------------------------------------------------
do $$
declare
  v_club record;
  v_player record;
  v_number integer;
  v_match uuid;
  v_opponent uuid;
  v_kickoff timestamptz;
  v_gf integer;
  v_ga integer;
  v_entries jsonb;
  v_payload jsonb;
  v_field integer;
  v_scorer uuid;
  v_candidate uuid;
  v_state text;
  v_message text;
begin
  for v_club in select * from sim_clubs order by label loop
    for v_number in 1..10 loop
      v_match := null;
      -- Score déterministe, différent d'un club à l'autre.
      v_gf := (v_number * case v_club.label when 'a' then 3 else 5 end) % 5;
      v_ga := (v_number * case v_club.label when 'a' then 2 else 1 end + 1) % 4;

      -- Création du match (admin), deux jours à l'avance.
      begin
        perform pg_temp.sim_as(v_club.admin_id);
        select id into v_opponent from public.opponents
        where name = format('Adversaire %s %s', upper(v_club.label), (array['Nord','Sud','Est','Ouest','Centre'])[1 + (v_number - 1) % 5]);
        v_kickoff := now() + interval '2 days' + make_interval(mins => v_number);
        v_match := public.admin_create_match_complete(
          v_club.season_id, v_opponent,
          (v_kickoff at time zone 'Europe/Paris')::date,
          (v_kickoff at time zone 'Europe/Paris')::time,
          case when v_number % 2 = 0 then 'domicile' else 'exterieur' end,
          2.10, 3.20, 2.90, null, null, false, 'championnat', null
        );
        perform pg_temp.sim_as(null);
      exception when others then
        get stacked diagnostics v_state = returned_sqlstate, v_message = message_text;
        perform pg_temp.sim_note(v_club.label, v_number, 'création du match', v_state, v_message);
        continue;
      end;
      insert into sim_matches values (v_club.label, v_number, v_match, v_gf, v_ga);

      -- Disponibilités : environ 4 joueurs sur 5 sont disponibles.
      for v_player in select * from sim_players where club = v_club.label order by number loop
        begin
          perform pg_temp.sim_as(v_player.profile_id);
          perform public.set_my_match_availability(
            v_match,
            case when (v_player.number + v_number) % 5 = 0 then 'absent' else 'available' end,
            null
          );
          perform pg_temp.sim_as(null);
        exception when others then
          get stacked diagnostics v_state = returned_sqlstate, v_message = message_text;
          perform pg_temp.sim_note(v_club.label, v_number, 'disponibilité joueur ' || v_player.number, v_state, v_message);
        end;
      end loop;

      -- Pronostics : chaque joueur parie un score.
      for v_player in select * from sim_players where club = v_club.label order by number loop
        begin
          perform pg_temp.sim_as(v_player.profile_id);
          perform public.save_match_prediction(
            v_match, (v_player.number + v_number) % 4, (v_player.number * 2 + v_number) % 3
          );
          perform pg_temp.sim_as(null);
        exception when others then
          get stacked diagnostics v_state = returned_sqlstate, v_message = message_text;
          perform pg_temp.sim_note(v_club.label, v_number, 'pronostic joueur ' || v_player.number, v_state, v_message);
        end;
      end loop;

      -- Convocations puis composition publiées par l'administrateur.
      begin
        perform pg_temp.sim_as(v_club.admin_id);
        perform public.admin_publish_match_convocations(v_match, 'Simulation');

        v_field := 0;
        select jsonb_agg(
          jsonb_build_object(
            'participant_id', ranked.participant_id,
            'zone', ranked.zone,
            'x', case when ranked.zone = 'field'
                      then round((0.05 + 0.08 * (ranked.sort_order % 12))::numeric, 2) end,
            'y', case when ranked.zone = 'field'
                      then round((0.15 + 0.06 * (ranked.sort_order % 12))::numeric, 2) end,
            'slot_label', ranked.slot_label,
            'sort_order', ranked.sort_order
          ) order by ranked.sort_order
        ) into v_entries
        from (
          select
            participant.id as participant_id,
            row_number() over (order by player.position, player.id) as sort_order,
            case
              when participant.convocation_status::text <> 'convoked' then 'not_selected'
              when row_number() over (
                partition by participant.convocation_status::text = 'convoked'
                order by player.position, player.id
              ) <= 11 then 'field'
              else 'bench'
            end as zone,
            player.position::text as slot_label
          from public.match_sport_participants participant
          join public.season_players player on player.id = participant.season_player_id
          where participant.match_id = v_match and participant.is_eligible
        ) ranked;

        perform public.admin_save_match_composition(v_match, '4-4-2', v_entries, false, 'Simulation');
        perform public.admin_publish_match_composition(v_match, false, 'Simulation');
        perform pg_temp.sim_as(null);
      exception when others then
        get stacked diagnostics v_state = returned_sqlstate, v_message = message_text;
        perform pg_temp.sim_note(v_club.label, v_number, 'convocations et composition', v_state, v_message);
        perform pg_temp.sim_as(null);
      end;

      -- Le match se joue : on le place dans le passé, un match par semaine.
      set local session_replication_role = replica;
      v_kickoff := now() - make_interval(days => 7 * (11 - v_number)) - interval '3 hours';
      update public.matches
      set kickoff_at = v_kickoff,
          match_date = (v_kickoff at time zone 'Europe/Paris')::date,
          match_time = (v_kickoff at time zone 'Europe/Paris')::time
      where id = v_match;
      set local session_replication_role = origin;

      -- Résultat, présents et buteurs saisis par l'administrateur.
      begin
        select jsonb_agg(jsonb_build_object(
          'participant_id', lineup.participant_id,
          'present', lineup.zone in ('field', 'bench'),
          'final_selection_status', case lineup.zone
            when 'field' then 'starter'
            when 'bench' then 'substitute'
            else 'not_selected'
          end,
          -- Les buts vont aux premiers titulaires de champ, un chacun.
          'goals', case when lineup.scorer_rank <= v_gf then 1 else 0 end,
          'clean_sheet', lineup.is_goalkeeper and lineup.zone = 'field' and v_ga = 0
        ) order by lineup.position)
        into v_payload
        from (
          select
            participant.id as participant_id,
            coalesce(entry.zone::text, 'not_selected') as zone,
            player.position,
            player.is_goalkeeper,
            case
              when entry.zone::text = 'field' and not player.is_goalkeeper
              then row_number() over (
                partition by (entry.zone::text = 'field' and not player.is_goalkeeper)
                order by player.position
              )
              else 999
            end as scorer_rank
          from public.match_sport_participants participant
          join public.season_players player on player.id = participant.season_player_id
          left join public.match_composition_entries entry
            on entry.participant_id = participant.id and entry.match_id = v_match
          where participant.match_id = v_match and participant.is_eligible
        ) lineup;

        perform pg_temp.sim_as(v_club.admin_id);
        perform public.admin_finalize_match_sport_postgame(v_match, v_gf, v_ga, v_payload, 'Simulation');
        perform pg_temp.sim_as(null);
      exception when others then
        get stacked diagnostics v_state = returned_sqlstate, v_message = message_text;
        perform pg_temp.sim_note(v_club.label, v_number, 'résultat du match', v_state, v_message);
        perform pg_temp.sim_as(null);
        continue;
      end;

      -- Vote de l'Étoile du match : chaque présent vote pour le premier
      -- buteur (ou le gardien), ou pour un autre présent s'il s'agit de lui.
      select participant.id into v_scorer
      from public.match_sport_participants participant
      join public.season_players player on player.id = participant.season_player_id
      join public.match_composition_entries entry
        on entry.participant_id = participant.id and entry.match_id = v_match
      where participant.match_id = v_match and entry.zone::text = 'field'
      order by (player.position = 2) desc, player.position
      limit 1;

      for v_player in
        select sim.*, participant.id as participant_id
        from sim_players sim
        join public.match_sport_participants participant
          on participant.season_player_id = sim.season_player_id and participant.match_id = v_match
        join public.match_composition_entries entry
          on entry.participant_id = participant.id and entry.match_id = v_match
        where sim.club = v_club.label and entry.zone::text in ('field', 'bench')
        order by sim.number
      loop
        v_candidate := v_scorer;
        if v_player.participant_id = v_scorer then
          select participant.id into v_candidate
          from public.match_sport_participants participant
          join public.match_composition_entries entry
            on entry.participant_id = participant.id and entry.match_id = v_match
          where participant.match_id = v_match and entry.zone::text = 'field'
            and participant.id <> v_scorer
          limit 1;
        end if;
        begin
          perform pg_temp.sim_as(v_player.profile_id);
          perform public.cast_match_motm_vote(v_match, v_candidate);
          perform pg_temp.sim_as(null);
        exception when others then
          get stacked diagnostics v_state = returned_sqlstate, v_message = message_text;
          perform pg_temp.sim_note(v_club.label, v_number, 'vote Étoile joueur ' || v_player.number, v_state, v_message);
          perform pg_temp.sim_as(null);
        end;
      end loop;

      begin
        perform private.close_match_motm_election(v_match, false);
      exception when others then
        get stacked diagnostics v_state = returned_sqlstate, v_message = message_text;
        perform pg_temp.sim_note(v_club.label, v_number, 'clôture du vote', v_state, v_message);
      end;
    end loop;
  end loop;
end;
$$;

-- Toutes les étapes en échec, une par ligne, pour le rapport de la CI.
select diag(format('ÉCHEC club %s match %s — %s : [%s] %s',
  club, match_number, step, state, message))
from sim_errors order by id;

select is(
  (select count(*) from sim_errors),
  0::bigint,
  'toutes les étapes de la saison simulée passent'
);

-- ---------------------------------------------------------------------------
-- 4. Vérifications de fin de saison, club par club
-- ---------------------------------------------------------------------------
select is(
  (select count(*) from public.matches
   where season_id in (select season_id from sim_clubs) and status = 'termine'),
  20::bigint,
  'les 20 matchs (10 par club) sont terminés'
);

select is(
  (select count(*) from public.match_sport_motm_results
   where match_id in (select match_id from sim_matches)),
  20::bigint,
  'chaque match a son Étoile du match'
);

select is(
  (select coalesce(sum(stats.goals), 0) from public.match_player_stats stats
   where stats.match_id in (select match_id from sim_matches where club = 'a')),
  (select sum(goals_for)::bigint from sim_matches where club = 'a'),
  'club A : les buts des joueurs correspondent aux scores'
);
select is(
  (select coalesce(sum(stats.goals), 0) from public.match_player_stats stats
   where stats.match_id in (select match_id from sim_matches where club = 'b')),
  (select sum(goals_for)::bigint from sim_matches where club = 'b'),
  'club B : les buts des joueurs correspondent aux scores'
);

select cmp_ok(
  (select count(*) from public.match_attendance
   where match_id in (select match_id from sim_matches)),
  '>=',
  (select count(*) * 11 from sim_matches),
  'au moins 11 présents enregistrés par match'
);

-- Ce que voit chaque club, avec son propre compte.
create function pg_temp.sim_view(p_label text) returns table (
  classement integer, buteurs integer, stats_joueurs integer, pronos integer,
  badges integer, autres_clubs integer
)
language plpgsql as $$
declare
  v_admin uuid := (select admin_id from sim_clubs where label = p_label);
  v_other uuid := (select id from sim_clubs where label <> p_label);
begin
  perform pg_temp.sim_as(v_admin);
  return query select
    (select count(*)::integer from public.v_classement_general),
    (select count(*)::integer from public.v_scorer_standings),
    (select count(*)::integer from public.v_player_season_stats),
    (select count(*)::integer from public.match_predictions where is_filled),
    (select count(*)::integer from public.profile_badges),
    (
      (select count(*) from public.matches where club_id = v_other)
      + (select count(*) from public.match_predictions where club_id = v_other)
      + (select count(*) from public.profile_badges where club_id = v_other)
      + (select count(*) from public.season_players where club_id = v_other)
    )::integer;
  perform pg_temp.sim_as(null);
end;
$$;

select diag(format(
  'club %s : classement %s lignes, buteurs %s, stats joueurs %s, pronostics remplis %s, badges attribués %s',
  label, v.classement, v.buteurs, v.stats_joueurs, v.pronos, v.badges
))
from sim_clubs, lateral pg_temp.sim_view(label) v
order by label;

select is(
  (select sum(v.autres_clubs)::integer from sim_clubs, lateral pg_temp.sim_view(label) v),
  0,
  'pendant toute la saison, aucun club ne voit les données de l’autre'
);
select ok(
  (select bool_and(v.classement > 0 and v.buteurs > 0 and v.stats_joueurs > 0)
   from sim_clubs, lateral pg_temp.sim_view(label) v),
  'chaque club a un classement des pronostics, des buteurs et des stats joueurs'
);
select is(
  (select min(v.pronos) from sim_clubs, lateral pg_temp.sim_view(label) v),
  200,
  'chaque club a 200 pronostics remplis (20 joueurs × 10 matchs)'
);
select ok(
  (select bool_and(v.badges > 0) from sim_clubs, lateral pg_temp.sim_view(label) v),
  'des badges automatiques sont attribués dans chaque club'
);

-- ---------------------------------------------------------------------------
-- 5. Clôture de la saison : titres et bilan personnel
-- ---------------------------------------------------------------------------
do $$
declare
  v_club record;
  v_state text;
  v_message text;
begin
  for v_club in select * from sim_clubs order by label loop
    begin
      perform pg_temp.sim_as(v_club.admin_id);
      perform public.set_season_status(v_club.season_id, 'archived');
      perform pg_temp.sim_as(null);
    exception when others then
      get stacked diagnostics v_state = returned_sqlstate, v_message = message_text;
      perform pg_temp.sim_note(v_club.label, null, 'clôture de la saison', v_state, v_message);
      perform pg_temp.sim_as(null);
    end;
    begin
      perform private.build_season_wrapped(v_club.season_id);
    exception when others then
      get stacked diagnostics v_state = returned_sqlstate, v_message = message_text;
      perform pg_temp.sim_note(v_club.label, null, 'calcul du bilan', v_state, v_message);
    end;
  end loop;
end;
$$;

select diag(format('ÉCHEC club %s — %s : [%s] %s', club, step, state, message))
from sim_errors where match_number is null order by id;

select is(
  (select count(*) from sim_errors where match_number is null),
  0::bigint,
  'la clôture de saison passe dans les deux clubs'
);

select ok(
  (select count(distinct club_id) = 2 from public.season_awards
   where season_id in (select season_id from sim_clubs)),
  'chaque club reçoit ses titres de fin de saison'
);

select is(
  (select count(*) from public.season_wrapped
   where season_id in (select season_id from sim_clubs)),
  40::bigint,
  'chaque joueur des deux clubs a son bilan de saison'
);

select pg_temp.sim_as(profile_id) from sim_players where club = 'b' and number = 2;
select ok(
  public.get_my_season_wrapped() is not null,
  'un joueur du club B ouvre son bilan de saison'
);
select is(
  (select count(*) from public.season_wrapped
   where club_id = (select id from sim_clubs where label = 'a')),
  0::bigint,
  'un joueur du club B ne voit aucun bilan du club A'
);
select pg_temp.sim_as(null);

select * from finish();
rollback;
