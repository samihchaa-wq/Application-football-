begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Paiement hors ligne noté par l'éditeur, prolongation d'essai et blocage
-- nocturne des clubs qui n'ont pas payé 15 jours après l'échéance.
create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
grant select on test_clubs to authenticated;

insert into test_clubs
select 'a', (public.create_club('Club Impayé Alpha', 'IMPALPHA', null, null, null, null)).id;
insert into test_clubs
select 'b', (public.create_club('Club Impayé Bravo', 'IMPBRAVO', null, null, null, null)).id;
insert into test_clubs
select 'c', (public.create_club('Club Impayé Charlie', 'IMPCHARL', null, null, null, null)).id;

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select ('4d000000-0000-0000-0000-00000000000' || label)::uuid, 'unpaid-' || label || '@example.invalid',
  jsonb_build_object('first_name', 'Admin', 'last_name', upper(label)),
  jsonb_build_object('club_id', id)
from test_clubs;
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '4d000000-0000-0000-0000-0000000000e1', 'unpaid-operator@example.invalid',
  jsonb_build_object('first_name', 'Editeur', 'last_name', 'App'),
  jsonb_build_object('club_id', id)
from test_clubs where label = 'c';
update public.profiles set status = 'active' where id::text like '4d000000-%';
update public.profiles set role = 'admin'
where id::text in ('4d000000-0000-0000-0000-00000000000a', '4d000000-0000-0000-0000-00000000000b');
insert into private.platform_operators (user_id) values ('4d000000-0000-0000-0000-0000000000e1');

select is(
  (select base_price_cents from public.club_subscriptions
   where club_id = (select id from test_clubs where label = 'a')),
  7900,
  'un nouveau club démarre au forfait de 79 €'
);

-- ---------------------------------------------------------------------------
-- Blocage nocturne
-- ---------------------------------------------------------------------------

-- Alpha : essai fini depuis 16 jours. Bravo : essai fini depuis 10 jours.
update public.club_subscriptions set trial_ends_at = now() - interval '16 days'
where club_id = (select id from test_clubs where label = 'a');
update public.club_subscriptions set trial_ends_at = now() - interval '10 days'
where club_id = (select id from test_clubs where label = 'b');
-- Charlie : suspendu à la main par l'éditeur, abonnement payé.
update public.club_subscriptions
set status = 'active', current_period_end = now() + interval '6 months'
where club_id = (select id from test_clubs where label = 'c');
update public.clubs set status = 'suspended' where id = (select id from test_clubs where label = 'c');

select set_config('request.jwt.claims',
  '{"sub":"4d000000-0000-0000-0000-00000000000b","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select is(public.admin_get_club_subscription() ->> 'state', 'to_pay',
  'essai fini depuis 10 jours : à régler');
select ok(
  (public.admin_get_club_subscription() ->> 'access_ends_at')::timestamptz
    between now() + interval '4 days' and now() + interval '6 days',
  'l''admin voit la date de coupure, 15 jours après la fin de l''essai'
);
select throws_ok(
  $$select private.suspend_unpaid_clubs(now())$$,
  '42501', null,
  'un compte ne peut pas lancer le blocage des impayés'
);
reset role;

select ok(private.suspend_unpaid_clubs(now()) >= 1, 'le blocage nocturne s''exécute');

select is(
  (select status from public.clubs where id = (select id from test_clubs where label = 'a')),
  'suspended',
  'essai fini depuis plus de 15 jours sans paiement : club bloqué'
);
select ok(
  (select suspended_for_nonpayment_at is not null and status = 'past_due'
   from public.club_subscriptions where club_id = (select id from test_clubs where label = 'a')),
  'le blocage est marqué comme impayé'
);
select is(
  (select status from public.clubs where id = (select id from test_clubs where label = 'b')),
  'active',
  'pendant les 15 jours de délai, le club garde l''accès'
);

