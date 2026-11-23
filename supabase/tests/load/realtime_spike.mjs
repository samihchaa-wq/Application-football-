// Temps réel : N clients ouvrent un canal en même temps sur Realtime LOCAL.
// Usage : node realtime_spike.mjs <ws-url> <anon-key> [clients]
const [url, key, n = "500"] = process.argv.slice(2);
if (!/^wss?:\/\/(127\.0\.0\.1|localhost)[:/]/.test(url ?? "")) {
  console.error("Refus : Realtime local uniquement."); process.exit(2);
}
const N = Number(n); let ok = 0, fail = 0; const t0 = Date.now(); const lat = [];
await Promise.all(Array.from({ length: N }, (_, i) => new Promise((res) => {
  const s = Date.now();
  const ws = new WebSocket(`${url}?apikey=${key}&vsn=1.0.0`);
  const done = (good) => { good ? ok++ : fail++; try { ws.close(); } catch {} res(); };
  const timer = setTimeout(() => done(false), 15000);
  ws.onopen = () => ws.send(JSON.stringify({ topic: `realtime:spike-${i % 50}`, event: "phx_join",
    payload: { config: { broadcast: { self: true }, presence: { key: "" } } }, ref: "1" }));
  ws.onmessage = (m) => { const d = JSON.parse(m.data);
    if (d.event === "phx_reply" && d.payload?.status === "ok") { clearTimeout(timer); lat.push(Date.now() - s); done(true); } };
  ws.onerror = () => { clearTimeout(timer); done(false); };
})));
lat.sort((a, b) => a - b);
console.log(`Realtime : ${ok}/${N} connectés, ${fail} échecs, p95 ${lat[Math.floor(lat.length * .95)] ?? "-"} ms, total ${Date.now() - t0} ms`);
process.exit(fail > N * 0.01 ? 1 : 0);
