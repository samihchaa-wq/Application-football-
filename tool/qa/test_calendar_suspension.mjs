// Execute the actual handler with fake data; no network or production keys.
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import vm from 'node:vm';
import assert from 'node:assert/strict';
const source = readFileSync('supabase/functions/calendar-feed/index.ts', 'utf8')
  .replace(/^import .*;\n/gm, '');
for (const method of ['GET', 'HEAD']) {
  for (const navigation of [false, true]) {
    for (const status of ['active', 'suspended']) {
      let handler;
      let matchReads = 0;
      const subscription = { profile_id: 'fake-profile', club_id: 'fake-club',
        profiles: { status: 'active' }, clubs: { name: 'QA', status } };
      const client = { from(table) {
        const filters = [];
        const query = {
          select() { return query; },
          eq(key, value) { filters.push([key, value]); return query; },
          async maybeSingle() {
            const visible = filters.every(([key, value]) => key === 'token' ||
              key === 'profiles.status' && value === subscription.profiles.status ||
              key === 'clubs.status' && value === subscription.clubs.status);
            return { data: visible ? subscription : null, error: null };
          },
          async order() {
            assert.equal(table, 'matches');
            assert.ok(filters.some(([key, value]) => key === 'club_id' && value === subscription.club_id));
            matchReads++;
            return { data: [], error: null };
          },
        };
        return query;
      } };
      const context = { Request, Response, URL, URLSearchParams, console,
        createClient: () => client,
        Deno: { env: { get: () => 'https://example.invalid' }, serve: fn => { handler = fn; } } };
      vm.runInNewContext(stripTypeScriptTypes(source), context);
      const response = await handler(new Request(
        'https://example.invalid?token=00000000-0000-4000-8000-000000000001',
        { method, headers: navigation ? { 'sec-fetch-mode': 'navigate' } : {} }));
      assert.equal(response.status, status === 'suspended' ? 404 : navigation ? 302 : 200,
        `${method} navigation=${navigation} club=${status}`);
      assert.equal(matchReads, status === 'active' && !navigation ? 1 : 0);
      if (status === 'suspended') assert.equal(response.headers.get('location'), null);
    }
  }
}
console.log('PASS: 8 handler cases: active/suspended club, GET/HEAD, calendar/browser; no network');
