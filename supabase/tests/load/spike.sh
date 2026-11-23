#!/usr/bin/env bash
# Pic de connexions : tout le monde ouvre l'appli en même temps (ex. après une
# notification). Chaque transaction ouvre sa propre connexion (pgbench -C).
# Usage : spike.sh [clubs] [membres] [clients]
set -euo pipefail
CLUBS="${1:-50}"; MEMBERS="${2:-30}"; CLIENTS="${3:-300}"
DB_URL="${DB_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
HERE="$(cd "$(dirname "$0")" && pwd)"
if [[ ! "$DB_URL" =~ ^postgres(ql)?://[^@/]+@(127\.0\.0\.1|localhost|\[::1\]):[0-9]+/[^/?#]+$ ]]; then
  echo "Refus : base locale uniquement." >&2; exit 2
fi
psql "$DB_URL" -v ON_ERROR_STOP=1 -q -v clubs="$CLUBS" -v members="$MEMBERS" -v matches=5 -f "$HERE/seed.sql"
echo "### Pic de connexions : ${CLIENTS} ouvertures simultanées, une connexion chacune"
psql "$DB_URL" -At -c "show max_connections"
R="$(mktemp)"; trap 'rm -f "$R"' EXIT
pgbench "$DB_URL" -n -C -c "$CLIENTS" -j 4 -T 30 -D users=$((CLUBS*MEMBERS)) \
  -f "$HERE/read.pgbench" -r --failures-detailed 2>&1 | sed '/^progress/d' | tee "$R"
python3 "$HERE/check_pgbench_report.py" "$R" "pic de connexions"
