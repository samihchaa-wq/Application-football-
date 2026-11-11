-- Parcours « créer un club » et « rejoindre un club ».
--
-- L'inscription passe toujours par la fonction Edge register-account, seule à
-- détenir la clé de service. Elle rattache le compte à un club de deux façons :
-- un code d'invitation (rejoindre), ou la création d'un club dont le demandeur
-- devient le premier administrateur.

-- ---------------------------------------------------------------------------
-- 1. Le club d'un nouveau compte ne peut venir que du serveur
-- ---------------------------------------------------------------------------
-- raw_user_meta_data est modifiable par le titulaire du compte ;
-- raw_app_meta_data ne l'est que par la clé de service. Le club est donc lu
-- dans la seconde, pour qu'aucun client ne puisse choisir son club lui-même.
create or replace function public.handle_new_auth_user() returns trigger
language plpgsql security definer
set search_path to ''
as $$
declare
  v_club uuid;
begin
  begin
    v_club := nullif(new.raw_app_meta_data ->> 'club_id', '')::uuid;
  exception when invalid_text_representation then
    v_club := null;
  end;

  if tg_op = 'UPDATE' then
    -- Le service d'authentification crée le compte, puis y inscrit la zone
    -- réservée au serveur dans un second temps : le profil est créé à ce
    -- moment-là. Un profil existant ne change jamais de club par ce biais.
    if v_club is null
       or exists (select 1 from public.profiles profile where profile.id = new.id) then
      return new;
    end if;
  else
    -- À défaut, le contexte courant (installations locales et tests).
    v_club := coalesce(v_club, private.current_club_id());
    -- Sans club connu, pas de profil : le compte reste inutilisable tant que
    -- le serveur ne l'a pas rattaché à un club.
    if v_club is null then
      return new;
    end if;
  end if;

  -- Les automatismes déclenchés par la création du profil doivent écrire dans
  -- ce club, et non dans un club déduit d'ailleurs.
  perform set_config('app.club_id', v_club::text, true);

  insert into public.profiles(
    id, club_id, email, first_name, last_name, role, is_goalkeeper, status
  )
  values (
    new.id,
    v_club,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data->>'first_name', ''),
    coalesce(new.raw_user_meta_data->>'last_name', ''),
    'pronostiqueur',
    false,
    'pending'
  )
  on conflict (id) do update
  set email = excluded.email,
      first_name = case when public.profiles.first_name = '' then excluded.first_name else public.profiles.first_name end,
      last_name = case when public.profiles.last_name = '' then excluded.last_name else public.profiles.last_name end,
      updated_at = now();
  return new;
end;
$$;

create trigger on_auth_user_club_assigned
  after update of raw_app_meta_data on auth.users
  for each row
  when (new.raw_app_meta_data ? 'club_id')
  execute function public.handle_new_auth_user();

-- ---------------------------------------------------------------------------
-- 2. Retrouver un club par son code d'invitation
-- ---------------------------------------------------------------------------
create function public.club_for_invite_code(p_code text)
returns table (id uuid, name text)
language sql stable security definer
set search_path to ''
as $$
  select club.id, club.name
  from public.clubs club
  where club.invite_code = upper(btrim(coalesce(p_code, '')))
    and club.status = 'active';
$$;

alter function public.club_for_invite_code(text) owner to postgres;
revoke all on function public.club_for_invite_code(text) from public, anon, authenticated;
grant execute on function public.club_for_invite_code(text) to service_role;

