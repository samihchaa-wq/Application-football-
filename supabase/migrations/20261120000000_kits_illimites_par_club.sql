-- Un maillot par défaut ; un nombre libre de tenues par club.
-- Migration additive : ni effacement des kits existants, ni changement des
-- identifiants historiques 'france', 'orange' et 'blue'.
-- Les tenues retirées sont conservées avec archived=true et enabled=false.

alter table public.clubs drop constraint clubs_kits_shape;
alter table public.clubs add constraint clubs_kits_shape check (
  kits is null or (jsonb_typeof(kits) = 'array' and jsonb_array_length(kits) >= 1)
);

create or replace function public.admin_update_club_kits(p_kits jsonb)
returns jsonb language plpgsql security definer set search_path to ''
as $$
declare
  v_club public.clubs;
  v_item jsonb;
  v_previous_kits jsonb;
  v_previous jsonb;
  v_prior jsonb;
  v_clean jsonb := '[]'::jsonb;
  v_ids text[] := array[]::text[];
  v_id text;
  v_label text;
  v_body text;
  v_trim text;
  v_gk_body text;
  v_gk_trim text;
  v_pattern jsonb;
  v_gk_pattern jsonb;
  v_dress jsonb;
  v_archive jsonb;
  v_enabled boolean;
  v_active_count integer := 0;
