-- Premier identifiant de connexion libre pour un nouveau compte.
--
-- Les identifiants (prénom + initiale : « thomasd ») sont uniques sur toute la
-- plateforme. Les homonymes reçoivent un numéro : « thomasd2 », « thomasd3 »…
-- Le calcul se fait ici, dans la base, en une seule requête : il ne dépend
-- d'aucune limite du nombre de lignes renvoyées à l'application et n'a pas de
-- plafond pratique (numéros jusqu'à 999 999 999).
--
-- L'unicité reste garantie par la base (adresse de connexion unique, et
-- profiles_username_key). Si deux inscriptions simultanées obtiennent le même
-- identifiant, la seconde est refusée par la base ; la fonction d'inscription
-- redemande alors un identifiant en passant celui qui vient d'échouer dans
-- `p_skip`, qui est traité comme déjà pris.
create function public.internal_next_free_username(
  p_base text,
  p_skip text[] default '{}'
)
returns text
language sql
stable
set search_path to ''
as $$
  with names as (
    select p.username as username from public.profiles p
    where p.username is not null
    union all
    select s.username from unnest(coalesce(p_skip, '{}'::text[])) as s(username)
  ),
  taken as (
    select case
             when n.username = p_base then 1
             else substring(n.username from char_length(p_base) + 1)::bigint
           end as n
    from names n
    where n.username = p_base
       or (n.username like p_base || '%'
           and substring(n.username from char_length(p_base) + 1) ~ '^[1-9][0-9]{0,8}$')
  )
  select case when candidate.n = 1 then p_base else p_base || candidate.n::text end
  from (
    select min(c.n) as n
    from (select 1::bigint as n union all select t.n + 1 from taken t) c
    where c.n not in (select t.n from taken t)
  ) candidate
  where p_base ~ '^[a-z0-9]{1,40}$';
$$;

comment on function public.internal_next_free_username(text, text[]) is
  'Premier identifiant libre (base, base2, base3…). Réservé aux fonctions serveur d''inscription.';

revoke all on function public.internal_next_free_username(text, text[]) from public, anon, authenticated;
grant execute on function public.internal_next_free_username(text, text[]) to service_role;
