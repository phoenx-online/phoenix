#!/usr/bin/env bash
set -Eeuo pipefail

EXPECTED_HOST="craniumtek"
PORT="8096"
ROOT="/srv/phoenix"
CONFIG="/etc/cloudflared/config.yml"
REPO="phoenx-online/phoenix"
SHA="${1:-}"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run this bootstrap with sudo/root"
  exit 2
fi

if [ "$(hostname)" != "$EXPECTED_HOST" ]; then
  echo "ERROR: expected host $EXPECTED_HOST, got $(hostname)"
  exit 3
fi

if [[ ! "$SHA" =~ ^[0-9a-f]{40}$ ]]; then
  echo "ERROR: pass the exact 40-character PHOENIX release SHA"
  exit 4
fi

echo "=== Capacity ==="
free -h
df -h /

echo "=== Port gate ==="
if ss -lnt | awk '{print $4}' | grep -Eq "(^|:)${PORT}$"; then
  if ! docker ps --format '{{.Names}} {{.Ports}}' | grep -Eq "^phoenix-prod-web .*127\.0\.0\.1:${PORT}->80/tcp"; then
    echo "ERROR: port ${PORT} is occupied by another service"
    ss -lntp | grep ":${PORT}" || true
    exit 5
  fi
fi

echo "=== Dedicated PHOENIX production account ==="
if ! id phoenix-prod >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash phoenix-prod
fi
getent group docker >/dev/null
usermod -aG docker phoenix-prod

install -d -o phoenix-prod -g phoenix-prod -m 0755 "$ROOT"
install -d -o phoenix-prod -g phoenix-prod -m 0755 "$ROOT/releases"
install -d -o phoenix-prod -g phoenix-prod -m 0755 /home/phoenix-prod/actions-runner

echo "=== Fetch exact static release ==="
REL="$ROOT/releases/$SHA"
install -d -o phoenix-prod -g phoenix-prod -m 0755 "$REL"

URL="https://raw.githubusercontent.com/$REPO/$SHA/public-site/index.html"
curl --fail --location --retry 4 --retry-delay 2 "$URL" -o "$REL/index.html"
grep -q "Live Commerce Growth Operating System" "$REL/index.html"
chown phoenix-prod:phoenix-prod "$REL/index.html"
chmod 0644 "$REL/index.html"

ln -sfn "$REL" "$ROOT/current.new"
mv -Tf "$ROOT/current.new" "$ROOT/current"
chown -h phoenix-prod:phoenix-prod "$ROOT/current"

cat >"$ROOT/compose.yml" <<EOF
services:
  web:
    image: nginx:stable-alpine
    container_name: phoenix-prod-web
    restart: unless-stopped
    ports:
      - "127.0.0.1:${PORT}:80"
    volumes:
      - "$REL:/usr/share/nginx/html:ro"
    read_only: true
    tmpfs:
      - /var/cache/nginx
      - /var/run
      - /tmp
    security_opt:
      - no-new-privileges:true
EOF
chown phoenix-prod:phoenix-prod "$ROOT/compose.yml"
chmod 0644 "$ROOT/compose.yml"

echo "=== Start isolated PHOENIX production container ==="
docker compose -p phoenix-prod -f "$ROOT/compose.yml" up -d --remove-orphans

for _ in $(seq 1 30); do
  if curl --fail --silent --show-error "http://127.0.0.1:${PORT}/" >"$ROOT/.local-health"; then
    break
  fi
  sleep 1
done
grep -q "Live Commerce Growth Operating System" "$ROOT/.local-health"
rm -f "$ROOT/.local-health"

echo "=== Cloudflare route is a separate operator-controlled step ==="
echo "No Cloudflare DNS, tunnel configuration, or shared tunnel service is modified."
echo "After local acceptance, in Cloudflare Networking > Tunnels > craniumtek-production:"
echo "  Add a Published application route: phoenx.live -> http://localhost:8096"
echo "  Confirm this tunnel connector runs on the same host/network as the PHOENIX origin."
echo "  Remove conflicting apex A records only as part of that controlled DNS cutover."
echo "  Preserve all existing production routes."
echo "  www.phoenx.live is optional and should redirect to the apex only after testing."

printf '%s\n' "$SHA" >"$ROOT/RELEASE_SHA"
chown phoenix-prod:phoenix-prod "$ROOT/RELEASE_SHA"

echo "=== Acceptance ==="
LOCAL="$(curl --fail --silent --show-error -o /tmp/phx-local -w '%{http_code}' http://127.0.0.1:${PORT}/)"
grep -q "Live Commerce Growth Operating System" /tmp/phx-local
rm -f /tmp/phx-local
echo "LOCAL_HTTP=$LOCAL"

set +e
PUBLIC="$(curl --silent --show-error --location --connect-timeout 5 --max-time 20 -o /tmp/phx-public -w '%{http_code}' https://phoenx.live/)"
CURL_RC=$?
set -e

if [ "$CURL_RC" -eq 0 ] && [ "$PUBLIC" = "200" ] && grep -q "Live Commerce Growth Operating System" /tmp/phx-public; then
  echo "PHOENIX_PUBLIC_ACCEPTANCE=PASS"
  rm -f /tmp/phx-public
  exit 0
fi

rm -f /tmp/phx-public
echo "PHOENIX_LOCAL_ACCEPTANCE=PASS"
echo "PHOENIX_PUBLIC_ACCEPTANCE=BLOCKED"
echo "PUBLIC_HTTP=${PUBLIC:-000}"
echo "The local production service is live. If the public domain is still blocked, update the Cloudflare DNS record for phoenx.live/www to the existing tunnel, then re-test."
exit 7