begin
  if not (select private.is_admin()) or not (select private.is_active_profile()) then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;
  if p_kits is null or jsonb_typeof(p_kits) <> 'array'
     or jsonb_array_length(p_kits) < 1 then
    raise exception 'Au moins un maillot est nécessaire.' using errcode = '22023';
  end if;

  select kits into v_previous_kits
  from public.clubs
  where id = (select private.current_club_id()) for update;
  if not found then
    raise exception 'Club introuvable.' using errcode = 'P0002';
  end if;

  -- Un client ancien ne doit jamais faire disparaître une tenue créée
  -- depuis un autre appareil : les identifiants existants sont immuables.
  for v_prior in
    select value from jsonb_array_elements(coalesce(v_previous_kits, '[]'::jsonb))
  loop
    if not exists (
      select 1 from jsonb_array_elements(p_kits) as entry(value)
      where entry.value ->> 'slot' = v_prior ->> 'slot'
    ) then
      raise exception 'Liste de maillots dépassée : recharge les réglages.'
        using errcode = '22023';
    end if;
  end loop;

  for v_item in select value from jsonb_array_elements(p_kits) loop
    v_id := v_item ->> 'slot';
    if jsonb_typeof(v_item) <> 'object'
       or v_id is null
       or v_id !~ '^(france|orange|blue|kit_[a-z0-9_]{1,48})$'
       or v_id = any(v_ids) then
      raise exception 'Identifiant de maillot invalide ou en double.'
        using errcode = '22023';
    end if;
    v_ids := v_ids || v_id;
    select value into v_previous from
      jsonb_array_elements(coalesce(v_previous_kits, '[]'::jsonb)) as entry(value)
      where value ->> 'slot' = v_id limit 1;

    v_label := regexp_replace(btrim(coalesce(v_item ->> 'label', '')),
                              '[[:space:]]+', ' ', 'g');
    if char_length(v_label) < 1 or char_length(v_label) > 20 then
      raise exception 'Nom de maillot invalide (1 à 20 caractères).'
        using errcode = '22023';
    end if;
    v_body := v_item ->> 'body';
    v_trim := v_item ->> 'trim';
    v_gk_body := coalesce(v_item ->> 'goalkeeper_body',
                          v_previous ->> 'goalkeeper_body',
                          case v_id
                            when 'orange' then '#F5A300'
                            when 'blue' then '#1F6FEB'
                            else '#168A52'
                          end);
    v_gk_trim := coalesce(v_item ->> 'goalkeeper_trim',
                          v_previous ->> 'goalkeeper_trim', '#FFFFFF');
    if v_body !~ '^#[0-9A-Fa-f]{6}$'
       or v_trim !~ '^#[0-9A-Fa-f]{6}$'
       or v_gk_body !~ '^#[0-9A-Fa-f]{6}$'
       or v_gk_trim !~ '^#[0-9A-Fa-f]{6}$' then
      raise exception 'Couleur de maillot invalide.' using errcode = '22023';
    end if;
    if jsonb_typeof(v_item -> 'enabled') <> 'boolean' then
      raise exception 'État du maillot invalide.' using errcode = '22023';
    end if;
    v_pattern := coalesce(v_item -> 'pattern',
                          v_previous -> 'pattern', to_jsonb('plain'::text));
    v_gk_pattern := coalesce(v_item -> 'goalkeeper_pattern',
                             v_previous -> 'goalkeeper_pattern',
                             to_jsonb('plain'::text));
    v_dress := coalesce(v_item -> 'dress_players',
                        v_previous -> 'dress_players', 'false'::jsonb);
    v_archive := coalesce(v_item -> 'archived',
                          v_previous -> 'archived', 'false'::jsonb);
    if jsonb_typeof(v_pattern) <> 'string' or
       (v_pattern #>> '{}') not in ('plain','stripes','hoops','sash') or
       jsonb_typeof(v_gk_pattern) <> 'string' or
       (v_gk_pattern #>> '{}') not in ('plain','stripes','hoops','sash') or
       jsonb_typeof(v_dress) <> 'boolean' or
       jsonb_typeof(v_archive) <> 'boolean' then
      raise exception 'Configuration de maillot invalide.' using errcode = '22023';
    end if;
    v_enabled := (v_item ->> 'enabled')::boolean
                 and not (v_archive #>> '{}')::boolean;
    if v_enabled then v_active_count := v_active_count + 1; end if;

    v_clean := v_clean || jsonb_build_array(jsonb_build_object(
      'slot', v_id, 'label', v_label,
      'body', upper(v_body), 'trim', upper(v_trim),
      'goalkeeper_body', upper(v_gk_body),
      'goalkeeper_trim', upper(v_gk_trim),
      'pattern', v_pattern, 'goalkeeper_pattern', v_gk_pattern,
      'dress_players', v_dress, 'archived', v_archive,
      'enabled', v_enabled
    ));
  end loop;
  if v_active_count = 0 then
    raise exception 'Au moins un maillot doit être proposé.'
      using errcode = '22023';
  end if;
  update public.clubs set kits = v_clean
  where id = (select private.current_club_id())
  returning * into v_club;
  return v_club.kits;
end;
$$;

-- Les compositions et archives acceptent désormais les identifiants custom.
alter table public.match_internal_compositions
  drop constraint match_internal_compositions_team1_jersey_check;
alter table public.match_internal_compositions
  drop constraint match_internal_compositions_team2_jersey_check;
alter table public.match_internal_compositions
  add constraint match_internal_compositions_team1_jersey_check
    check (team1_jersey ~ '^(france|orange|blue|kit_[a-z0-9_]{1,48})$');
alter table public.match_internal_compositions
  add constraint match_internal_compositions_team2_jersey_check
    check (team2_jersey ~ '^(france|orange|blue|kit_[a-z0-9_]{1,48})$');

alter table public.match_kit_snapshots
  drop constraint match_kit_snapshots_jersey_id_check;
alter table public.match_kit_snapshots
  drop constraint match_kit_snapshots_kits_check;
alter table public.match_kit_snapshots
  add constraint match_kit_snapshots_jersey_id_check
    check (jersey_id ~ '^(france|orange|blue|kit_[a-z0-9_]{1,48})$');
alter table public.match_kit_snapshots
  add constraint match_kit_snapshots_kits_check
    check (jsonb_typeof(kits) = 'array' and jsonb_array_length(kits) >= 1);

-- Couleurs et motifs de tous les maillots de la liste au moment du Live.
CREATE OR REPLACE FUNCTION private.match_kit_snapshot_value(p_kits jsonb, p_primary text, p_secondary text, p_slot text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
declare
  v_slot text := p_slot;
  v_kit jsonb;
  v_body text;
  v_trim text;
  v_label text;
  v_gk_body text;
begin
  if jsonb_typeof(p_kits) = 'array' then
    select elem.value into v_kit
    from jsonb_array_elements(p_kits) as elem(value)
    where elem.value ->> 'slot' = v_slot
    limit 1;
  end if;

  v_body := case v_slot
    when 'france' then coalesce(p_primary, '#1F6FEB')
    when 'orange' then '#FFFFFF'
    else '#1B1F2A'
  end;
  v_trim := case v_slot
    when 'orange' then coalesce(p_primary, '#1F6FEB')
    else coalesce(p_secondary, '#FFFFFF')
  end;
  v_label := case v_slot
    when 'france' then 'Domicile'
    when 'orange' then 'Extérieur'
    when 'blue' then 'Troisième'
    else 'Maillot archivé'
  end;
  v_gk_body := case v_slot
    when 'france' then '#168A52'
    when 'orange' then '#F5A300'
    else '#1F6FEB'
  end;
  return jsonb_build_object(
    'slot', v_slot,
    'label', coalesce(v_kit ->> 'label', v_label),
    'body', coalesce(v_kit ->> 'body', v_body),
    'trim', coalesce(v_kit ->> 'trim', v_trim),
    'goalkeeper_body', coalesce(v_kit ->> 'goalkeeper_body', v_gk_body),
    'goalkeeper_trim', coalesce(v_kit ->> 'goalkeeper_trim', '#FFFFFF'),
    'pattern', coalesce(v_kit ->> 'pattern', 'plain'),
    'goalkeeper_pattern', coalesce(v_kit ->> 'goalkeeper_pattern', 'plain'),
    'dress_players', coalesce((v_kit ->> 'dress_players')::boolean, false),
    'archived', coalesce((v_kit ->> 'archived')::boolean, false),
    'enabled', coalesce((v_kit ->> 'enabled')::boolean, true)
  );
end;
$function$


CREATE OR REPLACE FUNCTION private.capture_match_kit_snapshot(p_match_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_match record;
  v_kits jsonb;
  v_slot text;
  v_team_slot text;
begin
  select m.club_id, m.jersey_note, m.match_type,
         c.kits as club_kits, c.primary_color, c.secondary_color,
         i.team1_jersey, i.team2_jersey
  into v_match
  from public.matches m
  join public.clubs c on c.id = m.club_id
  left join public.match_internal_compositions i
    on i.match_id = m.id and i.club_id = m.club_id
  where m.id = p_match_id;
  if not found then return; end if;

  -- Ne pas recalculer les tenues en dur. Archiver la liste exacte du club.
  if jsonb_typeof(v_match.club_kits) = 'array'
     and jsonb_array_length(v_match.club_kits) > 0 then
    select jsonb_agg(
      private.match_kit_snapshot_value(
        v_match.club_kits, v_match.primary_color,
        v_match.secondary_color, element.value ->> 'slot'
      ) order by element.ordinality
    ) into v_kits
    from jsonb_array_elements(v_match.club_kits) with ordinality
      as element(value, ordinality);
  else
    v_kits := jsonb_build_array(private.match_kit_snapshot_value(
      null, v_match.primary_color, v_match.secondary_color, 'france'
    ));
  end if;

  -- Le match "entre nous" peut utiliser la tenue de contraste historique
  -- quand un seul maillot a été configuré.
  if v_match.match_type = 'entre_nous' then
    foreach v_team_slot in array array[v_match.team1_jersey, v_match.team2_jersey]
    loop
      if v_team_slot in ('france','orange','blue') and not exists (
        select 1 from jsonb_array_elements(v_kits) as element(value)
        where element.value ->> 'slot' = v_team_slot
      ) then
        v_kits := v_kits || jsonb_build_array(private.match_kit_snapshot_value(
          null, v_match.primary_color, v_match.secondary_color, v_team_slot
        ));
      end if;
    end loop;
  end if;

  select element.value ->> 'slot' into v_slot
  from jsonb_array_elements(v_kits) as element(value)
  where element.value ->> 'slot' = v_match.jersey_note
  limit 1;
  if v_slot is null then
    select element.value ->> 'slot' into v_slot
    from jsonb_array_elements(v_kits) as element(value)
    where element.value ->> 'slot' = 'france' limit 1;
  end if;
  if v_slot is null then v_slot := v_kits -> 0 ->> 'slot'; end if;

  insert into public.match_kit_snapshots(
    match_id, club_id, jersey_id, kit, kits, team1_kit, team2_kit
  ) values (
    p_match_id,
    v_match.club_id,
    v_slot,
    (select elem.value from jsonb_array_elements(v_kits) as elem(value)
      where elem.value ->> 'slot' = v_slot limit 1),
    v_kits,
    case when v_match.match_type = 'entre_nous' then
      (select elem.value from jsonb_array_elements(v_kits) as elem(value)
       where elem.value ->> 'slot' = v_match.team1_jersey limit 1)
    end,
    case when v_match.match_type = 'entre_nous' then
      (select elem.value from jsonb_array_elements(v_kits) as elem(value)
       where elem.value ->> 'slot' = v_match.team2_jersey limit 1)
    end
  )
  on conflict (match_id) do nothing;

  if v_match.match_type = 'entre_nous' then
    update public.match_kit_snapshots s
    set team1_kit = coalesce(
          s.team1_kit,
          (select elem.value from jsonb_array_elements(s.kits) as elem(value)
           where elem.value ->> 'slot' = v_match.team1_jersey limit 1)
        ),
        team2_kit = coalesce(
          s.team2_kit,
          (select elem.value from jsonb_array_elements(s.kits) as elem(value)
           where elem.value ->> 'slot' = v_match.team2_jersey limit 1)
        )
    where s.match_id = p_match_id
      and (s.team1_kit is null or s.team2_kit is null);
  end if;
end;
$function$


CREATE OR REPLACE FUNCTION public.admin_save_internal_composition_v2(p_match_id uuid, p_team1_name text, p_team2_name text, p_team1_jersey text, p_team2_jersey text, p_entries jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_match_type text;
  v_status text;
  v_kickoff_at timestamptz;
  v_team1_name text := coalesce(nullif(btrim(p_team1_name), ''), 'Équipe 1');
  v_team2_name text := coalesce(nullif(btrim(p_team2_name), ''), 'Équipe 2');
  v_team1_jersey text := lower(btrim(coalesce(p_team1_jersey, '')));
  v_team2_jersey text := lower(btrim(coalesce(p_team2_jersey, '')));
  v_entry jsonb;
begin
  if not public.is_match_staff() then
    raise exception 'Active administrator role required' using errcode = '42501';
  end if;
  if char_length(v_team1_name) > 40 or char_length(v_team2_name) > 40 then
    raise exception 'Nom d''équipe trop long (40 caractères max).' using errcode = '22023';
  end if;
  if v_team1_jersey !~ '^(france|orange|blue|kit_[a-z0-9_]{1,48})
      or v_team2_jersey !~ '^(france|orange|blue|kit_[a-z0-9_]{1,48}) then
    raise exception 'Maillot invalide.' using errcode = '22023';
  end if;
  if exists (
    select 1 from (values (v_team1_jersey), (v_team2_jersey)) as jersey(id)
    where jersey.id like 'kit_%'
      and not exists (
        select 1 from public.matches m
        join public.clubs c on c.id = m.club_id
        cross join lateral jsonb_array_elements(coalesce(c.kits, '[]'::jsonb))
          as entry(value)
        where m.id = p_match_id and entry.value ->> 'slot' = jersey.id
          and coalesce((entry.value ->> 'archived')::boolean, false) = false
      )
  ) then
    raise exception 'Maillot du club introuvable ou archivé.'
      using errcode = '22023';
  end if;

  if v_team1_jersey = v_team2_jersey then
    raise exception 'Les deux équipes doivent avoir des maillots différents.'
      using errcode = '22023';
  end if;

  select
    m.match_type,
    m.status,
    coalesce(
      m.kickoff_at,
      ((m.match_date + m.match_time) at time zone 'Europe/Paris')
    )
  into v_match_type, v_status, v_kickoff_at
  from public.matches m
  where m.id = p_match_id
  for update;

  if v_match_type is null or v_match_type <> 'entre_nous' then
    raise exception 'Match entre nous introuvable' using errcode = 'P0002';
  end if;
  if v_status <> 'a_venir' then
    raise exception 'La composition d’un match terminé ou annulé est verrouillée.'
      using errcode = '22023';
  end if;
  if v_kickoff_at is null then
    raise exception 'Horaire du match introuvable : composition refusée.' using errcode = '22023';
  end if;
  if now() >= private.match_prediction_closes_at(v_kickoff_at) then
    raise exception 'La composition est figée depuis l’ouverture du Live.'
      using errcode = '22023';
  end if;

  insert into public.match_internal_compositions (
    match_id,
    team1_name,
    team2_name,
    team1_jersey,
    team2_jersey,
    updated_by
  ) values (
    p_match_id,
    v_team1_name,
    v_team2_name,
    v_team1_jersey,
    v_team2_jersey,
    (select private.uid())
  )
  on conflict (match_id) do update
  set team1_name = excluded.team1_name,
      team2_name = excluded.team2_name,
      team1_jersey = excluded.team1_jersey,
      team2_jersey = excluded.team2_jersey,
      updated_by = excluded.updated_by,
      updated_at = now();

  delete from public.match_internal_composition_entries
  where match_id = p_match_id;

  for v_entry in
    select value
    from jsonb_array_elements(coalesce(p_entries, '[]'::jsonb))
  loop
    insert into public.match_internal_composition_entries (
      match_id,
      participant_id,
      team_no,
      sort_order
    ) values (
      p_match_id,
      (v_entry ->> 'participant_id')::uuid,
      nullif(v_entry ->> 'team_no', '')::smallint,
      coalesce((v_entry ->> 'sort_order')::integer, 0)
    );
  end loop;

  -- Un match entre nous n'a pas de publication séparée : la feuille est en
  -- ligne dès qu'elle est enregistrée. On ne prévient qu'une fois des joueurs
  -- réellement répartis, pour ne pas annoncer une feuille vide.
  if exists (
    select 1
    from public.match_internal_composition_entries entry
    where entry.match_id = p_match_id
      and entry.team_no is not null
  ) then
    perform private.notify_composition_published(p_match_id);
  end if;

  return public.get_internal_composition(p_match_id);
end;
$function$

      or v_team2_jersey not in ('france', 'orange', 'blue') then
    raise exception 'Maillot invalide.' using errcode = '22023';
  end if;
  if v_team1_jersey = v_team2_jersey then
    raise exception 'Les deux équipes doivent avoir des maillots différents.'
      using errcode = '22023';
  end if;

  select
    m.match_type,
    m.status,
    coalesce(
      m.kickoff_at,
      ((m.match_date + m.match_time) at time zone 'Europe/Paris')
    )
  into v_match_type, v_status, v_kickoff_at
  from public.matches m
  where m.id = p_match_id
  for update;

  if v_match_type is null or v_match_type <> 'entre_nous' then
    raise exception 'Match entre nous introuvable' using errcode = 'P0002';
  end if;
  if v_status <> 'a_venir' then
    raise exception 'La composition d’un match terminé ou annulé est verrouillée.'
      using errcode = '22023';
  end if;
  if v_kickoff_at is null then
    raise exception 'Horaire du match introuvable : composition refusée.' using errcode = '22023';
  end if;
  if now() >= private.match_prediction_closes_at(v_kickoff_at) then
    raise exception 'La composition est figée depuis l’ouverture du Live.'
      using errcode = '22023';
  end if;

  insert into public.match_internal_compositions (
    match_id,
    team1_name,
    team2_name,
    team1_jersey,
    team2_jersey,
    updated_by
  ) values (
    p_match_id,
    v_team1_name,
    v_team2_name,
    v_team1_jersey,
    v_team2_jersey,
    (select private.uid())
  )
  on conflict (match_id) do update
  set team1_name = excluded.team1_name,
      team2_name = excluded.team2_name,
      team1_jersey = excluded.team1_jersey,
      team2_jersey = excluded.team2_jersey,
      updated_by = excluded.updated_by,
      updated_at = now();

  delete from public.match_internal_composition_entries
  where match_id = p_match_id;

  for v_entry in
    select value
    from jsonb_array_elements(coalesce(p_entries, '[]'::jsonb))
  loop
    insert into public.match_internal_composition_entries (
      match_id,
      participant_id,
      team_no,
      sort_order
    ) values (
      p_match_id,
      (v_entry ->> 'participant_id')::uuid,
      nullif(v_entry ->> 'team_no', '')::smallint,
      coalesce((v_entry ->> 'sort_order')::integer, 0)
    );
  end loop;

  -- Un match entre nous n'a pas de publication séparée : la feuille est en
  -- ligne dès qu'elle est enregistrée. On ne prévient qu'une fois des joueurs
  -- réellement répartis, pour ne pas annoncer une feuille vide.
  if exists (
    select 1
    from public.match_internal_composition_entries entry
    where entry.match_id = p_match_id
      and entry.team_no is not null
  ) then
    perform private.notify_composition_published(p_match_id);
  end if;

  return public.get_internal_composition(p_match_id);
end;
$function$
 then
    raise exception 'Maillot invalide.' using errcode = '22023';
  end if;
  if v_team1_jersey = v_team2_jersey then
    raise exception 'Les deux équipes doivent avoir des maillots différents.'
      using errcode = '22023';
  end if;

  select
    m.match_type,
    m.status,
    coalesce(
      m.kickoff_at,
      ((m.match_date + m.match_time) at time zone 'Europe/Paris')
    )
  into v_match_type, v_status, v_kickoff_at
  from public.matches m
  where m.id = p_match_id
  for update;

  if v_match_type is null or v_match_type <> 'entre_nous' then
    raise exception 'Match entre nous introuvable' using errcode = 'P0002';
  end if;
  if v_status <> 'a_venir' then
    raise exception 'La composition d’un match terminé ou annulé est verrouillée.'
      using errcode = '22023';
  end if;
  if v_kickoff_at is null then
    raise exception 'Horaire du match introuvable : composition refusée.' using errcode = '22023';
  end if;
  if now() >= private.match_prediction_closes_at(v_kickoff_at) then
    raise exception 'La composition est figée depuis l’ouverture du Live.'
      using errcode = '22023';
  end if;

  insert into public.match_internal_compositions (
    match_id,
    team1_name,
    team2_name,
    team1_jersey,
    team2_jersey,
    updated_by
  ) values (
    p_match_id,
    v_team1_name,
    v_team2_name,
    v_team1_jersey,
    v_team2_jersey,
    (select private.uid())
  )
  on conflict (match_id) do update
  set team1_name = excluded.team1_name,
      team2_name = excluded.team2_name,
      team1_jersey = excluded.team1_jersey,
      team2_jersey = excluded.team2_jersey,
      updated_by = excluded.updated_by,
      updated_at = now();

  delete from public.match_internal_composition_entries
  where match_id = p_match_id;

  for v_entry in
    select value
    from jsonb_array_elements(coalesce(p_entries, '[]'::jsonb))
  loop
    insert into public.match_internal_composition_entries (
      match_id,
      participant_id,
      team_no,
      sort_order
    ) values (
      p_match_id,
      (v_entry ->> 'participant_id')::uuid,
      nullif(v_entry ->> 'team_no', '')::smallint,
      coalesce((v_entry ->> 'sort_order')::integer, 0)
    );
  end loop;

  -- Un match entre nous n'a pas de publication séparée : la feuille est en
  -- ligne dès qu'elle est enregistrée. On ne prévient qu'une fois des joueurs
  -- réellement répartis, pour ne pas annoncer une feuille vide.
  if exists (
    select 1
    from public.match_internal_composition_entries entry
    where entry.match_id = p_match_id
      and entry.team_no is not null
  ) then
    perform private.notify_composition_published(p_match_id);
  end if;

  return public.get_internal_composition(p_match_id);
end;
$function$

      or v_team2_jersey !~ '^(france|orange|blue|kit_[a-z0-9_]{1,48}) then
    raise exception 'Maillot invalide.' using errcode = '22023';
  end if;
  if v_team1_jersey = v_team2_jersey then
    raise exception 'Les deux équipes doivent avoir des maillots différents.'
      using errcode = '22023';
  end if;

  select
    m.match_type,
    m.status,
    coalesce(
      m.kickoff_at,
      ((m.match_date + m.match_time) at time zone 'Europe/Paris')
    )
  into v_match_type, v_status, v_kickoff_at
  from public.matches m
  where m.id = p_match_id
  for update;

  if v_match_type is null or v_match_type <> 'entre_nous' then
    raise exception 'Match entre nous introuvable' using errcode = 'P0002';
  end if;
  if v_status <> 'a_venir' then
    raise exception 'La composition d’un match terminé ou annulé est verrouillée.'
      using errcode = '22023';
  end if;
  if v_kickoff_at is null then
    raise exception 'Horaire du match introuvable : composition refusée.' using errcode = '22023';
  end if;
  if now() >= private.match_prediction_closes_at(v_kickoff_at) then
    raise exception 'La composition est figée depuis l’ouverture du Live.'
      using errcode = '22023';
  end if;

  insert into public.match_internal_compositions (
    match_id,
    team1_name,
    team2_name,
    team1_jersey,
    team2_jersey,
    updated_by
  ) values (
    p_match_id,
    v_team1_name,
    v_team2_name,
    v_team1_jersey,
    v_team2_jersey,
    (select private.uid())
  )
  on conflict (match_id) do update
  set team1_name = excluded.team1_name,
      team2_name = excluded.team2_name,
      team1_jersey = excluded.team1_jersey,
      team2_jersey = excluded.team2_jersey,
      updated_by = excluded.updated_by,
      updated_at = now();

  delete from public.match_internal_composition_entries
  where match_id = p_match_id;

  for v_entry in
    select value
    from jsonb_array_elements(coalesce(p_entries, '[]'::jsonb))
  loop
    insert into public.match_internal_composition_entries (
      match_id,
      participant_id,
      team_no,
      sort_order
    ) values (
      p_match_id,
      (v_entry ->> 'participant_id')::uuid,
      nullif(v_entry ->> 'team_no', '')::smallint,
      coalesce((v_entry ->> 'sort_order')::integer, 0)
    );
  end loop;

  -- Un match entre nous n'a pas de publication séparée : la feuille est en
  -- ligne dès qu'elle est enregistrée. On ne prévient qu'une fois des joueurs
  -- réellement répartis, pour ne pas annoncer une feuille vide.
  if exists (
    select 1
    from public.match_internal_composition_entries entry
    where entry.match_id = p_match_id
      and entry.team_no is not null
  ) then
    perform private.notify_composition_published(p_match_id);
  end if;

  return public.get_internal_composition(p_match_id);
end;
$function$
 then
    raise exception 'Maillot invalide.' using errcode = '22023';
  end if;
  if v_team1_jersey = v_team2_jersey then
    raise exception 'Les deux équipes doivent avoir des maillots différents.'
      using errcode = '22023';
  end if;

  select
    m.match_type,
    m.status,
    coalesce(
      m.kickoff_at,
      ((m.match_date + m.match_time) at time zone 'Europe/Paris')
    )
  into v_match_type, v_status, v_kickoff_at
  from public.matches m
  where m.id = p_match_id
  for update;

  if v_match_type is null or v_match_type <> 'entre_nous' then
    raise exception 'Match entre nous introuvable' using errcode = 'P0002';
  end if;
  if v_status <> 'a_venir' then
    raise exception 'La composition d’un match terminé ou annulé est verrouillée.'
      using errcode = '22023';
  end if;
  if v_kickoff_at is null then
    raise exception 'Horaire du match introuvable : composition refusée.' using errcode = '22023';
  end if;
  if now() >= private.match_prediction_closes_at(v_kickoff_at) then
    raise exception 'La composition est figée depuis l’ouverture du Live.'
      using errcode = '22023';
  end if;

  insert into public.match_internal_compositions (
    match_id,
    team1_name,
    team2_name,
    team1_jersey,
    team2_jersey,
    updated_by
  ) values (
    p_match_id,
    v_team1_name,
    v_team2_name,
    v_team1_jersey,
    v_team2_jersey,
    (select private.uid())
  )
  on conflict (match_id) do update
  set team1_name = excluded.team1_name,
      team2_name = excluded.team2_name,
      team1_jersey = excluded.team1_jersey,
      team2_jersey = excluded.team2_jersey,
      updated_by = excluded.updated_by,
      updated_at = now();

  delete from public.match_internal_composition_entries
  where match_id = p_match_id;

  for v_entry in
    select value
    from jsonb_array_elements(coalesce(p_entries, '[]'::jsonb))
  loop
    insert into public.match_internal_composition_entries (
      match_id,
      participant_id,
      team_no,
      sort_order
    ) values (
      p_match_id,
      (v_entry ->> 'participant_id')::uuid,
      nullif(v_entry ->> 'team_no', '')::smallint,
      coalesce((v_entry ->> 'sort_order')::integer, 0)
    );
  end loop;

  -- Un match entre nous n'a pas de publication séparée : la feuille est en
  -- ligne dès qu'elle est enregistrée. On ne prévient qu'une fois des joueurs
  -- réellement répartis, pour ne pas annoncer une feuille vide.
  if exists (
    select 1
    from public.match_internal_composition_entries entry
    where entry.match_id = p_match_id
      and entry.team_no is not null
  ) then
    perform private.notify_composition_published(p_match_id);
  end if;

  return public.get_internal_composition(p_match_id);
end;
$function$


CREATE OR REPLACE FUNCTION public.admin_save_internal_composition_v3(p_match_id uuid, p_team1_name text, p_team2_name text, p_team1_jersey text, p_team2_jersey text, p_team1_formation text, p_team2_formation text, p_entries jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_match_type text;
  v_status text;
  v_kickoff_at timestamptz;
  v_team1_name text := coalesce(nullif(btrim(p_team1_name), ''), 'Équipe 1');
  v_team2_name text := coalesce(nullif(btrim(p_team2_name), ''), 'Équipe 2');
  v_team1_jersey text := lower(btrim(coalesce(p_team1_jersey, '')));
  v_team2_jersey text := lower(btrim(coalesce(p_team2_jersey, '')));
  v_team1_formation text := btrim(coalesce(p_team1_formation, ''));
  v_team2_formation text := btrim(coalesce(p_team2_formation, ''));
  v_expected_count integer;
  v_team1_count integer;
  v_team2_count integer;
  v_team1_starters integer;
  v_team2_starters integer;
  v_team1_slots text[];
  v_team2_slots text[];
  v_entry jsonb;
begin
  if not public.is_match_staff() then
    raise exception 'Active administrator role required' using errcode = '42501';
  end if;
  if jsonb_typeof(coalesce(p_entries, 'null'::jsonb)) <> 'array' then
    raise exception 'La composition doit être une liste.' using errcode = '22023';
  end if;
  if char_length(v_team1_name) > 40 or char_length(v_team2_name) > 40 then
    raise exception 'Nom d''équipe trop long (40 caractères max).' using errcode = '22023';
  end if;
  if v_team1_jersey !~ '^(france|orange|blue|kit_[a-z0-9_]{1,48})
      or v_team2_jersey !~ '^(france|orange|blue|kit_[a-z0-9_]{1,48}) then
    raise exception 'Maillot invalide.' using errcode = '22023';
  end if;
  if exists (
    select 1 from (values (v_team1_jersey), (v_team2_jersey)) as jersey(id)
    where jersey.id like 'kit_%'
      and not exists (
        select 1 from public.matches m
        join public.clubs c on c.id = m.club_id
        cross join lateral jsonb_array_elements(coalesce(c.kits, '[]'::jsonb))
          as entry(value)
        where m.id = p_match_id and entry.value ->> 'slot' = jersey.id
          and coalesce((entry.value ->> 'archived')::boolean, false) = false
      )
  ) then
    raise exception 'Maillot du club introuvable ou archivé.'
      using errcode = '22023';
  end if;

  if v_team1_jersey = v_team2_jersey then
    raise exception 'Les deux équipes doivent avoir des maillots différents.'
      using errcode = '22023';
  end if;

  select
    m.match_type,
    m.status,
    coalesce(
      m.kickoff_at,
      ((m.match_date + m.match_time) at time zone 'Europe/Paris')
    )
  into v_match_type, v_status, v_kickoff_at
  from public.matches m
  where m.id = p_match_id
  for update;

  if v_match_type is null or v_match_type <> 'entre_nous' then
    raise exception 'Match entre nous introuvable' using errcode = 'P0002';
  end if;
  if v_status <> 'a_venir' then
    raise exception 'La composition d’un match terminé ou annulé est verrouillée.'
      using errcode = '22023';
  end if;
  if v_kickoff_at is null then
    raise exception 'Horaire du match introuvable : composition refusée.' using errcode = '22023';
  end if;
  if now() >= private.match_prediction_closes_at(v_kickoff_at) then
    raise exception 'La composition est figée depuis l’ouverture du Live.'
      using errcode = '22023';
  end if;

  select count(*)::integer
  into v_expected_count
  from public.match_sport_participants participant
  where participant.match_id = p_match_id
    and participant.convocation_status = 'convoked';

  if v_expected_count = 0 then
    raise exception 'Aucun joueur convoqué.' using errcode = '22023';
  end if;
  if jsonb_array_length(p_entries) <> v_expected_count then
    raise exception 'Tous les joueurs convoqués doivent apparaître exactement une fois.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    group by e ->> 'participant_id'
    having count(*) > 1
  ) then
    raise exception 'Un joueur apparaît plusieurs fois dans la composition.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where not exists (
      select 1
      from public.match_sport_participants participant
      where participant.id = (e ->> 'participant_id')::uuid
        and participant.match_id = p_match_id
        and participant.convocation_status = 'convoked'
    )
  ) then
    raise exception 'La composition contient un joueur non convoqué.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where coalesce(btrim(e ->> 'team_no'), '') not in ('1', '2')
  ) then
    raise exception 'Chaque joueur doit être affecté à une équipe.'
      using errcode = '22023';
  end if;

  select
    count(*) filter (where (e ->> 'team_no')::integer = 1)::integer,
    count(*) filter (where (e ->> 'team_no')::integer = 2)::integer,
    count(*) filter (
      where (e ->> 'team_no')::integer = 1
        and nullif(btrim(e ->> 'slot_label'), '') is not null
    )::integer,
    count(*) filter (
      where (e ->> 'team_no')::integer = 2
        and nullif(btrim(e ->> 'slot_label'), '') is not null
    )::integer
  into v_team1_count, v_team2_count, v_team1_starters, v_team2_starters
  from jsonb_array_elements(p_entries) e;

  if v_team1_count = 0 or v_team2_count = 0 then
    raise exception 'Les deux équipes doivent contenir au moins un joueur.'
      using errcode = '22023';
  end if;
  if v_team1_starters <> least(v_team1_count, 11)
      or v_team2_starters <> least(v_team2_count, 11) then
    raise exception 'Chaque équipe doit avoir jusqu’à 11 titulaires ; le surplus reste sur le banc.'
      using errcode = '22023';
  end if;
  if not private.internal_formation_is_allowed(
      v_team1_formation, least(v_team1_count, 11)
    ) or not private.internal_formation_is_allowed(
      v_team2_formation, least(v_team2_count, 11)
    ) then
    raise exception 'Formation invalide pour le nombre de titulaires.'
      using errcode = '22023';
  end if;

  v_team1_slots := private.internal_formation_slots(v_team1_formation);
  v_team2_slots := private.internal_formation_slots(v_team2_formation);

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where (e ->> 'team_no')::integer = 1
      and nullif(btrim(e ->> 'slot_label'), '') is not null
      and not (btrim(e ->> 'slot_label') = any(v_team1_slots))
  ) or exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where (e ->> 'team_no')::integer = 2
      and nullif(btrim(e ->> 'slot_label'), '') is not null
      and not (btrim(e ->> 'slot_label') = any(v_team2_slots))
  ) then
    raise exception 'Un poste ne correspond pas à la formation choisie.'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where nullif(btrim(e ->> 'slot_label'), '') is not null
    group by (e ->> 'team_no'), btrim(e ->> 'slot_label')
    having count(*) > 1
  ) then
    raise exception 'Deux joueurs ne peuvent pas occuper le même poste dans une équipe.'
      using errcode = '22023';
  end if;

  insert into public.match_internal_compositions (
    match_id,
    team1_name,
    team2_name,
    team1_jersey,
    team2_jersey,
    team1_formation,
    team2_formation,
    updated_by
  ) values (
    p_match_id,
    v_team1_name,
    v_team2_name,
    v_team1_jersey,
    v_team2_jersey,
    v_team1_formation,
    v_team2_formation,
    (select private.uid())
  )
  on conflict (match_id) do update
  set team1_name = excluded.team1_name,
      team2_name = excluded.team2_name,
      team1_jersey = excluded.team1_jersey,
      team2_jersey = excluded.team2_jersey,
      team1_formation = excluded.team1_formation,
      team2_formation = excluded.team2_formation,
      updated_by = excluded.updated_by,
      updated_at = now();

  delete from public.match_internal_composition_entries
  where match_id = p_match_id;

  for v_entry in
    select value
    from jsonb_array_elements(p_entries)
  loop
    insert into public.match_internal_composition_entries (
      match_id,
      participant_id,
      team_no,
      slot_label,
      sort_order
    ) values (
      p_match_id,
      (v_entry ->> 'participant_id')::uuid,
      (v_entry ->> 'team_no')::smallint,
      nullif(btrim(v_entry ->> 'slot_label'), ''),
      coalesce((v_entry ->> 'sort_order')::integer, 0)
    );
  end loop;

  perform private.notify_composition_published(p_match_id);
  return public.get_internal_composition(p_match_id);
