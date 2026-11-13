begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Cotes d'un club qui a très peu de matchs (cas de tout nouveau club).
-- Constaté à l'écran le 13/11/2026 : une seule victoire dans l'historique
-- donnait 1,00 pour la victoire et 1 000 001,18 pour la défaite.

insert into auth.users(id, email, raw_user_meta_data)
values ('f6a10000-0000-0000-0000-000000000001', 'cotes-admin@example.invalid', '{"first_name":"Admin"}'::jsonb);
update public.profiles
set role = 'admin', status = 'active'
where id = 'f6a10000-0000-0000-0000-000000000001';

insert into public.seasons(id, name, status)
select 'f6a20000-0000-0000-0000-000000000001', '2026-2027', 'open'
where not exists (select 1 from public.seasons);

insert into public.opponents(id, name) values
  ('f6a30000-0000-0000-0000-000000000001', 'Archives Cotes FC'),
  ('f6a30000-0000-0000-0000-000000000002', 'Nouvel Adversaire FC');

select set_config('test.cutoff', private.history_entry_cutoff()::text, true);
select set_config('request.jwt.claims',
  '{"sub":"f6a10000-0000-0000-0000-000000000001","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select lives_ok($$
  select public.admin_add_historical_match(jsonb_build_object(
    'opponent', 'Archives Cotes FC',
    'date', current_setting('test.cutoff')::date - 7,
    'is_home', true,
    'score_for', 3,
    'score_against', 1
  ))
$$, 'une seule victoire est ajoutée à l’historique');
reset role;
select set_config('request.jwt.claims', '', true);

select set_config('test.odds',
  public.calculate_match_odds_v5('f6a30000-0000-0000-0000-000000000002', current_date + 10)::text, true);

select cmp_ok((current_setting('test.odds')::jsonb ->> 'loss')::numeric, '<=', 12::numeric,
  'la cote de la défaite reste raisonnable après une seule victoire');
select cmp_ok((current_setting('test.odds')::jsonb ->> 'draw')::numeric, '<=', 12::numeric,
  'la cote du nul reste raisonnable après une seule victoire');
select cmp_ok((current_setting('test.odds')::jsonb ->> 'win')::numeric, '>=', 1.2::numeric,
  'la victoire rapporte encore quelque chose');
select cmp_ok((current_setting('test.odds')::jsonb ->> 'win')::numeric, '<',
  (current_setting('test.odds')::jsonb ->> 'loss')::numeric,
  'la victoire reste la cote la plus basse');

select * from finish();
rollback;
