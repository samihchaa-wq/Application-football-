begin;
set local search_path = public, extensions, pg_catalog;
select no_plan();

select ok(
  exists (
    select 1 from pg_constraint
    where conrelid = 'public.clubs'::regclass and conname = 'clubs_kits_shape'
      and pg_get_constraintdef(oid) like '%jsonb_array_length(kits) >= 1%'
  ),
  'le nombre de tenues ne doit plus être exactement trois'
);

select is(
  private.match_kit_snapshot_value(
    '[{"slot":"kit_123","label":"Quatrième","body":"#AB1200",
      "trim":"#FFFFFF","goalkeeper_body":"#123456",
      "goalkeeper_trim":"#112233","pattern":"stripes",
      "goalkeeper_pattern":"hoops","archived":false,"enabled":true}]'::jsonb,
    '#112233', '#FFFFFF', 'kit_123'
  ) ->> 'label', 'Quatrième',
  'une tenue personnalisée conserve son identité dans le snapshot'
);

select is(
  private.match_kit_snapshot_value(
    '[{"slot":"kit_123","label":"Quatrième","body":"#AB1200",
      "trim":"#FFFFFF","goalkeeper_body":"#123456",
      "goalkeeper_trim":"#112233","pattern":"stripes",
      "goalkeeper_pattern":"hoops","archived":false,"enabled":true}]'::jsonb,
    '#112233', '#FFFFFF', 'kit_123'
  ) ->> 'goalkeeper_body', '#123456',
  'le maillot du gardien est conservé sur une tenue personnalisée'
);

select ok(
  exists (
    select 1 from pg_constraint where conrelid = 'public.match_kit_snapshots'::regclass
      and conname = 'match_kit_snapshots_kits_check'
      and pg_get_constraintdef(oid) like '%jsonb_array_length(kits) >= 1%'
  ),
  'un snapshot peut mémoriser un nombre libre de tenues'
);

select ok(
  not has_table_privilege('authenticated', 'public.match_kit_snapshots', 'UPDATE'),
  'la migration ne donne pas accès à la modification des snapshots'
);

select * from finish();
rollback;