end;
$function$

      or v_team2_jersey not in ('france', 'orange', 'blue') then
    raise exception 'Maillot invalide.' using errcode = '22023';
  end if;
  if v_team1_jersey = v_team2_jersey then
    raise exception 'Les deux équipes doivent avoir des maillots différents.'
      using errcode = '22023';
  end if;

  select
    m.match_type,
    m.status,
    coalesce(
      m.kickoff_at,
      ((m.match_date + m.match_time) at time zone 'Europe/Paris')
    )
  into v_match_type, v_status, v_kickoff_at
  from public.matches m
  where m.id = p_match_id
  for update;

  if v_match_type is null or v_match_type <> 'entre_nous' then
    raise exception 'Match entre nous introuvable' using errcode = 'P0002';
  end if;
  if v_status <> 'a_venir' then
    raise exception 'La composition d’un match terminé ou annulé est verrouillée.'
      using errcode = '22023';
  end if;
  if v_kickoff_at is null then
    raise exception 'Horaire du match introuvable : composition refusée.' using errcode = '22023';
  end if;
  if now() >= private.match_prediction_closes_at(v_kickoff_at) then
    raise exception 'La composition est figée depuis l’ouverture du Live.'
      using errcode = '22023';
  end if;

  select count(*)::integer
  into v_expected_count
  from public.match_sport_participants participant
  where participant.match_id = p_match_id
    and participant.convocation_status = 'convoked';

  if v_expected_count = 0 then
    raise exception 'Aucun joueur convoqué.' using errcode = '22023';
  end if;
  if jsonb_array_length(p_entries) <> v_expected_count then
    raise exception 'Tous les joueurs convoqués doivent apparaître exactement une fois.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    group by e ->> 'participant_id'
    having count(*) > 1
  ) then
    raise exception 'Un joueur apparaît plusieurs fois dans la composition.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where not exists (
      select 1
      from public.match_sport_participants participant
      where participant.id = (e ->> 'participant_id')::uuid
        and participant.match_id = p_match_id
        and participant.convocation_status = 'convoked'
    )
  ) then
    raise exception 'La composition contient un joueur non convoqué.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where coalesce(btrim(e ->> 'team_no'), '') not in ('1', '2')
  ) then
    raise exception 'Chaque joueur doit être affecté à une équipe.'
      using errcode = '22023';
  end if;

  select
    count(*) filter (where (e ->> 'team_no')::integer = 1)::integer,
    count(*) filter (where (e ->> 'team_no')::integer = 2)::integer,
    count(*) filter (
      where (e ->> 'team_no')::integer = 1
        and nullif(btrim(e ->> 'slot_label'), '') is not null
    )::integer,
    count(*) filter (
      where (e ->> 'team_no')::integer = 2
        and nullif(btrim(e ->> 'slot_label'), '') is not null
    )::integer
  into v_team1_count, v_team2_count, v_team1_starters, v_team2_starters
  from jsonb_array_elements(p_entries) e;

  if v_team1_count = 0 or v_team2_count = 0 then
    raise exception 'Les deux équipes doivent contenir au moins un joueur.'
      using errcode = '22023';
  end if;
  if v_team1_starters <> least(v_team1_count, 11)
      or v_team2_starters <> least(v_team2_count, 11) then
    raise exception 'Chaque équipe doit avoir jusqu’à 11 titulaires ; le surplus reste sur le banc.'
      using errcode = '22023';
  end if;
  if not private.internal_formation_is_allowed(
      v_team1_formation, least(v_team1_count, 11)
    ) or not private.internal_formation_is_allowed(
      v_team2_formation, least(v_team2_count, 11)
    ) then
    raise exception 'Formation invalide pour le nombre de titulaires.'
      using errcode = '22023';
  end if;

  v_team1_slots := private.internal_formation_slots(v_team1_formation);
  v_team2_slots := private.internal_formation_slots(v_team2_formation);

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where (e ->> 'team_no')::integer = 1
      and nullif(btrim(e ->> 'slot_label'), '') is not null
      and not (btrim(e ->> 'slot_label') = any(v_team1_slots))
  ) or exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where (e ->> 'team_no')::integer = 2
      and nullif(btrim(e ->> 'slot_label'), '') is not null
      and not (btrim(e ->> 'slot_label') = any(v_team2_slots))
  ) then
    raise exception 'Un poste ne correspond pas à la formation choisie.'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where nullif(btrim(e ->> 'slot_label'), '') is not null
    group by (e ->> 'team_no'), btrim(e ->> 'slot_label')
    having count(*) > 1
  ) then
    raise exception 'Deux joueurs ne peuvent pas occuper le même poste dans une équipe.'
      using errcode = '22023';
  end if;

  insert into public.match_internal_compositions (
    match_id,
    team1_name,
    team2_name,
    team1_jersey,
    team2_jersey,
    team1_formation,
    team2_formation,
    updated_by
  ) values (
    p_match_id,
    v_team1_name,
    v_team2_name,
    v_team1_jersey,
    v_team2_jersey,
    v_team1_formation,
    v_team2_formation,
    (select private.uid())
  )
  on conflict (match_id) do update
  set team1_name = excluded.team1_name,
      team2_name = excluded.team2_name,
      team1_jersey = excluded.team1_jersey,
      team2_jersey = excluded.team2_jersey,
      team1_formation = excluded.team1_formation,
      team2_formation = excluded.team2_formation,
      updated_by = excluded.updated_by,
      updated_at = now();

  delete from public.match_internal_composition_entries
  where match_id = p_match_id;

  for v_entry in
    select value
    from jsonb_array_elements(p_entries)
  loop
    insert into public.match_internal_composition_entries (
      match_id,
      participant_id,
      team_no,
      slot_label,
      sort_order
    ) values (
      p_match_id,
      (v_entry ->> 'participant_id')::uuid,
      (v_entry ->> 'team_no')::smallint,
      nullif(btrim(v_entry ->> 'slot_label'), ''),
      coalesce((v_entry ->> 'sort_order')::integer, 0)
    );
  end loop;

  perform private.notify_composition_published(p_match_id);
  return public.get_internal_composition(p_match_id);
