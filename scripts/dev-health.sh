#!/usr/bin/env bash
set -Eeuo pipefail

ENV_FILE="${1:-.env.dev}"
[[ -f "$ENV_FILE" ]] || { echo "Missing $ENV_FILE" >&2; exit 1; }

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

export PHOENIX_ENV_FILE="$ENV_FILE"
PORT="${PHOENIX_HTTP_PORT:-18080}"
COMPOSE=(docker compose --project-name phoenix-dev --env-file "$ENV_FILE" -f compose.dev.yml)

printf '=== PHOENIX DEV HEALTH ===\n'
"${COMPOSE[@]}" ps

printf '\n--- PostgreSQL ---\n'
"${COMPOSE[@]}" exec -T postgres pg_isready -U "$DB_USERNAME" -d "$DB_DATABASE"

printf '\n--- Redis ---\n'
[[ "$("${COMPOSE[@]}" exec -T redis redis-cli ping | tr -d '\r')" == "PONG" ]]
echo "Redis PONG"

printf '\n--- Laravel /healthz ---\n'
for attempt in $(seq 1 30); do
  if curl --fail --silent --show-error "http://127.0.0.1:${PORT}/healthz" >/tmp/phoenix-health.$$ 2>/tmp/phoenix-health-err.$$; then
    cat /tmp/phoenix-health.$$
    rm -f /tmp/phoenix-health.$$ /tmp/phoenix-health-err.$$
    echo
    echo "PHOENIX DEV health gate: GREEN"
    exit 0
  fi
  sleep 2
done

cat /tmp/phoenix-health-err.$$ >&2 || true
rm -f /tmp/phoenix-health.$$ /tmp/phoenix-health-err.$$
echo "PHOENIX DEV health gate: RED" >&2
"${COMPOSE[@]}" logs --tail=200 app postgres redis >&2 || true
exit 1