-- Période payée échue depuis plus de 15 jours.
update public.club_subscriptions
set status = 'active', current_period_end = now() - interval '20 days'
where club_id = (select id from test_clubs where label = 'b');
select private.suspend_unpaid_clubs(now());
select is(
  (select status from public.clubs where id = (select id from test_clubs where label = 'b')),
  'suspended',
  'abonnement non renouvelé 15 jours après l''échéance : club bloqué'
);

-- ---------------------------------------------------------------------------
-- Actions de l'éditeur
-- ---------------------------------------------------------------------------

select set_config('request.jwt.claims',
  '{"sub":"4d000000-0000-0000-0000-00000000000a","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select throws_ok(
  $$select public.platform_record_payment((select id from test_clubs where label = 'a'))$$,
  '42501', null,
  'un admin de club ne peut pas se déclarer payé'
);
select throws_ok(
  $$select public.platform_extend_trial((select id from test_clubs where label = 'a'), 30)$$,
  '42501', null,
  'un admin de club ne peut pas prolonger son essai'
);
reset role;

select set_config('request.jwt.claims',
  '{"sub":"4d000000-0000-0000-0000-0000000000e1","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;

select is(
  (public.platform_record_payment((select id from test_clubs where label = 'a')) ->> 'reopened')::boolean,
  true,
  'noter le paiement rouvre un club bloqué pour impayé'
);
select is(
  (public.platform_extend_trial((select id from test_clubs where label = 'b'), 30) ->> 'reopened')::boolean,
  true,
  'prolonger l''essai rouvre un club bloqué pour impayé'
);
select throws_ok(
  $$select public.platform_extend_trial((select id from test_clubs where label = 'b'), 0)$$,
  '22023', null,
  'une prolongation de 0 jour est refusée'
);
select throws_ok(
  $$select public.platform_extend_trial((select id from test_clubs where label = 'a'), 30)$$,
  '22023', null,
  'on ne prolonge pas l''essai d''un club déjà abonné'
);
select is(
  (public.platform_record_payment((select id from test_clubs where label = 'c')) ->> 'reopened')::boolean,
  false,
  'un paiement ne lève pas une suspension décidée à la main'
);
reset role;

select is(
  (select status from public.clubs where id = (select id from test_clubs where label = 'a')),
  'active',
  'Alpha est rouvert'
);
select ok(
  (select status = 'active'
      and suspended_for_nonpayment_at is null
      and current_period_end between now() + interval '364 days' and now() + interval '366 days'
   from public.club_subscriptions where club_id = (select id from test_clubs where label = 'a')),
  'paiement après retard : un an d''abonnement à partir d''aujourd''hui'
);
select ok(
  (select current_period_end between now() + interval '1 year 6 months' - interval '1 day'
                                 and now() + interval '1 year 6 months' + interval '1 day'
   from public.club_subscriptions where club_id = (select id from test_clubs where label = 'c')),
  'renouvellement anticipé : l''année s''ajoute à la période en cours'
);
select is(
  (select status from public.clubs where id = (select id from test_clubs where label = 'c')),
  'suspended',
  'Charlie reste suspendu'
);
select is(
  (select amount_cents from private.club_payments
   where club_id = (select id from test_clubs where label = 'a')),
  7900,
  'le paiement est journalisé avec son montant'
);
select ok(
  (select status = 'trialing'
      and trial_ends_at between now() + interval '29 days' and now() + interval '31 days'
   from public.club_subscriptions where club_id = (select id from test_clubs where label = 'b')),
  'essai prolongé de 30 jours à partir d''aujourd''hui'
);

-- Un club rouvert n'est pas rebloqué la nuit suivante.
select private.suspend_unpaid_clubs(now());
select ok(
  (select count(*) from public.clubs
   where id in (select id from test_clubs where label in ('a', 'b')) and status = 'active') = 2,
  'les clubs payés ou prolongés restent ouverts'
);

select isnt(
  (select jobid from cron.job where jobname = 'suspend-unpaid-clubs'),
  null,
  'le blocage des impayés est planifié chaque nuit'
);

select * from finish();
rollback;