end;
$function$
 then
    raise exception 'Maillot invalide.' using errcode = '22023';
  end if;
  if v_team1_jersey = v_team2_jersey then
    raise exception 'Les deux équipes doivent avoir des maillots différents.'
      using errcode = '22023';
  end if;

  select
    m.match_type,
    m.status,
    coalesce(
      m.kickoff_at,
      ((m.match_date + m.match_time) at time zone 'Europe/Paris')
    )
  into v_match_type, v_status, v_kickoff_at
  from public.matches m
  where m.id = p_match_id
  for update;

  if v_match_type is null or v_match_type <> 'entre_nous' then
    raise exception 'Match entre nous introuvable' using errcode = 'P0002';
  end if;
  if v_status <> 'a_venir' then
    raise exception 'La composition d’un match terminé ou annulé est verrouillée.'
      using errcode = '22023';
  end if;
  if v_kickoff_at is null then
    raise exception 'Horaire du match introuvable : composition refusée.' using errcode = '22023';
  end if;
  if now() >= private.match_prediction_closes_at(v_kickoff_at) then
    raise exception 'La composition est figée depuis l’ouverture du Live.'
      using errcode = '22023';
  end if;

  select count(*)::integer
  into v_expected_count
  from public.match_sport_participants participant
  where participant.match_id = p_match_id
    and participant.convocation_status = 'convoked';

  if v_expected_count = 0 then
    raise exception 'Aucun joueur convoqué.' using errcode = '22023';
  end if;
  if jsonb_array_length(p_entries) <> v_expected_count then
    raise exception 'Tous les joueurs convoqués doivent apparaître exactement une fois.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    group by e ->> 'participant_id'
    having count(*) > 1
  ) then
    raise exception 'Un joueur apparaît plusieurs fois dans la composition.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where not exists (
      select 1
      from public.match_sport_participants participant
      where participant.id = (e ->> 'participant_id')::uuid
        and participant.match_id = p_match_id
        and participant.convocation_status = 'convoked'
    )
  ) then
    raise exception 'La composition contient un joueur non convoqué.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where coalesce(btrim(e ->> 'team_no'), '') not in ('1', '2')
  ) then
    raise exception 'Chaque joueur doit être affecté à une équipe.'
      using errcode = '22023';
  end if;

  select
    count(*) filter (where (e ->> 'team_no')::integer = 1)::integer,
    count(*) filter (where (e ->> 'team_no')::integer = 2)::integer,
    count(*) filter (
      where (e ->> 'team_no')::integer = 1
        and nullif(btrim(e ->> 'slot_label'), '') is not null
    )::integer,
    count(*) filter (
      where (e ->> 'team_no')::integer = 2
        and nullif(btrim(e ->> 'slot_label'), '') is not null
    )::integer
  into v_team1_count, v_team2_count, v_team1_starters, v_team2_starters
  from jsonb_array_elements(p_entries) e;

  if v_team1_count = 0 or v_team2_count = 0 then
    raise exception 'Les deux équipes doivent contenir au moins un joueur.'
      using errcode = '22023';
  end if;
  if v_team1_starters <> least(v_team1_count, 11)
      or v_team2_starters <> least(v_team2_count, 11) then
    raise exception 'Chaque équipe doit avoir jusqu’à 11 titulaires ; le surplus reste sur le banc.'
      using errcode = '22023';
  end if;
  if not private.internal_formation_is_allowed(
      v_team1_formation, least(v_team1_count, 11)
    ) or not private.internal_formation_is_allowed(
      v_team2_formation, least(v_team2_count, 11)
    ) then
    raise exception 'Formation invalide pour le nombre de titulaires.'
      using errcode = '22023';
  end if;

  v_team1_slots := private.internal_formation_slots(v_team1_formation);
  v_team2_slots := private.internal_formation_slots(v_team2_formation);

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where (e ->> 'team_no')::integer = 1
      and nullif(btrim(e ->> 'slot_label'), '') is not null
      and not (btrim(e ->> 'slot_label') = any(v_team1_slots))
  ) or exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where (e ->> 'team_no')::integer = 2
      and nullif(btrim(e ->> 'slot_label'), '') is not null
      and not (btrim(e ->> 'slot_label') = any(v_team2_slots))
  ) then
    raise exception 'Un poste ne correspond pas à la formation choisie.'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where nullif(btrim(e ->> 'slot_label'), '') is not null
    group by (e ->> 'team_no'), btrim(e ->> 'slot_label')
    having count(*) > 1
  ) then
    raise exception 'Deux joueurs ne peuvent pas occuper le même poste dans une équipe.'
      using errcode = '22023';
  end if;

  insert into public.match_internal_compositions (
    match_id,
    team1_name,
    team2_name,
    team1_jersey,
    team2_jersey,
    team1_formation,
    team2_formation,
    updated_by
  ) values (
    p_match_id,
    v_team1_name,
    v_team2_name,
    v_team1_jersey,
    v_team2_jersey,
    v_team1_formation,
    v_team2_formation,
    (select private.uid())
  )
  on conflict (match_id) do update
  set team1_name = excluded.team1_name,
      team2_name = excluded.team2_name,
      team1_jersey = excluded.team1_jersey,
      team2_jersey = excluded.team2_jersey,
      team1_formation = excluded.team1_formation,
      team2_formation = excluded.team2_formation,
      updated_by = excluded.updated_by,
      updated_at = now();

  delete from public.match_internal_composition_entries
  where match_id = p_match_id;

  for v_entry in
    select value
    from jsonb_array_elements(p_entries)
  loop
    insert into public.match_internal_composition_entries (
      match_id,
      participant_id,
      team_no,
      slot_label,
      sort_order
    ) values (
      p_match_id,
      (v_entry ->> 'participant_id')::uuid,
      (v_entry ->> 'team_no')::smallint,
      nullif(btrim(v_entry ->> 'slot_label'), ''),
      coalesce((v_entry ->> 'sort_order')::integer, 0)
    );
  end loop;

  perform private.notify_composition_published(p_match_id);
  return public.get_internal_composition(p_match_id);
