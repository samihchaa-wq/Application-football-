begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Migration 20261203040000 : limites anti-abus de la création de club.
-- La création reste ouverte : seul un abus est refusé.

select ok(
  has_function_privilege('service_role', 'public.check_club_creation_limits(text,text)', 'EXECUTE')
  and not has_function_privilege('authenticated', 'public.check_club_creation_limits(text,text)', 'EXECUTE')
  and not has_function_privilege('anon', 'public.check_club_creation_limits(text,text)', 'EXECUTE'),
  'seul le service interne appelle les limites'
);

select ok(
  not has_table_privilege('authenticated', 'private.club_creation_log', 'SELECT')
  and not has_table_privilege('anon', 'private.club_creation_log', 'SELECT'),
  'le journal des créations n''est lisible ni par un compte connecté ni par un visiteur'
);

create temporary table res (n int, r jsonb) on commit drop;
grant all on res to public;

-- 1re demande : autorisée.
insert into res select 1, public.check_club_creation_limits(repeat('a', 64), 'Premier@Exemple.fr');
select is((select r->>'allowed' from res where n = 1), 'true', 'une première création est autorisée');

-- Immédiatement après, même adresse : délai de 60 s.
insert into res select 2, public.check_club_creation_limits(repeat('a', 64), 'autre@exemple.fr');
select is((select r->>'reason' from res where n = 2), 'too_soon', 'deux créations à moins de 60 s sont refusées');

-- E-mail jetable.
insert into res select 3, public.check_club_creation_limits(repeat('b', 64), 'x@mailinator.com');
select is((select r->>'reason' from res where n = 3), 'disposable_email', 'un e-mail jetable est refusé');

-- Gmail : points et +étiquette ignorés (même e-mail normalisé).
update private.club_creation_log set created_at = now() - interval '2 minutes';
insert into res select 4, public.check_club_creation_limits(repeat('c', 64), 'jean.dupont@gmail.com');
update private.club_creation_log set created_at = now() - interval '2 minutes';
insert into res select 5, public.check_club_creation_limits(repeat('d', 64), 'jeandupont+club2@gmail.com');
update private.club_creation_log set created_at = now() - interval '2 minutes';
insert into res select 6, public.check_club_creation_limits(repeat('e', 64), 'j.e.a.n.dupont@googlemail.com');
select is((select r->>'allowed' from res where n = 5), 'true', 'la 2e création du même e-mail est autorisée');
select is((select r->>'reason' from res where n = 6), 'email_daily', 'la 3e création du même e-mail en un jour est refusée');

-- Une même adresse réseau : 3 par jour, la 4e est refusée.
delete from private.club_creation_log;
insert into res select 7, public.check_club_creation_limits(repeat('f', 64), 'a1@exemple.fr');
update private.club_creation_log set created_at = now() - interval '2 minutes';
insert into res select 8, public.check_club_creation_limits(repeat('f', 64), 'a2@exemple.fr');
update private.club_creation_log set created_at = now() - interval '2 minutes';
insert into res select 9, public.check_club_creation_limits(repeat('f', 64), 'a3@exemple.fr');
update private.club_creation_log set created_at = now() - interval '2 minutes';
insert into res select 10, public.check_club_creation_limits(repeat('f', 64), 'a4@exemple.fr');
select is((select r->>'reason' from res where n = 10), 'origin_daily', 'la 4e création du jour depuis une même adresse est refusée');

-- Les refus sont journalisés et ne comptent pas dans les plafonds.
select ok(
  exists (select 1 from private.club_creation_log where not allowed and reason = 'origin_daily'),
  'un refus est journalisé'
);

-- Entrées invalides.
select throws_ok(
  $$select public.check_club_creation_limits('pas-un-hash', 'a@exemple.fr')$$,
  '22023', null, 'une adresse hachée invalide est rejetée'
);
select throws_ok(
  $$select public.check_club_creation_limits(repeat('a', 64), 'pas-un-email')$$,
  '22023', null, 'un e-mail invalide est rejeté'
);

select * from finish();
rollback;
