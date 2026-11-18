begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Migration 20261125000000 : les anciennes RPC que l'appli n'appelle plus ne
-- sont plus exécutables par un compte connecté, mais existent toujours et
-- restent utilisables par le service interne et leur propriétaire.

create temporary table revoked_rpcs (signature text primary key) on commit drop;
insert into revoked_rpcs (signature) values
  ('public.admin_close_match_motm_vote_early(uuid,text)'),
  ('public.admin_configure_match_sport_workflow(uuid,integer)'),
  ('public.admin_create_match_complete(uuid,uuid,date,time without time zone,text,numeric,numeric,numeric,integer,text,boolean,text,text)'),
  ('public.admin_create_match_complete_v2(uuid,uuid,date,time without time zone,text,numeric,numeric,numeric,integer,text,boolean,text,text,text,timestamp with time zone)'),
  ('public.admin_finalize_match_sport_postgame(uuid,integer,integer,jsonb,text)'),
  ('public.admin_finalize_match_waitlist_turns(uuid)'),
  ('public.admin_get_internal_composition(uuid)'),
  ('public.admin_get_match_motm_dashboard(uuid)'),
  ('public.admin_get_match_sport_statistics_integrity(uuid)'),
  ('public.admin_list_match_motm_votes()'),
  ('public.admin_publish_match_convocations(uuid,text)'),
  ('public.admin_recalculate_sport_waitlist(uuid)'),
  ('public.admin_recent_client_incidents(integer)'),
  ('public.admin_recompute_match_convocations(uuid,boolean)'),
  ('public.admin_reorder_sport_waitlist(uuid,uuid[],text)'),
  ('public.admin_require_password_change(uuid)'),
  ('public.admin_restart_match_motm_vote(uuid,text)'),
  ('public.admin_save_internal_composition(uuid,text,text,jsonb)'),
  ('public.admin_save_internal_composition_v3(uuid,text,text,text,text,text,text,jsonb)'),
  ('public.admin_save_match_composition(uuid,text,jsonb,boolean,text)'),
  ('public.admin_save_match_effectif(uuid,integer,jsonb,text)'),
  ('public.admin_set_match_address(uuid,text,boolean)'),
  ('public.admin_set_match_convocation(uuid,uuid,text,boolean,text)'),
  ('public.admin_set_match_jersey(uuid,text)'),
  ('public.admin_set_match_type(uuid,text)'),
  ('public.admin_sync_match_sport_workflow(uuid)'),
  ('public.admin_update_match_complete(uuid,uuid,uuid,date,time without time zone,text,text,numeric,numeric,numeric,timestamp with time zone,integer,text,boolean,text,text)'),
  ('public.close_match_predictions(uuid)'),
  ('public.create_internal_match(uuid,date,time without time zone,text)'),
  ('public.create_internal_match_v2(uuid,date,time without time zone,text,text,timestamp with time zone)'),
  ('public.create_match_with_odds(uuid,uuid,date,time without time zone,text,numeric,numeric,numeric)'),
  ('public.create_match_with_odds_and_sport_limit(uuid,uuid,date,time without time zone,text,numeric,numeric,numeric,integer)'),
  ('public.finalize_match_postgame_with_lineup(uuid,integer,jsonb,uuid,integer,uuid[],uuid)'),
  ('public.is_moderator()'),
  ('public.platform_update_club(uuid,text,text,timestamp with time zone,timestamp with time zone,integer,integer,bigint,text)'),
  ('public.profile_badge_metrics(uuid)'),
  ('public.save_match_prediction(uuid,integer,integer,boolean)'),
  ('public.send_test_push()'),
  ('public.set_sports_management_enabled(boolean,text)'),
  ('public.staff_app_integrity_report()'),
  ('public.staff_profile_username(uuid)'),
  ('public.staff_revoke_badge(uuid,text)'),
  ('public.update_internal_match(uuid,uuid,date,time without time zone,text,timestamp with time zone)'),
  ('public.update_match_with_odds(uuid,uuid,uuid,date,time without time zone,text,text,numeric,numeric,numeric)'),
  ('public.update_match_with_odds_and_sport_limit(uuid,uuid,uuid,date,time without time zone,text,text,numeric,numeric,numeric,integer)'),
  ('public.update_my_app_preferences(boolean,boolean,boolean)');