end;
$function$

      or v_team2_jersey !~ '^(france|orange|blue|kit_[a-z0-9_]{1,48}) then
    raise exception 'Maillot invalide.' using errcode = '22023';
  end if;
  if v_team1_jersey = v_team2_jersey then
    raise exception 'Les deux équipes doivent avoir des maillots différents.'
      using errcode = '22023';
  end if;

  select
    m.match_type,
    m.status,
    coalesce(
      m.kickoff_at,
      ((m.match_date + m.match_time) at time zone 'Europe/Paris')
    )
  into v_match_type, v_status, v_kickoff_at
  from public.matches m
  where m.id = p_match_id
  for update;

  if v_match_type is null or v_match_type <> 'entre_nous' then
    raise exception 'Match entre nous introuvable' using errcode = 'P0002';
  end if;
  if v_status <> 'a_venir' then
    raise exception 'La composition d’un match terminé ou annulé est verrouillée.'
      using errcode = '22023';
  end if;
  if v_kickoff_at is null then
    raise exception 'Horaire du match introuvable : composition refusée.' using errcode = '22023';
  end if;
  if now() >= private.match_prediction_closes_at(v_kickoff_at) then
    raise exception 'La composition est figée depuis l’ouverture du Live.'
      using errcode = '22023';
  end if;

  select count(*)::integer
  into v_expected_count
  from public.match_sport_participants participant
  where participant.match_id = p_match_id
    and participant.convocation_status = 'convoked';

  if v_expected_count = 0 then
    raise exception 'Aucun joueur convoqué.' using errcode = '22023';
  end if;
  if jsonb_array_length(p_entries) <> v_expected_count then
    raise exception 'Tous les joueurs convoqués doivent apparaître exactement une fois.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    group by e ->> 'participant_id'
    having count(*) > 1
  ) then
    raise exception 'Un joueur apparaît plusieurs fois dans la composition.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where not exists (
      select 1
      from public.match_sport_participants participant
      where participant.id = (e ->> 'participant_id')::uuid
        and participant.match_id = p_match_id
        and participant.convocation_status = 'convoked'
    )
  ) then
    raise exception 'La composition contient un joueur non convoqué.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where coalesce(btrim(e ->> 'team_no'), '') not in ('1', '2')
  ) then
    raise exception 'Chaque joueur doit être affecté à une équipe.'
      using errcode = '22023';
  end if;

  select
    count(*) filter (where (e ->> 'team_no')::integer = 1)::integer,
    count(*) filter (where (e ->> 'team_no')::integer = 2)::integer,
    count(*) filter (
      where (e ->> 'team_no')::integer = 1
        and nullif(btrim(e ->> 'slot_label'), '') is not null
    )::integer,
    count(*) filter (
      where (e ->> 'team_no')::integer = 2
        and nullif(btrim(e ->> 'slot_label'), '') is not null
    )::integer
  into v_team1_count, v_team2_count, v_team1_starters, v_team2_starters
  from jsonb_array_elements(p_entries) e;

  if v_team1_count = 0 or v_team2_count = 0 then
    raise exception 'Les deux équipes doivent contenir au moins un joueur.'
      using errcode = '22023';
  end if;
  if v_team1_starters <> least(v_team1_count, 11)
      or v_team2_starters <> least(v_team2_count, 11) then
    raise exception 'Chaque équipe doit avoir jusqu’à 11 titulaires ; le surplus reste sur le banc.'
      using errcode = '22023';
  end if;
  if not private.internal_formation_is_allowed(
      v_team1_formation, least(v_team1_count, 11)
    ) or not private.internal_formation_is_allowed(
      v_team2_formation, least(v_team2_count, 11)
    ) then
    raise exception 'Formation invalide pour le nombre de titulaires.'
      using errcode = '22023';
  end if;

  v_team1_slots := private.internal_formation_slots(v_team1_formation);
  v_team2_slots := private.internal_formation_slots(v_team2_formation);

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where (e ->> 'team_no')::integer = 1
      and nullif(btrim(e ->> 'slot_label'), '') is not null
      and not (btrim(e ->> 'slot_label') = any(v_team1_slots))
  ) or exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where (e ->> 'team_no')::integer = 2
      and nullif(btrim(e ->> 'slot_label'), '') is not null
      and not (btrim(e ->> 'slot_label') = any(v_team2_slots))
  ) then
    raise exception 'Un poste ne correspond pas à la formation choisie.'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where nullif(btrim(e ->> 'slot_label'), '') is not null
    group by (e ->> 'team_no'), btrim(e ->> 'slot_label')
    having count(*) > 1
  ) then
    raise exception 'Deux joueurs ne peuvent pas occuper le même poste dans une équipe.'
      using errcode = '22023';
  end if;

  insert into public.match_internal_compositions (
    match_id,
    team1_name,
    team2_name,
    team1_jersey,
    team2_jersey,
    team1_formation,
    team2_formation,
    updated_by
  ) values (
    p_match_id,
    v_team1_name,
    v_team2_name,
    v_team1_jersey,
    v_team2_jersey,
    v_team1_formation,
    v_team2_formation,
    (select private.uid())
  )
  on conflict (match_id) do update
  set team1_name = excluded.team1_name,
      team2_name = excluded.team2_name,
      team1_jersey = excluded.team1_jersey,
      team2_jersey = excluded.team2_jersey,
      team1_formation = excluded.team1_formation,
      team2_formation = excluded.team2_formation,
      updated_by = excluded.updated_by,
      updated_at = now();

  delete from public.match_internal_composition_entries
  where match_id = p_match_id;

  for v_entry in
    select value
    from jsonb_array_elements(p_entries)
  loop
    insert into public.match_internal_composition_entries (
      match_id,
      participant_id,
      team_no,
      slot_label,
      sort_order
    ) values (
      p_match_id,
      (v_entry ->> 'participant_id')::uuid,
      (v_entry ->> 'team_no')::smallint,
      nullif(btrim(v_entry ->> 'slot_label'), ''),
      coalesce((v_entry ->> 'sort_order')::integer, 0)
    );
  end loop;

  perform private.notify_composition_published(p_match_id);
  return public.get_internal_composition(p_match_id);
end;
$function$
 then
    raise exception 'Maillot invalide.' using errcode = '22023';
  end if;
  if v_team1_jersey = v_team2_jersey then
    raise exception 'Les deux équipes doivent avoir des maillots différents.'
      using errcode = '22023';
  end if;

  select
    m.match_type,
    m.status,
    coalesce(
      m.kickoff_at,
      ((m.match_date + m.match_time) at time zone 'Europe/Paris')
    )
  into v_match_type, v_status, v_kickoff_at
  from public.matches m
  where m.id = p_match_id
  for update;

  if v_match_type is null or v_match_type <> 'entre_nous' then
    raise exception 'Match entre nous introuvable' using errcode = 'P0002';
  end if;
  if v_status <> 'a_venir' then
    raise exception 'La composition d’un match terminé ou annulé est verrouillée.'
      using errcode = '22023';
  end if;
  if v_kickoff_at is null then
    raise exception 'Horaire du match introuvable : composition refusée.' using errcode = '22023';
  end if;
  if now() >= private.match_prediction_closes_at(v_kickoff_at) then
    raise exception 'La composition est figée depuis l’ouverture du Live.'
      using errcode = '22023';
  end if;

  select count(*)::integer
  into v_expected_count
  from public.match_sport_participants participant
  where participant.match_id = p_match_id
    and participant.convocation_status = 'convoked';

  if v_expected_count = 0 then
    raise exception 'Aucun joueur convoqué.' using errcode = '22023';
  end if;
  if jsonb_array_length(p_entries) <> v_expected_count then
    raise exception 'Tous les joueurs convoqués doivent apparaître exactement une fois.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    group by e ->> 'participant_id'
    having count(*) > 1
  ) then
    raise exception 'Un joueur apparaît plusieurs fois dans la composition.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where not exists (
      select 1
      from public.match_sport_participants participant
      where participant.id = (e ->> 'participant_id')::uuid
        and participant.match_id = p_match_id
        and participant.convocation_status = 'convoked'
    )
  ) then
    raise exception 'La composition contient un joueur non convoqué.'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where coalesce(btrim(e ->> 'team_no'), '') not in ('1', '2')
  ) then
    raise exception 'Chaque joueur doit être affecté à une équipe.'
      using errcode = '22023';
  end if;

  select
    count(*) filter (where (e ->> 'team_no')::integer = 1)::integer,
    count(*) filter (where (e ->> 'team_no')::integer = 2)::integer,
    count(*) filter (
      where (e ->> 'team_no')::integer = 1
        and nullif(btrim(e ->> 'slot_label'), '') is not null
    )::integer,
    count(*) filter (
      where (e ->> 'team_no')::integer = 2
        and nullif(btrim(e ->> 'slot_label'), '') is not null
    )::integer
  into v_team1_count, v_team2_count, v_team1_starters, v_team2_starters
  from jsonb_array_elements(p_entries) e;

  if v_team1_count = 0 or v_team2_count = 0 then
    raise exception 'Les deux équipes doivent contenir au moins un joueur.'
      using errcode = '22023';
  end if;
  if v_team1_starters <> least(v_team1_count, 11)
      or v_team2_starters <> least(v_team2_count, 11) then
    raise exception 'Chaque équipe doit avoir jusqu’à 11 titulaires ; le surplus reste sur le banc.'
      using errcode = '22023';
  end if;
  if not private.internal_formation_is_allowed(
      v_team1_formation, least(v_team1_count, 11)
    ) or not private.internal_formation_is_allowed(
      v_team2_formation, least(v_team2_count, 11)
    ) then
    raise exception 'Formation invalide pour le nombre de titulaires.'
      using errcode = '22023';
  end if;

  v_team1_slots := private.internal_formation_slots(v_team1_formation);
  v_team2_slots := private.internal_formation_slots(v_team2_formation);

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where (e ->> 'team_no')::integer = 1
      and nullif(btrim(e ->> 'slot_label'), '') is not null
      and not (btrim(e ->> 'slot_label') = any(v_team1_slots))
  ) or exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where (e ->> 'team_no')::integer = 2
      and nullif(btrim(e ->> 'slot_label'), '') is not null
      and not (btrim(e ->> 'slot_label') = any(v_team2_slots))
  ) then
    raise exception 'Un poste ne correspond pas à la formation choisie.'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where nullif(btrim(e ->> 'slot_label'), '') is not null
    group by (e ->> 'team_no'), btrim(e ->> 'slot_label')
    having count(*) > 1
  ) then
    raise exception 'Deux joueurs ne peuvent pas occuper le même poste dans une équipe.'
      using errcode = '22023';
  end if;

  insert into public.match_internal_compositions (
    match_id,
    team1_name,
    team2_name,
    team1_jersey,
    team2_jersey,
    team1_formation,
    team2_formation,
    updated_by
  ) values (
    p_match_id,
    v_team1_name,
    v_team2_name,
    v_team1_jersey,
    v_team2_jersey,
    v_team1_formation,
    v_team2_formation,
    (select private.uid())
  )
  on conflict (match_id) do update
  set team1_name = excluded.team1_name,
      team2_name = excluded.team2_name,
      team1_jersey = excluded.team1_jersey,
      team2_jersey = excluded.team2_jersey,
      team1_formation = excluded.team1_formation,
      team2_formation = excluded.team2_formation,
      updated_by = excluded.updated_by,
      updated_at = now();

  delete from public.match_internal_composition_entries
  where match_id = p_match_id;

  for v_entry in
    select value
    from jsonb_array_elements(p_entries)
  loop
    insert into public.match_internal_composition_entries (
      match_id,
      participant_id,
      team_no,
      slot_label,
      sort_order
    ) values (
      p_match_id,
      (v_entry ->> 'participant_id')::uuid,
      (v_entry ->> 'team_no')::smallint,
      nullif(btrim(v_entry ->> 'slot_label'), ''),
      coalesce((v_entry ->> 'sort_order')::integer, 0)
    );
  end loop;

  perform private.notify_composition_published(p_match_id);
  return public.get_internal_composition(p_match_id);
end;
$function$


