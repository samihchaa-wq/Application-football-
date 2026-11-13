begin;
set local search_path = public, extensions, pg_catalog;
select no_plan();

select has_table(
  'public', 'match_kit_snapshots',
  'les maillots historiques disposent d une table dédiée'
);

select is(
  private.match_kit_snapshot_value(null, '#AA0000', '#FFFFFF', 'france')
    ->> 'body', '#AA0000',
  'la tenue domicile prend la couleur primaire du club non configuré'
);
select is(
  private.match_kit_snapshot_value(null, '#AA0000', '#FFFFFF', 'france')
    ->> 'goalkeeper_body', '#168A52',
  'le gardien domicile possède un défaut indépendant'
);
select is(
  private.match_kit_snapshot_value(null, '#AA0000', '#FFFFFF', 'orange')
    ->> 'goalkeeper_body', '#F5A300',
  'le gardien extérieur conserve son propre défaut'
);
select is(
  private.match_kit_snapshot_value(null, '#AA0000', '#FFFFFF', 'blue')
    ->> 'goalkeeper_body', '#1F6FEB',
  'le troisième gardien possède son propre défaut'
);
select is(
  private.match_kit_snapshot_value(
    '[{"slot":"france","label":"Rouge","body":"#991100","trim":"#EEEEEE",
       "goalkeeper_body":"#111111","goalkeeper_trim":"#DDDD00","enabled":true}]'::jsonb,
    '#AA0000', '#FFFFFF', 'france'
  ) ->> 'goalkeeper_body', '#111111',
  'la personnalisation du gardien est conservée dans le snapshot'
);
select is(
  private.match_kit_snapshot_value(
    '[{"slot":"france","label":"Rouge","body":"#991100","trim":"#EEEEEE",
       "enabled":true}]'::jsonb,
    '#AA0000', '#FFFFFF', 'france'
  ) ->> 'goalkeeper_body', '#168A52',
  'les maillots anciens sans couleur gardien restent lisibles'
);

select ok(
  (select relrowsecurity from pg_class
   where oid = 'public.match_kit_snapshots'::regclass),
  'RLS obligatoire sur les snapshots'
);
select ok(
  has_table_privilege('authenticated', 'public.match_kit_snapshots', 'SELECT'),
  'les membres authentifiés peuvent lire leur historique'
);
select ok(
  not has_table_privilege('authenticated', 'public.match_kit_snapshots', 'INSERT'),
  'un utilisateur ne peut pas créer un faux snapshot'
);
select ok(
  not has_table_privilege('authenticated', 'public.match_kit_snapshots', 'UPDATE'),
  'un utilisateur ne peut pas changer un ancien maillot'
);
select ok(
  not has_table_privilege('authenticated', 'public.match_kit_snapshots', 'DELETE'),
  'un utilisateur ne peut pas supprimer son historique'
);
select ok(
  not has_table_privilege('anon', 'public.match_kit_snapshots', 'SELECT'),
  'les snapshots ne sont pas publics'
);
select ok(
  exists(
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'match_kit_snapshots'
      and policyname = 'match_kit_snapshots_member_read'
      and qual like '%current_club_id%'
  ),
  'la lecture impose le club connecté'
);
select ok(
  exists(
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'match_kit_snapshots'
      and policyname = 'match_kit_snapshots_member_read'
      and qual like '%is_active_profile%'
  ),
  'la lecture impose un membre actif'
);
select is(
  (select count(*)::integer
   from pg_trigger
   where tgname in (
     'trg_match_kit_snapshot_live_start',
     'trg_match_kit_snapshot_finished_insert',
     'trg_match_kit_snapshot_finished_update',
     'trg_match_kit_snapshot_internal_jerseys'
   )),
  4,
  'les déclencheurs Live, résultat et entre-nous sont installés'
);
select ok(
  not has_function_privilege(
    'authenticated', 'private.capture_match_kit_snapshot(uuid)', 'EXECUTE'),
  'aucun compte client ne peut forcer un snapshot historique'
);

select * from finish();
rollback;
