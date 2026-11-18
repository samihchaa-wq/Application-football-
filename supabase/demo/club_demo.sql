-- Club de démonstration pour les prospects : « FC Démo ».
--
-- Crée (ou recrée à neuf) un club fictif complet : un administrateur,
-- 18 joueurs, une saison terminée avec son bilan, une saison en cours et un
-- match à venir dans 3 jours (disponibilités et pronostics ouverts).
-- Toutes les dates sont calculées à partir du jour où le script tourne : la
-- démo a toujours un « prochain match ».
--
-- Remise à zéro : relancer le script. Il supprime d'abord l'ancien club de
-- démo, ses données et ses comptes de connexion, puis recrée tout.
--
-- Deux comptes de connexion, à donner aux prospects :
--   demoadmin   (administrateur)
--   demojoueur  (joueur)
-- Les 17 autres joueurs n'ont pas de mot de passe : impossible de s'y connecter.
--
-- Sécurité :
--   - notifications coupées pour ce club (coupe-circuit) avant la moindre
--     écriture : aucun envoi ne part d'un faux club ;
--   - abonnement marqué « ne pas facturer » ;
--   - aucun autre club n'est touché : tout passe par l'identifiant fixe des
--     comptes de démo (de000000-0000-4000-8000-…).
--
-- Utilisation (base en ligne, avec l'accord du propriétaire uniquement) :
--
--   psql "$DATABASE_URL" --single-transaction -v ON_ERROR_STOP=1 \
--     -v demo_password='<mot de passe de 12 caractères ou plus>' \
--     -v username_domain='<USERNAME_DOMAIN de config/production.json>' \
--     -f supabase/demo/club_demo.sql
--
-- Le mot de passe n'est jamais écrit dans le dépôt.
-- Le script ne contient ni BEGIN ni COMMIT : --single-transaction fait que
-- tout passe ou rien ne passe.
-- Testé en CI par supabase/tests/database/demo_club_script.test.sql.

\if :{?demo_password}
\else
  \echo 'Variable demo_password manquante (-v demo_password=...).'
  \quit
\endif
\if :{?username_domain}
\else
  \echo 'Variable username_domain manquante (-v username_domain=...).'
  \quit
\endif

select set_config('demo.password', :'demo_password', true);
select set_config('demo.username_domain', :'username_domain', true);

do $$
begin
  if char_length(current_setting('demo.password')) < 12 then
    raise exception 'Le mot de passe de démo doit faire au moins 12 caractères.';
  end if;
  if current_setting('demo.username_domain') !~ '^[a-z0-9.-]+$' then
    raise exception 'username_domain invalide.';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Outils de session
-- ---------------------------------------------------------------------------

-- Passe sous l'identité d'un compte connecté (ou revient au propriétaire).
create or replace function pg_temp.demo_as(p_profile uuid) returns void
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

-- Identifiant fixe des comptes de démo : 0 = administrateur, 1..18 = joueurs.
create or replace function pg_temp.demo_id(p_number integer) returns uuid
language sql immutable as $$
  select ('de000000-0000-4000-8000-' || lpad(p_number::text, 12, '0'))::uuid;
$$;

drop table if exists pg_temp.demo_players;
create temporary table demo_players (
  number integer primary key,
  profile_id uuid not null,
  first_name text not null,
  last_name text not null,
  season_player_id uuid
);
grant select on demo_players to authenticated;

insert into demo_players (number, profile_id, first_name, last_name)
select n, pg_temp.demo_id(n), names.first_name, names.last_name
from unnest(
  array['Lucas','Hugo','Nathan','Théo','Maxime','Antoine','Julien','Romain','Kevin',
        'Yanis','Mehdi','Thomas','Sofiane','Baptiste','Alexis','Florian','Karim','Quentin'],
  array['Moreau','Lefèvre','Girard','Fontaine','Roux','Chevalier','Mercier','Blanc','Garnier',
        'Bertrand','Fabre','Lambert','Rousseau','Vincent','Morel','Dupuis','Benali','Perrin']
) with ordinality as names(first_name, last_name, n);

-- ---------------------------------------------------------------------------
-- 1. Suppression de l'ancien club de démo et de ses comptes
-- ---------------------------------------------------------------------------
-- Ordre imposé : le club d'abord (ses données partent en cascade), les
-- comptes de connexion ensuite. Sont aussi retirés les comptes qu'un prospect
-- aurait créés dans le club de démo avec son code d'invitation.
do $$
declare
  v_old_clubs uuid[];
  v_users uuid[];
begin
  select array_agg(distinct profile.club_id) into v_old_clubs
  from public.profiles profile
  where profile.id::text like 'de000000-0000-4000-8000-%';

  select array_agg(distinct profile.id) into v_users
  from public.profiles profile
  where profile.club_id = any(coalesce(v_old_clubs, '{}'))
    and profile.id not in (select operator.user_id from private.platform_operators operator);

  delete from public.clubs where id = any(coalesce(v_old_clubs, '{}'));
  delete from auth.users
  where id = any(coalesce(v_users, '{}'))
     or id::text like 'de000000-0000-4000-8000-%';
end;
$$;

-- ---------------------------------------------------------------------------
-- 2. Le club, ses réglages et ses comptes
-- ---------------------------------------------------------------------------
do $$
declare
  v_club uuid;
  v_domain text := current_setting('demo.username_domain');
  v_password text := extensions.crypt(current_setting('demo.password'), extensions.gen_salt('bf'));
  v_player record;
  v_login boolean;
  v_username text;
begin
  v_club := (public.create_club('FC Démo', 'FCDEMO', '#1B5E20', '#FFFFFF', 'Europe/Paris', null)).id;
  perform set_config('demo.club_id', v_club::text, true);
  perform set_config('app.club_id', v_club::text, true);

  -- Coupe-circuit avant toute écriture : aucune notification ne part.
  update private.app_feature_flags
  set enabled = true, updated_at = now()
  where club_id = v_club and key = 'notifications_paused';
  update private.app_feature_flags
  set enabled = true, updated_at = now()
  where club_id = v_club and key = 'sports_management';

  update public.club_subscriptions
  set status = 'active',
      current_period_end = now() + interval '10 years',
      notes = 'Club de démonstration pour les prospects : ne pas facturer.',
      updated_at = now()
  where club_id = v_club;

  -- Administrateur (0) puis joueurs (1..18). Seuls demoadmin et demojoueur
  -- (joueur n° 2) ont un mot de passe.
  for v_player in
    select 0 as number, pg_temp.demo_id(0) as profile_id, 'Coach'::text as first_name, 'Démo'::text as last_name
    union all
    select number, profile_id, first_name, last_name from demo_players
    order by number
  loop
    v_login := v_player.number in (0, 2);
    v_username := case v_player.number when 0 then 'demoadmin' when 2 then 'demojoueur' end;

    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change
    ) values (
      '00000000-0000-0000-0000-000000000000', v_player.profile_id, 'authenticated', 'authenticated',
      case when v_login then v_username || '@' || v_domain
           else format('demo-%s@example.invalid', v_player.number) end,
      case when v_login then v_password else '' end,
      now(),
      jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email'), 'club_id', v_club),
      jsonb_build_object('first_name', v_player.first_name, 'last_name', v_player.last_name),
      now(), now(), '', '', '', ''
    );

    if v_login then
      insert into auth.identities (
        provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
      ) values (
        v_player.profile_id::text, v_player.profile_id,
        jsonb_build_object(
          'sub', v_player.profile_id::text,
          'email', v_username || '@' || v_domain,
          'email_verified', true
        ),
        'email', now(), now(), now()
      );
    end if;

    update public.profiles
    set role = case when v_player.number = 0 then 'admin' else 'pronostiqueur' end,
        status = 'active',
        is_goalkeeper = (v_player.number = 1),
        username = v_username,
        password_set = v_login
    where id = v_player.profile_id;
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- 3. Une saison complète, jouée par les fonctions de l'application
-- ---------------------------------------------------------------------------
-- Chaque étape passe par la fonction qu'utilise l'appli, avec le compte qui
-- la fait dans la vraie vie. Seul le temps est avancé à la main : chaque
-- match est joué « aujourd'hui », puis reculé à sa vraie date avec toutes ses
-- dates (validation, vote), comme dans le test de saison de la CI.
create or replace function pg_temp.demo_play_season(
  p_season_name text,
  p_weeks_ago integer[],
  p_scores integer[]
) returns uuid
language plpgsql as $$
declare
  v_admin uuid := pg_temp.demo_id(0);
  v_club uuid := current_setting('demo.club_id')::uuid;
  v_season uuid;
  v_player record;
  v_number integer;
  v_match uuid;
  v_opponent uuid;
  v_kickoff timestamptz;
  v_target timestamptz;
  v_shift interval;
  v_gf integer;
  v_ga integer;
  v_entries jsonb;
  v_payload jsonb;
  v_winner uuid;
  v_candidate uuid;
  v_season_player uuid;
  v_opponents text[] := array['US Les Peupliers', 'AS Val Fleuri', 'FC Rive Gauche',
                              'Olympique des Coteaux', 'Stade du Moulin', 'ES Trois Chênes'];
