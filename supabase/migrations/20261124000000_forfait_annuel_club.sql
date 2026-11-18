-- Tarif retenu par le propriétaire le 18/11/2026 : forfait de 79 € par club
-- et par an, quel que soit le nombre de joueurs.
--
-- Le calcul existant (forfait + joueurs × prix par joueur) reste inchangé :
-- le forfait passe à 79 € et le prix par joueur à 0 €. L'éditeur peut
-- toujours ajuster le tarif d'un club depuis sa console.
--
-- Seuls les clubs encore à l'ancien tarif par défaut (10 € par joueur, sans
-- forfait) sont basculés : un tarif déjà ajusté à la main n'est pas écrasé.

alter table public.club_subscriptions
  alter column price_per_player_cents set default 0,
  alter column base_price_cents set default 7900;

update public.club_subscriptions
set price_per_player_cents = 0,
    base_price_cents = 7900,
    updated_at = now()
where price_per_player_cents = 1000
  and base_price_cents = 0;

comment on table public.club_subscriptions is
  'Abonnement annuel d''un club : essai, forfait annuel (et prix par joueur facultatif), état du paiement.';
