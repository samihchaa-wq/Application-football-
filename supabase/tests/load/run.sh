#!/usr/bin/env bash
# Test de charge sur une base Supabase locale et éphémère.
# Usage : run.sh [clubs] [membres] [matchs] [clients] [secondes]
set -euo pipefail

CLUBS="${1:-500}"
MEMBERS="${2:-30}"
MATCHES="${3:-20}"
CLIENTS="${4:-50}"
SECONDS_PER_RUN="${5:-60}"
DB_URL="${DB_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
HERE="$(cd "$(dirname "$0")" && pwd)"
USERS=$((CLUBS * MEMBERS))

# Refuser toute base distante : ce script charge des milliers de données fictives.
# La base de test Supabase est locale (port 54322 par défaut).
if [[ ! "$DB_URL" =~ ^postgres(ql)?://[^@/]+@(127\.0\.0\.1|localhost|\[::1\]):[0-9]+/[^/?#]+$ ]]; then
  echo "Refus : le test de charge exige une base PostgreSQL sur localhost." >&2
  exit 2
fi

echo "## Test de charge : ${CLUBS} clubs, ${USERS} comptes, ${CLIENTS} connexions simultanées"
echo

start=$(date +%s)
psql "$DB_URL" -v ON_ERROR_STOP=1 -q \
  -v clubs="$CLUBS" -v members="$MEMBERS" -v matches="$MATCHES" \
  -f "$HERE/seed.sql"
echo "Données créées en $(( $(date +%s) - start )) s."
echo

echo "### Cloisonnement à grande échelle"
PGOPTIONS="-c loadtest.members=${MEMBERS} -c loadtest.matches=${MATCHES}" \
  psql "$DB_URL" -v ON_ERROR_STOP=1 -q -f "$HERE/isolation_check.sql" 2>&1
echo

echo "### Tâches planifiées (durée d'un passage, tous clubs confondus)"
# Chaque tâche est lancée seule, limitée à 120 s : une tâche trop lente est
# signalée au lieu de bloquer tout le test.
psql "$DB_URL" -q -c "create table if not exists loadtest.cron_timing (job text, schedule text, ms numeric, error text)"
psql "$DB_URL" -At -c "select jobname from cron.job where jobname not like 'purge-%' order by jobname" |
while read -r job; do
  [ -z "$job" ] && continue
  PGOPTIONS="-c statement_timeout=120000" psql "$DB_URL" -q -At -v job="$job" -f "$HERE/cron_timing.sql" 2>&1 || true
done
psql "$DB_URL" -q -f "$HERE/cron_summary.sql"
echo

# Les tests de charge ne peuvent pas passer avec zéro transaction ou des
# échecs métier seulement parce que pgbench retourne 0.
READ_REPORT="$(mktemp)"
WRITE_REPORT="$(mktemp)"
trap 'rm -f "$READ_REPORT" "$WRITE_REPORT"' EXIT

echo "### Lecture : ouverture de l'appli par des membres au hasard"
pgbench "$DB_URL" -n -c "$CLIENTS" -j 4 -T "$SECONDS_PER_RUN" -P 15 \
  -D users="$USERS" -f "$HERE/read.pgbench" -r --failures-detailed 2>&1 \
  | sed '/^progress/d' | tee "$READ_REPORT"
python3 "$HERE/check_pgbench_report.py" "$READ_REPORT" "lecture"
echo

echo "### Écriture : saisie de buts simultanée dans les Lives"
pgbench "$DB_URL" -n -c "$CLIENTS" -j 4 -T "$SECONDS_PER_RUN" -P 15 \
  -D clubs="$CLUBS" -f "$HERE/write.pgbench" -r --failures-detailed 2>&1 \
  | sed '/^progress/d' | tee "$WRITE_REPORT"
python3 "$HERE/check_pgbench_report.py" "$WRITE_REPORT" "écriture"
echo

echo "### Taille de la base"
psql "$DB_URL" -q -c "select pg_size_pretty(pg_database_size(current_database())) as taille_base"
