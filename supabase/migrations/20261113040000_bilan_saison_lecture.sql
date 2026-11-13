-- Bilan de fin de saison : la règle de lecture de la table appelait une
-- fonction que les joueurs connectés n'ont pas le droit d'exécuter. Toute
-- lecture directe de la table par un joueur échouait donc avec « permission
-- refusée ». On utilise la variante autorisée, avec le même sens.
-- Le cloisonnement par club (règle restrictive club_isolation) est inchangé.

drop policy if exists season_wrapped_read on public.season_wrapped;
create policy season_wrapped_read on public.season_wrapped
  for select to authenticated
  using (
    (select private.is_active_profile())
    and (
      profile_id = (select auth.uid())
      or (select public.is_admin())
    )
  );
