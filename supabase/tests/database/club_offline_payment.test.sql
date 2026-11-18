begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Paiement hors ligne noté par l'éditeur et suspension automatique des clubs
-- impayés le jour de l'échéance (plus de délai de grâce depuis
-- 20261126000000_rappel_echeance_abonnement.sql).
create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
grant select on test_clubs to authenticated;

insert into test_clubs
select 'a', (public.create_club('Club Paiement Alpha', 'PALPHA', null, null, null, null)).id;
insert into test_clubs
select 'b', (public.create_club('Club Paiement Bravo', 'PBRAVO', null, null, null, null)).id;
insert into test_clubs
select 'c', (public.create_club('Club Paiement Charlie', 'PCHARL', null, null, null, null)).id;

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select ('4d000000-0000-0000-0000-00000000000' || label)::uuid, 'pay-' || label || '@example.invalid',
  jsonb_build_object('first_name', 'Admin', 'last_name', upper(label)),
  jsonb_build_object('club_id', id)
from test_clubs;
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '4d000000-0000-0000-0000-0000000000c1', 'pay-member@example.invalid',
  jsonb_build_object('first_name', 'Membre', 'last_name', 'Alpha'),
  jsonb_build_object('club_id', id)
from test_clubs where label = 'a';
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '4d000000-0000-0000-0000-0000000000e1', 'pay-operator@example.invalid',
  jsonb_build_object('first_name', 'Editeur', 'last_name', 'App'),
  jsonb_build_object('club_id', id)
from test_clubs where label = 'b';

update public.profiles set status = 'active' where id::text like '4d000000-%';
update public.profiles set role = 'admin'
where id in ('4d000000-0000-0000-0000-00000000000a', '4d000000-0000-0000-0000-00000000000b',
             '4d000000-0000-0000-0000-00000000000c');
insert into private.platform_operators (user_id) values ('4d000000-0000-0000-0000-0000000000e1');

select is(
  (select count(*)::int from cron.job where jobname = 'suspend-unpaid-clubs' and active),
  1,
  'la suspension des clubs impayés est planifiée chaque nuit'
);

-- ---------------------------------------------------------------------------
-- Suspension à l'échéance
-- ---------------------------------------------------------------------------

-- Alpha : essai qui se termine dans 5 jours.
update public.club_subscriptions set trial_ends_at = now() + interval '5 days'
where club_id = (select id from test_clubs where label = 'a');
-- Charlie : essai fini depuis 20 jours.
update public.club_subscriptions set trial_ends_at = now() - interval '20 days'
where club_id = (select id from test_clubs where label = 'c');

select set_config('request.jwt.claims',
  '{"sub":"4d000000-0000-0000-0000-00000000000a","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select ok(
  (public.admin_get_club_subscription() ->> 'suspension_on')::timestamptz
    between now() + interval '4 days' and now() + interval '6 days',
  'l''administrateur voit la date de suspension : le jour de la fin de l''essai'
);
reset role;

select is(private.suspend_unpaid_clubs(now()), 1,
  'un seul club a dépassé son échéance');
select is(
  (select status from public.clubs where id = (select id from test_clubs where label = 'a')),
  'active',
  'un club avant son échéance garde l''accès'
);
select is(
  (select status from public.clubs where id = (select id from test_clubs where label = 'c')),
  'suspended',
  'un club impayé après son échéance est suspendu, sans délai de grâce'
);
select is(
  (select status from public.clubs where id = (select id from test_clubs where label = 'b')),
  'active',
  'un club en essai n''est pas touché'
);

-- Alpha dépasse à son tour son échéance (essai fini hier).
update public.club_subscriptions set trial_ends_at = now() - interval '1 day'
where club_id = (select id from test_clubs where label = 'a');
select is(private.suspend_unpaid_clubs(now()), 1,
  'l''échéance passée, le club suivant est suspendu');
select is(private.suspend_unpaid_clubs(now()), 0,
  'un club déjà suspendu n''est pas compté deux fois');

select set_config('request.jwt.claims',
  '{"sub":"4d000000-0000-0000-0000-0000000000c1","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select is(public.get_my_club_access() ->> 'status', 'suspended',
  'un membre d''un club impayé voit la suspension');
select is(public.get_my_club_access() ->> 'reason', 'unpaid',
  'il sait que la suspension vient d''un abonnement non réglé');
select is((select count(*) from public.club_payments), 0::bigint,
  'un club suspendu ne lit plus ses paiements');
reset role;

-- ---------------------------------------------------------------------------
-- Qui peut noter un paiement
-- ---------------------------------------------------------------------------

