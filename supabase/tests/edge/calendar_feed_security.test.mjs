import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import test from 'node:test';

// Execute the actual entry point without loading the external Deno/SDK imports.
// Only the SDK transport and Deno environment are replaced. No service, secret,
// database or network connection is used. This does not emulate PostgREST/RLS.
const source = readFileSync(
  new URL('../../functions/calendar-feed/index.ts', import.meta.url), 'utf8',
);
const executable = stripTypeScriptTypes(
  source.replace(/^import .*;\r?\n/gm, ''), { mode: 'strip' },
);
const TOKEN = 'c1000000-0000-4000-8000-000000000001';
const CLUB = 'c2000000-0000-4000-8000-000000000001';
const OTHER = 'c2000000-0000-4000-8000-000000000002';

function harness() {
  const state = {
    subscriptions: [{
      token: TOKEN, profile_id: 'fictional-member', club_id: CLUB,
      profiles: { status: 'active' }, clubs: { name: 'Club fictif A', status: 'active' },
    }],
    matches: [CLUB, OTHER].map((club_id, i) => ({
      id: `fictional-match-${i}`, club_id, kickoff_at: '2027-03-20T14:00:00Z',
      status: 'planifie', location: 'domicile', match_type: 'amical',
      seasons: { name: 'Saison fictive', status: 'open' },
      clubs: { name: i ? 'Club fictif B' : 'Club fictif A' },
      opponents: { name: i ? 'Adversaire privé B' : 'Adversaire A' },
    })),
    subscriptionError: null, matchError: null,
  };
  const reads = [];
  const errors = [];
  let clientCount = 0;
  let handler;
  const readPath = (row, path) => path.split('.').reduce((v, p) => v?.[p], row);
  const createClient = () => {
    clientCount++;
    return { from(table) {
      reads.push(table);
      const filters = [];
      let innerRelations = [];
      const result = () => {
        const rows = table === 'calendar_subscriptions' ? state.subscriptions : state.matches;
        return rows.filter(row => innerRelations.every(key => row[key] != null)
          && filters.every(([key, value]) => readPath(row, key) === value));
      };
      return {
        select(columns) {
          innerRelations = [...columns.matchAll(/(\w+)!inner\(/g)].map(match => match[1]);
          return this;
        },
        eq(key, value) { filters.push([key, value]); return this; },
        async maybeSingle() { return { data: result()[0] ?? null, error: state.subscriptionError }; },
        async order() { return { data: result(), error: state.matchError }; },
      };
    } };
  };
  const deno = {
    env: { get: key => ({
      SUPABASE_URL: 'https://supabase.invalid',
      SUPABASE_SERVICE_ROLE_KEY: 'fictional-key-never-used-for-network',
      PUBLIC_APP_URL: 'https://app.invalid/',
    })[key] },
    serve: callback => { handler = callback; },
  };
  new Function('Deno', 'createClient', 'console', executable)(
    deno, createClient, { error: (...args) => errors.push(args) },
  );
  assert.equal(typeof handler, 'function');
  return {
    state, reads, errors, clientCount: () => clientCount,
    request: (init = {}, token = TOKEN) => handler(new Request(
      `https://supabase.invalid/functions/v1/calendar-feed?token=${token}`, init,
    )),
  };
}

test('active club keeps its feed, stable UID, and only its own matches', async () => {
  const h = harness();
  const response = await h.request();
  assert.equal(response.status, 200);
  assert.match(response.headers.get('content-type'), /text\/calendar/);
  const body = await response.text();
  assert.match(body, /UID:fictional-match-0@sporteasy-grinta/);
  assert.match(body, /Club fictif A - Adversaire A/);
  assert.doesNotMatch(body, /fictional-match-1|Adversaire privé B/);
});

for (const status of ['suspended', 'unknown', null, undefined]) {
  test(`club status ${status} refuses access before any match read`, async () => {
    const h = harness();
    h.state.subscriptions[0].clubs.status = status;
    const response = await h.request();
    assert.equal(response.status, 404);
    assert.equal(await response.text(), 'Not found');
    assert.deepEqual(h.reads, ['calendar_subscriptions']);
  });
}

test('suspended club also refuses browser redirects and HEAD requests', async () => {
  for (const init of [{ headers: { 'sec-fetch-mode': 'navigate' } }, { method: 'HEAD' }]) {
    const h = harness();
    h.state.subscriptions[0].clubs.status = 'suspended';
    const response = await h.request(init);
    assert.equal(response.status, 404);
    assert.equal(response.headers.get('location'), null);
    assert.deepEqual(h.reads, ['calendar_subscriptions']);
  }
});

test('same token sees suspension immediately and works again after reactivation', async () => {
  const h = harness();
  assert.equal((await h.request()).status, 200);
  h.state.subscriptions[0].clubs.status = 'suspended';
  assert.equal((await h.request()).status, 404);
  h.state.subscriptions[0].clubs.status = 'active';
  assert.equal((await h.request()).status, 200);
  assert.equal(h.reads.filter(t => t === 'matches').length, 2);
});

test('inactive profile, missing club, and revoked token stay unavailable', async () => {
  for (const change of [
    h => { h.state.subscriptions[0].profiles.status = 'pending'; },
    h => { h.state.subscriptions[0].clubs = null; },
    h => { h.state.subscriptions = []; },
  ]) {
    const h = harness();
    change(h);
    assert.equal((await h.request()).status, 404);
    assert.deepEqual(h.reads, ['calendar_subscriptions']);
  }
});

test('lookup error fails closed before any match read', async () => {
  const h = harness();
  h.state.subscriptionError = { message: 'fictional lookup failure' };
  assert.equal((await h.request()).status, 500);
  assert.deepEqual(h.reads, ['calendar_subscriptions']);
  assert.equal(h.errors.length, 1);
});

test('active browser navigation preserves the subscription flow', async () => {
  const h = harness();
  const response = await h.request({ headers: { 'sec-fetch-mode': 'navigate' } });
  assert.equal(response.status, 302);
  assert.match(response.headers.get('location'), /^https:\/\/app.invalid\/abonnement-calendrier.html#/);
  assert.deepEqual(h.reads, ['calendar_subscriptions']);
});

test('active HEAD response keeps calendar headers without a body', async () => {
  const h = harness();
  const response = await h.request({ method: 'HEAD' });
  assert.equal(response.status, 200);
  assert.match(response.headers.get('content-type'), /text\/calendar/);
  assert.equal(await response.text(), '');
});

test('malformed token and disallowed method never create a privileged client', async () => {
  const h = harness();
  assert.equal((await h.request({}, 'invalid')).status, 404);
  assert.equal((await h.request({ method: 'POST' })).status, 405);
  assert.equal(h.clientCount(), 0);
  assert.deepEqual(h.reads, []);
});
