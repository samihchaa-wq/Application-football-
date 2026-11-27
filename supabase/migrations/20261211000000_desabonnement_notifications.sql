-- Couper les notifications d'un appareil.
--
-- Avant : l'appli supprimait la ligne avec un DELETE filtré sur `endpoint`.
-- Le rôle authenticated n'a que le droit DELETE sur push_subscriptions (pas
-- SELECT, pour ne pas exposer les clés). Postgres exige pourtant le droit de
-- lecture sur la colonne du filtre : chaque suppression était refusée (42501).
-- Résultat : « Impossible de désactiver les notifications » à chaque essai,
-- et une ligne orpheline à chaque déconnexion.
--
-- Maintenant : une fonction dédiée, qui ne supprime que l'abonnement du
-- demandeur. Pas d'exigence de profil actif : un compte suspendu doit pouvoir
-- couper ses notifications.

create or replace function public.unregister_push_subscription(p_endpoint text)
returns void
language plpgsql security definer
set search_path to ''
as $$
declare
  v_actor uuid := (select private.uid());
begin
  if v_actor is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if btrim(coalesce(p_endpoint, '')) = '' then
    return;
  end if;

  -- Uniquement la ligne du demandeur.
  delete from public.push_subscriptions subscription
  where subscription.endpoint = p_endpoint
    and subscription.profile_id = v_actor;
end;
$$;

-- Soumise au cloisonnement par club, comme les autres fonctions privilégiées.
alter function public.unregister_push_subscription(text) owner to club_scope;

comment on function public.unregister_push_subscription(text) is
  'Supprime l''abonnement aux notifications de cet appareil, seulement s''il appartient au compte connecté.';

revoke all on function public.unregister_push_subscription(text) from public, anon;
grant all on function public.unregister_push_subscription(text) to service_role;
grant all on function public.unregister_push_subscription(text) to authenticated;
