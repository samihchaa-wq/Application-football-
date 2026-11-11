-- Règles du club modifiables par son administrateur.
--
-- Dans la version d'origine, les règles que le club s'était données (quand
-- s'ouvrent les convocations et les pronostics, quand ils se ferment, combien
-- de temps dure le vote de l'homme du match, à quelle heure part le rappel…)
-- étaient écrites en dur dans la base. Chaque club peut maintenant fixer les
-- siennes ; sans réglage, la valeur par défaut est celle du club d'origine.

-- ---------------------------------------------------------------------------
-- 1. Catalogue des règles (liste fermée) et valeurs choisies par club
-- ---------------------------------------------------------------------------
create function private.club_rule_catalogue()
returns table (
  key text,
  label text,
  description text,
  unit text,
  group_label text,
  default_value integer,
  min_value integer,
  max_value integer,
  sort_order integer
)
language sql immutable
set search_path to ''
as $$
  select * from (values
    ('features_open_days', 'Ouverture avant le match',
     'Combien de jours avant le coup d’envoi s’ouvrent les disponibilités, la composition et les pronostics.',
     'jours', 'Avant le match', 6, 1, 21, 10),
    ('features_open_hour', 'Heure d’ouverture',
     'Heure (en France) à laquelle ils s’ouvrent ce jour-là.',
     'h', 'Avant le match', 12, 0, 23, 20),
    ('prediction_close_minutes', 'Fermeture des pronostics',
     'Combien de minutes avant le coup d’envoi les pronostics se ferment (et le mode live s’ouvre).',
     'min', 'Pronostics', 15, 0, 240, 30),
    ('prediction_reminder_hour', 'Heure du rappel de pronostic',
     'Heure (en France) du rappel envoyé le jour du match à ceux qui n’ont pas pronostiqué.',
     'h', 'Pronostics', 16, 0, 23, 40),
    ('motm_window_hours', 'Durée du vote de l’homme du match',
     'Combien d’heures après le coup d’envoi le vote reste ouvert.',
     'h', 'Après le match', 24, 1, 168, 50),
    ('correction_window_hours', 'Délai de correction du résultat',
     'Combien d’heures après sa validation le résultat peut encore être corrigé.',
     'h', 'Après le match', 24, 1, 168, 60),
    ('waitlist_cutoff_days', 'Liste d’attente : jour limite',
     'Combien de jours avant le match la liste d’attente cesse de créditer des places (0 = le jour même).',
     'jours', 'Liste d’attente', 1, 0, 7, 70),
    ('waitlist_cutoff_hour', 'Liste d’attente : heure limite',
     'Heure (en France) de ce jour limite.',
     'h', 'Liste d’attente', 12, 0, 23, 80)
  ) as catalogue(key, label, description, unit, group_label,
                 default_value, min_value, max_value, sort_order);
$$;

create table private.club_rules (
  club_id uuid not null default private.current_club_id()
    references public.clubs(id) on delete cascade,
  key text not null check (key ~ '^[a-z][a-z0-9_]*$'),
  value integer not null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null,
  primary key (club_id, key)
);
create index club_rules_club_id_idx on private.club_rules (club_id);
create index club_rules_updated_by_idx on private.club_rules (updated_by);
alter table private.club_rules enable row level security;
revoke all on private.club_rules from public, anon, authenticated;
create policy club_isolation on private.club_rules
  as restrictive
  using (club_id = (select private.current_club_id()))
  with check (club_id = (select private.current_club_id()));
create policy deny_client_access on private.club_rules
  as restrictive to anon, authenticated using (false) with check (false);
create policy club_scope_access on private.club_rules
  to club_scope using (true) with check (true);
grant select, insert, update, delete on private.club_rules to club_scope;
grant all on private.club_rules to service_role;

-- Valeur d'une règle pour le club courant (défaut du catalogue sinon).
create function private.club_rule(p_key text) returns integer
language sql stable security definer
set search_path to ''
as $$
  select coalesce(
    (
      select rule.value
      from private.club_rules rule
      where rule.key = p_key
        and rule.club_id = (select private.current_club_id())
    ),
    (select catalogue.default_value
     from private.club_rule_catalogue() catalogue
     where catalogue.key = p_key)
  );
$$;

alter function private.club_rule(text) owner to club_scope;
revoke all on function private.club_rule(text) from public, anon;
grant execute on function private.club_rule(text) to authenticated, service_role, club_scope;
revoke all on function private.club_rule_catalogue() from public, anon;
grant execute on function private.club_rule_catalogue() to authenticated, service_role, club_scope;

-- ---------------------------------------------------------------------------
-- 2. Lecture et modification par l'administrateur
-- ---------------------------------------------------------------------------
create function public.get_club_rules() returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
begin
  if not (select private.is_active_profile()) then
    return '[]'::jsonb;
  end if;

  return coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'key', catalogue.key,
        'label', catalogue.label,
        'description', catalogue.description,
        'unit', catalogue.unit,
        'group', catalogue.group_label,
        'default', catalogue.default_value,
        'min', catalogue.min_value,
        'max', catalogue.max_value,
        'value', private.club_rule(catalogue.key)
      )
      order by catalogue.sort_order
    )
    from private.club_rule_catalogue() catalogue
  ), '[]'::jsonb);