-- ---------------------------------------------------------------------------
-- 3. Le créateur d'un club en devient le premier administrateur
-- ---------------------------------------------------------------------------
-- Appelée par register-account juste après la création du compte. Refuse tout
-- club qui a déjà un membre actif : elle ne peut pas servir à s'emparer d'un
-- club existant.
create function public.promote_club_founder(p_club_id uuid, p_profile_id uuid)
returns void
language plpgsql security definer
set search_path to ''
as $$
begin
  perform set_config('app.club_id', p_club_id::text, true);

  if not exists (
    select 1 from public.profiles profile
    where profile.id = p_profile_id and profile.club_id = p_club_id
  ) then
    raise exception 'Ce compte n’appartient pas à ce club.' using errcode = '22023';
  end if;

  if exists (
    select 1 from public.profiles profile
    where profile.club_id = p_club_id
      and profile.id <> p_profile_id
      and profile.status = 'active'
  ) then
    raise exception 'Ce club a déjà des membres.' using errcode = '22023';
  end if;

  update public.profiles
  set role = 'admin', status = 'active', updated_at = now()
  where id = p_profile_id and club_id = p_club_id;

  update public.clubs
  set created_by = p_profile_id
  where id = p_club_id and created_by is null;
end;
$$;

alter function public.promote_club_founder(uuid, uuid) owner to postgres;
revoke all on function public.promote_club_founder(uuid, uuid) from public, anon, authenticated;
grant execute on function public.promote_club_founder(uuid, uuid) to service_role;

-- La suppression d'un club ne doit pas être bloquée par le signal de
-- rafraîchissement des écrans, qui tentait d'écrire pour un club disparu.
create or replace function private.signal_shared_data_change() returns trigger
language plpgsql security definer
set search_path to ''
as $function$
declare
  v_profile_increment bigint := 0;
  v_sports_increment bigint := 0;
begin
  -- Pendant la suppression d'un club, ses tables se vident en cascade : il
  -- n'y a plus personne à prévenir, ni de club auquel rattacher le signal.
  if not exists (
    select 1 from public.clubs club
    where club.id = (select private.current_club_id())
  ) then
    return null;
  end if;

  if tg_table_schema = 'public' and tg_table_name = 'profiles' then
    v_profile_increment := 1;
  end if;

  if tg_table_schema = 'public' and tg_table_name = any (array[
    'guest_players',
    'match_compositions',
    'match_composition_entries',
    'match_composition_publications',
    'sport_waitlist_entries',
    'match_sport_participants',
    'match_sport_workflows'
  ]) then
    v_sports_increment := 1;
  end if;

  insert into public.shared_data_change_signals(
    key,
    revision,
    profile_revision,
    sports_revision,
    updated_at
  )
  values ('global', 1, 1, 1, now())
  on conflict (club_id, key) do update
  set revision = public.shared_data_change_signals.revision + 1,
      profile_revision =
        public.shared_data_change_signals.profile_revision
        + v_profile_increment,
      sports_revision =
        public.shared_data_change_signals.sports_revision
        + v_sports_increment,
      updated_at = excluded.updated_at;
  return null;
end;
$function$;

-- Annulation d'une création de club qui a échoué en cours de route. Ne
-- supprime qu'un club sans aucun membre actif.
create function public.discard_empty_club(p_club_id uuid)
returns void
language plpgsql security definer
set search_path to ''
as $$
begin
  perform set_config('app.club_id', p_club_id::text, true);

  if exists (
    select 1 from public.profiles profile
    where profile.club_id = p_club_id and profile.status = 'active'
  ) then
    raise exception 'Ce club a des membres : il ne peut pas être supprimé ainsi.'
      using errcode = '22023';
  end if;

  delete from public.clubs where id = p_club_id;
end;
$$;

alter function public.discard_empty_club(uuid) owner to postgres;
revoke all on function public.discard_empty_club(uuid) from public, anon, authenticated;
grant execute on function public.discard_empty_club(uuid) to service_role;

-- ---------------------------------------------------------------------------
-- 4. L'administrateur peut changer le code d'invitation de son club
-- ---------------------------------------------------------------------------
-- Utile si le code a circulé en dehors du club. Les membres déjà inscrits ne
-- sont pas touchés.
create function public.admin_regenerate_club_invite_code() returns text
language plpgsql security definer
set search_path to ''
as $$
declare
  v_code text;
begin
  if not (select private.is_admin()) then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;

  v_code := private.generate_invite_code();

  update public.clubs
  set invite_code = v_code
  where id = (select private.current_club_id());

  if not found then
    raise exception 'Club introuvable.' using errcode = 'P0002';
  end if;

  return v_code;
