begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Premier identifiant libre, calculé par la base sans limite de lignes.
create temporary table test_club on commit drop as
select id from public.create_club('Club Identifiants', null, null, null, null, null);

-- 1 200 homonymes « manyx », « manyx2 » … « manyx1200 », plus quelques
-- identifiants qui ressemblent sans être des homonymes.
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select gen_random_uuid(), format('homonyme-%s@example.invalid', g),
       jsonb_build_object('first_name', 'Many', 'last_name', 'X'),
       jsonb_build_object('club_id', (select id from test_club))
from generate_series(1, 1205) g;

with numbered as (
  select p.id, row_number() over (order by p.id) as rn
  from public.profiles p
  join auth.users u on u.id = p.id
  where u.email like 'homonyme-%@example.invalid'
)
update public.profiles p
set username = case
    when n.rn = 1 then 'manyx'
    when n.rn <= 1200 then 'manyx' || n.rn
    when n.rn = 1201 then 'manyxx'
    when n.rn = 1202 then 'manyx0'
    when n.rn = 1203 then 'zoeq'
    when n.rn = 1204 then 'zoeq2'
    else 'zoeq4'
  end
from numbered n
where p.id = n.id;

select is(
  public.internal_next_free_username('manyx'),
  'manyx1201',
  'au-delà de 1 000 homonymes, le premier numéro libre est trouvé'
);
select is(
  public.internal_next_free_username('zoeq'),
  'zoeq3',
  'un trou dans la numérotation est réutilisé'
);
select is(
  public.internal_next_free_username('zoeq', array['zoeq3']),
  'zoeq5',
  'un identifiant qui vient d’échouer (inscription simultanée) est sauté'
);
select is(
  public.internal_next_free_username('personnenouvelle'),
  'personnenouvelle',
  'le premier compte garde l’identifiant sans numéro'
);
select is(
  public.internal_next_free_username('Bad Base%'),
  null,
  'une base mal formée ne donne aucun identifiant'
);

select throws_ok(
  $$update public.profiles set username = 'zoeq' where username = 'zoeq2'$$,
  '23505', null,
  'la base refuse deux comptes avec le même identifiant'
);

-- Réservé aux fonctions serveur.
create function pg_temp.can_call(p_role text) returns boolean language sql as $$
  select has_function_privilege(p_role, 'public.internal_next_free_username(text, text[])', 'execute');
$$;
select ok(not pg_temp.can_call('anon'), 'un visiteur ne peut pas appeler la fonction');
select ok(not pg_temp.can_call('authenticated'), 'un membre connecté ne peut pas appeler la fonction');
select ok(pg_temp.can_call('service_role'), 'les fonctions serveur peuvent l’appeler');

select * from finish();
rollback;