begin
  perform pg_temp.demo_as(v_admin);
  v_season := public.open_or_create_season(p_season_name);
  for v_number in 1..array_length(v_opponents, 1) loop
    perform public.get_or_create_opponent(v_opponents[v_number]);
  end loop;
  perform pg_temp.demo_as(null);

  -- Effectif de la saison : les membres actifs y entrent d'eux-mêmes ; on
  -- complète le gardien et le numéro.
  for v_player in select * from demo_players order by number loop
    select id into v_season_player from public.season_players
    where season_id = v_season and profile_id = v_player.profile_id;
    if v_season_player is null then
      v_season_player := gen_random_uuid();
      insert into public.season_players (
        id, club_id, season_id, first_name, last_name, is_goalkeeper, is_active, position, profile_id
      ) values (
        v_season_player, v_club, v_season, v_player.first_name, v_player.last_name,
        v_player.number = 1, true, v_player.number, v_player.profile_id
      );
    else
      update public.season_players
      set is_goalkeeper = (v_player.number = 1), is_active = true
      where id = v_season_player;
    end if;
    update demo_players set season_player_id = v_season_player where number = v_player.number;
  end loop;

  for v_number in 1..array_length(p_weeks_ago, 1) loop
    v_gf := p_scores[2 * v_number - 1];
    v_ga := p_scores[2 * v_number];

    -- Création du match par l'administrateur, deux jours à l'avance.
    perform pg_temp.demo_as(v_admin);
    select id into v_opponent from public.opponents
    where name = v_opponents[1 + (v_number - 1) % array_length(v_opponents, 1)];
    v_kickoff := now() + interval '2 days' + make_interval(mins => v_number);
    v_match := public.admin_create_match_complete(
      v_season, v_opponent,
      (v_kickoff at time zone 'Europe/Paris')::date,
      (v_kickoff at time zone 'Europe/Paris')::time,
      case when v_number % 2 = 0 then 'domicile' else 'exterieur' end,
      2.10, 3.20, 2.90, null, null, false, 'championnat', null
    );
    perform pg_temp.demo_as(null);

    -- Disponibilités : environ 4 joueurs sur 5.
    for v_player in select * from demo_players order by number loop
      perform pg_temp.demo_as(v_player.profile_id);
      perform public.set_my_match_availability(
        v_match,
        case when (v_player.number + v_number) % 5 = 0 then 'absent' else 'available' end,
        null
      );
      perform pg_temp.demo_as(null);
    end loop;

    -- Pronostics : 15 joueurs sur 18 pronostiquent.
    for v_player in select * from demo_players where (number + v_number) % 6 <> 0 order by number loop
      perform pg_temp.demo_as(v_player.profile_id);
      perform public.save_match_prediction(
        v_match, (v_player.number + v_number) % 4, (v_player.number * 2 + v_number) % 3
      );
      perform pg_temp.demo_as(null);
    end loop;

    -- Convocations et composition publiées par l'administrateur.
    perform pg_temp.demo_as(v_admin);
    perform public.admin_publish_match_convocations(v_match, 'Démo');
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
    perform public.admin_save_match_composition(v_match, '4-4-2', v_entries, false, 'Démo');
    perform public.admin_publish_match_composition(v_match, false, 'Démo');
    perform pg_temp.demo_as(null);

    -- Le match se joue : coup d'envoi trois heures plus tôt.
    set local session_replication_role = replica;
    v_kickoff := now() - interval '3 hours' - make_interval(mins => v_number);
    update public.matches
    set kickoff_at = v_kickoff,
        match_date = (v_kickoff at time zone 'Europe/Paris')::date,
        match_time = (v_kickoff at time zone 'Europe/Paris')::time
    where id = v_match;
    set local session_replication_role = origin;

    -- Résultat, présents et buteurs. Les buts tournent entre les joueurs de
    -- champ d'un match à l'autre, pour un classement des buteurs varié.
    select jsonb_agg(jsonb_build_object(
      'participant_id', lineup.participant_id,
      'present', lineup.zone in ('field', 'bench'),
      'final_selection_status', case lineup.zone
        when 'field' then 'starter'
        when 'bench' then 'substitute'
        else 'not_selected'
      end,
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
            order by (player.position * 7 + v_number * 3) % 19, player.position
          )
          else 999
        end as scorer_rank
      from public.match_sport_participants participant
      join public.season_players player on player.id = participant.season_player_id
      left join public.match_composition_entries entry
        on entry.participant_id = participant.id and entry.match_id = v_match
      where participant.match_id = v_match and participant.is_eligible
    ) lineup;

    perform pg_temp.demo_as(v_admin);
    perform public.admin_finalize_match_sport_postgame(v_match, v_gf, v_ga, v_payload, 'Démo');
    perform pg_temp.demo_as(null);

    -- Vote de l'Homme du match : la plupart des présents votent pour le même
    -- joueur de champ, qui change à chaque match.
    select participant.id into v_winner
    from public.match_sport_participants participant
    join public.season_players player on player.id = participant.season_player_id
    join public.match_composition_entries entry
      on entry.participant_id = participant.id and entry.match_id = v_match
    where participant.match_id = v_match and entry.zone::text = 'field'
    order by (player.position * 5 + v_number * 7) % 17, player.position
    limit 1;

    for v_player in
      select demo.*, participant.id as participant_id
      from demo_players demo
      join public.match_sport_participants participant
        on participant.season_player_id = demo.season_player_id and participant.match_id = v_match
      join public.match_composition_entries entry
        on entry.participant_id = participant.id and entry.match_id = v_match
      where entry.zone::text in ('field', 'bench')
      order by demo.number
    loop
      v_candidate := v_winner;
      if v_player.participant_id = v_winner or v_player.number % 4 = 0 then
        select participant.id into v_candidate
        from public.match_sport_participants participant
        join public.match_composition_entries entry
          on entry.participant_id = participant.id and entry.match_id = v_match
        where participant.match_id = v_match and entry.zone::text = 'field'
          and participant.id not in (v_winner, v_player.participant_id)
        order by participant.id
        limit 1;
      end if;
      perform pg_temp.demo_as(v_player.profile_id);
      perform public.cast_match_motm_vote(v_match, v_candidate);
      perform pg_temp.demo_as(null);
    end loop;
    perform private.close_match_motm_election(v_match, false);

    -- Le match recule à sa vraie date, avec toutes ses dates.
    v_target := (date_trunc('day', now() at time zone 'Europe/Paris')
                 - make_interval(days => 7 * p_weeks_ago[v_number])
                 + interval '15 hours') at time zone 'Europe/Paris';
    v_shift := v_target - v_kickoff;
    set local session_replication_role = replica;
    update public.matches
    set kickoff_at = v_target,
        match_date = (v_target at time zone 'Europe/Paris')::date,
        match_time = (v_target at time zone 'Europe/Paris')::time,
        result_validated_at = result_validated_at + v_shift
    where id = v_match;
    update public.match_sport_finalizations
    set validated_at = validated_at + v_shift
    where match_id = v_match;
    update public.match_sport_motm_elections
    set opens_at = opens_at + v_shift,
        closes_at = closes_at + v_shift,
        closed_at = closed_at + v_shift
    where match_id = v_match;
    set local session_replication_role = origin;
  end loop;

  return v_season;
