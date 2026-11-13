-- Un compte administrateur actif ne suffit pas : son club doit aussi être
-- actif. Le profil et l'état du club sont relus en base, jamais depuis des
-- métadonnées JWT. Ce prédicat est partagé par les RPC et manage-user.
-- CREATE OR REPLACE conserve propriétaires et ACL ; aucune ancienne
-- migration, politique de cloisonnement ni donnée métier n'est modifiée.
create or replace function private.is_admin() returns boolean
language sql stable security definer
set search_path to ''
as $$
  select private.is_active_profile()
    and exists (
      select 1
      from public.profiles profile
      where profile.id = (select private.uid())
        and profile.role = 'admin'
    );
$$;

-- Les images, textes et seuils de badges utilisent la même autorisation.
-- Conserver l'accès des traitements techniques authentifiés en service_role.
create or replace function private.can_manage_badges() returns boolean
language sql stable security definer
set search_path to ''
as $$
  select coalesce(private.jwt() ->> 'role' = 'service_role', false)
    or private.is_admin();
$$;

-- Alias conservé pour les anciens clients, avec exactement les mêmes droits
-- que les autres chemins d'administration (aucun retour du rôle modérateur).
create or replace function public.is_moderator() returns boolean
language sql stable security definer
set search_path to ''
as $$
  select private.is_admin();
$$;

-- Exceptions intentionnelles, inchangées : get_my_club_access permet de
-- comprendre la suspension ; export_my_data reste limité à auth.uid() ;
-- l'effacement personnel passe par manage-user après validation du JWT.
-- La réactivation reste réservée aux opérateurs de la plateforme.