end;
$$;

alter function public.admin_regenerate_club_invite_code() owner to club_scope;
revoke all on function public.admin_regenerate_club_invite_code() from public, anon;
grant execute on function public.admin_regenerate_club_invite_code() to authenticated, service_role, club_scope;
grant execute on function private.generate_invite_code() to club_scope;

-- ---------------------------------------------------------------------------
-- 5. Supprimer un membre sans compte technique
-- ---------------------------------------------------------------------------
-- La suppression d'un compte réattribue ses actions passées à un compte
-- technique à identifiant fixe, qui n'existe que dans le club d'origine. Un
-- nouveau club n'en a pas : la suppression d'un membre y était impossible.
create or replace function private.prepare_profile_for_hard_deletion(p_profile_id uuid) returns void
language plpgsql security definer
set search_path to ''
as $function$
declare
  v_technical constant uuid := '00000000-0000-0000-0000-000000000001'::uuid;
  v_club uuid;
  v_system_actor uuid;
begin
  if p_profile_id is null then
    raise exception 'Profile id is required' using errcode = '22023';
  end if;
  if p_profile_id = v_technical then
    raise exception 'Technical profile cannot be deleted' using errcode = '22023';
  end if;

  select profile.club_id into v_club
  from public.profiles profile
  where profile.id = p_profile_id;

  -- Qui reprend la signature des actions passées du compte supprimé : le
  -- compte technique du club s'il existe, sinon son plus ancien
  -- administrateur actif. Jamais un compte d'un autre club.
  select profile.id into v_system_actor
  from public.profiles profile
  where profile.club_id = v_club
    and profile.id <> p_profile_id
    and (
      profile.id = v_technical
      or (profile.role = 'admin' and profile.status = 'active')
    )
  order by (profile.id = v_technical) desc, profile.created_at, profile.id
  limit 1;

  if v_system_actor is null then
    raise exception 'Technical replacement profile is missing' using errcode = '55000';
  end if;

  delete from public.sport_availability_notification_events
  where profile_id = p_profile_id;

  delete from public.match_sport_motm_votes
  where voter_profile_id = p_profile_id;

  update private.sport_admin_audit_log
  set actor_profile_id = v_system_actor
  where actor_profile_id = p_profile_id;

  update public.guest_players
  set created_by = v_system_actor
  where created_by = p_profile_id;
  update public.guest_players
  set updated_by = v_system_actor
  where updated_by = p_profile_id;

  perform set_config('as_grinta.allow_postmatch_composition_write', 'on', true);

  update public.match_composition_publications
  set published_by = v_system_actor
  where published_by = p_profile_id;

  update public.match_compositions
  set last_modified_by = v_system_actor
  where last_modified_by = p_profile_id;
  update public.match_compositions
  set published_by = v_system_actor
  where published_by = p_profile_id;

  update public.match_sport_finalization_versions
  set created_by = v_system_actor
  where created_by = p_profile_id;

  update public.match_sport_finalizations
  set validated_by = v_system_actor
  where validated_by = p_profile_id;
  update public.match_sport_finalizations
  set corrected_by = null
  where corrected_by = p_profile_id;

  update public.match_sport_workflows
  set created_by = v_system_actor
  where created_by = p_profile_id;
  update public.match_sport_workflows
  set updated_by = v_system_actor
  where updated_by = p_profile_id;

  update public.sport_waitlist_entries
  set created_by = v_system_actor
  where created_by = p_profile_id;
  update public.sport_waitlist_entries
  set updated_by = v_system_actor
  where updated_by = p_profile_id;

  -- Les deux tables oubliees : elles se remplissent des le premier Live
  -- reellement arbitre.
  update public.match_live_events
  set created_by = v_system_actor
  where created_by = p_profile_id;

  update public.match_live_sessions
  set updated_by = v_system_actor
  where updated_by = p_profile_id;
end;
$function$;
