-- Couper les notifications sur un appareil échouait toujours.
--
-- L'appli supprimait la ligne de public.push_subscriptions directement
-- (delete … where endpoint = …). Le rôle authenticated a le droit DELETE sur
-- la table, mais pas SELECT : or un DELETE filtré doit lire la colonne
-- endpoint, et Postgres le refuse (42501). Le joueur voyait « Impossible de
-- désactiver les notifications », son choix n'était pas retenu, et la même
-- erreur remontait à chaque déconnexion (auth.sign_out.push_unsubscribe).
--
-- Plutôt que d'ouvrir la lecture de la table (clés de chiffrement des
-- appareils), une fonction supprime l'abonnement du demandeur, comme
-- register_push_subscription l'enregistre.

create or replace function public.unregister_push_subscription(p_endpoint text)
returns integer
language plpgsql security definer
set search_path to ''
as $$
declare
  v_actor uuid := (select private.uid());
  v_count integer;
begin
  if v_actor is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  -- Rien à supprimer : pas une erreur (le navigateur n'avait plus de point
  -- d'envoi, ou la ligne a déjà été retirée).
  if btrim(coalesce(p_endpoint, '')) = '' or length(p_endpoint) > 2048 then
    return 0;
  end if;

  -- Uniquement la ligne du demandeur : un point d'envoi passé à un autre
  -- compte (téléphone partagé) reste à ce compte. Pas d'exigence de profil
  -- actif : un compte suspendu doit pouvoir couper son téléphone.
  delete from public.push_subscriptions subscription
  where subscription.endpoint = p_endpoint
    and subscription.profile_id = v_actor;
  get diagnostics v_count = row_count;

  return v_count;
end;
$$;

-- Soumise au cloisonnement par club, comme les autres fonctions privilégiées.
alter function public.unregister_push_subscription(text) owner to club_scope;

comment on function public.unregister_push_subscription(text) is
  'Supprime l''abonnement aux notifications du compte connecté pour ce point d''envoi et rend le nombre de lignes retirées (0 ou 1).';

revoke all on function public.unregister_push_subscription(text) from public, anon;
grant all on function public.unregister_push_subscription(text) to service_role;
grant all on function public.unregister_push_subscription(text) to authenticated;
