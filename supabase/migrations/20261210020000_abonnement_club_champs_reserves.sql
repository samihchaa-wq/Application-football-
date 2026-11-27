-- Abonnement d'un club : la note interne et les identifiants Stripe ne sont
-- plus lisibles par l'administrateur du club.
--
-- Avant : la politique club_subscriptions_admin_read et le droit SELECT sur
-- toute la table laissaient l'administrateur d'un club lire, par l'API, la
-- note interne de l'éditeur (par exemple « ne pas facturer ni suspendre ») et
-- les identifiants client et abonnement Stripe.
--
-- Maintenant : le rôle authenticated ne garde le droit de lecture que sur les
-- colonnes utiles au club. notes, stripe_customer_id et stripe_subscription_id
-- restent lisibles par l'éditeur (fonctions platform_*, propriétaires
-- postgres ou club_scope) et par les fonctions serveur (service_role).
--
-- L'appli lit l'abonnement par admin_get_club_subscription(), qui ne renvoie
-- déjà aucun de ces trois champs : rien ne change à l'écran.
--
-- Les droits sont posés colonne par colonne à partir du schéma réel, pour
-- qu'une colonne ajoutée plus tard reste fermée tant qu'on ne l'ouvre pas.

revoke select on public.club_subscriptions from authenticated;

do $$
declare
  v_columns text;
begin
  select string_agg(quote_ident(column_name), ', ' order by ordinal_position)
  into v_columns
  from information_schema.columns
  where table_schema = 'public'
    and table_name = 'club_subscriptions'
    and column_name not in ('notes', 'stripe_customer_id', 'stripe_subscription_id');

  execute format(
    'grant select (%s) on public.club_subscriptions to authenticated',
    v_columns
  );
end;
$$;

-- Paiement par carte d'un club qui n'a rien à payer : message selon le cas.
--
-- Avant : tout club sans montant dû recevait « Rien à payer : active ton
-- année offerte », y compris un club déjà réglé pour plusieurs années.
-- Maintenant :
--   - parrainage à 100 % : « Rien à payer : active ton année offerte. »
--   - abonnement actif et payé : « Ton abonnement est déjà réglé jusqu'au
--     JJ/MM/AAAA. » (date à l'heure de Paris) ;
--   - sinon : « Rien à payer pour ton club : contacte l'éditeur. »
-- Le code d'erreur (22023) ne change pas. Reprise de 20261206010000 pour le
-- reste. CREATE OR REPLACE conserve propriétaire, droits et search_path.

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
    if v_discount >= 100 then
      raise exception 'Rien à payer : active ton année offerte.' using errcode = '22023';
    elsif v_sub.status = 'active' and v_sub.current_period_end > now() then
      raise exception 'Ton abonnement est déjà réglé jusqu''au %.',
        pg_catalog.to_char(v_sub.current_period_end at time zone 'Europe/Paris', 'DD/MM/YYYY')
        using errcode = '22023';
    else
      raise exception 'Rien à payer pour ton club : contacte l''éditeur.' using errcode = '22023';
    end if;
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