CREATE OR REPLACE FUNCTION public.admin_save_internal_composition_v4(p_match_id uuid, p_team1_name text, p_team2_name text, p_team1_jersey text, p_team2_jersey text, p_team1_formation text, p_team2_formation text, p_entries jsonb, p_require_visual_complete boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_match_type text;
  v_status text;
  v_kickoff_at timestamptz;
  v_team1_name text := coalesce(nullif(btrim(p_team1_name), ''), 'Équipe 1');
  v_team2_name text := coalesce(nullif(btrim(p_team2_name), ''), 'Équipe 2');
  v_team1_jersey text := lower(btrim(coalesce(p_team1_jersey, '')));
  v_team2_jersey text := lower(btrim(coalesce(p_team2_jersey, '')));
  v_expected_count integer;
  v_team1_count integer;
  v_team2_count integer;
  v_team1_field integer;
  v_team2_field integer;
  v_team1_bench integer;
  v_team2_bench integer;
  v_entry jsonb;
begin
  if not public.is_match_staff() then
    raise exception 'Active administrator role required' using errcode = '42501';
  end if;
  if jsonb_typeof(coalesce(p_entries, 'null'::jsonb)) <> 'array' then
    raise exception 'La composition doit être une liste.' using errcode = '22023';
  end if;
  if char_length(v_team1_name) > 40 or char_length(v_team2_name) > 40 then
    raise exception 'Nom d''équipe trop long (40 caractères max).' using errcode = '22023';
  end if;
  if v_team1_jersey !~ '^(france|orange|blue|kit_[a-z0-9_]{1,48})
      or v_team2_jersey !~ '^(france|orange|blue|kit_[a-z0-9_]{1,48})
      or v_team1_jersey = v_team2_jersey then
    raise exception 'Maillots invalides ou identiques.' using errcode = '22023';
  end if;

  if exists (
    select 1 from (values (v_team1_jersey), (v_team2_jersey)) as jersey(id)
    where jersey.id like 'kit_%'
      and not exists (
        select 1 from public.matches m
        join public.clubs c on c.id = m.club_id
        cross join lateral jsonb_array_elements(coalesce(c.kits, '[]'::jsonb))
          as entry(value)
        where m.id = p_match_id and entry.value ->> 'slot' = jersey.id
          and coalesce((entry.value ->> 'archived')::boolean, false) = false
      )
  ) then
    raise exception 'Maillot du club introuvable ou archivé.'
      using errcode = '22023';
  end if;

  select m.match_type, m.status,
    coalesce(m.kickoff_at, ((m.match_date + m.match_time) at time zone 'Europe/Paris'))
  into v_match_type, v_status, v_kickoff_at
  from public.matches m
  where m.id = p_match_id
  for update;

  if v_match_type is null or v_match_type <> 'entre_nous' then
    raise exception 'Match entre nous introuvable' using errcode = 'P0002';
  end if;
  if v_status <> 'a_venir' then
    raise exception 'La composition d’un match terminé ou annulé est verrouillée.'
      using errcode = '22023';
  end if;
  if v_kickoff_at is null
      or now() >= private.match_prediction_closes_at(v_kickoff_at) then
    raise exception 'La composition est figée depuis l’ouverture du Live.'
      using errcode = '22023';
  end if;

  select count(*)::integer into v_expected_count
  from public.match_sport_participants participant
  where participant.match_id = p_match_id
    and participant.convocation_status = 'convoked';

  if jsonb_array_length(p_entries) <> v_expected_count then
    raise exception 'Tous les joueurs convoqués doivent apparaître exactement une fois.'
      using errcode = '22023';
  end if;

  if exists (
    select 1 from jsonb_array_elements(p_entries) e
    group by e ->> 'participant_id'
    having count(*) > 1
  ) then
    raise exception 'Un joueur apparaît plusieurs fois dans la composition.'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where not exists (
      select 1
      from public.match_sport_participants participant
      where participant.id = (e ->> 'participant_id')::uuid
        and participant.match_id = p_match_id
        and participant.convocation_status = 'convoked'
    )
  ) then
    raise exception 'La composition contient un joueur non convoqué.'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where nullif(btrim(e ->> 'team_no'), '') is not null
      and btrim(e ->> 'team_no') not in ('1', '2')
  ) then
    raise exception 'Équipe invalide.' using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where coalesce(e ->> 'zone', 'available') in ('field', 'bench')
      and coalesce(btrim(e ->> 'team_no'), '') not in ('1', '2')
  ) then
    raise exception 'Un joueur placé doit appartenir à une équipe.'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where coalesce(e ->> 'zone', 'available') not in ('available', 'field', 'bench')
       or (
         coalesce(e ->> 'zone', 'available') = 'field'
         and (
           nullif(btrim(e ->> 'slot_label'), '') is null
           or (e ->> 'x') is null
           or (e ->> 'y') is null
           or (e ->> 'x')::numeric not between 0 and 1
           or (e ->> 'y')::numeric not between 0 and 1
         )
       )
  ) then
    raise exception 'Placement terrain invalide.' using errcode = '22023';
  end if;

  if p_require_visual_complete then
    if exists (
      select 1 from jsonb_array_elements(p_entries) e
      where coalesce(btrim(e ->> 'team_no'), '') not in ('1', '2')
    ) then
      raise exception 'Chaque joueur doit être affecté à une équipe.'
        using errcode = '22023';
    end if;

    select
      count(*) filter (where (e ->> 'team_no') = '1')::integer,
      count(*) filter (where (e ->> 'team_no') = '2')::integer,
      count(*) filter (where (e ->> 'team_no') = '1' and e ->> 'zone' = 'field')::integer,
      count(*) filter (where (e ->> 'team_no') = '2' and e ->> 'zone' = 'field')::integer,
      count(*) filter (where (e ->> 'team_no') = '1' and e ->> 'zone' = 'bench')::integer,
      count(*) filter (where (e ->> 'team_no') = '2' and e ->> 'zone' = 'bench')::integer
    into v_team1_count, v_team2_count, v_team1_field, v_team2_field,
         v_team1_bench, v_team2_bench
    from jsonb_array_elements(p_entries) e;

    if v_team1_count = 0 or v_team2_count = 0 then
      raise exception 'Les deux équipes doivent contenir au moins un joueur.'
        using errcode = '22023';
    end if;
    if nullif(btrim(p_team1_formation), '') is null
        or nullif(btrim(p_team2_formation), '') is null then
      raise exception 'Choisis le dispositif de chaque équipe.' using errcode = '22023';
    end if;
    if v_team1_field <> least(v_team1_count, 11)
        or v_team2_field <> least(v_team2_count, 11)
        or v_team1_bench <> greatest(v_team1_count - 11, 0)
        or v_team2_bench <> greatest(v_team2_count - 11, 0) then
      raise exception 'Terrain ou banc incomplet.' using errcode = '22023';
    end if;

    if cardinality(private.internal_v4_formation_slots(p_team1_formation))
          <> least(v_team1_count, 11)
        or cardinality(private.internal_v4_formation_slots(p_team2_formation))
          <> least(v_team2_count, 11) then
      raise exception 'Dispositif invalide pour le nombre de titulaires.'
        using errcode = '22023';
    end if;

    if exists (
      select 1 from jsonb_array_elements(p_entries) e
      where e ->> 'zone' = 'field'
        and (
          (e ->> 'team_no' = '1'
            and not (e ->> 'slot_label' = any(private.internal_v4_formation_slots(p_team1_formation))))
          or
          (e ->> 'team_no' = '2'
            and not (e ->> 'slot_label' = any(private.internal_v4_formation_slots(p_team2_formation))))
        )
    ) then
      raise exception 'Un poste ne correspond pas au dispositif choisi.'
        using errcode = '22023';
    end if;

    if exists (
      select 1 from jsonb_array_elements(p_entries) e
      where e ->> 'zone' = 'field'
      group by e ->> 'team_no', e ->> 'slot_label'
      having count(*) > 1
    ) then
      raise exception 'Deux joueurs ne peuvent pas occuper le même poste.'
        using errcode = '22023';
    end if;
  end if;

  insert into public.match_internal_compositions (
    match_id, team1_name, team2_name, team1_jersey, team2_jersey,
    team1_formation, team2_formation, updated_by
  ) values (
    p_match_id, v_team1_name, v_team2_name, v_team1_jersey, v_team2_jersey,
    nullif(btrim(p_team1_formation), ''), nullif(btrim(p_team2_formation), ''),
    (select private.uid())
  )
  on conflict (match_id) do update
  set team1_name = excluded.team1_name,
      team2_name = excluded.team2_name,
      team1_jersey = excluded.team1_jersey,
      team2_jersey = excluded.team2_jersey,
      team1_formation = excluded.team1_formation,
      team2_formation = excluded.team2_formation,
      updated_by = excluded.updated_by,
      updated_at = now();

  delete from public.match_internal_composition_entries
  where match_id = p_match_id;

  for v_entry in select value from jsonb_array_elements(p_entries)
  loop
    insert into public.match_internal_composition_entries (
      match_id, participant_id, team_no, zone, x, y, slot_label, sort_order
    ) values (
      p_match_id,
      (v_entry ->> 'participant_id')::uuid,
      nullif(btrim(v_entry ->> 'team_no'), '')::smallint,
      coalesce(v_entry ->> 'zone', 'available'),
      case when v_entry ->> 'zone' = 'field' then (v_entry ->> 'x')::numeric else null end,
      case when v_entry ->> 'zone' = 'field' then (v_entry ->> 'y')::numeric else null end,
      case when v_entry ->> 'zone' = 'field'
        then nullif(btrim(v_entry ->> 'slot_label'), '') else null end,
      coalesce((v_entry ->> 'sort_order')::integer, 0)
    );
  end loop;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where coalesce(btrim(e ->> 'team_no'), '') in ('1', '2')
  ) then
    perform private.notify_composition_published(p_match_id);
  end if;

  return public.get_internal_composition(p_match_id);
end;
$function$

      or v_team2_jersey not in ('france', 'orange', 'blue')
      or v_team1_jersey = v_team2_jersey then
    raise exception 'Maillots invalides ou identiques.' using errcode = '22023';
  end if;

  select m.match_type, m.status,
    coalesce(m.kickoff_at, ((m.match_date + m.match_time) at time zone 'Europe/Paris'))
  into v_match_type, v_status, v_kickoff_at
  from public.matches m
  where m.id = p_match_id
  for update;

  if v_match_type is null or v_match_type <> 'entre_nous' then
    raise exception 'Match entre nous introuvable' using errcode = 'P0002';
  end if;
  if v_status <> 'a_venir' then
    raise exception 'La composition d’un match terminé ou annulé est verrouillée.'
      using errcode = '22023';
  end if;
  if v_kickoff_at is null
      or now() >= private.match_prediction_closes_at(v_kickoff_at) then
    raise exception 'La composition est figée depuis l’ouverture du Live.'
      using errcode = '22023';
  end if;

  select count(*)::integer into v_expected_count
  from public.match_sport_participants participant
  where participant.match_id = p_match_id
    and participant.convocation_status = 'convoked';

  if jsonb_array_length(p_entries) <> v_expected_count then
    raise exception 'Tous les joueurs convoqués doivent apparaître exactement une fois.'
      using errcode = '22023';
  end if;

  if exists (
    select 1 from jsonb_array_elements(p_entries) e
    group by e ->> 'participant_id'
    having count(*) > 1
  ) then
    raise exception 'Un joueur apparaît plusieurs fois dans la composition.'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where not exists (
      select 1
      from public.match_sport_participants participant
      where participant.id = (e ->> 'participant_id')::uuid
        and participant.match_id = p_match_id
        and participant.convocation_status = 'convoked'
    )
  ) then
    raise exception 'La composition contient un joueur non convoqué.'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where nullif(btrim(e ->> 'team_no'), '') is not null
      and btrim(e ->> 'team_no') not in ('1', '2')
  ) then
    raise exception 'Équipe invalide.' using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where coalesce(e ->> 'zone', 'available') in ('field', 'bench')
      and coalesce(btrim(e ->> 'team_no'), '') not in ('1', '2')
  ) then
    raise exception 'Un joueur placé doit appartenir à une équipe.'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where coalesce(e ->> 'zone', 'available') not in ('available', 'field', 'bench')
       or (
         coalesce(e ->> 'zone', 'available') = 'field'
         and (
           nullif(btrim(e ->> 'slot_label'), '') is null
           or (e ->> 'x') is null
           or (e ->> 'y') is null
           or (e ->> 'x')::numeric not between 0 and 1
           or (e ->> 'y')::numeric not between 0 and 1
         )
       )
  ) then
    raise exception 'Placement terrain invalide.' using errcode = '22023';
  end if;

  if p_require_visual_complete then
    if exists (
      select 1 from jsonb_array_elements(p_entries) e
      where coalesce(btrim(e ->> 'team_no'), '') not in ('1', '2')
    ) then
      raise exception 'Chaque joueur doit être affecté à une équipe.'
        using errcode = '22023';
    end if;

    select
      count(*) filter (where (e ->> 'team_no') = '1')::integer,
      count(*) filter (where (e ->> 'team_no') = '2')::integer,
      count(*) filter (where (e ->> 'team_no') = '1' and e ->> 'zone' = 'field')::integer,
      count(*) filter (where (e ->> 'team_no') = '2' and e ->> 'zone' = 'field')::integer,
      count(*) filter (where (e ->> 'team_no') = '1' and e ->> 'zone' = 'bench')::integer,
      count(*) filter (where (e ->> 'team_no') = '2' and e ->> 'zone' = 'bench')::integer
    into v_team1_count, v_team2_count, v_team1_field, v_team2_field,
         v_team1_bench, v_team2_bench
    from jsonb_array_elements(p_entries) e;

    if v_team1_count = 0 or v_team2_count = 0 then
      raise exception 'Les deux équipes doivent contenir au moins un joueur.'
        using errcode = '22023';
    end if;
    if nullif(btrim(p_team1_formation), '') is null
        or nullif(btrim(p_team2_formation), '') is null then
      raise exception 'Choisis le dispositif de chaque équipe.' using errcode = '22023';
    end if;
    if v_team1_field <> least(v_team1_count, 11)
        or v_team2_field <> least(v_team2_count, 11)
        or v_team1_bench <> greatest(v_team1_count - 11, 0)
        or v_team2_bench <> greatest(v_team2_count - 11, 0) then
      raise exception 'Terrain ou banc incomplet.' using errcode = '22023';
    end if;

    if cardinality(private.internal_v4_formation_slots(p_team1_formation))
          <> least(v_team1_count, 11)
        or cardinality(private.internal_v4_formation_slots(p_team2_formation))
          <> least(v_team2_count, 11) then
      raise exception 'Dispositif invalide pour le nombre de titulaires.'
        using errcode = '22023';
    end if;

    if exists (
      select 1 from jsonb_array_elements(p_entries) e
      where e ->> 'zone' = 'field'
        and (
          (e ->> 'team_no' = '1'
            and not (e ->> 'slot_label' = any(private.internal_v4_formation_slots(p_team1_formation))))
          or
          (e ->> 'team_no' = '2'
            and not (e ->> 'slot_label' = any(private.internal_v4_formation_slots(p_team2_formation))))
        )
    ) then
      raise exception 'Un poste ne correspond pas au dispositif choisi.'
        using errcode = '22023';
    end if;

    if exists (
      select 1 from jsonb_array_elements(p_entries) e
      where e ->> 'zone' = 'field'
      group by e ->> 'team_no', e ->> 'slot_label'
      having count(*) > 1
    ) then
      raise exception 'Deux joueurs ne peuvent pas occuper le même poste.'
        using errcode = '22023';
    end if;
  end if;

  insert into public.match_internal_compositions (
    match_id, team1_name, team2_name, team1_jersey, team2_jersey,
    team1_formation, team2_formation, updated_by
  ) values (
    p_match_id, v_team1_name, v_team2_name, v_team1_jersey, v_team2_jersey,
    nullif(btrim(p_team1_formation), ''), nullif(btrim(p_team2_formation), ''),
    (select private.uid())
  )
  on conflict (match_id) do update
  set team1_name = excluded.team1_name,
      team2_name = excluded.team2_name,
      team1_jersey = excluded.team1_jersey,
      team2_jersey = excluded.team2_jersey,
      team1_formation = excluded.team1_formation,
      team2_formation = excluded.team2_formation,
      updated_by = excluded.updated_by,
      updated_at = now();

  delete from public.match_internal_composition_entries
  where match_id = p_match_id;

  for v_entry in select value from jsonb_array_elements(p_entries)
  loop
    insert into public.match_internal_composition_entries (
      match_id, participant_id, team_no, zone, x, y, slot_label, sort_order
    ) values (
      p_match_id,
      (v_entry ->> 'participant_id')::uuid,
      nullif(btrim(v_entry ->> 'team_no'), '')::smallint,
      coalesce(v_entry ->> 'zone', 'available'),
      case when v_entry ->> 'zone' = 'field' then (v_entry ->> 'x')::numeric else null end,
      case when v_entry ->> 'zone' = 'field' then (v_entry ->> 'y')::numeric else null end,
      case when v_entry ->> 'zone' = 'field'
        then nullif(btrim(v_entry ->> 'slot_label'), '') else null end,
      coalesce((v_entry ->> 'sort_order')::integer, 0)
    );
  end loop;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where coalesce(btrim(e ->> 'team_no'), '') in ('1', '2')
  ) then
    perform private.notify_composition_published(p_match_id);
  end if;

  return public.get_internal_composition(p_match_id);
