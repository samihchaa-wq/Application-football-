-- Quota d'inscription : un plafond par parcours.
--
-- Avant : 5 inscriptions par heure et 15 par jour depuis une même adresse
-- réseau, tous parcours confondus. Un club qui inscrit ses joueurs ensemble
-- (même Wi-Fi au vestiaire, même box, même antenne 4G) était bloqué au
-- sixième pendant une heure.
--
-- Désormais :
--   * rejoindre un club (code d'invitation) : 30 par heure, 100 par jour.
--     Le compte reste de toute façon en attente de validation par un
--     administrateur du club ;
--   * créer un club : 5 par heure, 15 par jour, comme avant, car chaque club
--     ajoute du travail planifié à toute la plate-forme.
-- Les deux compteurs sont séparés : des créations de club ne bloquent pas les
-- joueurs, et inversement.
--
-- Compatibilité : `p_mode` a une valeur par défaut. La fonction Edge
-- `register-account` déjà en ligne appelle sans ce paramètre : ses appels
-- comptent comme « rejoindre » jusqu'à son redéploiement, qui passe le mode.

alter table private.registration_attempts
  add column if not exists mode text not null default 'join';

alter table private.registration_attempts
  drop constraint if exists registration_attempts_mode_check;
alter table private.registration_attempts
  add constraint registration_attempts_mode_check check (mode in ('join', 'create'));

create index if not exists registration_attempts_origin_mode_idx
  on private.registration_attempts (origin_hash, mode, attempted_at);

drop function if exists public.consume_registration_rate_limit(text);

create function public.consume_registration_rate_limit(
  p_origin_hash text,
  p_mode text default 'join'
) returns boolean
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_mode text := coalesce(nullif(btrim(p_mode), ''), 'join');
  v_hour_limit integer;
  v_day_limit integer;
  v_origin_hour integer;
  v_origin_day integer;
begin
  if p_origin_hash is null or p_origin_hash !~ '^[0-9a-f]{64}$' then
    raise exception 'Invalid origin hash' using errcode = '22023';
  end if;
  if v_mode not in ('join', 'create') then
    raise exception 'Invalid registration mode' using errcode = '22023';
  end if;

  if v_mode = 'create' then
    v_hour_limit := 5;
    v_day_limit := 15;
  else
    v_hour_limit := 30;
    v_day_limit := 100;
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(p_origin_hash, 0)
  );

  delete from private.registration_attempts
  where attempted_at < now() - interval '24 hours';

  select count(*)::integer
  into v_origin_hour
  from private.registration_attempts
  where origin_hash = p_origin_hash
    and mode = v_mode
    and attempted_at >= now() - interval '1 hour';

  select count(*)::integer
  into v_origin_day
  from private.registration_attempts
  where origin_hash = p_origin_hash
    and mode = v_mode
    and attempted_at >= now() - interval '24 hours';

  if v_origin_hour >= v_hour_limit or v_origin_day >= v_day_limit then
    return false;
  end if;

  insert into private.registration_attempts(origin_hash, mode)
  values (p_origin_hash, v_mode);

  return true;
end;
$$;

alter function public.consume_registration_rate_limit(text, text) owner to postgres;
revoke all on function public.consume_registration_rate_limit(text, text) from public, anon, authenticated;
grant execute on function public.consume_registration_rate_limit(text, text) to service_role;

comment on function public.consume_registration_rate_limit(text, text) is
  'Quota d''inscription par adresse réseau hachée : rejoindre un club 30/h et 100/j, créer un club 5/h et 15/j. Réservé aux fonctions Edge (service_role).';
