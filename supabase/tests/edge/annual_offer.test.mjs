import { test } from 'node:test';
import assert from 'node:assert/strict';
import { quoteAnnualOffer } from '../../functions/_shared/annual_offer.ts';

// Entirely synthetic identifiers. No customer, code, payment or credentials.
const credit = (n, overrides = {}) => ({
  id: `credit-${n}`, sponsorTeamId: 'team-a', referredTeamId: `team-${n}`,
  status: 'validated', annualPaymentSucceeded: true, paidAmountCents: 7900,
  targetRenewalId: 'renewal-1', consumedRenewalId: null, ...overrides,
});
const promo = (overrides = {}) => ({
  id: 'promo-synthetic', kind: 'half_price', status: 'active',
  eligibleTeamId: 'team-a', eligibleAnnualPeriodId: 'renewal-1', ...overrides,
});
const input = (overrides = {}) => ({
  teamId: 'team-a', annualPeriodId: 'renewal-1', periodKind: 'renewal',
  referralCredits: [], promotion: null, ...overrides,
});

for (const [count, percent, amount] of [
  [0, 0, 7900], [1, 5, 7505], [2, 10, 7110],
  [9, 45, 4345], [10, 50, 3950], [11, 50, 3950],
]) {
  test(`${count} distinct paid teams: ${percent}% and ${amount} cents`, () => {
    const result = quoteAnnualOffer(input({
      referralCredits: Array.from({ length: count }, (_, n) => credit(n)),
    }));
    assert.equal(result.discountPercent, percent);
    assert.equal(result.amountDueCents, amount);
    assert.equal(result.eligibleReferralCount, count);
    assert.equal(result.referralCreditsToConsume.length, count);
    assert.equal(result.currency, 'EUR');
  });
}

test('initial subscription never spends referral rewards', () => {
  const result = quoteAnnualOffer(input({ periodKind: 'initial', referralCredits: [credit(1)] }));
  assert.equal(result.amountDueCents, 7900);
  assert.deepEqual(result.referralCreditsToConsume, []);
});

for (const overrides of [
  { status: 'pending' }, { status: 'reversed' },
  { annualPaymentSucceeded: false }, { paidAmountCents: 0 },
  { targetRenewalId: 'renewal-2' }, { consumedRenewalId: 'renewal-1' },
]) {
  test(`ineligible referral: ${JSON.stringify(overrides)}`, () => {
    assert.equal(quoteAnnualOffer(input({ referralCredits: [credit(1, overrides)] })).amountDueCents, 7900);
  });
}

test('does not automatically repeat a reward on the following year', () => {
  const result = quoteAnnualOffer(input({ annualPeriodId: 'renewal-2', referralCredits: [credit(1)] }));
  assert.equal(result.discountPercent, 0);
});

test('half-price wins over 45%; no stacking or referral consumption', () => {
  const result = quoteAnnualOffer(input({
    promotion: promo(), referralCredits: Array.from({ length: 9 }, (_, n) => credit(n)),
  }));
  assert.equal(result.amountDueCents, 3950);
  assert.equal(result.source, 'promotion');
  assert.equal(result.promotionToConsume, 'promo-synthetic');
  assert.deepEqual(result.referralCreditsToConsume, []);
});

test('equal offers preserve the single-use promo', () => {
  const result = quoteAnnualOffer(input({
    promotion: promo(), referralCredits: Array.from({ length: 10 }, (_, n) => credit(n)),
  }));
  assert.equal(result.source, 'referral');
  assert.equal(result.amountDueCents, 3950);
  assert.equal(result.promotionToConsume, null);
  assert.equal(result.referralCreditsToConsume.length, 10);
});

for (const periodKind of ['initial', 'renewal']) {
  test(`one free annual period on ${periodKind}`, () => {
    const result = quoteAnnualOffer(input({
      periodKind, promotion: promo({ kind: 'free_year' }), referralCredits: [credit(1)],
    }));
    assert.equal(result.amountDueCents, 0);
    assert.equal(result.discountPercent, 100);
    assert.equal(result.source, 'promotion');
    assert.deepEqual(result.referralCreditsToConsume, []);
  });
}

for (const overrides of [
  { status: 'consumed' }, { status: 'disabled' },
  { eligibleTeamId: 'team-b' }, { eligibleAnnualPeriodId: 'renewal-2' },
  { kind: 'unexpected' }, { status: 'unexpected' },
]) {
  test(`reject unavailable promo, never silently quote full price: ${JSON.stringify(overrides)}`, () => {
    assert.throws(() => quoteAnnualOffer(input({ promotion: promo(overrides) })), TypeError);
  });
}

test('reject self-referral and another team ledger', () => {
  for (const overrides of [{ referredTeamId: 'team-a' }, { sponsorTeamId: 'team-b' }]) {
    assert.throws(() => quoteAnnualOffer(input({ referralCredits: [credit(1, overrides)] })), TypeError);
  }
});

test('reject duplicate credits or teams instead of double counting', () => {
  for (const credits of [
    [credit(1), credit(1)],
    [credit(1), credit(2, { referredTeamId: 'team-1' })],
    [credit(1), credit(1, { status: 'reversed' })],
  ]) assert.throws(() => quoteAnnualOffer(input({ referralCredits: credits })), TypeError);
});

test('reject malformed ledger money and states', () => {
  for (const overrides of [
    { paidAmountCents: -1 }, { paidAmountCents: 0.5 }, { paidAmountCents: NaN },
    { paidAmountCents: Infinity }, { paidAmountCents: Number.MAX_SAFE_INTEGER + 1 },
    { paidAmountCents: '7900' }, { annualPaymentSucceeded: 'true' },
    { status: 'paid' }, { id: '' }, { consumedRenewalId: '' },
  ]) assert.throws(() => quoteAnnualOffer(input({ referralCredits: [credit(1, overrides)] })), TypeError);
});

test('reject malformed billing period', () => {
  for (const overrides of [
    { teamId: '' }, { annualPeriodId: ' ' }, { periodKind: 'monthly' },
    { referralCredits: null }, { promotion: promo({ id: '' }) },
  ]) assert.throws(() => quoteAnnualOffer(input(overrides)), TypeError);
});

test('quoting is repeatable, order independent and changes no ledger state', () => {
  const data = input({ referralCredits: [credit(2), credit(1)], promotion: promo() });
  const snapshot = structuredClone(data);
  Object.freeze(data);
  Object.freeze(data.referralCredits);
  data.referralCredits.forEach(Object.freeze);
  Object.freeze(data.promotion);
  const quote = quoteAnnualOffer(data);
  assert.deepEqual(quoteAnnualOffer(data), quote);
  assert.deepEqual(quoteAnnualOffer({ ...data, referralCredits: [...data.referralCredits].reverse() }), quote);
  assert.deepEqual(data, snapshot);
});

test('all counts from 0 to 100 stay integral, nonnegative and capped', () => {
  for (let n = 0; n <= 100; n++) {
    const data = input({ referralCredits: Array.from({ length: n }, (_, i) => credit(i)) });
    for (const promotion of [null, promo(), promo({ kind: 'free_year' })]) {
      const result = quoteAnnualOffer({ ...data, promotion });
      assert(Number.isSafeInteger(result.amountDueCents));
      assert(result.amountDueCents >= 0 && result.amountDueCents <= 7900);
      assert(result.referralDiscountPercent <= 50);
      assert.equal(result.referenceAmountCents - result.amountDueCents, result.discountPercent * 79);
    }
  }
});
