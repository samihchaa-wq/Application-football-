-- Données personnelles : acceptation des conditions, âge, export.
--
-- 1. Chaque compte garde la version des CGU et de la politique de
--    confidentialité qu'il a acceptée, la date, et sa déclaration d'âge
--    (15 ans ou plus, ou accord d'un parent pour un moins de 15 ans, comme
--    l'exige la loi française).
-- 2. Chaque membre peut télécharger ses données (droit d'accès et à la
--    portabilité du RGPD) sans passer par un administrateur.
-- La suppression de son propre compte passe par la fonction manage-user.

alter table public.profiles
  add column terms_version text,
  add column terms_accepted_at timestamptz,
  add column age_confirmation text
    constraint profiles_age_confirmation_check
      check (age_confirmation in ('15_or_more', 'parental_consent'));

comment on column public.profiles.terms_version is
  'Version des CGU et de la politique de confidentialité acceptée.';
comment on column public.profiles.age_confirmation is
  '15_or_more : a déclaré avoir 15 ans ou plus ; parental_consent : moins de 15 ans avec accord d''un parent.';

-- Acceptation (ou nouvelle acceptation après un changement des textes) par
-- le membre connecté.
create function public.accept_terms(p_version text, p_age_confirmation text)
returns void
language plpgsql security definer
set search_path to ''
as $$
declare
  v_version text := btrim(coalesce(p_version, ''));
begin
  if private.uid() is null then
    raise exception 'Connexion requise.' using errcode = '42501';
  end if;
  if v_version !~ '^\d{4}-\d{2}-\d{2}$' then
    raise exception 'Version des conditions invalide.' using errcode = '22023';
  end if;
  if p_age_confirmation not in ('15_or_more', 'parental_consent') then
    raise exception 'Indique ton âge ou l''accord d''un parent.' using errcode = '22023';
  end if;

  update public.profiles
  set terms_version = v_version,
      terms_accepted_at = now(),
      age_confirmation = p_age_confirmation,
      updated_at = now()
  where id = private.uid();
end;
$$;

alter function public.accept_terms(text, text) owner to club_scope;
revoke all on function public.accept_terms(text, text) from public, anon;
grant execute on function public.accept_terms(text, text) to authenticated;

-- Toutes les données rattachées au membre connecté, dans un fichier lisible
-- par un autre service. Les secrets techniques (clés de notification) sont
-- exclus. Appartient à club_scope : ne lit que le club du membre.
create function public.export_my_data() returns jsonb
language plpgsql stable security definer
set search_path to ''
as $$
declare
  v_uid uuid := private.uid();
  v_table record;
  v_rows jsonb;
  v_result jsonb;
  -- Colonnes jamais exportées : secrets des abonnements de notification.
  v_hidden text[] := array['p256dh', 'auth', 'endpoint', 'token', 'token_hash'];
begin
  if v_uid is null then
    raise exception 'Connexion requise.' using errcode = '42501';
  end if;

  v_result := jsonb_build_object(
    'exported_at', now(),
    'format', 'Export des données personnelles, version 1',
    'club', (select to_jsonb(club) - 'invite_code' from public.clubs club
             where club.id = private.current_club_id()),
    'profile', (select to_jsonb(profile) from public.profiles profile
                where profile.id = v_uid)
  );

  -- Chaque table du schéma public qui rattache une ligne à un profil.
  for v_table in
    select c.table_name, c.column_name
    from information_schema.columns c
    join information_schema.tables t
      on t.table_schema = c.table_schema and t.table_name = c.table_name
    where c.table_schema = 'public'
      and t.table_type = 'BASE TABLE'
      and c.column_name in ('profile_id', 'voter_profile_id')
      and c.table_name <> 'profiles'
    order by c.table_name
  loop
    execute format(
      'select coalesce(jsonb_agg(to_jsonb(row_data) - $2), ''[]''::jsonb) '
      'from public.%I row_data where row_data.%I = $1',
      v_table.table_name, v_table.column_name
    )
    into v_rows
    using v_uid, v_hidden;

    if jsonb_array_length(v_rows) > 0 then
      v_result := v_result || jsonb_build_object(v_table.table_name, v_rows);
    end if;
  end loop;

  -- Absences déclarées et historique des notifications.
  v_result := v_result || jsonb_build_object(
    'notification_history',
    coalesce((select jsonb_agg(to_jsonb(history))
              from private.notification_history history
              where history.profile_id = v_uid), '[]'::jsonb)
  );

  return v_result;
end;
$$;

alter function public.export_my_data() owner to club_scope;
revoke all on function public.export_my_data() from public, anon;
grant execute on function public.export_my_data() to authenticated;
