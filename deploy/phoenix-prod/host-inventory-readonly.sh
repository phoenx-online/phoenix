#!/usr/bin/env bash
# PHOENIX/Server1 inventory before changing any services or Cloudflare routes.
# Safe for execution under sudo; never reads token or environment files.
set -Eeuo pipefail

if [[ "$(hostname -s)" != "craniumtek" ]]; then
  echo "HOST_AUDIT=BLOCKED: run on Server 1 (craniumtek) only" >&2
  exit 2
fi

echo "=== IDENTITY AND CAPACITY ==="
printf 'HOST=%s\n' "$(hostname -s)"
date -Is
uname -sr
free -h
df -h /
df -h /srv 2>/dev/null || true

echo "=== DOCKER ENGINE / COMPOSE ==="
docker info --format 'Docker server: {{.ServerVersion}}' 2>/dev/null ||
  echo "Docker daemon inspection unavailable"
docker compose version || true
docker compose ls || true

echo "=== RUNNING CONTAINERS (NO ENV/COMMAND/TOKENS) ==="
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' || true

echo "=== NETWORK NAMES ONLY ==="
docker network ls --format '{{.Name}}' || true

echo "=== PHOENIX DEPLOYMENT BOUNDARY ==="
if [[ -d /srv/phoenix ]]; then echo "PHOENIX_ROOT_EXISTS=YES"; else echo "PHOENIX_ROOT_EXISTS=NO"; fi
if [[ -e /srv/phoenix/RELEASE_SHA ]]; then echo "PHOENIX_RELEASE_MARKER_EXISTS=YES"; else echo "PHOENIX_RELEASE_MARKER_EXISTS=NO"; fi
ss -ltn '( sport = :8096 )' || true
docker ps --format '{{.Names}}' | grep -E '^phoenix-prod-' || true

echo "=== TUNNEL CONNECTOR NAMES ONLY ==="
docker ps --format '{{.Names}} | {{.Image}}' | grep -Ei 'cloudflare|cloudflared' || true
systemctl list-unit-files --type=service --no-pager 2>/dev/null |
  grep -Ei '(cloudflared|actions\\.runner)' || true

echo "=== PUBLIC SITE RESPONSE CODES (NO PAGE CONTENT) ==="
for site in craniumtek.com morningbreaks.online ibayong.com flashdate.online phoenx.live; do
  code="$(curl -sS -L --connect-timeout 4 --max-time 12 -o /dev/null -w '%{http_code}' "https://$site/" 2>/dev/null || true)"
  printf '%s HTTP %s\n' "$site" "$code"
done

echo "HOST_AUDIT_COMPLETED=YES"
echo "NO_SERVICES_OR_DNS_CHANGED=TRUE"