select is(
  (select count(*) from revoked_rpcs where to_regprocedure(signature) is null),
  0::bigint,
  'toutes les anciennes RPC visées existent toujours (rien n''est supprimé)'
);

select diag('encore exécutables par authenticated : ' || string_agg(signature, ', '))
from revoked_rpcs
where has_function_privilege('authenticated', to_regprocedure(signature), 'EXECUTE')
having count(*) > 0;

select is(
  (
    select count(*) from revoked_rpcs
    where has_function_privilege('authenticated', to_regprocedure(signature), 'EXECUTE')
       or has_function_privilege('anon', to_regprocedure(signature), 'EXECUTE')
  ),
  0::bigint,
  'aucune ancienne RPC n''est exécutable par un compte connecté ou un visiteur'
);

select is(
  (
    select count(*) from revoked_rpcs
    where not has_function_privilege('service_role', to_regprocedure(signature), 'EXECUTE')
  ),
  0::bigint,
  'le service interne garde l''accès à toutes les anciennes RPC'
);

-- Les versions actuelles appellent les anciennes en interne : elles tournent
-- sous leur propriétaire, qui doit garder le droit d'exécution.
select is(
  (
    select count(*) from revoked_rpcs r
    join pg_proc p on p.oid = to_regprocedure(r.signature)
    where not has_function_privilege(p.proowner, p.oid, 'EXECUTE')
  ),
  0::bigint,
  'le propriétaire de chaque ancienne RPC garde le droit d''exécution'
);

-- Gardées volontairement pour les comptes connectés.
select ok(
  has_function_privilege('authenticated', 'public.is_match_staff()', 'EXECUTE'),
  'is_match_staff reste exécutable : des règles d''accès l''utilisent'
);
select ok(
  has_function_privilege('authenticated', 'public.is_valid_person_name(text)', 'EXECUTE'),
  'is_valid_person_name reste exécutable : un déclencheur l''appelle sous l''identité de l''appelant'
);
select ok(
  has_function_privilege('authenticated', 'public.accept_terms(text,text)', 'EXECUTE'),
  'accept_terms reste exécutable'
);
select ok(
  has_function_privilege('authenticated', 'public.save_match_prediction(uuid,integer,integer)', 'EXECUTE'),
  'le pronostic actuel (sans ×2) reste exécutable'
);
select ok(
  has_function_privilege('authenticated', 'public.admin_save_match_composition(uuid,text,jsonb,boolean,text,integer)', 'EXECUTE'),
  'l''enregistrement de composition avec version attendue reste exécutable'
);
select ok(
  has_function_privilege('authenticated', 'public.admin_create_match_complete_v3(uuid,uuid,date,time without time zone,text,numeric,numeric,numeric,integer,text,boolean,text,text,text,timestamp with time zone,timestamp with time zone)', 'EXECUTE')
  and has_function_privilege('authenticated', 'public.admin_update_match_complete_v3(uuid,uuid,uuid,date,time without time zone,text,text,numeric,numeric,numeric,timestamp with time zone,integer,text,boolean,text,text,timestamp with time zone,text,timestamp with time zone)', 'EXECUTE')
  and has_function_privilege('authenticated', 'public.create_internal_match_v3(uuid,date,time without time zone,text,text,timestamp with time zone,timestamp with time zone)', 'EXECUTE')
  and has_function_privilege('authenticated', 'public.update_internal_match_v3(uuid,uuid,date,time without time zone,text,timestamp with time zone,timestamp with time zone,text,timestamp with time zone)', 'EXECUTE'),
  'les versions actuelles de création et modification de match restent exécutables'
);

select * from finish();
rollback;
