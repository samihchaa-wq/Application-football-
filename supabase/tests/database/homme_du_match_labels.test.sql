begin;
set local search_path = public, extensions, pg_catalog;
select no_plan();
select is((select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname in ('public','private') and p.prokind='f'
 and (p.prosrc ~* '[Éé]toiles? du match' or p.prosrc like '%Étoile : notification%')),0::bigint,
 'Les fonctions exécutables ne contiennent plus l’ancien nom du trophée');
select is((select count(*) from public.badges where name ~* '[Éé]toiles? du match'
 or description ~* '[Éé]toiles? du match'),0::bigint,'Badges persistés renommés');
select is((select count(*) from private.badge_templates where name ~* '[Éé]toiles? du match'
 or description ~* '[Éé]toiles? du match'),0::bigint,'Modèles des futures équipes renommés');
select is((select count(*) from private.notification_history
 where kind in ('motm_open','motm_result_general','motm_result_winner','badge_unlocked')
 and (title ~* '[Éé]toiles? du match' or body ~* '[Éé]toiles? du match')),0::bigint,
 'Historique système HDM renommé sans nouvel envoi');
select ok(to_regprocedure('public.get_my_profile()') is not null,'API technique conservée');
select * from finish();
rollback;
