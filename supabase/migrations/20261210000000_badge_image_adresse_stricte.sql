-- Image de badge : l'adresse doit COMMENCER par le chemin du stockage
-- (avant : elle devait seulement le contenir, donc une image hébergée
-- ailleurs passait). Création : même contrôle, qui n'existait pas.
-- Retire aussi grinta_sync.ping, reste inutile de l'ancien projet.

create or replace function public.staff_update_badge_image(p_badge_code text, p_image_url text)
returns boolean
language plpgsql
security definer
set search_path to ''
as $function$
begin
  if not private.can_manage_badges() then
    raise exception 'Badge administration access required' using errcode = '42501';
  end if;

  if nullif(btrim(p_badge_code), '') is null then
    raise exception 'Badge code is required' using errcode = '22023';
  end if;

  if nullif(btrim(p_image_url), '') is null then
    raise exception 'Badge image URL is required' using errcode = '22023';
  end if;

  if btrim(p_image_url) !~ '^https?://[^/?#]+/storage/v1/object/public/badge-images/[^?#]+$' then
    raise exception 'Badge image must come from badge-images storage'
      using errcode = '22023';
  end if;

  update public.badges
  set image_url = btrim(p_image_url)
  where code = btrim(p_badge_code);

  if not found then
    raise exception 'Badge not found' using errcode = 'P0002';
  end if;

  return true;
end;
$function$;

create or replace function public.staff_create_badge(
  p_code text, p_name text, p_emoji text default '🏅'::text,
  p_description text default ''::text, p_image_url text default null::text,
  p_color text default '#C0455B'::text)
returns boolean
language plpgsql
security definer
set search_path to ''
as $function$
begin
  if not private.can_manage_badges() then
    raise exception 'Badge administration access required' using errcode = '42501';
  end if;

  if p_code is null or p_code = '' or p_name is null or p_name = '' then
    raise exception 'code and name are required' using errcode = '22023';
  end if;

  if nullif(btrim(p_image_url), '') is not null
     and btrim(p_image_url) !~ '^https?://[^/?#]+/storage/v1/object/public/badge-images/[^?#]+$' then
    raise exception 'Badge image must come from badge-images storage'
      using errcode = '22023';
  end if;

  insert into public.badges(
    code, name, description, emoji, image_url, color,
    family, auto, kind, category, metric, threshold, sort_order
  )
  values (
    p_code,
    p_name,
    coalesce(p_description, ''),
    coalesce(nullif(p_emoji, ''), '🏅'),
    nullif(btrim(p_image_url), ''),
    coalesce(nullif(p_color, ''), '#C0455B'),
    'joueur',
    false,
    'custom',
    'faits_de_jeu',
    null,
    null,
    900
  )
  on conflict (club_id, code) do update
  set name = excluded.name,
      emoji = excluded.emoji,
      description = excluded.description,
      image_url = excluded.image_url,
      color = excluded.color;

  return true;
end;
$function$;

drop function if exists grinta_sync.ping();
