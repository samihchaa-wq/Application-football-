-- Paiement par carte : un appui répété ne crée plus un second paiement à régler.
--
-- Avant : chaque appel de admin_prepare_card_payment() créait une nouvelle
-- ligne private.card_checkouts, donc une nouvelle page de paiement Stripe,
-- et les anciennes restaient payables 24 h. Un administrateur qui réglait deux
-- pages de paiement ouvrait deux années d'abonnement pour deux débits.
--
-- Maintenant : un paiement encore en attente, créé il y a moins de 30 minutes,
-- pour le même club et les mêmes montant et réductions figés, est réutilisé.
-- La fonction renvoie aussi l'heure de création (created_at_epoch) : la
-- fonction stripe-checkout en déduit l'expiration de la page (création +
-- 32 minutes, donc 2 minutes après la fin de la fenêtre de réutilisation).
--
-- Un verrou par club évite que deux appels simultanés créent chacun une ligne.
-- CREATE OR REPLACE conserve propriétaire, droits et search_path.

create or replace function public.admin_prepare_card_payment()
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_club_id uuid := private.billing_admin_club_id();
  v_club public.clubs;
  v_sub public.club_subscriptions;
  v_discount integer;
  v_welcome integer;
  v_amount integer;
  v_id uuid;
  v_created_at timestamptz;
begin
  if v_club_id is null then
    raise exception 'Réservé aux administrateurs du club.' using errcode = '42501';
  end if;
  select * into v_club from public.clubs where id = v_club_id;
  select * into v_sub from public.club_subscriptions where club_id = v_club_id;
  if v_sub.status = 'canceled' then
    raise exception 'Abonnement arrêté : contacte l''éditeur.' using errcode = '22023';
  end if;

  v_discount := private.club_referral_discount_percent(v_club_id);
  v_welcome := private.club_referral_welcome_percent(v_club_id);
  v_amount := private.club_amount_due_cents(v_club_id);
  if v_amount is null or v_amount <= 0 then
    raise exception 'Rien à payer : active ton année offerte.' using errcode = '22023';
  end if;
  if v_amount < 50 then
    raise exception 'Montant trop faible pour un paiement par carte.' using errcode = '22023';
  end if;

  -- Un seul appel à la fois par club.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('card_checkout:' || v_club_id::text, 0)
  );

  select checkout.id, checkout.created_at
  into v_id, v_created_at
  from private.card_checkouts checkout
  where checkout.club_id = v_club_id
    and checkout.status = 'pending'
    and checkout.amount_cents = v_amount
    and checkout.discount_percent = v_discount
    and checkout.welcome_percent = v_welcome
    and checkout.created_at > now() - interval '30 minutes'
  order by checkout.created_at desc
  limit 1;

  if v_id is null then
    insert into private.card_checkouts (
      club_id, amount_cents, discount_percent, welcome_percent, created_by
    ) values (
      v_club_id, v_amount, v_discount, v_welcome, private.uid()
    )
    returning id, created_at into v_id, v_created_at;
  end if;

  return jsonb_build_object(
    'checkout_id', v_id,
    'club_id', v_club_id,
    'club_name', v_club.name,
    'amount_cents', v_amount,
    'discount_percent', v_discount,
    'created_at_epoch', floor(extract(epoch from v_created_at))::bigint
  );
end;
$function$;
