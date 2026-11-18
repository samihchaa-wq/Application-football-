begin;
set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Rejoue le vrai script du club de démo (supabase/demo/club_demo.sql) deux
-- fois dans cette transaction, puis annule tout. Base isolée de la CI
-- uniquement. Lancé avec psql (\ir), comme la recette de migration HDM.

-- Un autre club, qui ne doit pas être touché par la remise à zéro.
create temporary table other_club on commit drop as
select (public.create_club('Club Voisin QA', 'VOISIN')).id;
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select 'dd180000-0000-4000-8000-000000000001'::uuid, 'voisin-qa@example.invalid',
       '{"first_name":"Voisin","last_name":"QA"}'::jsonb, jsonb_build_object('club_id', id)
from other_club;

\set demo_password 'motdepasse-demo-ci-123'
\set username_domain 'comptes.test.invalid'

-- Première création.
\ir ../../demo/club_demo.sql

create temporary table first_run on commit drop as
select current_setting('demo.club_id')::uuid as club_id;

-- Remise à zéro : deuxième passage.
\ir ../../demo/club_demo.sql

select isnt(
  current_setting('demo.club_id')::uuid,
  (select club_id from first_run),
  'la remise à zéro recrée un club neuf'
);
select is(
  (select count(*) from public.clubs where id = (select club_id from first_run)),
  0::bigint,
  'l’ancien club de démo est supprimé avec ses données'
);
create function pg_temp.rows_left_for_club(p_club uuid) returns bigint
language plpgsql as $$
declare
  v_table record;
  v_count bigint;
  v_total bigint := 0;
begin
  for v_table in
    select namespace.nspname as schema_name, class.relname as table_name
    from pg_attribute attribute
    join pg_class class on class.oid = attribute.attrelid
    join pg_namespace namespace on namespace.oid = class.relnamespace
    where attribute.attname = 'club_id' and not attribute.attisdropped
      and class.relkind in ('r', 'p') and namespace.nspname in ('public', 'private')
  loop
    execute format('select count(*) from %I.%I where club_id = $1', v_table.schema_name, v_table.table_name)
    into v_count using p_club;
    v_total := v_total + v_count;
  end loop;
  return v_total;
end;
$$;
select is(
  pg_temp.rows_left_for_club((select club_id from first_run)),
  0::bigint,
  'aucune ligne de l’ancien club ne reste, dans aucune table'
);
select is(
  (select count(*) from public.clubs where name = 'FC Démo'),
  1::bigint,
  'un seul club de démo après deux passages'
);
select is(
  (select count(*) from auth.users where id::text like 'de000000-0000-4000-8000-%'),
  19::bigint,
  'les 19 comptes de démo existent une seule fois'
);
select is(
  (select count(*) from auth.users u
   where u.id::text like 'de000000-0000-4000-8000-%'
     and not exists (select 1 from public.profiles p where p.id = u.id)),
  0::bigint,
  'aucun compte de connexion sans club ne reste après la remise à zéro'
);
select is(
  (select count(*) from public.profiles where id = 'dd180000-0000-4000-8000-000000000001'),
  1::bigint,
  'le membre d’un autre club n’est pas touché'
);

-- Comptes de connexion.
select ok(
  (select encrypted_password = extensions.crypt('motdepasse-demo-ci-123', encrypted_password)
   from auth.users where email = 'demoadmin@comptes.test.invalid'),
  'demoadmin se connecte avec le mot de passe donné'
);
select ok(
  (select encrypted_password = extensions.crypt('motdepasse-demo-ci-123', encrypted_password)
   from auth.users where email = 'demojoueur@comptes.test.invalid'),
  'demojoueur se connecte avec le mot de passe donné'
);
select is(
  (select count(*) from auth.users
   where id::text like 'de000000-0000-4000-8000-%' and encrypted_password <> ''),
  2::bigint,
  'seuls deux comptes de démo ont un mot de passe'
);
select is(
  (select role from public.profiles where username = 'demoadmin'),
  'admin',
  'demoadmin est administrateur'
);
select is(
  (select role from public.profiles where username = 'demojoueur'),
  'pronostiqueur',
  'demojoueur est joueur'
);

-- Contenu visible par le prospect.
select pg_temp.demo_as(pg_temp.demo_id(2));
select ok((select count(*) from public.v_classement_general) > 0, 'classement des pronostics rempli');
select ok((select count(*) from public.v_scorer_standings) > 3, 'plusieurs buteurs au classement');
select is(
  (select count(*) from public.matches where kickoff_at > now()),
  1::bigint,
  'le joueur voit le prochain match'
);
select is(
  (select count(*) from public.matches where club_id <> current_setting('demo.club_id')::uuid),
  0::bigint,
  'le joueur de démo ne voit aucun match d’un autre club'
);
select pg_temp.demo_as(null);

select ok(
  (select count(distinct participant.season_player_id) >= 5
   from public.match_sport_motm_results winner
   join public.match_sport_participants participant on participant.id = winner.participant_id
   join public.matches match on match.id = winner.match_id
   where match.club_id = current_setting('demo.club_id')::uuid and winner.is_winner),
  'au moins 5 joueurs différents ont été Homme du match'
);
-- Règle de l'appli : pas de bilan personnel avant la saison 2026-2027.
-- Tant que la saison terminée de la démo est plus ancienne, elle n'en a pas.
select ok(
  (select case
     when private.season_wrapped_is_supported(season.id)
       then (select count(*) from public.season_wrapped wrapped where wrapped.season_id = season.id) >= 12
     else (select count(*) from public.season_wrapped wrapped where wrapped.season_id = season.id) = 0
   end
   from public.seasons season
   where season.club_id = current_setting('demo.club_id')::uuid and season.status = 'archived'),
  'la saison terminée a ses bilans personnels quand l’appli les prévoit'
);
select ok(
  (select count(*) from public.profile_badges where club_id = current_setting('demo.club_id')::uuid) > 0,
  'des badges sont débloqués'
);
select is(
  (select notes from public.club_subscriptions where club_id = current_setting('demo.club_id')::uuid),
  'Club de démonstration pour les prospects : ne pas facturer.',
  'l’abonnement est marqué « ne pas facturer »'
);

select * from finish();
rollback;
