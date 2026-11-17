-- Import atomique d'archives Petit Filet v1 (réservé à l'admin de l'équipe).
-- Lot complet dans une seule transaction ; aucun accès à AS Grinta original.
-- Le droit de la fonction reste limité au rôle club_scope comme la saisie manuelle.
create function public.admin_import_historical_matches(p_document jsonb)
returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_rows jsonb;
  v_row jsonb;
  v_date date;
  v_opponent text;
  v_key text;
  v_seen jsonb := '{}'::jsonb;
  v_signature text;
  v_current_club uuid;
  v_existing record;
  v_imported integer := 0;
  v_skipped integer := 0;
begin
  if not (select private.is_admin()) then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;
  if p_document is null or jsonb_typeof(p_document) <> 'object'
     or p_document ->> 'format' is distinct from 'petit-filet-historique'
     or p_document ->> 'version' is distinct from '1'
     or jsonb_typeof(p_document -> 'matches') is distinct from 'array' then
    raise exception 'Format d’historique incorrect : Petit Filet v1 requis.'
      using errcode = '22023';
  end if;
  v_rows := p_document -> 'matches';
  if jsonb_array_length(v_rows) < 1 or jsonb_array_length(v_rows) > 400 then
    raise exception 'Un fichier doit contenir de 1 à 400 matchs.'
      using errcode = '22023';
  end if;
  v_current_club := (select private.current_club_id());
  if v_current_club is null then
    raise exception 'Équipe introuvable.' using errcode = '42501';
  end if;

  -- Empêche deux imports concurrents du même club de créer le même match.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_current_club::text || ':history-import', 0)
  );

  for v_row in select value from jsonb_array_elements(v_rows) loop
    if jsonb_typeof(v_row) <> 'object' then
      raise exception 'Une ligne de match est invalide.' using errcode = '22023';
    end if;
    if jsonb_typeof(v_row -> 'score_for') is distinct from 'number'
       or jsonb_typeof(v_row -> 'score_against') is distinct from 'number'
       or jsonb_typeof(v_row -> 'is_home') is distinct from 'boolean'
       or coalesce(v_row ->> 'match_type', '') not in ('amical', 'championnat') then
      raise exception 'Date, score, domicile/extérieur ou type manquant.'
        using errcode = '22023';
    end if;
    begin
      v_date := (v_row ->> 'date')::date;
    exception when others then
      raise exception 'Date illisible dans le document.' using errcode = '22023';
    end;
    if v_date is null or v_date >= private.history_entry_cutoff() or v_date > current_date then
      raise exception 'Match hors de la période historique autorisée.' using errcode = '22023';
    end if;
    v_opponent := btrim(regexp_replace(coalesce(v_row ->> 'opponent', ''), '\s+', ' ', 'g'));
    if char_length(v_opponent) < 2 or char_length(v_opponent) > 100 then
      raise exception 'Nom d’adversaire invalide.' using errcode = '22023';
    end if;
    v_key := v_date::text || '|' || lower(v_opponent);
    v_signature := (v_row ->> 'score_for') || '/' ||
                   (v_row ->> 'score_against') || '/' ||
                   (v_row ->> 'is_home') || '/' ||
                   (v_row ->> 'match_type');
    if v_seen ? v_key then
      if v_seen ->> v_key is distinct from v_signature then
        raise exception 'Deux matchs contradictoires le même jour contre %.',
          v_opponent using errcode = '22023';
      end if;
      v_skipped := v_skipped + 1;
      continue;
    end if;
    v_seen := v_seen || jsonb_build_object(v_key, v_signature);

    select score.score_as_grinta, score.score_adverse, score.is_home,
           score.match_type
      into v_existing
    from public.historical_match_scores score
    join public.opponents opponent on opponent.id = score.opponent_id
    where score.club_id = v_current_club
      and opponent.club_id = v_current_club
      and score.match_date = v_date
      and lower(btrim(opponent.name)) = lower(v_opponent)
    limit 1;
    if found then
      if v_existing.score_as_grinta = (v_row ->> 'score_for')::integer
         and v_existing.score_adverse = (v_row ->> 'score_against')::integer
         and v_existing.is_home = (v_row ->> 'is_home')::boolean
         and v_existing.match_type = v_row ->> 'match_type' then
        v_skipped := v_skipped + 1;
        continue;
      end if;
      raise exception 'Match déjà présent avec des valeurs différentes : % contre %.',
        v_date, v_opponent using errcode = '22023';
    end if;

    -- Réutilise exactement les validations et les liens joueur de la saisie.
    perform public.admin_add_historical_match(v_row);
    v_imported := v_imported + 1;
  end loop;
  return jsonb_build_object('imported', v_imported, 'skipped', v_skipped);
end;
$$;

alter function public.admin_import_historical_matches(jsonb) owner to club_scope;
revoke all on function public.admin_import_historical_matches(jsonb)
  from public, anon, authenticated;
grant execute on function public.admin_import_historical_matches(jsonb)
  to authenticated, service_role, club_scope;
