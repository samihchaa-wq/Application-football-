begin;

set local search_path = public, storage, extensions, pg_catalog;
select no_plan();

insert into auth.users(id, email, raw_user_meta_data)
values
  (
    '00000000-0000-4000-8000-000000000033',
    'badge-authorized@example.invalid',
    '{"first_name":"Badge","last_name":"Authorized"}'::jsonb
  ),
  (
    'ba6e0000-0000-0000-0000-000000000001',
    'badge-other-admin@example.invalid',
    '{"first_name":"Badge","last_name":"OtherAdmin"}'::jsonb
  );

update public.profiles
set role = 'admin',
    status = 'active',
    updated_at = now()
where id in (
  '00000000-0000-4000-8000-000000000033',
  'ba6e0000-0000-0000-0000-000000000001'
);

select set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-4000-8000-000000000033","role":"authenticated","aud":"authenticated"}',
  true
);
set local role authenticated;

select lives_ok(
  $$select public.staff_create_badge(
    'badge_access_allowed_test',
    'Badge access allowed',
    '🏅',
    '',
    null,
    '#F97316'
  )$$,
  'un gestionnaire autorisé peut créer un badge'
);

select lives_ok(
  $$select public.staff_update_badge_text(
    'badge_access_allowed_test',
    '  Nom corrigé  ',
    '  Descriptif corrigé  '
  )$$,
  'un gestionnaire autorisé peut renommer un badge'
);

select is(
  (
    select name || '|' || description
    from public.badges
    where code = 'badge_access_allowed_test'
  ),
  'Nom corrigé|Descriptif corrigé',
  'le nom et le descriptif sont enregistrés sans espaces superflus'
);

select throws_ok(
  $$select public.staff_update_badge_text(
    'badge_access_allowed_test',
    '   ',
    ''
  )$$,
  '22023',
  'un badge ne peut pas recevoir un nom vide'
);

select throws_ok(
  $$select public.staff_update_badge_text('badge_inconnu_test', 'Nom', '')$$,
  'P0002',
  'un badge inconnu est signalé'
);

reset role;

select set_config(
  'request.jwt.claims',
  '{"sub":"ba6e0000-0000-0000-0000-000000000001","role":"authenticated","aud":"authenticated"}',
  true
);
set local role authenticated;

select lives_ok(
  $$select public.staff_create_badge(
    'badge_access_other_admin_test',
    'Badge other admin',
    '🏅',
    '',
    null,
    '#F97316'
  )$$,
  'tout administrateur du club peut créer un badge'
);

select lives_ok(
  $$select public.staff_update_badge_text(
    'badge_access_other_admin_test',
    'Nom modifié',
    ''
  )$$,
  'tout administrateur du club peut renommer un badge'
);

reset role;

-- Un simple joueur n'a aucun droit de gestion.
insert into auth.users(id, email, raw_user_meta_data)
values (
  'ba6e0000-0000-0000-0000-000000000002',
  'badge-player@example.invalid',
  '{"first_name":"Badge","last_name":"Player"}'::jsonb
);
update public.profiles
set status = 'active', updated_at = now()
where id = 'ba6e0000-0000-0000-0000-000000000002';

select set_config(
  'request.jwt.claims',
  '{"sub":"ba6e0000-0000-0000-0000-000000000002","role":"authenticated","aud":"authenticated"}',
  true
);
set local role authenticated;

select throws_ok(
  $$select public.staff_create_badge(
    'badge_access_denied_test',
    'Badge access denied',
    '🏅',
    '',
    null,
    '#F97316'
  )$$,
  '42501',
  'un joueur ne peut pas créer de badge'
);

select throws_ok(
  $$select public.staff_update_badge_text(
    'badge_access_allowed_test',
    'Nom interdit',
    ''
  )$$,
  '42501',
  'un joueur ne peut pas renommer un badge'
);

select throws_ok(
  $$insert into storage.objects(
      id, bucket_id, name, owner, owner_id, metadata
    ) values (
      'ba6e1000-0000-0000-0000-000000000001',
      'badge-images',
      'forbidden.webp',
      'ba6e0000-0000-0000-0000-000000000002',
      'ba6e0000-0000-0000-0000-000000000002',
      '{"mimetype":"image/webp"}'::jsonb
    )$$,
  '42501',
  'un joueur ne peut pas téléverser une image de badge'
);

reset role;
select * from finish();
rollback;
