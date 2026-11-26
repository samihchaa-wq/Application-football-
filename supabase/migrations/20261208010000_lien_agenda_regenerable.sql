-- Lien d'abonnement au calendrier régénérable.
--
-- Le lien d'agenda contient un jeton aléatoire qui sert de mot de passe :
-- quiconque obtient le lien lit le calendrier du club. Il n'existait aucun
-- moyen de le changer en cas de fuite (lien partagé par erreur, téléphone
-- perdu). Cette fonction remplace le jeton du demandeur par un nouveau :
-- l'ancien lien cesse aussitôt de fonctionner.

create function public.regenerate_calendar_subscription_token()
returns uuid
language plpgsql security definer
set search_path to ''
as $$
declare
  v_profile_id uuid := private.uid();
  v_token uuid;
begin
  if v_profile_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.profiles p
    where p.id = v_profile_id
      and p.status = 'active'
  ) then
    raise exception 'Active profile required' using errcode = '42501';
  end if;

  insert into public.calendar_subscriptions(profile_id)
  values (v_profile_id)
  on conflict (profile_id) do update
    set token = pg_catalog.gen_random_uuid()
  returning token into v_token;

  return v_token;
end;
$$;

-- Soumise au cloisonnement par club, comme les autres fonctions privilégiées.
alter function public.regenerate_calendar_subscription_token() owner to club_scope;
revoke all on function public.regenerate_calendar_subscription_token() from public, anon;
grant execute on function public.regenerate_calendar_subscription_token() to authenticated, service_role;

comment on function public.regenerate_calendar_subscription_token() is
  'Remplace le jeton d''abonnement au calendrier du demandeur (profil actif exigé) ; l''ancien lien cesse de fonctionner.';
