#!/usr/bin/env bash
set -Eeuo pipefail

TARGET="${1:-.env.dev}"
HTTP_PORT="${2:-18080}"

if [[ -e "$TARGET" ]]; then
  echo "Refusing to overwrite existing $TARGET" >&2
  exit 1
fi

command -v openssl >/dev/null 2>&1 || { echo "openssl is required" >&2; exit 1; }

APP_KEY="base64:$(openssl rand -base64 32 | tr -d '\n')"
DB_PASSWORD="$(openssl rand -hex 24)"

cat >"$TARGET" <<EOF
APP_NAME=PHOENIX
APP_ENV=local
APP_KEY=$APP_KEY
APP_DEBUG=true
APP_URL=http://127.0.0.1:$HTTP_PORT

LOG_CHANNEL=stderr
LOG_LEVEL=debug

DB_CONNECTION=pgsql
DB_HOST=postgres
DB_PORT=5432
DB_DATABASE=phoenix_dev
DB_USERNAME=phoenix_dev
DB_PASSWORD=$DB_PASSWORD
DB_SSLMODE=prefer

CACHE_STORE=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=file
SESSION_LIFETIME=120

REDIS_CLIENT=phpredis
REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379
REDIS_DB=0
REDIS_CACHE_DB=1
REDIS_PREFIX=phoenix_dev_database_
CACHE_PREFIX=phoenix_dev_cache_
REDIS_QUEUE=phoenix-dev

PHOENIX_HTTP_PORT=$HTTP_PORT
PHOENIX_ENV_FILE=$TARGET
EOF

chmod 600 "$TARGET"
echo "Created $TARGET with generated PHOENIX DEV-only secrets (mode 600)."
