#!/usr/bin/env bash
# Read-only post-cutover acceptance check. Never changes services or DNS.
set -Eeuo pipefail
die() { printf 'PHOENIX_PRODUCTION_VERIFIED=NO | %s\n' "$*" >&2; exit 1; }

[[ "$(hostname -s)" == craniumtek ]] || die "wrong host"
command -v curl >/dev/null || die "curl missing"
command -v docker >/dev/null || die "docker missing"

for service in phoenix-prod-web phoenix-prod-cloudflared; do
  status="$(docker inspect -f '{{.State.Status}}' "$service" 2>/dev/null || true)"
  [[ "$status" == running ]] || die "$service not running"
  networks="$(docker inspect -f '{{json .NetworkSettings.Networks}}' "$service" 2>/dev/null || true)"
  [[ "$networks" == *'"phoenix_prod_ingress"'* ]] ||
    die "$service not on PHOENIX-only ingress network"
  printf 'PASS: %s running on PHOENIX ingress network\n' "$service"
done

web_ports="$(docker port phoenix-prod-web 8080/tcp 2>/dev/null || true)"
[[ "$web_ports" == "127.0.0.1:8096" ]] ||
  die "PHOENIX origin must be published only on 127.0.0.1:8096"

local_html="$(mktemp)"
public_html="$(mktemp)"
trap 'rm -f "$local_html" "$public_html"' EXIT

curl --fail --silent --show-error --max-time 12 \
  http://127.0.0.1:8096/ -o "$local_html" ||
  die "local PHOENIX origin failed"
curl --fail --silent --show-error --max-time 20 \
  https://phoenx.live/ -o "$public_html" ||
  die "public PHOENIX HTTPS failed"

for f in "$local_html" "$public_html"; do
  grep -Fq 'Live Commerce Growth Operating System' "$f" ||
    die "incorrect PHOENIX content"
  grep -Fq '<link rel="canonical" href="https://phoenx.live/">' "$f" ||
    die "incorrect canonical URL"
done
printf 'PASS: local and public PHOENIX contain required content and canonical URL\n'

for site in craniumtek.com morningbreaks.online ibayong.com flashdate.online; do
  code="$(curl --fail --location --silent --show-error \
    --connect-timeout 5 --max-time 20 -o /dev/null -w '%{http_code}' \
    "https://$site/" 2>/dev/null)" ||
      die "unrelated production site $site failed smoke check"
  [[ "$code" == "200" ]] ||
    die "unrelated site $site unexpected HTTP $code"
  printf 'PASS: unrelated site %s HTTP %s\n' "$site" "$code"
done

printf 'PHOENIX_PRODUCTION_VERIFIED=PASS\n'
printf 'OTHER_PROJECTS_PUBLIC_SMOKE=PASS\n'
printf 'NO_SERVICES_OR_DNS_CHANGED=TRUE\n'