end;
$$;

-- Saisons : celle en cours suit le calendrier (juillet à juin).
select set_config(
  'demo.current_start_year',
  (extract(year from now() at time zone 'Europe/Paris')::integer
   - case when extract(month from now() at time zone 'Europe/Paris') >= 7 then 0 else 1 end)::text,
  true
);

-- Saison précédente : 10 matchs, un toutes les deux semaines, il y a 20 à 38
-- semaines. Puis clôture et bilan de saison.
do $$
declare
  v_year integer := current_setting('demo.current_start_year')::integer;
  v_season uuid;
begin
  v_season := pg_temp.demo_play_season(
    format('%s-%s', v_year - 1, v_year),
    array[38, 36, 34, 32, 30, 28, 26, 24, 22, 20],
    array[2,1, 0,0, 3,2, 1,2, 4,0, 2,2, 0,1, 3,1, 1,1, 2,0]
  );
  perform pg_temp.demo_as(pg_temp.demo_id(0));
  perform public.set_season_status(v_season, 'archived');
  perform pg_temp.demo_as(null);
  perform private.build_season_wrapped(v_season);
end;
$$;

-- Saison en cours : 8 matchs, un par semaine, le dernier il y a 7 jours.
do $$
declare
  v_year integer := current_setting('demo.current_start_year')::integer;
