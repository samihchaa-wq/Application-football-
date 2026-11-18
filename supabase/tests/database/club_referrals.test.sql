begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Parrainage entre clubs : code parrain, filleul relié à l'inscription,
-- réduction de 5 % par filleul payé, plafond 100 %, utilisée au paiement
-- suivant du parrain.

create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
grant select on test_clubs to authenticated;
insert into test_clubs
select 'parrain', (public.create_club('Club Parrain', 'PARR', null, null, null, null)).id;
insert into test_clubs
select 'autre', (public.create_club('Club Autre', 'AUTRE', null, null, null, null)).id;

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select v.id::uuid, v.id || '@example.invalid',
  jsonb_build_object('first_name', 'Test', 'last_name', v.label),
  jsonb_build_object('club_id', (select id from test_clubs where label = v.club))
from (values
  ('6f000000-0000-0000-0000-000000000001', 'Admin', 'parrain'),
  ('6f000000-0000-0000-0000-000000000002', 'Membre', 'parrain'),
  ('6f000000-0000-0000-0000-000000000003', 'Voisin', 'autre'),
  ('6f000000-0000-0000-0000-0000000000e1', 'Editeur', 'autre')
) as v(id, label, club);
update public.profiles set status = 'active' where id::text like '6f000000-%';
update public.profiles set role = 'admin'
where id in ('6f000000-0000-0000-0000-000000000001', '6f000000-0000-0000-0000-000000000003');
insert into private.platform_operators (user_id) values ('6f000000-0000-0000-0000-0000000000e1');

create function pg_temp.code(p_label text) returns text language sql as $f$
  select referral_code from public.clubs where id = (select id from test_clubs where label = p_label)
$f$;

-- ---------------------------------------------------------------------------
-- Code parrain
-- ---------------------------------------------------------------------------

select ok(pg_temp.code('parrain') ~ '^PF[A-Z2-9]{6}$', 'chaque nouveau club reçoit un code parrain');
select isnt(pg_temp.code('parrain'), pg_temp.code('autre'), 'les codes sont uniques');
select ok(not exists (select 1 from public.clubs where referral_code is null),
  'tous les clubs existants ont un code');

select is(
  (select name from public.club_for_referral_code(lower(substr(pg_temp.code('parrain'), 1, 4)) || ' - ' || substr(pg_temp.code('parrain'), 5))),
  'Club Parrain',
  'un code saisi en minuscules, avec espaces ou tirets, est reconnu'
);
select is((select count(*)::int from public.club_for_referral_code('PFZZZZZZ')), 0,
  'un code inconnu ne désigne aucun club');

-- ---------------------------------------------------------------------------
-- Filleuls à l'inscription
-- ---------------------------------------------------------------------------

-- 22 clubs filleuls (plus que le plafond de 20).
insert into test_clubs
select 'f' || n, (public.create_club('Club Filleul ' || chr(64 + n), 'FIL' || n, null, null, null, null)).id
from generate_series(1, 22) n;

select is(
  (select count(*)::int from test_clubs t
   where t.label like 'f%' and public.attach_club_referral(t.id, pg_temp.code('parrain'))),
  22,
  'les nouveaux clubs sont reliés à leur parrain'
);
select is(public.attach_club_referral((select id from test_clubs where label = 'f1'), pg_temp.code('autre')), false,
  'un filleul n''a qu''un seul parrain');
select is(public.attach_club_referral((select id from test_clubs where label = 'parrain'), pg_temp.code('parrain')), false,
  'un club ne peut pas se parrainer lui-même');
select is(public.attach_club_referral((select id from test_clubs where label = 'autre'), 'PFZZZZZZ'), false,
  'un code inconnu ne relie rien');

update public.clubs set status = 'suspended' where id = (select id from test_clubs where label = 'autre');
select is((select count(*)::int from public.club_for_referral_code(pg_temp.code('autre'))), 0,
  'le code d''un club suspendu n''est pas accepté');
update public.clubs set status = 'active' where id = (select id from test_clubs where label = 'autre');

select is(private.club_referral_discount_percent((select id from test_clubs where label = 'parrain')), 0,
  'tant qu''aucun filleul n''a payé, pas de réduction');

select is(private.club_amount_due_cents((select id from test_clubs where label = 'f1')), 7505,
  'un club parrainé a lui aussi −5 % sur sa première année');
select is(private.club_amount_due_cents((select id from test_clubs where label = 'autre')), 7900,
  'un club sans parrain paie le tarif plein');

-- ---------------------------------------------------------------------------
-- Paiements des filleuls
-- ---------------------------------------------------------------------------

