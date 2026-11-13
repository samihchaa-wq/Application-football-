-- Modèles et portraits habillés, opt-in par club. Cette nouvelle migration
-- prolonge le JSON déjà présent ; aucune photo ni ancien snapshot modifié.
-- Générée par supabase migration new, ordonnée après 20261116020000.

create or replace function public.admin_update_club_kits(p_kits jsonb)
returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_club public.clubs;
  v_item jsonb;
  v_clean jsonb := '[]'::jsonb;
  v_slots text[] := array[]::text[];
  v_label text;
  v_goalkeeper_body text;
  v_goalkeeper_trim text;
  v_previous_kits jsonb;
  v_enabled_count integer := 0;
  v_previous jsonb;
  v_pattern jsonb;
  v_goalkeeper_pattern jsonb;
  v_dress_players jsonb;
begin
  -- Administrateur actif d'un club actif : un club suspendu ou un compte
  -- suspendu ne peut plus rien modifier.
  if not (select private.is_admin()) or not (select private.is_active_profile()) then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;
  if p_kits is null or jsonb_typeof(p_kits) <> 'array'
     or jsonb_array_length(p_kits) <> 3 then
    raise exception 'Il faut exactement trois maillots.' using errcode = '22023';
  end if;

  -- Lire uniquement les tenues du club courant : préserver les personnalisations
  -- gardien lors d'une écriture provenant d'un ancien client Flutter.
  select kits into v_previous_kits
  from public.clubs
  where id = (select private.current_club_id()) for update;

  for v_item in select value from jsonb_array_elements(p_kits) loop
    if jsonb_typeof(v_item) <> 'object'
       or coalesce(v_item ->> 'slot', '') not in ('france', 'orange', 'blue')
       or (v_item ->> 'slot') = any (v_slots) then
      raise exception 'Emplacement de maillot invalide.' using errcode = '22023';
    end if;
    v_label := regexp_replace(btrim(coalesce(v_item ->> 'label', '')), '\s+', ' ', 'g');
    if char_length(v_label) < 1 or char_length(v_label) > 20 then
      raise exception 'Nom de maillot invalide (1 à 20 caractères).' using errcode = '22023';
    end if;
    if coalesce(v_item ->> 'body', '') !~ '^#[0-9A-Fa-f]{6}$'
       or coalesce(v_item ->> 'trim', '') !~ '^#[0-9A-Fa-f]{6}$' then
      raise exception 'Couleur de maillot invalide.' using errcode = '22023';
    end if;
    -- Un ancien client ne peut pas écraser les couleurs gardien existantes.
    v_goalkeeper_body := coalesce(
      v_item ->> 'goalkeeper_body',
      (
        select prior ->> 'goalkeeper_body'
        from jsonb_array_elements(coalesce(v_previous_kits, '[]'::jsonb)) as prior
        where prior ->> 'slot' = v_item ->> 'slot'
        limit 1
      ),
      case v_item ->> 'slot'
        when 'france' then '#168A52'
        when 'orange' then '#F5A300'
        else '#1F6FEB'
      end
    );
    v_goalkeeper_trim := coalesce(
      v_item ->> 'goalkeeper_trim',
      (
        select prior ->> 'goalkeeper_trim'
        from jsonb_array_elements(coalesce(v_previous_kits, '[]'::jsonb)) as prior
        where prior ->> 'slot' = v_item ->> 'slot'
        limit 1
      ),
      '#FFFFFF'
    );
    if v_goalkeeper_body !~ '^#[0-9A-Fa-f]{6}$'
       or v_goalkeeper_trim !~ '^#[0-9A-Fa-f]{6}$' then
      raise exception 'Couleur de gardien invalide.' using errcode = '22023';
    end if;
    if coalesce(jsonb_typeof(v_item -> 'enabled'), 'null') <> 'boolean' then
      raise exception 'État du maillot invalide.' using errcode = '22023';
    end if;
    if (v_item ->> 'enabled')::boolean then
      v_enabled_count := v_enabled_count + 1;
    end if;

    select prior into v_previous
    from jsonb_array_elements(coalesce(v_previous_kits, '[]'::jsonb)) as prior
    where prior ->> 'slot' = v_item ->> 'slot' limit 1;
    -- Les anciens clients omettent ces clés : conserver le choix existant.
    v_pattern := coalesce(v_item -> 'pattern', v_previous -> 'pattern', '"plain"'::jsonb);
    v_goalkeeper_pattern := coalesce(v_item -> 'goalkeeper_pattern',
      v_previous -> 'goalkeeper_pattern', '"plain"'::jsonb);
    v_dress_players := coalesce(v_item -> 'dress_players',
      v_previous -> 'dress_players', 'false'::jsonb);
    if jsonb_typeof(v_pattern) <> 'string'
       or v_pattern #>> '{}' not in ('plain','stripes','hoops','sash')
       or jsonb_typeof(v_goalkeeper_pattern) <> 'string'
       or v_goalkeeper_pattern #>> '{}' not in ('plain','stripes','hoops','sash') then
      raise exception 'Modèle de maillot invalide.' using errcode = '22023';
    end if;
    if jsonb_typeof(v_dress_players) <> 'boolean' then
      raise exception 'Option de portrait invalide.' using errcode = '22023';
    end if;

    v_slots := v_slots || (v_item ->> 'slot');
    v_clean := v_clean || jsonb_build_array(jsonb_build_object(
      'slot', v_item ->> 'slot',
      'label', v_label,
      'body', upper(v_item ->> 'body'),
      'trim', upper(v_item ->> 'trim'),
      'goalkeeper_body', upper(v_goalkeeper_body),
      'goalkeeper_trim', upper(v_goalkeeper_trim),
      'pattern', v_pattern,
      'goalkeeper_pattern', v_goalkeeper_pattern,
      'dress_players', v_dress_players,
      'enabled', (v_item ->> 'enabled')::boolean
    ));
  end loop;

  if v_enabled_count = 0 then
    raise exception 'Au moins un maillot doit être proposé.' using errcode = '22023';
  end if;

  update public.clubs
  set kits = v_clean
  where id = (select private.current_club_id())
  returning * into v_club;

  if v_club.id is null then
    raise exception 'Club introuvable.' using errcode = 'P0002';
  end if;

  return v_club.kits;
end;
$$;

alter function public.admin_update_club_kits(jsonb) owner to club_scope;
revoke all on function public.admin_update_club_kits(jsonb) from public, anon;
grant execute on function public.admin_update_club_kits(jsonb)
  to authenticated, service_role, club_scope;

create or replace function private.match_kit_snapshot_value(
  p_kits jsonb,
  p_primary text,
  p_secondary text,
  p_slot text
) returns jsonb
language plpgsql stable
set search_path to ''
as $$
declare
  v_slot text := case when p_slot in ('france','orange','blue')
    then p_slot else 'france' end;
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
    else 'Troisième'
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
    'enabled', coalesce((v_kit ->> 'enabled')::boolean, true)
  );
end;
$$;

revoke all on function private.match_kit_snapshot_value(jsonb,text,text,text)
  from public, anon, authenticated;
