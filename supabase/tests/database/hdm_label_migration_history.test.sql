begin;
set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Fixtures fictives seulement : le vrai fichier de migration est rejoué
-- dans cette transaction puis annulé. Aucun serveur commercial.
create temporary table hdm_team on commit drop as
select (public.create_club('Equipe QA migration HDM', 'QHD')).id;

insert into auth.users(id, email, raw_user_meta_data, raw_app_meta_data)
select 'dd170000-0000-4000-8000-000000000001'::uuid,
 'hdm-migration@example.invalid', '{"first_name":"QA","last_name":"Fictif"}'::jsonb,
 jsonb_build_object('club_id', id) from hdm_team;

update public.badges set name = 'Étoile du match',
 description = 'Étoiles du match'
where club_id = (select id from hdm_team) and code = 'mvp__10';
update private.badge_templates set description = 'Étoiles du match'
where code = 'mvp__10';

insert into private.notification_history(profile_id, club_id, kind, title, body, tag)
select 'dd170000-0000-4000-8000-000000000001'::uuid, id,
 k, 'Étoile du match', 'Étoiles du match', 'qa-hdm-migration'
from hdm_team cross join unnest(array['motm_open','motm_result_general','motm_result_winner','badge_unlocked','custom']) k;

create function private.m03_hdm_migration_fixture() returns text
language sql security definer set search_path to ''
as $$ select 'Étoile du match'::text $$;
revoke all on function private.m03_hdm_migration_fixture() from public;
grant execute on function private.m03_hdm_migration_fixture() to authenticated;

create temporary table hdm_function_before on commit drop as
select oid, proowner, proacl::text as acl, prosecdef, proconfig::text as config
from pg_proc where oid = 'private.m03_hdm_migration_fixture()'::regprocedure;
create temporary table hdm_badges_before on commit drop as
select id, to_jsonb(b) - 'name' - 'description' as unchanged
from public.badges b where club_id = (select id from hdm_team);
create temporary table hdm_notifications_before on commit drop as
select id, to_jsonb(n) - 'title' - 'body' as unchanged
from private.notification_history n where tag = 'qa-hdm-migration';

\ir ../../migrations/20261122090001_homme_du_match_partout.sql

select is(private.m03_hdm_migration_fixture(), 'Homme du match',
 'la vraie migration traduit le corps de la fonction fixture');
select is((select count(*) from hdm_function_before b join pg_proc p on p.oid=b.oid
 where p.proowner=b.proowner and p.proacl::text is not distinct from b.acl
 and p.prosecdef=b.prosecdef and p.proconfig::text is not distinct from b.config),
 1::bigint, 'OID, propriétaire, ACL, SECURITY DEFINER et config conservés');
select is((select name from public.badges
 where club_id=(select id from hdm_team) and code='mvp__10'),
 'Homme du match', 'le badge historique est traduit');
select is((select description from private.badge_templates where code='mvp__10'),
 'Hommes du match', 'le modèle des prochaines équipes est traduit');
select is((select count(*) from hdm_badges_before b full join
 (select id, to_jsonb(x)-'name'-'description' as unchanged from public.badges x
 where club_id=(select id from hdm_team)) a using(id)
 where a.unchanged is distinct from b.unchanged),
 0::bigint, 'identifiants, codes, seuils, médias et autres attributs des badges conservés');
select is((select count(*) from private.notification_history
 where tag='qa-hdm-migration' and kind <> 'custom'
 and title='Homme du match' and body='Hommes du match'),
 4::bigint, 'les historiques système HDM et badges sont traduits');
select is((select title from private.notification_history
 where tag='qa-hdm-migration' and kind='custom'), 'Étoile du match',
 'le texte libre administrateur est préservé');
select is((select count(*) from hdm_notifications_before b full join
 (select id, to_jsonb(n)-'title'-'body' as unchanged from private.notification_history n
 where tag='qa-hdm-migration') a using(id)
 where a.unchanged is distinct from b.unchanged),
 0::bigint, 'aucune notification ajoutée ou supprimée ; destinataire, équipe, dates et lecture conservés');
select is(pg_temp.hdm_label('Aucune Étoile du match collective n’est attribuée'),
 'Aucun Homme du match collectif n’est attribué', 'Accord masculin de l’annulation conservé');
select * from finish();
rollback;