end;
$function$

      or v_team1_jersey = v_team2_jersey then
    raise exception 'Maillots invalides ou identiques.' using errcode = '22023';
  end if;

  select m.match_type, m.status,
    coalesce(m.kickoff_at, ((m.match_date + m.match_time) at time zone 'Europe/Paris'))
  into v_match_type, v_status, v_kickoff_at
  from public.matches m
  where m.id = p_match_id
  for update;

  if v_match_type is null or v_match_type <> 'entre_nous' then
    raise exception 'Match entre nous introuvable' using errcode = 'P0002';
  end if;
  if v_status <> 'a_venir' then
    raise exception 'La composition d’un match terminé ou annulé est verrouillée.'
      using errcode = '22023';
  end if;
  if v_kickoff_at is null
      or now() >= private.match_prediction_closes_at(v_kickoff_at) then
    raise exception 'La composition est figée depuis l’ouverture du Live.'
      using errcode = '22023';
  end if;

  select count(*)::integer into v_expected_count
  from public.match_sport_participants participant
  where participant.match_id = p_match_id
    and participant.convocation_status = 'convoked';

  if jsonb_array_length(p_entries) <> v_expected_count then
    raise exception 'Tous les joueurs convoqués doivent apparaître exactement une fois.'
      using errcode = '22023';
  end if;

  if exists (
    select 1 from jsonb_array_elements(p_entries) e
    group by e ->> 'participant_id'
    having count(*) > 1
  ) then
    raise exception 'Un joueur apparaît plusieurs fois dans la composition.'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where not exists (
      select 1
      from public.match_sport_participants participant
      where participant.id = (e ->> 'participant_id')::uuid
        and participant.match_id = p_match_id
        and participant.convocation_status = 'convoked'
    )
  ) then
    raise exception 'La composition contient un joueur non convoqué.'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where nullif(btrim(e ->> 'team_no'), '') is not null
      and btrim(e ->> 'team_no') not in ('1', '2')
  ) then
    raise exception 'Équipe invalide.' using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where coalesce(e ->> 'zone', 'available') in ('field', 'bench')
      and coalesce(btrim(e ->> 'team_no'), '') not in ('1', '2')
  ) then
    raise exception 'Un joueur placé doit appartenir à une équipe.'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where coalesce(e ->> 'zone', 'available') not in ('available', 'field', 'bench')
       or (
         coalesce(e ->> 'zone', 'available') = 'field'
         and (
           nullif(btrim(e ->> 'slot_label'), '') is null
           or (e ->> 'x') is null
           or (e ->> 'y') is null
           or (e ->> 'x')::numeric not between 0 and 1
           or (e ->> 'y')::numeric not between 0 and 1
         )
       )
  ) then
    raise exception 'Placement terrain invalide.' using errcode = '22023';
  end if;

  if p_require_visual_complete then
    if exists (
      select 1 from jsonb_array_elements(p_entries) e
      where coalesce(btrim(e ->> 'team_no'), '') not in ('1', '2')
    ) then
      raise exception 'Chaque joueur doit être affecté à une équipe.'
        using errcode = '22023';
    end if;

    select
      count(*) filter (where (e ->> 'team_no') = '1')::integer,
      count(*) filter (where (e ->> 'team_no') = '2')::integer,
      count(*) filter (where (e ->> 'team_no') = '1' and e ->> 'zone' = 'field')::integer,
      count(*) filter (where (e ->> 'team_no') = '2' and e ->> 'zone' = 'field')::integer,
      count(*) filter (where (e ->> 'team_no') = '1' and e ->> 'zone' = 'bench')::integer,
      count(*) filter (where (e ->> 'team_no') = '2' and e ->> 'zone' = 'bench')::integer
    into v_team1_count, v_team2_count, v_team1_field, v_team2_field,
         v_team1_bench, v_team2_bench
    from jsonb_array_elements(p_entries) e;

    if v_team1_count = 0 or v_team2_count = 0 then
      raise exception 'Les deux équipes doivent contenir au moins un joueur.'
        using errcode = '22023';
    end if;
    if nullif(btrim(p_team1_formation), '') is null
        or nullif(btrim(p_team2_formation), '') is null then
      raise exception 'Choisis le dispositif de chaque équipe.' using errcode = '22023';
    end if;
    if v_team1_field <> least(v_team1_count, 11)
        or v_team2_field <> least(v_team2_count, 11)
        or v_team1_bench <> greatest(v_team1_count - 11, 0)
        or v_team2_bench <> greatest(v_team2_count - 11, 0) then
      raise exception 'Terrain ou banc incomplet.' using errcode = '22023';
    end if;

    if cardinality(private.internal_v4_formation_slots(p_team1_formation))
          <> least(v_team1_count, 11)
        or cardinality(private.internal_v4_formation_slots(p_team2_formation))
          <> least(v_team2_count, 11) then
      raise exception 'Dispositif invalide pour le nombre de titulaires.'
        using errcode = '22023';
    end if;

    if exists (
      select 1 from jsonb_array_elements(p_entries) e
      where e ->> 'zone' = 'field'
        and (
          (e ->> 'team_no' = '1'
            and not (e ->> 'slot_label' = any(private.internal_v4_formation_slots(p_team1_formation))))
          or
          (e ->> 'team_no' = '2'
            and not (e ->> 'slot_label' = any(private.internal_v4_formation_slots(p_team2_formation))))
        )
    ) then
      raise exception 'Un poste ne correspond pas au dispositif choisi.'
        using errcode = '22023';
    end if;

    if exists (
      select 1 from jsonb_array_elements(p_entries) e
      where e ->> 'zone' = 'field'
      group by e ->> 'team_no', e ->> 'slot_label'
      having count(*) > 1
    ) then
      raise exception 'Deux joueurs ne peuvent pas occuper le même poste.'
        using errcode = '22023';
    end if;
  end if;

  insert into public.match_internal_compositions (
    match_id, team1_name, team2_name, team1_jersey, team2_jersey,
    team1_formation, team2_formation, updated_by
  ) values (
    p_match_id, v_team1_name, v_team2_name, v_team1_jersey, v_team2_jersey,
    nullif(btrim(p_team1_formation), ''), nullif(btrim(p_team2_formation), ''),
    (select private.uid())
  )
  on conflict (match_id) do update
  set team1_name = excluded.team1_name,
      team2_name = excluded.team2_name,
      team1_jersey = excluded.team1_jersey,
      team2_jersey = excluded.team2_jersey,
      team1_formation = excluded.team1_formation,
      team2_formation = excluded.team2_formation,
      updated_by = excluded.updated_by,
      updated_at = now();

  delete from public.match_internal_composition_entries
  where match_id = p_match_id;

  for v_entry in select value from jsonb_array_elements(p_entries)
  loop
    insert into public.match_internal_composition_entries (
      match_id, participant_id, team_no, zone, x, y, slot_label, sort_order
    ) values (
      p_match_id,
      (v_entry ->> 'participant_id')::uuid,
      nullif(btrim(v_entry ->> 'team_no'), '')::smallint,
      coalesce(v_entry ->> 'zone', 'available'),
      case when v_entry ->> 'zone' = 'field' then (v_entry ->> 'x')::numeric else null end,
      case when v_entry ->> 'zone' = 'field' then (v_entry ->> 'y')::numeric else null end,
      case when v_entry ->> 'zone' = 'field'
        then nullif(btrim(v_entry ->> 'slot_label'), '') else null end,
      coalesce((v_entry ->> 'sort_order')::integer, 0)
    );
  end loop;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where coalesce(btrim(e ->> 'team_no'), '') in ('1', '2')
  ) then
    perform private.notify_composition_published(p_match_id);
  end if;

  return public.get_internal_composition(p_match_id);
