#!/usr/bin/env bash
set -Eeuo pipefail

EXPECTED_HOST="${PHOENIX_EXPECTED_HOST:-craniumtek}"
EXPECTED_PORT="${PHOENIX_EXPECTED_PORT:-8096}"
EXPECTED_ROOT="${PHOENIX_EXPECTED_ROOT:-/srv/phoenix}"
EXPECTED_CONTAINER="${PHOENIX_EXPECTED_CONTAINER:-phoenix-prod-web}"
EXPECTED_PROJECT="${PHOENIX_EXPECTED_PROJECT:-phoenix-prod}"
EXPECTED_MARKER="Live Commerce Growth Operating System"
CONFIG="${PHOENIX_CLOUDFLARED_CONFIG:-/etc/cloudflared/config.yml}"
FAILURES=0

pass() { printf 'PASS %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; FAILURES=$((FAILURES + 1)); }

printf 'PHOENIX_DOMAIN_DIAGNOSTIC_V1\n'
printf 'UTC=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'HOST=%s\n' "$(hostname)"

if [ "$(hostname)" = "$EXPECTED_HOST" ]; then pass host_identity; else fail host_identity; fi
if id phoenix-prod >/dev/null 2>&1; then pass linux_identity; else fail linux_identity; fi
if [ -d "$EXPECTED_ROOT/releases" ]; then pass release_root; else fail release_root; fi

RELEASE_SHA=""
if [ -r "$EXPECTED_ROOT/RELEASE_SHA" ]; then
  RELEASE_SHA="$(tr -d '[:space:]' < "$EXPECTED_ROOT/RELEASE_SHA")"
fi
if [[ "$RELEASE_SHA" =~ ^[0-9a-f]{40}$ ]]; then
  printf 'RELEASE_SHA=%s\n' "$RELEASE_SHA"
  pass release_identity
else
  printf 'RELEASE_SHA=UNVERIFIED\n'
  fail release_identity
fi

if docker ps --format '{{.Names}}' | grep -Fxq "$EXPECTED_CONTAINER"; then
  pass container_running
else
  fail container_running
fi

COMPOSE_PROJECT="$(docker inspect --format '{{ index .Config.Labels "com.docker.compose.project" }}' "$EXPECTED_CONTAINER" 2>/dev/null || true)"
if [ "$COMPOSE_PROJECT" = "$EXPECTED_PROJECT" ]; then pass compose_isolation; else fail compose_isolation; fi

PUBLISHED_PORT="$(docker inspect --format '{{ (index (index .NetworkSettings.Ports "80/tcp") 0).HostIp }}:{{ (index (index .NetworkSettings.Ports "80/tcp") 0).HostPort }}' "$EXPECTED_CONTAINER" 2>/dev/null || true)"
if [ "$PUBLISHED_PORT" = "127.0.0.1:$EXPECTED_PORT" ]; then pass loopback_binding; else fail loopback_binding; fi

LOCAL_BODY="$(curl --fail --silent --show-error --max-time 10 "http://127.0.0.1:$EXPECTED_PORT/" 2>/dev/null || true)"
if grep -Fq "$EXPECTED_MARKER" <<<"$LOCAL_BODY"; then pass local_origin_content; else fail local_origin_content; fi

if [ -r "$CONFIG" ] && cloudflared tunnel ingress validate >/dev/null 2>&1; then
  pass tunnel_config_valid
else
  fail tunnel_config_valid
fi

APEX_RULE="$(cloudflared tunnel ingress rule https://phoenx.online 2>&1 || true)"
WWW_RULE="$(cloudflared tunnel ingress rule https://www.phoenx.online 2>&1 || true)"
if grep -Fq "http://localhost:$EXPECTED_PORT" <<<"$APEX_RULE"; then pass apex_ingress_target; else fail apex_ingress_target; fi
if grep -Fq "http://localhost:$EXPECTED_PORT" <<<"$WWW_RULE"; then pass www_ingress_target; else fail www_ingress_target; fi
if systemctl is-active --quiet cloudflared; then pass tunnel_service_active; else fail tunnel_service_active; fi

PUBLIC_BODY="$(curl --silent --show-error --location --max-time 20 https://phoenx.online/ 2>/dev/null || true)"
PUBLIC_HTTP="$(curl --silent --show-error --location --max-time 20 --output /dev/null --write-out '%{http_code}' https://phoenx.online/ 2>/dev/null || printf '000')"
printf 'PUBLIC_HTTP=%s\n' "$PUBLIC_HTTP"
if grep -Fq "$EXPECTED_MARKER" <<<"$PUBLIC_BODY"; then
  pass public_phoenix_content
else
  fail public_phoenix_content
fi
if grep -Fqi "A.I.D.A" <<<"$PUBLIC_BODY"; then
  printf 'PUBLIC_AIDA_MARKER=DETECTED\n'
else
  printf 'PUBLIC_AIDA_MARKER=NOT_DETECTED\n'
fi

if [ "$FAILURES" -eq 0 ]; then
  printf 'PHOENIX_DOMAIN_DIAGNOSTIC=PASS\n'
  exit 0
fi
printf 'PHOENIX_DOMAIN_DIAGNOSTIC=FAIL failures=%s\n' "$FAILURES"
exit 1
