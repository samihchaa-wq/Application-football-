-- Petit Filet : retirer le nom d'un membre du staff d'AS Grinta codé en dur.
--
-- La copie initiale a gardé une fonction qui écartait un nom précis des
-- statistiques historiques (un membre du staff de l'ancien club). Dans une
-- base partagée par plusieurs clubs, un joueur portant ce nom dans un autre
-- club aurait été exclu de ses propres statistiques historiques, et le nom
-- d'une personne réelle restait inscrit dans la base.
--
-- La fonction est conservée (elle est appelée par la résolution des noms
-- historiques) mais ne reconnaît plus aucun nom. Aucune donnée n'est modifiée.

create or replace function private.is_known_non_player_archive_name(p_name text)
returns boolean
language sql
immutable
strict
set search_path to ''
as $$
  select false;
$$;

-- Propriétaire et droits inchangés : « create or replace » garde ceux de la
-- fonction existante (les fonctions serveur appartiennent au rôle club_scope).
