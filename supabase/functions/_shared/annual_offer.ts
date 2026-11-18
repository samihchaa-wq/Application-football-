/** Server-side pricing policy for #161. Pure calculation, NOT a payment API.
 * All inputs must come from the private billing ledger, never a request body.
 * Eligibility, operator authorization, coupon reservation and credit consumption
 * must be checked transactionally by the future billing adapter.
 */
export const ANNUAL_TEAM_PRICE_CENTS = 7_900;
export const ANNUAL_OFFER_POLICY_VERSION = "161-v1";

export type ReferralCredit = {
  id: string;
  sponsorTeamId: string;
  referredTeamId: string;
  status: "pending" | "validated" | "reversed";
  annualPaymentSucceeded: boolean;
  paidAmountCents: number;
  targetRenewalId: string;
  consumedRenewalId: string | null;
};

export type Promotion = {
  id: string;
  kind: "free_year" | "half_price";
  status: "active" | "disabled" | "consumed";
  eligibleTeamId: string;
  eligibleAnnualPeriodId: string;
};

export type AnnualOfferInput = {
  teamId: string;
  annualPeriodId: string;
  periodKind: "initial" | "renewal";
  referralCredits: readonly ReferralCredit[];
  promotion: Promotion | null;
};

export type AnnualOffer = {
  policyVersion: string;
  teamId: string;
  annualPeriodId: string;
  currency: "EUR";
  referenceAmountCents: number;
  amountDueCents: number;
  discountPercent: number;
  eligibleReferralCount: number;
  referralDiscountPercent: number;
  source: "none" | "referral" | "promotion";
  promotionToConsume: string | null;
  referralCreditsToConsume: readonly string[];
};

function identifier(value: unknown): asserts value is string {
  if (typeof value !== "string" || value.trim().length === 0 || value.length > 200) {
    throw new TypeError("Invalid billing identifier");
  }
}

function cents(value: unknown): asserts value is number {
  if (!Number.isSafeInteger(value) || (value as number) < 0) {
    throw new TypeError("Invalid payment amount");
  }
}

/** A quote consumes nothing. IDs describe the effects to commit atomically
 * only after successful annual settlement (or explicit free-year acceptance).
 * On ties prefer referrals: a single-use promotion must not be wasted.
 * Credits are scoped to a renewal; this calculator never moves them to a later
 * period. Treatment of unused credits requires an explicit billing policy.
 */
export function quoteAnnualOffer(input: AnnualOfferInput): AnnualOffer {
  identifier(input.teamId);
  identifier(input.annualPeriodId);
  if (input.periodKind !== "initial" && input.periodKind !== "renewal") {
    throw new TypeError("Invalid annual period kind");
  }
  if (!Array.isArray(input.referralCredits)) {
    throw new TypeError("Invalid referral ledger");
  }

  const byCredit = new Map<string, ReferralCredit>();
  const byTeam = new Map<string, ReferralCredit>();
  for (const credit of input.referralCredits) {
    identifier(credit.id);
    identifier(credit.sponsorTeamId);
    identifier(credit.referredTeamId);
    identifier(credit.targetRenewalId);
    if (credit.consumedRenewalId !== null) identifier(credit.consumedRenewalId);
    cents(credit.paidAmountCents);
    if (!["pending", "validated", "reversed"].includes(credit.status) ||
      typeof credit.annualPaymentSucceeded !== "boolean") {
      throw new TypeError("Invalid referral state");
    }
    // Duplicate rows are a ledger error, not an opportunity to choose a state.
    if (byCredit.has(credit.id)) throw new TypeError("Duplicate referral credit");
    byCredit.set(credit.id, credit);
    if (credit.sponsorTeamId !== input.teamId) {
      throw new TypeError("Referral belongs to another team");
    }
    if (credit.referredTeamId === input.teamId) {
      throw new TypeError("Self referral is forbidden");
    }
    if (byTeam.has(credit.referredTeamId)) {
      throw new TypeError("Duplicate referred team");
    }
    byTeam.set(credit.referredTeamId, credit);
  }

  const eligible = [...byTeam.values()].filter((credit) =>
    input.periodKind === "renewal" &&
    credit.status === "validated" &&
    credit.annualPaymentSucceeded && credit.paidAmountCents > 0 &&
    credit.targetRenewalId === input.annualPeriodId &&
    credit.consumedRenewalId === null
  ).sort((a, b) => a.id < b.id ? -1 : a.id > b.id ? 1 : 0);
  const referralPercent = Math.min(eligible.length, 10) * 5;

  let promoPercent = 0;
  if (input.promotion !== null) {
    const promo = input.promotion;
    identifier(promo.id);
    identifier(promo.eligibleTeamId);
    identifier(promo.eligibleAnnualPeriodId);
    if (!["free_year", "half_price"].includes(promo.kind) ||
      !["active", "disabled", "consumed"].includes(promo.status)) {
      throw new TypeError("Invalid promotion state");
    }
    // A submitted but ineligible promo must never silently become a full bill.
    if (promo.status !== "active" || promo.eligibleTeamId !== input.teamId ||
      promo.eligibleAnnualPeriodId !== input.annualPeriodId) {
      throw new TypeError("Promotion unavailable");
    }
    promoPercent = promo.kind === "free_year" ? 100 : 50;
  }

  const discount = Math.max(referralPercent, promoPercent);
  const source = promoPercent > referralPercent ? "promotion" :
    referralPercent > 0 ? "referral" : "none";
  return {
    policyVersion: ANNUAL_OFFER_POLICY_VERSION,
    teamId: input.teamId,
    annualPeriodId: input.annualPeriodId,
    currency: "EUR",
    referenceAmountCents: ANNUAL_TEAM_PRICE_CENTS,
    amountDueCents: ANNUAL_TEAM_PRICE_CENTS * (100 - discount) / 100,
    discountPercent: discount,
    eligibleReferralCount: eligible.length,
    referralDiscountPercent: referralPercent,
    source,
    promotionToConsume: source === "promotion" ? input.promotion!.id : null,
    referralCreditsToConsume: source === "referral"
      ? eligible.map((credit) => credit.id) : [],
  };
}
