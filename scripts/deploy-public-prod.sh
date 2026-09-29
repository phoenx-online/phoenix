#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="${PHOENIX_PROD_ROOT:-/srv/phoenix}"
PORT="${PHOENIX_PROD_PORT:-8096}"
SHA="${GITHUB_SHA:-${1:-}}"

if [[ ! "$SHA" =~ ^[0-9a-f]{40}$ ]]; then
  echo "ERROR: exact 40-character release SHA required"
  exit 2
fi

test -s public-site/index.html
grep -q "Live Commerce Growth Operating System" public-site/index.html

if ss -lnt | awk '{print $4}' | grep -Eq "(^|:)${PORT}$"; then
  if ! docker ps --format '{{.Names}} {{.Ports}}' | grep -Eq "^phoenix-prod-web .*127\.0\.0\.1:${PORT}->80/tcp"; then
    echo "ERROR: port ${PORT} is already occupied by another service"
    ss -lntp | grep ":${PORT}" || true
    exit 3
  fi
fi

mkdir -p "$ROOT/releases/$SHA"
install -m 0644 public-site/index.html "$ROOT/releases/$SHA/index.html"
ln -sfn "$ROOT/releases/$SHA" "$ROOT/current.new"
mv -Tf "$ROOT/current.new" "$ROOT/current"

cat >"$ROOT/compose.yml" <<EOF
services:
  web:
    image: nginx:stable-alpine
    container_name: phoenix-prod-web
    restart: unless-stopped
    ports:
      - "127.0.0.1:${PORT}:80"
    volumes:
      - "$ROOT/current:/usr/share/nginx/html:ro"
    read_only: true
    tmpfs:
      - /var/cache/nginx
      - /var/run
      - /tmp
    security_opt:
      - no-new-privileges:true
EOF

docker compose -p phoenix-prod -f "$ROOT/compose.yml" up -d --remove-orphans

for _ in $(seq 1 30); do
  if curl --fail --silent --show-error "http://127.0.0.1:${PORT}/" >"$ROOT/.health.html"; then
    break
  fi
  sleep 1
done

grep -q "Live Commerce Growth Operating System" "$ROOT/.health.html"
rm -f "$ROOT/.health.html"

printf '%s\n' "$SHA" >"$ROOT/RELEASE_SHA"
printf 'PHOENIX_LOCAL_PRODUCTION=PASS\n'
printf 'PHOENIX_RELEASE_SHA=%s\n' "$SHA"
printf 'PHOENIX_LOCAL_URL=http://127.0.0.1:%s/\n' "$PORT"
