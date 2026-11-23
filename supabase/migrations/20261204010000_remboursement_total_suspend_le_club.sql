-- Remboursement total d'un paiement : le club est suspendu tout de suite
-- (décision du propriétaire, 23/11/2026, KYKY_QUESTIONS Q5, option B).
--
-- Avant : après un remboursement total, le club restait « actif » jusqu'à
-- l'échéance ; seul un avoir était émis. Désormais, si le paiement
-- intégralement remboursé est le DERNIER paiement du club, l'abonnement
-- s'arrête (statut « canceled », échéance ramenée à maintenant) et le club
-- est suspendu.
--
-- Choix de sécurité : suspension « à la main » (auto_suspended_at vide). Elle
-- n'entre donc PAS dans la purge des données des clubs impayés, et un
-- nouveau paiement ne la lève pas tout seul : l'éditeur rouvre le club
-- depuis le Gestionnaire (Autoriser l'accès).
-- Un remboursement partiel, ou celui d'un ancien paiement, ne suspend rien.

create or replace function private.apply_refund(
  p_payment_id uuid,
  p_amount_cents integer,
  p_method text,
  p_reason text,
  p_stripe_refund_id text,
  p_recorded_by uuid
) returns jsonb
language plpgsql security definer
set search_path to ''
as $$
declare
  v_payment public.club_payments;
  v_existing private.club_refunds;
  v_id uuid;
  v_note text;
  v_suspended boolean := false;
begin
  if p_stripe_refund_id is not null then
    select * into v_existing from private.club_refunds
    where stripe_refund_id = p_stripe_refund_id;
    if found then
      return jsonb_build_object('refund_id', v_existing.id, 'already_recorded', true,
        'credit_note_number', v_existing.credit_note_number);
    end if;
  end if;

  select * into v_payment from public.club_payments where id = p_payment_id for update;
  if not found then
    raise exception 'Paiement inconnu.' using errcode = 'P0002';
  end if;
  if p_amount_cents is null or p_amount_cents < 1
     or p_amount_cents > v_payment.amount_cents - v_payment.refunded_cents then
    raise exception 'Montant à rembourser invalide (au plus % centimes).',
      v_payment.amount_cents - v_payment.refunded_cents using errcode = '22023';
  end if;
  if p_method is null or p_method not in ('carte', 'virement', 'cheque', 'especes', 'autre') then
    raise exception 'Moyen de remboursement invalide.' using errcode = '22023';
  end if;
  if p_reason is not null and char_length(p_reason) > 300 then
    raise exception 'Motif trop long (300 caractères au plus).' using errcode = '22023';
  end if;

  insert into private.club_refunds (
    club_id, payment_id, invoice_id, amount_cents, method, reason,
    stripe_refund_id, recorded_by
  ) values (
    v_payment.club_id, v_payment.id,
    (select id from public.club_invoices where payment_id = v_payment.id limit 1),
    p_amount_cents, p_method, nullif(btrim(coalesce(p_reason, '')), ''),
    p_stripe_refund_id, p_recorded_by
  )
  returning id into v_id;

  update public.club_payments
  set refunded_cents = refunded_cents + p_amount_cents
  where id = v_payment.id;

  v_note := private.issue_credit_note(v_id);

  -- Remboursement total du dernier paiement : l'abonnement s'arrête.
  if v_payment.refunded_cents + p_amount_cents = v_payment.amount_cents
     and v_payment.amount_cents > 0
     and not exists (
       select 1 from public.club_payments other
       where other.club_id = v_payment.club_id
         and other.id <> v_payment.id
         and (other.created_at, other.id) > (v_payment.created_at, v_payment.id)
     ) then
    update public.clubs set status = 'suspended' where id = v_payment.club_id;
    update public.club_subscriptions
    set status = 'canceled',
        current_period_end = least(current_period_end, now()),
        auto_suspended_at = null,
        updated_at = now()
    where club_id = v_payment.club_id;
    v_suspended := true;
  end if;

  return jsonb_build_object('refund_id', v_id, 'already_recorded', false,
    'credit_note_number', v_note, 'club_suspended', v_suspended);
end;
$$;

alter function private.apply_refund(uuid, integer, text, text, text, uuid) owner to postgres;
revoke all on function private.apply_refund(uuid, integer, text, text, text, uuid)
  from public, anon, authenticated;
