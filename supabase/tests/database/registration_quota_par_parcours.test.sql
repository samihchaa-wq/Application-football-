begin;

set local search_path = public, extensions, pg_catalog;
select plan(8);

delete from private.registration_attempts;

-- Rejoindre un club : 30 par heure depuis la même adresse réseau.
select is(
  (select count(*) filter (where ok)::integer
   from (select public.consume_registration_rate_limit(repeat('a', 64)) as ok
         from generate_series(1, 31)) attempts),
  30,
  'rejoindre un club : 30 inscriptions acceptées par heure depuis la même adresse'
);

select is(
  public.consume_registration_rate_limit(repeat('a', 64), 'join'),
  false,
  'rejoindre un club : la 31e de l''heure est refusée'
);

-- Créer un club : plafond strict, compteur séparé.
select is(
  (select count(*) filter (where ok)::integer
   from (select public.consume_registration_rate_limit(repeat('a', 64), 'create') as ok
         from generate_series(1, 6)) attempts),
  5,
  'créer un club : 5 créations acceptées par heure, même si les joueurs ont épuisé leur quota'
);

select is(
  public.consume_registration_rate_limit(repeat('b', 64), 'join'),
  true,
  'une autre adresse réseau a son propre quota'
);

-- Plafond journalier des créations : 15.
delete from private.registration_attempts;
insert into private.registration_attempts(origin_hash, mode, attempted_at)
select repeat('c', 64), 'create', now() - interval '2 hours'
from generate_series(1, 15);
select is(
  public.consume_registration_rate_limit(repeat('c', 64), 'create'),
  false,
  'créer un club : 15 créations par jour au plus'
);

-- Plafond journalier pour rejoindre : 100.
insert into private.registration_attempts(origin_hash, mode, attempted_at)
select repeat('d', 64), 'join', now() - interval '2 hours'
from generate_series(1, 100);
select is(
  public.consume_registration_rate_limit(repeat('d', 64)),
  false,
  'rejoindre un club : 100 inscriptions par jour au plus'
);

select throws_ok(
  $$select public.consume_registration_rate_limit(repeat('e', 64), 'autre')$$,
  '22023',
  'Invalid registration mode',
  'un parcours inconnu est refusé'
);

select ok(
  not has_function_privilege('authenticated', 'public.consume_registration_rate_limit(text,text)', 'execute')
  and not has_function_privilege('anon', 'public.consume_registration_rate_limit(text,text)', 'execute')
  and has_function_privilege('service_role', 'public.consume_registration_rate_limit(text,text)', 'execute'),
  'le quota reste réservé aux fonctions Edge'
);

select * from finish();
rollback;
