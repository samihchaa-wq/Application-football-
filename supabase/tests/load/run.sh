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
psql "$DB_URL" -v ON_ERROR_STOP=1 -q -f "$HERE/cron_timing.sql"
echo

echo "### Lecture : ouverture de l'appli par des membres au hasard"
pgbench "$DB_URL" -n -c "$CLIENTS" -j 4 -T "$SECONDS_PER_RUN" -P 15 \
  -D users="$USERS" -f "$HERE/read.pgbench" -r --failures-detailed 2>&1 \
  | grep -vE '^progress' || true
echo

echo "### Écriture : saisie de buts simultanée dans les Lives"
pgbench "$DB_URL" -n -c "$CLIENTS" -j 4 -T "$SECONDS_PER_RUN" -P 15 \
  -D clubs="$CLUBS" -f "$HERE/write.pgbench" -r --failures-detailed 2>&1 \
  | grep -vE '^progress' || true
echo

echo "### Taille de la base"
psql "$DB_URL" -q -c "select pg_size_pretty(pg_database_size(current_database())) as taille_base"
