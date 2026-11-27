begin;

-- Copie AS Grinta (migration 20261210050000) :
-- * une alerte « copie en échec » peut être enregistrée et apparaît dans la
--   liste lue par l'onglet « À faire » du Poste de contrôle ;
-- * après une insertion avec un id explicite (comme le fait la copie), le
--   recalage remet le compteur au-delà du plus grand id.
set local search_path = public, extensions, pg_catalog;
select plan(4);

select lives_ok(
  $$insert into private.payment_alerts (kind, stripe_object_id, club_name, message)
    values ('sync_failed', 'sync-as-grinta-test', 'AS Grinta',
            'La copie automatique AS Grinta a échoué : test')$$,
  'le type d''alerte sync_failed est accepté'
);

select throws_ok(
  $$insert into private.payment_alerts (kind, message) values ('inconnu', 'x')$$,
  '23514',
  null,
  'un type d''alerte inconnu reste refusé'
);

select is(
  (select count(*) from private.payment_alerts
   where kind = 'sync_failed' and resolved_at is null
     and stripe_object_id = 'sync-as-grinta-test'),
  1::bigint,
  'l''alerte est ouverte (non traitée), donc visible dans « À faire »'
);

-- Compteur en retard, comme après une copie : une ligne au-delà du compteur.
select setval('public.player_aliases_id_seq', 1, false);
insert into public.player_aliases (id, player_id, alias, club_id)
select 990000, p.id, 'alias-test-compteur', p.club_id
from public.players p
limit 1;

select setval(pg_get_serial_sequence('public.player_aliases', 'id')::regclass,
              greatest(coalesce(max(id), 0),
                       coalesce(pg_sequence_last_value('public.player_aliases_id_seq'::regclass), 0),
                       1))
from public.player_aliases;

select ok(
  nextval('public.player_aliases_id_seq') > coalesce((select max(id) from public.player_aliases), 0),
  'après recalage, le prochain id dépasse le plus grand id présent'
);

select * from finish();
rollback;
