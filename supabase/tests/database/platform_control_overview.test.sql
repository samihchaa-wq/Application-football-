begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Poste de contrôle de l'éditeur : visites (une par personne et par jour),
-- vue d'ensemble par club et chiffres globaux, effacement des clubs impayés
-- 3 ans après leur suspension.

create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
grant select on test_clubs to authenticated;
insert into test_clubs
select 'alpha', (public.create_club('Club Poste Alpha', 'PALPHA', null, null, null, null)).id;
insert into test_clubs
select 'bravo', (public.create_club('Club Poste Bravo', 'PBRAVO', null, null, null, null)).id;
insert into test_clubs
select 'vieux', (public.create_club('Club Poste Vieux', 'PVIEUX', null, null, null, null)).id;
insert into test_clubs
select 'recent', (public.create_club('Club Poste Recent', 'PRECENT', null, null, null, null)).id;
insert into test_clubs
select 'manuel', (public.create_club('Club Poste Manuel', 'PMANUEL', null, null, null, null)).id;

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select v.id::uuid, v.id || '@example.invalid',
  jsonb_build_object('first_name', 'Test', 'last_name', v.label),
  jsonb_build_object('club_id', (select id from test_clubs where label = v.club))
from (values
  ('7a000000-0000-0000-0000-000000000001', 'Un', 'alpha'),
  ('7a000000-0000-0000-0000-000000000002', 'Deux', 'alpha'),
  ('7a000000-0000-0000-0000-000000000003', 'Trois', 'alpha'),
  ('7a000000-0000-0000-0000-000000000004', 'Quatre', 'bravo'),
  ('7a000000-0000-0000-0000-000000000005', 'Ancien', 'vieux'),
  ('7a000000-0000-0000-0000-000000000006', 'Recent', 'recent'),
  ('7a000000-0000-0000-0000-0000000000e1', 'Editeur', 'manuel')
) as v(id, label, club);
update public.profiles set status = 'active' where id::text like '7a000000-%';
update public.profiles set status = 'archived' where id = '7a000000-0000-0000-0000-000000000003';
update public.profiles set role = 'admin' where id = '7a000000-0000-0000-0000-000000000001';
insert into private.platform_operators (user_id) values ('7a000000-0000-0000-0000-0000000000e1');

-- Bravo a été parrainé par Alpha.
select ok(public.attach_club_referral(
  (select id from test_clubs where label = 'bravo'),
  (select referral_code from public.clubs where id = (select id from test_clubs where label = 'alpha'))
), 'Bravo est parrainé par Alpha');

-- ---------------------------------------------------------------------------
-- Visites
-- ---------------------------------------------------------------------------

create function pg_temp.visit_as(p_id text) returns void language plpgsql as $f$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_id, 'role', 'authenticated', 'aud', 'authenticated')::text, true);
  set local role authenticated;
  perform public.log_app_visit();
  reset role;
end;
$f$;

select pg_temp.visit_as('7a000000-0000-0000-0000-000000000001');
select pg_temp.visit_as('7a000000-0000-0000-0000-000000000001');
select pg_temp.visit_as('7a000000-0000-0000-0000-000000000002');
select pg_temp.visit_as('7a000000-0000-0000-0000-000000000003');
select pg_temp.visit_as('7a000000-0000-0000-0000-000000000004');

select is(
  (select count(*)::int from private.profile_daily_visits
   where club_id = (select id from test_clubs where label = 'alpha')),
  2,
  'une seule visite par personne et par jour ; un membre archivé n''est pas compté'
);

-- Visites passées : 28 jours de plus pour une personne d'Alpha.
insert into private.profile_daily_visits (club_id, profile_id, day)
select (select id from test_clubs where label = 'alpha'),
       '7a000000-0000-0000-0000-000000000001',
       (now() at time zone 'Europe/Paris')::date - n