end;
$function$

      or v_team2_jersey !~ '^(france|orange|blue|kit_[a-z0-9_]{1,48})
      or v_team1_jersey = v_team2_jersey then
    raise exception 'Maillots invalides ou identiques.' using errcode = '22023';
  end if;

  select m.match_type, m.status,
    coalesce(m.kickoff_at, ((m.match_date + m.match_time) at time zone 'Europe/Paris'))
  into v_match_type, v_status, v_kickoff_at
  from public.matches m
  where m.id = p_match_id
  for update;

  if v_match_type is null or v_match_type <> 'entre_nous' then
    raise exception 'Match entre nous introuvable' using errcode = 'P0002';
  end if;
  if v_status <> 'a_venir' then
    raise exception 'La composition d’un match terminé ou annulé est verrouillée.'
      using errcode = '22023';
  end if;
  if v_kickoff_at is null
      or now() >= private.match_prediction_closes_at(v_kickoff_at) then
    raise exception 'La composition est figée depuis l’ouverture du Live.'
      using errcode = '22023';
  end if;

  select count(*)::integer into v_expected_count
  from public.match_sport_participants participant
  where participant.match_id = p_match_id
    and participant.convocation_status = 'convoked';

  if jsonb_array_length(p_entries) <> v_expected_count then
    raise exception 'Tous les joueurs convoqués doivent apparaître exactement une fois.'
      using errcode = '22023';
  end if;

  if exists (
    select 1 from jsonb_array_elements(p_entries) e
    group by e ->> 'participant_id'
    having count(*) > 1
  ) then
    raise exception 'Un joueur apparaît plusieurs fois dans la composition.'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where not exists (
      select 1
      from public.match_sport_participants participant
      where participant.id = (e ->> 'participant_id')::uuid
        and participant.match_id = p_match_id
        and participant.convocation_status = 'convoked'
    )
  ) then
    raise exception 'La composition contient un joueur non convoqué.'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where nullif(btrim(e ->> 'team_no'), '') is not null
      and btrim(e ->> 'team_no') not in ('1', '2')
  ) then
    raise exception 'Équipe invalide.' using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where coalesce(e ->> 'zone', 'available') in ('field', 'bench')
      and coalesce(btrim(e ->> 'team_no'), '') not in ('1', '2')
  ) then
    raise exception 'Un joueur placé doit appartenir à une équipe.'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where coalesce(e ->> 'zone', 'available') not in ('available', 'field', 'bench')
       or (
         coalesce(e ->> 'zone', 'available') = 'field'
         and (
           nullif(btrim(e ->> 'slot_label'), '') is null
           or (e ->> 'x') is null
           or (e ->> 'y') is null
           or (e ->> 'x')::numeric not between 0 and 1
           or (e ->> 'y')::numeric not between 0 and 1
         )
       )
  ) then
    raise exception 'Placement terrain invalide.' using errcode = '22023';
  end if;

  if p_require_visual_complete then
    if exists (
      select 1 from jsonb_array_elements(p_entries) e
      where coalesce(btrim(e ->> 'team_no'), '') not in ('1', '2')
    ) then
      raise exception 'Chaque joueur doit être affecté à une équipe.'
        using errcode = '22023';
    end if;

    select
      count(*) filter (where (e ->> 'team_no') = '1')::integer,
      count(*) filter (where (e ->> 'team_no') = '2')::integer,
      count(*) filter (where (e ->> 'team_no') = '1' and e ->> 'zone' = 'field')::integer,
      count(*) filter (where (e ->> 'team_no') = '2' and e ->> 'zone' = 'field')::integer,
      count(*) filter (where (e ->> 'team_no') = '1' and e ->> 'zone' = 'bench')::integer,
      count(*) filter (where (e ->> 'team_no') = '2' and e ->> 'zone' = 'bench')::integer
    into v_team1_count, v_team2_count, v_team1_field, v_team2_field,
         v_team1_bench, v_team2_bench
    from jsonb_array_elements(p_entries) e;

    if v_team1_count = 0 or v_team2_count = 0 then
      raise exception 'Les deux équipes doivent contenir au moins un joueur.'
        using errcode = '22023';
    end if;
    if nullif(btrim(p_team1_formation), '') is null
        or nullif(btrim(p_team2_formation), '') is null then
      raise exception 'Choisis le dispositif de chaque équipe.' using errcode = '22023';
    end if;
    if v_team1_field <> least(v_team1_count, 11)
        or v_team2_field <> least(v_team2_count, 11)
        or v_team1_bench <> greatest(v_team1_count - 11, 0)
        or v_team2_bench <> greatest(v_team2_count - 11, 0) then
      raise exception 'Terrain ou banc incomplet.' using errcode = '22023';
    end if;

    if cardinality(private.internal_v4_formation_slots(p_team1_formation))
          <> least(v_team1_count, 11)
        or cardinality(private.internal_v4_formation_slots(p_team2_formation))
          <> least(v_team2_count, 11) then
      raise exception 'Dispositif invalide pour le nombre de titulaires.'
        using errcode = '22023';
    end if;

    if exists (
      select 1 from jsonb_array_elements(p_entries) e
      where e ->> 'zone' = 'field'
        and (
          (e ->> 'team_no' = '1'
            and not (e ->> 'slot_label' = any(private.internal_v4_formation_slots(p_team1_formation))))
          or
          (e ->> 'team_no' = '2'
            and not (e ->> 'slot_label' = any(private.internal_v4_formation_slots(p_team2_formation))))
        )
    ) then
      raise exception 'Un poste ne correspond pas au dispositif choisi.'
        using errcode = '22023';
    end if;

    if exists (
      select 1 from jsonb_array_elements(p_entries) e
      where e ->> 'zone' = 'field'
      group by e ->> 'team_no', e ->> 'slot_label'
      having count(*) > 1
    ) then
      raise exception 'Deux joueurs ne peuvent pas occuper le même poste.'
        using errcode = '22023';
    end if;
  end if;

  insert into public.match_internal_compositions (
    match_id, team1_name, team2_name, team1_jersey, team2_jersey,
    team1_formation, team2_formation, updated_by
  ) values (
    p_match_id, v_team1_name, v_team2_name, v_team1_jersey, v_team2_jersey,
    nullif(btrim(p_team1_formation), ''), nullif(btrim(p_team2_formation), ''),
    (select private.uid())
  )
  on conflict (match_id) do update
  set team1_name = excluded.team1_name,
      team2_name = excluded.team2_name,
      team1_jersey = excluded.team1_jersey,
      team2_jersey = excluded.team2_jersey,
      team1_formation = excluded.team1_formation,
      team2_formation = excluded.team2_formation,
      updated_by = excluded.updated_by,
      updated_at = now();

  delete from public.match_internal_composition_entries
  where match_id = p_match_id;

  for v_entry in select value from jsonb_array_elements(p_entries)
  loop
    insert into public.match_internal_composition_entries (
      match_id, participant_id, team_no, zone, x, y, slot_label, sort_order
    ) values (
      p_match_id,
      (v_entry ->> 'participant_id')::uuid,
      nullif(btrim(v_entry ->> 'team_no'), '')::smallint,
      coalesce(v_entry ->> 'zone', 'available'),
      case when v_entry ->> 'zone' = 'field' then (v_entry ->> 'x')::numeric else null end,
      case when v_entry ->> 'zone' = 'field' then (v_entry ->> 'y')::numeric else null end,
      case when v_entry ->> 'zone' = 'field'
        then nullif(btrim(v_entry ->> 'slot_label'), '') else null end,
      coalesce((v_entry ->> 'sort_order')::integer, 0)
    );
  end loop;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where coalesce(btrim(e ->> 'team_no'), '') in ('1', '2')
  ) then
    perform private.notify_composition_published(p_match_id);
  end if;

  return public.get_internal_composition(p_match_id);
end;
$function$

      or v_team1_jersey = v_team2_jersey then
    raise exception 'Maillots invalides ou identiques.' using errcode = '22023';
  end if;

  select m.match_type, m.status,
    coalesce(m.kickoff_at, ((m.match_date + m.match_time) at time zone 'Europe/Paris'))
  into v_match_type, v_status, v_kickoff_at
  from public.matches m
  where m.id = p_match_id
  for update;

  if v_match_type is null or v_match_type <> 'entre_nous' then
    raise exception 'Match entre nous introuvable' using errcode = 'P0002';
  end if;
  if v_status <> 'a_venir' then
    raise exception 'La composition d’un match terminé ou annulé est verrouillée.'
      using errcode = '22023';
  end if;
  if v_kickoff_at is null
      or now() >= private.match_prediction_closes_at(v_kickoff_at) then
    raise exception 'La composition est figée depuis l’ouverture du Live.'
      using errcode = '22023';
  end if;

  select count(*)::integer into v_expected_count
  from public.match_sport_participants participant
  where participant.match_id = p_match_id
    and participant.convocation_status = 'convoked';

  if jsonb_array_length(p_entries) <> v_expected_count then
    raise exception 'Tous les joueurs convoqués doivent apparaître exactement une fois.'
      using errcode = '22023';
  end if;

  if exists (
    select 1 from jsonb_array_elements(p_entries) e
    group by e ->> 'participant_id'
    having count(*) > 1
  ) then
    raise exception 'Un joueur apparaît plusieurs fois dans la composition.'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where not exists (
      select 1
      from public.match_sport_participants participant
      where participant.id = (e ->> 'participant_id')::uuid
        and participant.match_id = p_match_id
        and participant.convocation_status = 'convoked'
    )
  ) then
    raise exception 'La composition contient un joueur non convoqué.'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where nullif(btrim(e ->> 'team_no'), '') is not null
      and btrim(e ->> 'team_no') not in ('1', '2')
  ) then
    raise exception 'Équipe invalide.' using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where coalesce(e ->> 'zone', 'available') in ('field', 'bench')
      and coalesce(btrim(e ->> 'team_no'), '') not in ('1', '2')
  ) then
    raise exception 'Un joueur placé doit appartenir à une équipe.'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where coalesce(e ->> 'zone', 'available') not in ('available', 'field', 'bench')
       or (
         coalesce(e ->> 'zone', 'available') = 'field'
         and (
           nullif(btrim(e ->> 'slot_label'), '') is null
           or (e ->> 'x') is null
           or (e ->> 'y') is null
           or (e ->> 'x')::numeric not between 0 and 1
           or (e ->> 'y')::numeric not between 0 and 1
         )
       )
  ) then
    raise exception 'Placement terrain invalide.' using errcode = '22023';
  end if;

  if p_require_visual_complete then
    if exists (
      select 1 from jsonb_array_elements(p_entries) e
      where coalesce(btrim(e ->> 'team_no'), '') not in ('1', '2')
    ) then
      raise exception 'Chaque joueur doit être affecté à une équipe.'
        using errcode = '22023';
    end if;

    select
      count(*) filter (where (e ->> 'team_no') = '1')::integer,
      count(*) filter (where (e ->> 'team_no') = '2')::integer,
      count(*) filter (where (e ->> 'team_no') = '1' and e ->> 'zone' = 'field')::integer,
      count(*) filter (where (e ->> 'team_no') = '2' and e ->> 'zone' = 'field')::integer,
      count(*) filter (where (e ->> 'team_no') = '1' and e ->> 'zone' = 'bench')::integer,
      count(*) filter (where (e ->> 'team_no') = '2' and e ->> 'zone' = 'bench')::integer
    into v_team1_count, v_team2_count, v_team1_field, v_team2_field,
         v_team1_bench, v_team2_bench
    from jsonb_array_elements(p_entries) e;

    if v_team1_count = 0 or v_team2_count = 0 then
      raise exception 'Les deux équipes doivent contenir au moins un joueur.'
        using errcode = '22023';
    end if;
    if nullif(btrim(p_team1_formation), '') is null
        or nullif(btrim(p_team2_formation), '') is null then
      raise exception 'Choisis le dispositif de chaque équipe.' using errcode = '22023';
    end if;
    if v_team1_field <> least(v_team1_count, 11)
        or v_team2_field <> least(v_team2_count, 11)
        or v_team1_bench <> greatest(v_team1_count - 11, 0)
        or v_team2_bench <> greatest(v_team2_count - 11, 0) then
      raise exception 'Terrain ou banc incomplet.' using errcode = '22023';
    end if;

    if cardinality(private.internal_v4_formation_slots(p_team1_formation))
          <> least(v_team1_count, 11)
        or cardinality(private.internal_v4_formation_slots(p_team2_formation))
          <> least(v_team2_count, 11) then
      raise exception 'Dispositif invalide pour le nombre de titulaires.'
        using errcode = '22023';
    end if;

    if exists (
      select 1 from jsonb_array_elements(p_entries) e
      where e ->> 'zone' = 'field'
        and (
          (e ->> 'team_no' = '1'
            and not (e ->> 'slot_label' = any(private.internal_v4_formation_slots(p_team1_formation))))
          or
          (e ->> 'team_no' = '2'
            and not (e ->> 'slot_label' = any(private.internal_v4_formation_slots(p_team2_formation))))
        )
    ) then
      raise exception 'Un poste ne correspond pas au dispositif choisi.'
        using errcode = '22023';
    end if;

    if exists (
      select 1 from jsonb_array_elements(p_entries) e
      where e ->> 'zone' = 'field'
      group by e ->> 'team_no', e ->> 'slot_label'
      having count(*) > 1
    ) then
      raise exception 'Deux joueurs ne peuvent pas occuper le même poste.'
        using errcode = '22023';
    end if;
  end if;

  insert into public.match_internal_compositions (
    match_id, team1_name, team2_name, team1_jersey, team2_jersey,
    team1_formation, team2_formation, updated_by
  ) values (
    p_match_id, v_team1_name, v_team2_name, v_team1_jersey, v_team2_jersey,
    nullif(btrim(p_team1_formation), ''), nullif(btrim(p_team2_formation), ''),
    (select private.uid())
  )
  on conflict (match_id) do update
  set team1_name = excluded.team1_name,
      team2_name = excluded.team2_name,
      team1_jersey = excluded.team1_jersey,
      team2_jersey = excluded.team2_jersey,
      team1_formation = excluded.team1_formation,
      team2_formation = excluded.team2_formation,
      updated_by = excluded.updated_by,
      updated_at = now();

  delete from public.match_internal_composition_entries
  where match_id = p_match_id;

  for v_entry in select value from jsonb_array_elements(p_entries)
  loop
    insert into public.match_internal_composition_entries (
      match_id, participant_id, team_no, zone, x, y, slot_label, sort_order
    ) values (
      p_match_id,
      (v_entry ->> 'participant_id')::uuid,
      nullif(btrim(v_entry ->> 'team_no'), '')::smallint,
      coalesce(v_entry ->> 'zone', 'available'),
      case when v_entry ->> 'zone' = 'field' then (v_entry ->> 'x')::numeric else null end,
      case when v_entry ->> 'zone' = 'field' then (v_entry ->> 'y')::numeric else null end,
      case when v_entry ->> 'zone' = 'field'
        then nullif(btrim(v_entry ->> 'slot_label'), '') else null end,
      coalesce((v_entry ->> 'sort_order')::integer, 0)
    );
  end loop;

  if exists (
    select 1
    from jsonb_array_elements(p_entries) e
    where coalesce(btrim(e ->> 'team_no'), '') in ('1', '2')
  ) then
    perform private.notify_composition_published(p_match_id);
  end if;

  return public.get_internal_composition(p_match_id);
end;
$function$


-- Les fonctions existantes conservent leurs propriétaires, droits et RLS.
-- Pas d'UPDATE des lignes de clubs / matchs ni de réécriture des snapshots.
comment on table public.match_kit_snapshots is
  'Tenues figées au Live ou à la clôture, en nombre libre. Lecture uniquement sous RLS.';
