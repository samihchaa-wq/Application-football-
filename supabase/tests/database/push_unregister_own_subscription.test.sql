begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Couper les notifications sur un appareil (ou se déconnecter) supprime son
-- abonnement. L'appli passait par un delete direct sur la table, refusé faute
-- de droit de lecture (42501) : le joueur voyait toujours une erreur.

select ok(
  not has_function_privilege(
    'anon',
    'public.unregister_push_subscription(text)',
    'EXECUTE'
  )
  and has_function_privilege(
    'authenticated',
    'public.unregister_push_subscription(text)',
    'EXECUTE'
  ),
  'seul un compte connecté peut retirer l’abonnement de son appareil'
);

select is(
  (
    select pg_get_userbyid(p.proowner)::text
    from pg_proc p
    where p.oid = 'public.unregister_push_subscription(text)'::regprocedure
  ),
  'club_scope',
  'la fonction reste soumise au cloisonnement par club'
);

insert into auth.users (id, email, raw_user_meta_data)
values
  (
    'e5000000-0000-0000-0000-000000000001',
    'push-unregister-a@example.invalid',
    '{"first_name":"Unregister","last_name":"Alpha"}'::jsonb
  ),
  (
    'e5000000-0000-0000-0000-000000000002',
    'push-unregister-b@example.invalid',
    '{"first_name":"Unregister","last_name":"Beta"}'::jsonb
  );

update public.profiles
set status = 'active', updated_at = now()
where id in (
  'e5000000-0000-0000-0000-000000000001',
  'e5000000-0000-0000-0000-000000000002'
);

insert into public.push_subscriptions (profile_id, endpoint, p256dh, auth)
values
  (
    'e5000000-0000-0000-0000-000000000001',
    'https://push.invalid/unregister-alpha-phone',
    'alpha-phone-key',
    'alpha-phone-auth'
  ),
  (
    'e5000000-0000-0000-0000-000000000001',
    'https://push.invalid/unregister-alpha-laptop',
    'alpha-laptop-key',
    'alpha-laptop-auth'
  ),
  (
    'e5000000-0000-0000-0000-000000000002',
    'https://push.invalid/unregister-beta-phone',
    'beta-phone-key',
    'beta-phone-auth'
  );

select set_config(
  'request.jwt.claims',
  '{"sub":"e5000000-0000-0000-0000-000000000001","role":"authenticated","aud":"authenticated"}',
  true
);
set local role authenticated;

-- L'ancien chemin de l'appli échoue bien : c'est la panne corrigée ici.
select throws_ok(
  $$delete from public.push_subscriptions
    where endpoint = 'https://push.invalid/unregister-alpha-phone'$$,
  '42501',
  null,
  'le delete direct sur la table reste refusé (pas de lecture des clés)'
);

select is(
  public.unregister_push_subscription('https://push.invalid/unregister-alpha-phone'),
  1,
  'couper les notifications retire l’abonnement de cet appareil'
);

select is(
  public.unregister_push_subscription('https://push.invalid/unregister-beta-phone'),
  0,
  'l’appareil d’un autre compte n’est jamais retiré'
);

select is(
  public.unregister_push_subscription('https://push.invalid/unregister-alpha-phone'),
  0,
  'recommencer ne provoque pas d’erreur'
);

select is(
  public.unregister_push_subscription(''),
  0,
  'un point d’envoi vide ne provoque pas d’erreur'
);

reset role;

select is(
  (
    select array_agg(endpoint order by endpoint)
    from public.push_subscriptions
    where endpoint like 'https://push.invalid/unregister-%'
  ),
  array[
    'https://push.invalid/unregister-alpha-laptop',
    'https://push.invalid/unregister-beta-phone'
  ],
  'seul l’appareil coupé disparaît ; l’ordinateur du même joueur et le téléphone de l’autre restent'
);

-- Un compte non actif peut encore couper son téléphone. Le changement de
-- statut se fait hors de toute identité (sinon le garde des champs sensibles
-- du profil le refuse), puis on redevient le joueur.
select set_config('request.jwt.claims', '', true);
update public.profiles
set status = 'pending', updated_at = now()
where id = 'e5000000-0000-0000-0000-000000000001';

select set_config(
  'request.jwt.claims',
  '{"sub":"e5000000-0000-0000-0000-000000000001","role":"authenticated","aud":"authenticated"}',
  true
);
set local role authenticated;

select is(
  public.unregister_push_subscription('https://push.invalid/unregister-alpha-laptop'),
  1,
  'un compte non actif peut quand même retirer son appareil'
);

reset role;

select set_config('request.jwt.claims', '{"role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;

select throws_ok(
  $$select public.unregister_push_subscription('https://push.invalid/unregister-beta-phone')$$,
  '42501',
  'Authentication required',
  'sans compte, rien n’est retiré'
);

reset role;

select * from finish();
rollback;