from generate_series(1, 28) n;
-- Alpha existe depuis 60 jours : la moyenne porte sur 30 jours.
update public.clubs set created_at = now() - interval '60 days'
where id = (select id from test_clubs where label = 'alpha');

select ok(
  not has_table_privilege('authenticated', 'private.profile_daily_visits', 'select'),
  'les visites ne sont pas lisibles depuis l''appli'
);

-- ---------------------------------------------------------------------------
-- Vue d'ensemble
-- ---------------------------------------------------------------------------

-- Un paiement pour Bravo (premier paiement d'un filleul).
select set_config('request.jwt.claims',
  '{"sub":"7a000000-0000-0000-0000-0000000000e1","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select lives_ok(
  $$select public.platform_record_offline_payment((select id from test_clubs where label = 'bravo'), 7505, 'virement')$$,
  'Bravo paie sa première année avec −5 %'
);

create temporary table overview on commit drop as
select public.platform_control_overview() as data;
reset role;

create function pg_temp.club(p_label text) returns jsonb language sql as $f$
  select row_data
  from overview, jsonb_array_elements(overview.data -> 'clubs') row_data
  where row_data ->> 'id' = (select id::text from test_clubs where label = p_label)
$f$;

select is((pg_temp.club('alpha') ->> 'members')::int, 2, 'effectif : membres actifs seulement');
select is((pg_temp.club('alpha') ->> 'visits_30d')::int, 30, 'visites des 30 derniers jours');
select is((pg_temp.club('alpha') ->> 'visits_per_day')::numeric, 1.0, 'moyenne : 30 visites sur 30 jours');
select is((pg_temp.club('alpha') ->> 'people_7d')::int, 2, 'personnes venues cette semaine');
select is((pg_temp.club('alpha') ->> 'visits_today')::int, 2, 'visites du jour');
select is((pg_temp.club('bravo') ->> 'visits_per_day')::numeric, 1.0,
  'club créé aujourd''hui : la moyenne porte sur ses jours d''existence');
select is((pg_temp.club('alpha') ->> 'referrals_total')::int, 1, 'Alpha a un filleul');
select is((pg_temp.club('alpha') ->> 'referrals_paid')::int, 1, 'qui a payé');
select is((pg_temp.club('alpha') ->> 'discount_percent')::int, 5, 'Alpha a donc −5 %');
select is((pg_temp.club('alpha') ->> 'amount_due_cents')::int, 7505, 'et paiera 75,05 € à sa prochaine échéance');
select is(pg_temp.club('bravo') ->> 'referred_by', 'Club Poste Alpha', 'Bravo affiche son parrain');
select is((pg_temp.club('bravo') ->> 'paid_cents')::int, 7505, 'total payé par Bravo');
select is((pg_temp.club('bravo') ->> 'amount_due_cents')::int, 7900,
  'après sa première année, Bravo revient au tarif plein');
select is(pg_temp.club('alpha') ->> 'subscription_status', 'trialing', 'Alpha est en mois gratuit');
select is(
  (pg_temp.club('alpha') ->> 'next_due_at')::timestamptz,
  (select trial_ends_at from public.club_subscriptions where club_id = (select id from test_clubs where label = 'alpha')),
  'pendant le mois gratuit, la prochaine échéance est la fin de l''essai'
);
select is(
  (pg_temp.club('bravo') ->> 'next_due_at')::timestamptz,
  (select current_period_end from public.club_subscriptions where club_id = (select id from test_clubs where label = 'bravo')),
  'pour un club abonné, c''est la fin de l''année payée'
);

select ok((select (data -> 'totals' ->> 'collected_total_cents')::int >= 7505 from overview), 'total encaissé');
select ok((select (data -> 'totals' ->> 'paying')::int >= 1 from overview), 'nombre de clubs abonnés');
select is((select jsonb_array_length(data -> 'daily_visits') from overview), 30, 'courbe des visites sur 30 jours');
select ok(
  (select (data -> 'daily_visits' -> 29 ->> 'visits')::int >= 3 from overview),
  'le dernier point de la courbe est aujourd''hui'
);

-- Accès refusé à un admin de club.
select set_config('request.jwt.claims',
  '{"sub":"7a000000-0000-0000-0000-000000000001","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select throws_ok($$select public.platform_control_overview()$$, '42501', null,
  'un administrateur de club n''a pas accès au poste de contrôle');
reset role;

-- ---------------------------------------------------------------------------
-- Effacement 3 ans après une suspension pour impayé
-- ---------------------------------------------------------------------------

select is(private.unpaid_data_retention(), interval '3 years', 'conservation : 3 ans');
select is(
  (select count(*)::int from cron.job where jobname = 'purge-expired-clubs' and active),
  1,
  'l''effacement est vérifié chaque nuit'
);

select set_config('request.jwt.claims', '', true);

-- Vieux : suspendu pour impayé il y a 3 ans et 1 jour, avec un journal de
-- badges (qui refuse d'ordinaire toute suppression) et une visite.
-- Récent : suspendu pour impayé il y a 2 ans. Manuel : suspendu à la main.
update public.club_subscriptions set auto_suspended_at = now() - interval '3 years 1 day'
where club_id = (select id from test_clubs where label = 'vieux');
update public.club_subscriptions set auto_suspended_at = now() - interval '2 years'
where club_id = (select id from test_clubs where label = 'recent');
update public.clubs set status = 'suspended'
where id in (select id from test_clubs where label in ('vieux', 'recent', 'manuel'));
insert into private.profile_daily_visits (club_id, profile_id, day)
values ((select id from test_clubs where label = 'vieux'), '7a000000-0000-0000-0000-000000000005', current_date - 1200);
insert into private.profile_badge_audit_log (event_type, profile_id, badge_code, badge_name, club_id)
values ('award', '7a000000-0000-0000-0000-000000000005', 'test', 'Test',
        (select id from test_clubs where label = 'vieux'));

select is(
  (pg_temp.club('alpha') ->> 'deletion_at'), null,
  'un club actif n''a pas de date d''effacement'
);

select is(private.purge_expired_clubs(), 1, 'un seul club a dépassé les 3 ans');
select ok(not exists (select 1 from public.clubs where id = (select id from test_clubs where label = 'vieux')),
  'le club impayé depuis plus de 3 ans est effacé');
select ok(not exists (select 1 from public.profiles where club_id = (select id from test_clubs where label = 'vieux')),
  'ses membres aussi');
select ok(not exists (select 1 from private.profile_badge_audit_log where club_id = (select id from test_clubs where label = 'vieux')),
  'son journal de badges aussi');
select ok(not exists (select 1 from auth.users where id = '7a000000-0000-0000-0000-000000000005'),
  'et ses comptes de connexion');
select ok(exists (select 1 from public.clubs where id = (select id from test_clubs where label = 'recent')),
  'un club impayé depuis 2 ans est gardé intact');
select ok(exists (select 1 from public.profiles where id = '7a000000-0000-0000-0000-000000000006'),
  'avec ses membres');
select ok(exists (select 1 from public.clubs where id = (select id from test_clubs where label = 'manuel')),
  'un club suspendu à la main n''est jamais effacé automatiquement');
select ok(exists (select 1 from auth.users where id = '7a000000-0000-0000-0000-0000000000e1'),
  'le compte éditeur n''est jamais effacé');
select is(
  (select status from public.club_subscriptions where club_id = (select id from test_clubs where label = 'alpha')),
  'trialing',
  'les autres clubs ne sont pas touchés'
);
select is(private.purge_expired_clubs(), 0, 'relancer ne fait rien de plus');

select ok(
  not has_function_privilege('authenticated', 'private.purge_expired_clubs(timestamptz)', 'execute')
  and not has_function_privilege('anon', 'private.purge_expired_clubs(timestamptz)', 'execute'),
  'personne ne peut déclencher l''effacement depuis l''appli'
);

select * from finish();
rollback;
