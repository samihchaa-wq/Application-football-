-- Raccourcir ou remplacer le nom d'un ancien joueur dans tout l'historique.
--
-- Promesse de la politique de confidentialité (version 2026-11-19) : après la
-- suppression de son compte, le nom d'un joueur reste dans l'historique des
-- matchs ; sur demande, il est raccourci (« Yves D. ») ou remplacé par
-- « Ancien joueur ».
--
-- Le nom est recopié à de nombreux endroits : identité du joueur, alias,
-- effectifs de saison, invités, statistiques et feuilles historiques, et
-- instantanés JSON (compositions publiées, comptes rendus, direct, journaux).
-- Les feuilles historiques retrouvent le joueur par son nom écrit : le
-- nouveau nom est donc rattaché au même joueur AVANT de réécrire les
-- feuilles, pour que leurs statistiques restent attachées à la même
-- personne.
--
-- Réservé aux administrateurs actifs du club, pour un joueur qui n'a plus de
-- compte actif (ancien membre, invité). Un membre actif modifie son nom
-- lui-même depuis son profil.

-- ---------------------------------------------------------------------------
-- 1. Réécriture d'un document JSON
-- ---------------------------------------------------------------------------

-- Remplace, dans un document JSON :
-- - les champs de nom (name, display_name, first_name, last_name…) des
--   objets qui désignent ce joueur par l'un de ses identifiants ;
-- - toute chaîne égale (à la casse et aux accents près) à l'un de ses
--   anciens noms complets.
-- Le reste du document est rendu à l'identique.
create function private.rename_player_in_jsonb(
  p_doc jsonb,
  p_ids text[],
  p_old_names text[],
  p_display text,
  p_first text,
  p_last text
) returns jsonb
language plpgsql stable
set search_path to ''
as $$
declare
  v_entry record;
  v_out jsonb;
  v_is_player boolean;