select set_config('request.jwt.claims',
  '{"sub":"4d000000-0000-0000-0000-00000000000b","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select throws_ok(
  $$select public.platform_record_offline_payment((select id from test_clubs where label = 'b'), 7900, 'virement')$$,
  '42501', null,
  'un administrateur de club ne peut pas noter son propre paiement'
);
select throws_ok(
  $$insert into public.club_payments (club_id, amount_cents, method, received_on, period_end)
    values ((select id from test_clubs where label = 'b'), 7900, 'virement', current_date, now())$$,
  '42501', null,
  'un administrateur de club ne peut pas écrire dans le registre des paiements'
);
select throws_ok(
  $$select public.platform_club_billing((select id from test_clubs where label = 'b'))$$,
  '42501', null,
  'un administrateur de club n''a pas accès à la fiche de facturation de l''éditeur'
);
reset role;

-- ---------------------------------------------------------------------------
-- L'éditeur note les paiements
-- ---------------------------------------------------------------------------

select set_config('request.jwt.claims',
  '{"sub":"4d000000-0000-0000-0000-0000000000e1","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;

select throws_ok(
  $$select public.platform_record_offline_payment((select id from test_clubs where label = 'a'), 7900, 'carte')$$,
  '22023', null,
  'un moyen de paiement inconnu est refusé'
);
select throws_ok(
  $$select public.platform_record_offline_payment((select id from test_clubs where label = 'a'), -1, 'cheque')$$,
  '22023', null,
  'un montant négatif est refusé'
);

select is(
  (public.platform_record_offline_payment(
    (select id from test_clubs where label = 'a'), 7900, 'virement', current_date, 'Virement saison') ->> 'reopened')::boolean,
  true,
  'un paiement rouvre un club suspendu pour impayé'
);
reset role;

select is(
  (select status from public.clubs where id = (select id from test_clubs where label = 'a')),
  'active',
  'le club payé retrouve l''accès'
);
select ok(
  (select sub.status = 'active'
     and sub.auto_suspended_at is null
     and sub.current_period_end between now() + interval '364 days' and now() + interval '366 days'
   from public.club_subscriptions sub
   where sub.club_id = (select id from test_clubs where label = 'a')),
  'échéance passée : l''année payée commence le jour du paiement'
);

-- Bravo paie pendant son essai : il ne perd aucun jour d'essai.
select set_config('request.jwt.claims',
  '{"sub":"4d000000-0000-0000-0000-0000000000e1","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select lives_ok(
  $$select public.platform_record_offline_payment((select id from test_clubs where label = 'b'), 7900, 'cheque')$$,
  'l''éditeur note un chèque reçu pendant l''essai'
);
reset role;
select ok(
  (select sub.current_period_end = sub.trial_ends_at + interval '1 year'
   from public.club_subscriptions sub
   where sub.club_id = (select id from test_clubs where label = 'b')),
  'payer pendant l''essai : l''année commence à la fin de l''essai'
);

-- Une suspension décidée à la main n'est pas levée par un paiement.
select set_config('request.jwt.claims',
  '{"sub":"4d000000-0000-0000-0000-0000000000e1","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select lives_ok(
  $$select public.platform_update_club((select id from test_clubs where label = 'b'), p_status => 'suspended')$$,
  'l''éditeur suspend un club à la main'
);
select is(
  (public.platform_record_offline_payment(
    (select id from test_clubs where label = 'b'), 7900, 'especes') ->> 'reopened')::boolean,
  false,
  'un paiement ne lève pas une suspension décidée par l''éditeur'
);
select is(
  jsonb_array_length(public.platform_club_billing((select id from test_clubs where label = 'b')) -> 'payments'),
  2,
  'l''éditeur retrouve les paiements notés pour le club'
);

-- Charlie rouvert à la main sans paiement : plus de suspension automatique.
select lives_ok(
  $$select public.platform_update_club((select id from test_clubs where label = 'c'), p_status => 'active')$$,
  'l''éditeur rouvre à la main un club suspendu pour impayé'
);
reset role;
select is(private.suspend_unpaid_clubs(now()), 0,
  'un club rouvert à la main n''est pas re-suspendu avant son prochain paiement');
select is(
  (select status from public.clubs where id = (select id from test_clubs where label = 'b')),
  'suspended',
  'le club suspendu à la main le reste'
);

-- L'administrateur d'Alpha relit ses paiements.
select set_config('request.jwt.claims',
  '{"sub":"4d000000-0000-0000-0000-00000000000a","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select is((select count(*) from public.club_payments), 1::bigint,
  'l''administrateur voit uniquement les paiements de son club');
select is(public.admin_get_club_subscription() ->> 'state', 'active',
  'l''abonnement payé est actif');
reset role;

select * from finish();
rollback;