begin
  perform pg_temp.demo_play_season(
    format('%s-%s', v_year, v_year + 1),
    array[8, 7, 6, 5, 4, 3, 2, 1],
    array[1,0, 2,2, 3,1, 0,2, 2,1, 1,1, 4,2, 2,0]
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. Le prochain match, dans 3 jours à 15 h
-- ---------------------------------------------------------------------------
-- Disponibilités et pronostics ouverts (J-6). 14 joueurs ont répondu, 10 ont
-- pronostiqué : il reste de quoi montrer l'écran à remplir. demojoueur
-- (joueur n° 2) n'a encore rien rempli.
do $$
declare
  v_admin uuid := pg_temp.demo_id(0);
  v_season uuid;
  v_opponent uuid;
  v_kickoff timestamptz;
  v_match uuid;
  v_player record;
begin
  perform pg_temp.demo_as(v_admin);
  select id into v_season from public.seasons where status = 'open';
  select id into v_opponent from public.opponents where name = 'FC Rive Gauche';
  v_kickoff := ((date_trunc('day', now() at time zone 'Europe/Paris') + interval '3 days 15 hours')
                at time zone 'Europe/Paris');
  v_match := public.admin_create_match_complete(
    v_season, v_opponent,
    (v_kickoff at time zone 'Europe/Paris')::date,
    (v_kickoff at time zone 'Europe/Paris')::time,
    'domicile', 1.85, 3.40, 3.60, null, null, false, 'championnat', null
  );
  perform pg_temp.demo_as(null);

  for v_player in select * from demo_players where number <> 2 order by number limit 14 loop
    perform pg_temp.demo_as(v_player.profile_id);
    perform public.set_my_match_availability(
      v_match, case when v_player.number % 7 = 0 then 'absent' else 'available' end, null
    );
    if v_player.number <= 11 then
      perform public.save_match_prediction(v_match, v_player.number % 4, (v_player.number + 1) % 3);
    end if;
    perform pg_temp.demo_as(null);
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- 5. Contrôles : le script échoue (et rien n'est gardé) si la démo est incomplète
-- ---------------------------------------------------------------------------
do $$
declare
  v_club uuid := current_setting('demo.club_id')::uuid;
begin
  if (select count(*) from public.profiles where club_id = v_club) <> 19 then
    raise exception 'Démo : 19 comptes attendus.';
  end if;
  if (select count(*) from public.matches where club_id = v_club and status = 'termine') <> 18 then
    raise exception 'Démo : 18 matchs terminés attendus.';
  end if;
  if (select count(*) from public.matches where club_id = v_club and kickoff_at > now()) <> 1 then
    raise exception 'Démo : 1 match à venir attendu.';
  end if;
  if (select count(*) from public.seasons where club_id = v_club and status = 'archived') <> 1 then
    raise exception 'Démo : 1 saison terminée attendue.';
  end if;
  if not (select enabled from private.app_feature_flags
          where club_id = v_club and key = 'notifications_paused') then
    raise exception 'Démo : les notifications du club devraient être coupées.';
  end if;
end;
$$;

select 'Club de démo prêt' as statut,
       (select name from public.clubs where id = current_setting('demo.club_id')::uuid) as club,
       (select invite_code from public.clubs where id = current_setting('demo.club_id')::uuid) as code_invitation;