begin
  if p_doc is null then
    return null;
  end if;

  case jsonb_typeof(p_doc)
  when 'object' then
    v_is_player := exists (
      select 1 from jsonb_each_text(p_doc) field
      where field.key in (
          'id', 'player_id', 'season_player_id', 'guest_player_id',
          'profile_id', 'participant_id'
        )
        and field.value = any(p_ids)
    );
    v_out := '{}'::jsonb;
    for v_entry in select key, value from jsonb_each(p_doc) loop
      if v_is_player and jsonb_typeof(v_entry.value) = 'string'
         and v_entry.key in (
           'name', 'display_name', 'player_name', 'scorer_name', 'full_name',
           'nickname'
         ) then
        v_out := v_out || jsonb_build_object(v_entry.key, p_display);
      elsif v_is_player and jsonb_typeof(v_entry.value) = 'string'
            and v_entry.key = 'first_name' then
        v_out := v_out || jsonb_build_object(v_entry.key, p_first);
      elsif v_is_player and jsonb_typeof(v_entry.value) = 'string'
            and v_entry.key = 'last_name' then
        v_out := v_out || jsonb_build_object(v_entry.key, p_last);
      elsif v_is_player and jsonb_typeof(v_entry.value) = 'string'
            and v_entry.key = 'surnom' then
        v_out := v_out || jsonb_build_object(v_entry.key, '');
      else
        v_out := v_out || jsonb_build_object(
          v_entry.key,
          private.rename_player_in_jsonb(
            v_entry.value, p_ids, p_old_names, p_display, p_first, p_last
          )
        );
      end if;
    end loop;
    return v_out;
  when 'array' then
    return coalesce((
      select jsonb_agg(
        private.rename_player_in_jsonb(
          element.value, p_ids, p_old_names, p_display, p_first, p_last
        )
        order by element.ordinality
      )
      from jsonb_array_elements(p_doc) with ordinality element(value, ordinality)
    ), '[]'::jsonb);
  when 'string' then
    if private.normalize_player_name(p_doc #>> '{}') = any(p_old_names) then
      return to_jsonb(p_display);
    end if;
    return p_doc;
  else
    return p_doc;
  end case;
end;
$$;

revoke all on function private.rename_player_in_jsonb(jsonb, text[], text[], text, text, text)
  from public, anon, authenticated;
grant execute on function private.rename_player_in_jsonb(jsonb, text[], text[], text, text, text)
  to club_scope;

-- ---------------------------------------------------------------------------
-- 2. Liste des anciens joueurs (pour l'écran d'administration)
-- ---------------------------------------------------------------------------

-- Joueurs du club sans compte actif : anciens membres et invités.
create function public.admin_list_former_players()
returns table (player_id uuid, display_name text)
language plpgsql stable security definer
set search_path to ''
as $$
begin
  if not (select private.is_admin()) or not (select private.is_active_profile()) then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;

  return query
  select player.id, player.display_name
  from public.players player
  where player.club_id = (select private.current_club_id())
    and player.archived_at is null
    and not exists (
      select 1
      from public.season_players season_player
      join public.profiles profile on profile.id = season_player.profile_id
      where season_player.player_id = player.id
        and profile.status = 'active'
    )
    and not exists (
      select 1 from public.profiles profile
      where profile.player_id = player.id and profile.status = 'active'
    )
    and (
      exists (select 1 from public.season_players sp where sp.player_id = player.id)
      or exists (select 1 from public.guest_players g where g.player_id = player.id)
      or exists (
        select 1 from public.historical_player_statistics h
        where h.player_id = player.id
      )
    )
  order by lower(player.display_name);
end;
$$;

-- Appartient à club_scope : ne lit que le club de l'administrateur.
alter function public.admin_list_former_players() owner to club_scope;
revoke all on function public.admin_list_former_players() from public, anon;
grant execute on function public.admin_list_former_players() to authenticated;

-- ---------------------------------------------------------------------------
-- 3. Raccourcir ou remplacer
-- ---------------------------------------------------------------------------

-- Cœur du traitement, sans contrôle d'accès : appelé par la fonction des
-- administrateurs (ci-dessous) et par la suppression d'un compte
-- (migration 20261129020000). Agit dans
-- le club courant. p_mode : 'short' (« Yves D. ») ou 'anonymous'
-- (« Ancien joueur »). Renvoie le nouveau nom.
create function private.rename_player_everywhere(p_player_id uuid, p_mode text)
returns text
language plpgsql
set search_path to ''
as $$
declare
  v_club uuid := (select private.current_club_id());
  v_player public.players%rowtype;
  v_first text;
  v_last text;
  v_base_first text;
  v_base_last text;
  v_display text;
  v_candidate text;
  v_suffix integer := 1;
  v_old text[];
  v_ids text[];
  v_new_norm text;
begin
  if p_mode is null or p_mode not in ('short', 'anonymous') then
    raise exception 'Choix invalide.' using errcode = '22023';
  end if;

  select * into v_player
  from public.players player
  where player.id = p_player_id and player.club_id = v_club
  for update;
  if not found then
    raise exception 'Joueur introuvable.' using errcode = 'P0002';
  end if;

  -- Prénom et nom connus : effectif de saison, puis invité, puis le libellé.
  select nullif(btrim(sp.first_name), ''), nullif(btrim(sp.last_name), '')
  into v_first, v_last
  from public.season_players sp
  where sp.player_id = p_player_id
  limit 1;
  if v_first is null then
    select nullif(btrim(g.first_name), ''), nullif(btrim(g.last_name), '')
    into v_first, v_last
    from public.guest_players g
    where g.player_id = p_player_id
    order by g.created_at desc
    limit 1;
  end if;
  if v_first is null then
    v_first := split_part(btrim(v_player.display_name), ' ', 1);
    v_last := nullif(btrim(substr(btrim(v_player.display_name), length(v_first) + 1)), '');
  end if;

  if p_mode = 'short' then
    if v_last is null then
      raise exception 'Ce joueur n''a pas de nom de famille à raccourcir : choisis « Ancien joueur ».'
        using errcode = '22023';
    end if;
    v_base_first := v_first;
    v_base_last := upper(left(v_last, 1)) || '.';
  else
    v_base_first := 'Ancien';
    v_base_last := 'joueur';
  end if;

  -- Tous les noms déjà portés par ce joueur, normalisés.
  select array_agg(distinct normalized) filter (where normalized is not null)
  into v_old
  from (
    select private.normalize_player_name(v_player.display_name) as normalized
    union all
    select private.normalize_player_name(alias.alias)
    from public.player_aliases alias where alias.player_id = p_player_id
    union all
    select private.normalize_player_name(btrim(sp.first_name || ' ' || coalesce(sp.last_name, '')))
    from public.season_players sp where sp.player_id = p_player_id
    union all
    select private.normalize_player_name(btrim(g.first_name || ' ' || coalesce(g.last_name, '')))
    from public.guest_players g where g.player_id = p_player_id
    union all
    select private.normalize_player_name(btrim(profile.first_name || ' ' || coalesce(profile.last_name, '')))
    from public.profiles profile where profile.player_id = p_player_id
    union all
    select link.normalized_name
    from public.historical_player_name_links link where link.player_id = p_player_id
    union all
    select private.normalize_player_name(h.player_name)
    from public.historical_player_statistics h where h.player_id = p_player_id
  ) names;

  -- Nouveau nom unique dans le club : deux « Ancien joueur » ou deux
  -- « Yves D. » ne doivent jamais se confondre.
  loop
    v_last := v_base_last || case when v_suffix > 1 then ' ' || v_suffix else '' end;
    v_candidate := v_base_first || ' ' || v_last;
    v_new_norm := private.normalize_player_name(v_candidate);
    exit when not exists (
        select 1 from public.players other
        where other.club_id = v_club and other.id <> p_player_id
          and private.normalize_player_name(other.display_name) = v_new_norm
      )
      and not exists (
        select 1 from public.player_aliases alias
        where alias.club_id = v_club and alias.player_id <> p_player_id
          and private.normalize_player_name(alias.alias) = v_new_norm
      )
      and not exists (
        select 1 from public.historical_player_name_links link
        where link.club_id = v_club and link.player_id <> p_player_id
          and link.normalized_name = v_new_norm
      )
      and not exists (
        select 1 from public.historical_player_statistics h
        where h.club_id = v_club and h.player_id <> p_player_id
          and private.normalize_player_name(h.player_name) = v_new_norm
      );
    v_suffix := v_suffix + 1;
  end loop;
  v_display := v_candidate;
  v_old := array_remove(v_old, v_new_norm);

  -- Identifiants sous lesquels ce joueur apparaît dans les documents.
  select array_agg(distinct id) filter (where id is not null)
  into v_ids
  from (
    select p_player_id::text as id
    union all
    select sp.id::text from public.season_players sp where sp.player_id = p_player_id
    union all
    select sp.profile_id::text from public.season_players sp where sp.player_id = p_player_id
    union all
    select profile.id::text from public.profiles profile where profile.player_id = p_player_id
    union all
    select g.id::text from public.guest_players g where g.player_id = p_player_id
    union all
    select participant.id::text
    from public.match_sport_participants participant
    where participant.season_player_id in (
        select sp.id from public.season_players sp where sp.player_id = p_player_id
      )
      or participant.guest_player_id in (
        select g.id from public.guest_players g where g.player_id = p_player_id
      )
  ) ids;

  -- Les compositions de matchs terminés sont protégées : la réécriture du
  -- nom est la seule modification autorisée ici.
  perform set_config('as_grinta.allow_postmatch_composition_write', 'on', true);

  -- a. Le nouveau nom désigne d'abord le même joueur.
  insert into public.historical_player_name_links (normalized_name, source_name, player_id)
  values (v_new_norm, v_display, p_player_id)
  on conflict (club_id, normalized_name) do update
  set player_id = excluded.player_id, source_name = excluded.source_name, updated_at = now();

  -- b. Tables où le nom est une colonne.
  update public.players set display_name = v_display, updated_at = now()
  where id = p_player_id;
  update public.season_players set first_name = v_base_first, last_name = v_last
  where player_id = p_player_id;
  update public.guest_players set first_name = v_base_first, last_name = v_last
  where player_id = p_player_id;
  -- Compte encore présent mais inactif (archivé) : son nom suit aussi.
  update public.profiles set first_name = v_base_first, last_name = v_last, surnom = ''
  where player_id = p_player_id and status <> 'active';
  update public.historical_player_statistics set player_name = v_display
  where player_id = p_player_id;
  update public.historical_match_players set source_name = v_display
  where player_id = p_player_id;
  update private.match_live_notification_events set scorer_name = v_display
  where club_id = v_club and private.normalize_player_name(scorer_name) = any(v_old);

  -- c. Documents JSON (seules les lignes qui changent sont réécrites).
  with rewritten as (
    select d.match_id,
      private.rename_player_in_jsonb(d.field_players, v_ids, v_old, v_display, v_base_first, v_last) as field_players,
      private.rename_player_in_jsonb(d.bench_players, v_ids, v_old, v_display, v_base_first, v_last) as bench_players,
      private.rename_player_in_jsonb(d.present_names, v_ids, v_old, v_display, v_base_first, v_last) as present_names,
      private.rename_player_in_jsonb(d.motm_names, v_ids, v_old, v_display, v_base_first, v_last) as motm_names,
      private.rename_player_in_jsonb(d.scorers, v_ids, v_old, v_display, v_base_first, v_last) as scorers
    from public.historical_match_details d
    where d.club_id = v_club
  )
  update public.historical_match_details d
  set field_players = r.field_players, bench_players = r.bench_players,
      present_names = r.present_names, motm_names = r.motm_names, scorers = r.scorers
  from rewritten r
  where d.match_id = r.match_id
    and (d.field_players, d.bench_players, d.present_names, d.motm_names, d.scorers)
      is distinct from (r.field_players, r.bench_players, r.present_names, r.motm_names, r.scorers);

  update public.match_composition_publications t
  set snapshot = private.rename_player_in_jsonb(t.snapshot, v_ids, v_old, v_display, v_base_first, v_last)
  where t.club_id = v_club
    and t.snapshot is distinct from
      private.rename_player_in_jsonb(t.snapshot, v_ids, v_old, v_display, v_base_first, v_last);

  update public.match_sport_finalization_versions t
  set snapshot = private.rename_player_in_jsonb(t.snapshot, v_ids, v_old, v_display, v_base_first, v_last)
  where t.club_id = v_club
    and t.snapshot is distinct from
      private.rename_player_in_jsonb(t.snapshot, v_ids, v_old, v_display, v_base_first, v_last);

  update public.match_live_sessions t
  set starting_lineup_snapshot = private.rename_player_in_jsonb(t.starting_lineup_snapshot, v_ids, v_old, v_display, v_base_first, v_last)
  where t.club_id = v_club
    and t.starting_lineup_snapshot is distinct from
      private.rename_player_in_jsonb(t.starting_lineup_snapshot, v_ids, v_old, v_display, v_base_first, v_last);

  update public.match_sport_participant_events t
  set old_value = private.rename_player_in_jsonb(t.old_value, v_ids, v_old, v_display, v_base_first, v_last),
      new_value = private.rename_player_in_jsonb(t.new_value, v_ids, v_old, v_display, v_base_first, v_last)
  where t.club_id = v_club
    and (t.old_value, t.new_value) is distinct from (
      private.rename_player_in_jsonb(t.old_value, v_ids, v_old, v_display, v_base_first, v_last),
      private.rename_player_in_jsonb(t.new_value, v_ids, v_old, v_display, v_base_first, v_last)
    );

  update private.sport_admin_audit_log t
  set metadata = private.rename_player_in_jsonb(t.metadata, v_ids, v_old, v_display, v_base_first, v_last)
  where t.club_id = v_club
    and t.metadata is distinct from
      private.rename_player_in_jsonb(t.metadata, v_ids, v_old, v_display, v_base_first, v_last);

  update private.profile_badge_audit_log t
  set metadata = private.rename_player_in_jsonb(t.metadata, v_ids, v_old, v_display, v_base_first, v_last),
      state_before = private.rename_player_in_jsonb(t.state_before, v_ids, v_old, v_display, v_base_first, v_last),
      state_after = private.rename_player_in_jsonb(t.state_after, v_ids, v_old, v_display, v_base_first, v_last)
  where t.club_id = v_club
    and (t.metadata, t.state_before, t.state_after) is distinct from (
      private.rename_player_in_jsonb(t.metadata, v_ids, v_old, v_display, v_base_first, v_last),
      private.rename_player_in_jsonb(t.state_before, v_ids, v_old, v_display, v_base_first, v_last),
      private.rename_player_in_jsonb(t.state_after, v_ids, v_old, v_display, v_base_first, v_last)
    );

  -- d. Les anciens noms ne désignent plus personne.
  delete from public.historical_player_name_links
  where player_id = p_player_id and normalized_name <> v_new_norm;
  delete from public.player_aliases
  where player_id = p_player_id
    and private.normalize_player_name(alias) <> v_new_norm;

  -- Trace sans l'ancien nom.
  insert into private.sport_admin_audit_log (actor_profile_id, action, metadata)
  values (
    (select private.uid()),
    'rename_former_player',
    jsonb_build_object('player_id', p_player_id, 'mode', p_mode)
  );

  return v_display;
end;
$$;

revoke all on function private.rename_player_everywhere(uuid, text) from public, anon, authenticated;
grant execute on function private.rename_player_everywhere(uuid, text) to club_scope;

-- Pour les administrateurs : un ancien joueur (sans compte actif) de leur club.
create function public.admin_rename_former_player(p_player_id uuid, p_mode text)
returns jsonb
language plpgsql security definer
set search_path to ''
as $$
begin
  if not (select private.is_admin()) or not (select private.is_active_profile()) then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;
  if exists (
    select 1
    from public.season_players season_player
    join public.profiles profile on profile.id = season_player.profile_id
    where season_player.player_id = p_player_id
      and profile.status = 'active'
  ) or exists (
    select 1 from public.profiles profile
    where profile.player_id = p_player_id and profile.status = 'active'
  ) then
    raise exception 'Ce joueur a encore un compte actif : il peut changer son nom depuis son profil.'
      using errcode = '22023';
  end if;

  return jsonb_build_object(
    'display_name', private.rename_player_everywhere(p_player_id, p_mode)
  );
end;
$$;

-- Appartient à club_scope : ne peut modifier que le club de l'administrateur.
alter function public.admin_rename_former_player(uuid, text) owner to club_scope;
revoke all on function public.admin_rename_former_player(uuid, text) from public, anon;
grant execute on function public.admin_rename_former_player(uuid, text) to authenticated;
