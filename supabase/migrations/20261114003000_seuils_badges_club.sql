-- Seuils des badges réglables par club.
--
-- Les badges à paliers (buts, passes, matchs joués, victoires, clean sheets,
-- Étoile du match) se gagnent en atteignant un nombre fixé. Ce nombre était
-- le même pour tous les clubs. L'administrateur peut maintenant le changer
-- pour son club, en gardant l'ordre des paliers (le palier 2 reste au-dessus
-- du palier 1, etc.).
--
-- Un seuil abaissé décerne aussitôt le badge à ceux qui l'atteignent. Un seuil
-- relevé ne retire pas un badge déjà gagné.

-- Modifier le seuil d'un badge à paliers du club courant.
create function public.staff_update_badge_threshold(
  p_badge_code text,
  p_threshold integer
) returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_badge record;
  v_lower integer;
  v_higher integer;
  v_description text;
begin
  if not (select private.can_manage_badges()) then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;
  if p_threshold is null or p_threshold < 1 or p_threshold > 10000 then
    raise exception 'Le seuil doit être compris entre 1 et 10 000.'
      using errcode = '22023';
  end if;

  -- La règle de cloisonnement ne laisse voir que les badges du club courant.
  select badge.id, badge.code, badge.metric, badge.threshold, badge.description
  into v_badge
  from public.badges badge
  where badge.code = p_badge_code
    and badge.auto
    and badge.kind = 'tier'
    and badge.metric is not null
    and badge.threshold is not null
  for update;

  if not found
     or v_badge.metric in ('max_match_goals', 'max_match_assists',
                           'seasons_complete', 'bet_against_grinta')
     or v_badge.metric like 'title\_%' then
    raise exception 'Ce badge n’a pas de seuil réglable.' using errcode = '22023';
  end if;

  if p_threshold = v_badge.threshold then
    return jsonb_build_object('code', v_badge.code, 'threshold', v_badge.threshold);
  end if;

  select max(other.threshold) into v_lower
  from public.badges other
  where other.kind = 'tier' and other.metric = v_badge.metric
    and other.id <> v_badge.id and other.threshold < v_badge.threshold;
  select min(other.threshold) into v_higher
  from public.badges other
  where other.kind = 'tier' and other.metric = v_badge.metric
    and other.id <> v_badge.id and other.threshold > v_badge.threshold;

  if (v_lower is not null and p_threshold <= v_lower)
     or (v_higher is not null and p_threshold >= v_higher) then
    raise exception 'Le seuil doit rester entre les paliers voisins (% et %).',
      coalesce(v_lower::text, '1'), coalesce(v_higher::text, '10 000')
      using errcode = '22023';
  end if;

  -- La description suit le nouveau nombre quand elle citait l'ancien.
  v_description := v_badge.description;
  if v_description ~ ('(^|[^0-9])' || v_badge.threshold || '([^0-9]|$)') then
    v_description := regexp_replace(
      v_description,
      '(^|[^0-9])' || v_badge.threshold || '([^0-9]|$)',
      '\1' || p_threshold || '\2'
    );
  end if;

  update public.badges
  set threshold = p_threshold,
      description = v_description
  where id = v_badge.id;

  -- Décerne le badge à ceux qui atteignent désormais le seuil (club courant).
  perform public.recalculate_all_badges();

  return jsonb_build_object('code', v_badge.code, 'threshold', p_threshold);
end;
$$;

alter function public.staff_update_badge_threshold(text, integer) owner to club_scope;
revoke all on function public.staff_update_badge_threshold(text, integer) from public, anon;
grant execute on function public.staff_update_badge_threshold(text, integer)
  to authenticated, service_role, club_scope;