select set_config('request.jwt.claims',
  '{"sub":"6f000000-0000-0000-0000-0000000000e1","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;

select lives_ok(
  $$select public.platform_record_offline_payment((select id from test_clubs where label = 'f1'), 7900, 'virement')$$,
  'le premier filleul paie'
);
reset role;
select is(private.club_referral_discount_percent((select id from test_clubs where label = 'parrain')), 5,
  'un filleul payé : -5 %');
select is(private.club_amount_due_cents((select id from test_clubs where label = 'parrain')), 7505,
  'montant à payer : 75,05 €');

set local role authenticated;
select lives_ok(
  $$select public.platform_record_offline_payment((select id from test_clubs where label = 'f1'), 7900, 'virement')$$,
  'le même filleul paie une deuxième année'
);
reset role;
select is(private.club_referral_discount_percent((select id from test_clubs where label = 'parrain')), 5,
  'un filleul ne compte qu''une fois');
select is(private.club_amount_due_cents((select id from test_clubs where label = 'f1')), 7900,
  'après son premier paiement, le filleul revient au tarif plein');

set local role authenticated;
select lives_ok(
  $$select public.platform_record_offline_payment((select id from test_clubs where label = 'f2'), 0, 'autre', current_date, 'Geste commercial')$$,
  'un filleul offert à 0 €'
);
reset role;
select is(private.club_referral_discount_percent((select id from test_clubs where label = 'parrain')), 5,
  'un abonnement offert (0 €) ne rapporte pas de réduction');

set local role authenticated;
select count(*) from (
  select public.platform_record_offline_payment(t.id, 7900, 'cheque')
  from test_clubs t where t.label ~ '^f([3-9]|1[0-9]|2[0-2])$'
) paid;
reset role;
select is(private.club_referral_discount_percent((select id from test_clubs where label = 'parrain')), 100,
  '21 filleuls payés : réduction plafonnée à 100 %');
select is(private.club_amount_due_cents((select id from test_clubs where label = 'parrain')), 0,
  'année offerte : 0 € à payer');

-- ---------------------------------------------------------------------------
-- Ce que voient l'admin, le membre, un autre club
-- ---------------------------------------------------------------------------

select set_config('request.jwt.claims',
  '{"sub":"6f000000-0000-0000-0000-000000000001","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select is(public.admin_get_club_referrals() ->> 'code', pg_temp.code('parrain'),
  'l''admin voit son code parrain');
select is((public.admin_get_club_referrals() ->> 'discount_percent')::int, 100,
  'il voit la réduction acquise');
select is(jsonb_array_length(public.admin_get_club_referrals() -> 'referrals'), 22,
  'il voit la liste de ses filleuls');
select is(
  (select count(*)::int from jsonb_array_elements(public.admin_get_club_referrals() -> 'referrals') r
   where r ->> 'state' = 'trial'),
  1,
  'le filleul offert apparaît encore en essai'
);
select is((public.admin_get_club_subscription() ->> 'amount_due_cents')::int, 0,
  'le résumé d''abonnement donne le montant après réduction');
select is((public.admin_get_club_subscription() ->> 'referral_discount_percent')::int, 100,
  'et le pourcentage de réduction');
select throws_ok($$select count(*) from private.club_referrals$$, '42501', null,
  'le registre des parrainages n''est pas lisible directement');
reset role;

select set_config('request.jwt.claims',
  '{"sub":"6f000000-0000-0000-0000-000000000002","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select throws_ok($$select public.admin_get_club_referrals()$$, '42501', null,
  'un simple membre ne voit pas le parrainage');
reset role;

select set_config('request.jwt.claims',
  '{"sub":"6f000000-0000-0000-0000-000000000003","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select is(public.admin_get_club_referrals() ->> 'code', pg_temp.code('autre'),
  'l''admin d''un autre club ne voit que son propre code');
select is(jsonb_array_length(public.admin_get_club_referrals() -> 'referrals'), 0,
  'et aucun filleul du club voisin');
reset role;

select ok(
  not has_function_privilege('authenticated', 'public.attach_club_referral(uuid, text)', 'execute')
  and not has_function_privilege('anon', 'public.attach_club_referral(uuid, text)', 'execute')
  and not has_function_privilege('authenticated', 'public.club_for_referral_code(text)', 'execute')
  and not has_function_privilege('anon', 'public.club_for_referral_code(text)', 'execute'),
  'seule l''inscription côté serveur peut relier un parrain ou tester un code'
);

-- ---------------------------------------------------------------------------
-- Le parrain paie : la réduction est utilisée
-- ---------------------------------------------------------------------------

select set_config('request.jwt.claims',
  '{"sub":"6f000000-0000-0000-0000-0000000000e1","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select is(
  (public.platform_record_offline_payment((select id from test_clubs where label = 'parrain'), 0, 'autre') ->> 'referral_discount_percent')::int,
  100,
  'au paiement du parrain, la réduction appliquée est renvoyée'
);
select is((public.platform_club_billing((select id from test_clubs where label = 'parrain')) ->> 'referral_discount_percent')::int, 5,
  'au-delà du plafond, le surplus reste pour l''année suivante (21e filleul : -5 %)');
reset role;
select is(
  (select count(*)::int from private.club_referrals
   where referrer_club_id = (select id from test_clubs where label = 'parrain') and used_at is not null),
  20,
  'exactement 20 filleuls sont utilisés pour une année offerte'
);

set local role authenticated;
select lives_ok(
  $$select public.platform_record_offline_payment((select id from test_clubs where label = 'parrain'), 7505, 'virement')$$,
  'l''année suivante, le parrain paie avec le reste de sa réduction'
);
select is((public.platform_club_billing((select id from test_clubs where label = 'parrain')) ->> 'referral_discount_percent')::int, 0,
  'toute la réduction est utilisée');
select is((public.platform_club_billing((select id from test_clubs where label = 'parrain')) ->> 'amount_due_cents')::int, 7900,
  'le tarif plein revient');
reset role;

select * from finish();
rollback;
