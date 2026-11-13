-- Couleurs du gardien distinctes des joueurs, par tenue et par club.
-- Migration additive : mêmes trois identifiants de tenue et données existantes.
-- Les anciens clients sans goalkeeper_* reçoivent des valeurs par défaut ;
-- aucune table, saison ou ancienne migration n'est effacée.
-- Écriture limitée à l'administrateur du club actif (contrôles RPC existants).

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
  v_enabled_count integer := 0;
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
    -- Les anciens clients restent compatibles : couleurs gardien de repli.
    v_goalkeeper_body := coalesce(
      v_item ->> 'goalkeeper_body',
      case v_item ->> 'slot'
        when 'france' then '#168A52'
        when 'orange' then '#F5A300'
        else '#1F6FEB'
      end
    );
    v_goalkeeper_trim := coalesce(v_item ->> 'goalkeeper_trim', '#FFFFFF');
    if v_goalkeeper_body !~ '^#[0-9A-Fa-f]{6}$'
       or v_goalkeeper_trim !~ '^#[0-9A-Fa-f]{6}$' then
      raise exception 'Couleur de gardien invalide.' using errcode = '22023';
    end if;
    if jsonb_typeof(v_item -> 'enabled') <> 'boolean' then
      raise exception 'État du maillot invalide.' using errcode = '22023';
    end if;
    if (v_item ->> 'enabled')::boolean then
      v_enabled_count := v_enabled_count + 1;
    end if;

    v_slots := v_slots || (v_item ->> 'slot');
    v_clean := v_clean || jsonb_build_array(jsonb_build_object(
      'slot', v_item ->> 'slot',
      'label', v_label,
      'body', upper(v_item ->> 'body'),
      'trim', upper(v_item ->> 'trim'),
      'goalkeeper_body', upper(v_goalkeeper_body),
      'goalkeeper_trim', upper(v_goalkeeper_trim),
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
