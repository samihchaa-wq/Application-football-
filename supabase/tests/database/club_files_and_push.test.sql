begin;

set local search_path = public, extensions, pg_catalog;
select no_plan();

-- Fichiers et notifications avec plusieurs clubs dans la même base.
create temporary table test_clubs (label text primary key, id uuid not null) on commit drop;
grant select on test_clubs to authenticated;

insert into test_clubs
select 'a', (public.create_club('Club Fichiers Alpha', 'FALPHA', null, null, null, null)).id;
insert into test_clubs
select 'b', (public.create_club('Club Fichiers Bravo', 'FBRAVO', null, null, null, null)).id;

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '3c000000-0000-0000-0000-00000000000a', 'files-alpha@example.invalid',
  jsonb_build_object('first_name', 'Admin', 'last_name', 'Alpha'),
  jsonb_build_object('club_id', id)
from test_clubs where label = 'a';
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
select '3c000000-0000-0000-0000-00000000000b', 'files-bravo@example.invalid',
  jsonb_build_object('first_name', 'Admin', 'last_name', 'Bravo'),
  jsonb_build_object('club_id', id)
from test_clubs where label = 'b';

update public.profiles set role = 'admin', status = 'active'
where id in ('3c000000-0000-0000-0000-00000000000a', '3c000000-0000-0000-0000-00000000000b');

-- Une photo de profil et une image de badge déposées par l'admin d'Alpha.
insert into storage.objects (bucket_id, name, owner_id, metadata)
values
  ('profile-photos', '3c000000-0000-0000-0000-00000000000a/avatar.jpg',
   '3c000000-0000-0000-0000-00000000000a', '{"size": 200000}'),
  ('badge-images', 'alpha/badge.png',
   '3c000000-0000-0000-0000-00000000000a', '{"size": 50000}');

-- ---------------------------------------------------------------------------
-- Bravo ne voit ni ne touche les fichiers d'Alpha
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims',
  '{"sub":"3c000000-0000-0000-0000-00000000000b","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;

select is(
  (select count(*) from storage.objects
   where owner_id = '3c000000-0000-0000-0000-00000000000a'),
  0::bigint,
  'un membre d''un autre club ne voit pas les fichiers d''Alpha'
);

with changed as (
  update storage.objects set metadata = '{"size": 1}'
  where owner_id = '3c000000-0000-0000-0000-00000000000a'
  returning 1
)
select is((select count(*) from changed), 0::bigint,
  'un admin d''un autre club ne peut pas remplacer les fichiers d''Alpha');

select set_config('storage.allow_delete_query', 'true', true);
with removed as (
  delete from storage.objects
  where owner_id = '3c000000-0000-0000-0000-00000000000a'
  returning 1
)
select is((select count(*) from removed), 0::bigint,
  'un admin d''un autre club ne peut pas supprimer les fichiers d''Alpha');

select is(
  (public.admin_get_club_storage_usage() ->> 'used_bytes')::bigint,
  0::bigint,
  'Bravo n''est pas facturé de l''espace d''Alpha'
);

reset role;

-- ---------------------------------------------------------------------------
-- Alpha voit ses fichiers, et son quota est appliqué
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims',
  '{"sub":"3c000000-0000-0000-0000-00000000000a","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;

select is(
  (select count(*) from storage.objects
   where owner_id = '3c000000-0000-0000-0000-00000000000a'),
  2::bigint,
  'Alpha voit ses propres fichiers'
);

select is(
  public.admin_get_club_storage_usage(),
  jsonb_build_object('used_bytes', 250000, 'quota_bytes', 209715200),
  'l''admin voit l''espace occupé par son club et son quota'
);

select lives_ok(
  $$insert into storage.objects (bucket_id, name, owner_id, metadata)
    values ('profile-photos', '3c000000-0000-0000-0000-00000000000a/second.jpg',
            '3c000000-0000-0000-0000-00000000000a', '{"size": 1000}')$$,
  'un dépôt sous le quota est accepté'
);

reset role;
update public.clubs set storage_quota_bytes = 100000
where id = (select id from test_clubs where label = 'a');
set local role authenticated;

select throws_ok(
  $$insert into storage.objects (bucket_id, name, owner_id, metadata)
    values ('profile-photos', '3c000000-0000-0000-0000-00000000000a/third.jpg',
            '3c000000-0000-0000-0000-00000000000a', '{"size": 1000}')$$,
  '42501',
  null,
  'un dépôt est refusé quand le club a atteint son quota'
);

reset role;

-- Le quota de Bravo reste intact.
select set_config('request.jwt.claims',
  '{"sub":"3c000000-0000-0000-0000-00000000000b","role":"authenticated","aud":"authenticated"}', true);
set local role authenticated;
select lives_ok(
  $$insert into storage.objects (bucket_id, name, owner_id, metadata)
    values ('profile-photos', '3c000000-0000-0000-0000-00000000000b/avatar.jpg',
            '3c000000-0000-0000-0000-00000000000b', '{"size": 1000}')$$,
  'le quota plein d''un club ne bloque pas les autres clubs'
);
reset role;

-- ---------------------------------------------------------------------------
-- Les appels sortants portent le club courant
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '', true);
select set_config('app.club_id', (select id::text from test_clubs where label = 'b'), true);

select private.http_post(
  url := 'http://127.0.0.1:9/send-push',
  body := '{"kind":"test"}'::jsonb,
  headers := jsonb_build_object('Content-Type', 'application/json', 'x-push-token', 'secret')
);

select is(
  (select headers ->> 'x-club-id' from net.http_request_queue
   where url = 'http://127.0.0.1:9/send-push' order by id desc limit 1),
  (select id::text from test_clubs where label = 'b'),
  'une notification demandée par la base indique le club concerné'
);

select is(
  (select headers ->> 'x-push-token' from net.http_request_queue
   where url = 'http://127.0.0.1:9/send-push' order by id desc limit 1),
  'secret',
  'les autres en-têtes de l''appel sont conservés'
);

select set_config('app.club_id', '', true);

select * from finish();
rollback;