end;
$$;

-- p_value null : retour à la valeur par défaut.
create function public.admin_set_club_rule(p_key text, p_value integer)
returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_rule record;
begin
  if not (select private.is_admin()) then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;

  select * into v_rule from private.club_rule_catalogue() catalogue
  where catalogue.key = p_key;
  if not found then
    raise exception 'Règle inconnue.' using errcode = '22023';
  end if;

  if p_value is null then
    delete from private.club_rules
    where key = p_key and club_id = (select private.current_club_id());
  else
    if p_value < v_rule.min_value or p_value > v_rule.max_value then
      raise exception 'Valeur hors limites (% à %).', v_rule.min_value, v_rule.max_value
        using errcode = '22023';
    end if;
    insert into private.club_rules (key, value, updated_at, updated_by)
    values (p_key, p_value, now(), (select private.uid()))
    on conflict (club_id, key) do update
    set value = excluded.value,
        updated_at = excluded.updated_at,
        updated_by = excluded.updated_by;
  end if;

  return public.get_club_rules();
end;
$$;

do $$
declare
  v_signature text;
begin
  foreach v_signature in array array[
    'public.get_club_rules()',
    'public.admin_set_club_rule(text,integer)'
  ] loop
    execute format('alter function %s owner to club_scope', v_signature);
    execute format('revoke all on function %s from public, anon', v_signature);
    execute format('grant execute on function %s to authenticated, service_role, club_scope', v_signature);
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- 3. Les règles en dur lisent maintenant les réglages du club
-- ---------------------------------------------------------------------------
create or replace function private.match_features_open_at(p_kickoff_at timestamp with time zone)
returns timestamp with time zone
language sql stable strict
set search_path to ''
as $$
  select (
    (
      (p_kickoff_at at time zone 'Europe/Paris')::date
        - private.club_rule('features_open_days')
    ) + make_interval(hours => private.club_rule('features_open_hour'))
  ) at time zone 'Europe/Paris';
$$;

create or replace function private.match_prediction_closes_at(p_kickoff_at timestamp with time zone)
returns timestamp with time zone
language sql stable strict
set search_path to ''
as $$
  select p_kickoff_at
    - make_interval(mins => private.club_rule('prediction_close_minutes'));
$$;

create or replace function private.match_prediction_notification_at(p_kickoff_at timestamp with time zone)
returns timestamp with time zone
language sql stable strict
set search_path to ''
as $$
  select (
    ((p_kickoff_at at time zone 'Europe/Paris')::date
      + make_interval(hours => private.club_rule('prediction_reminder_hour')))
    at time zone 'Europe/Paris'
  );
$$;

create or replace function private.match_motm_closes_at(p_match_id uuid)
returns timestamp with time zone
language sql stable
set search_path to ''
as $$
  select match.kickoff_at
    + make_interval(hours => private.club_rule('motm_window_hours'))
  from public.matches match
  where match.id = p_match_id;
$$;

create or replace function private.match_postgame_correction_closes_at(p_match_id uuid)
returns timestamp with time zone
language sql stable security definer
set search_path to ''
as $$
  select coalesce(
    (
      select finalization.validated_at
        + make_interval(hours => private.club_rule('correction_window_hours'))
      from public.match_sport_finalizations finalization
      where finalization.match_id = p_match_id
    ),
    (
      select match.result_validated_at
        + make_interval(hours => private.club_rule('correction_window_hours'))
      from public.matches match
      where match.id = p_match_id
    )
  );
$$;

create or replace function private.waitlist_credit_cutoff(p_kickoff timestamp with time zone)
returns timestamp with time zone
language sql stable
set search_path to ''
as $$
  select (
    ((p_kickoff at time zone 'Europe/Paris')::date
      - private.club_rule('waitlist_cutoff_days'))
    + make_interval(hours => private.club_rule('waitlist_cutoff_hour'))
  ) at time zone 'Europe/Paris';
$$;
