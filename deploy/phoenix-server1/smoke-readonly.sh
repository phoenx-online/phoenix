#!/usr/bin/env bash
# PHOENIX-only smoke. Does not alter DNS, Docker or other workloads.
set -Eeuo pipefail
die() { printf 'PHOENIX_PUBLIC_ACCEPTANCE=FAIL: %s\n' "$*" >&2; exit 1; }

[[ "$(hostname -s)" == "craniumtek" ]] || die "wrong host"
command -v curl >/dev/null || die "curl missing"
command -v docker >/dev/null || die "docker missing"

[[ "$(docker inspect -f '{{.State.Status}}' phoenix-prod-web 2>/dev/null)" == "running" ]] ||
  die "PHOENIX web is not running"
test "$(docker port phoenix-prod-web 8080/tcp)" = "127.0.0.1:8096" ||
  die "PHOENIX web not exclusively on loopback 8096"
[[ "$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project"}}' phoenix-prod-web)" == "phoenix-prod" ]] ||
  die "web not PHOENIX-owned"

work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
curl --fail --silent --show-error --max-time 12 \
  http://127.0.0.1:8096/ -o "$work/local.html" -D "$work/local-headers" ||
  die "loopback homepage did not serve"
grep -Fq 'Go live.' "$work/local.html" || die "loopback content incorrect"
grep -Fq '<link rel="canonical" href="https://phoenx.live/">' "$work/local.html" ||
  die "loopback canonical missing"
grep -iq '^Content-Security-Policy:' "$work/local-headers" ||
  die "NGINX CSP header missing"
for asset in styles.css site.js favicon.svg robots.txt sitemap.xml; do
  curl --fail --silent --show-error --max-time 12 \
    "http://127.0.0.1:8096/$asset" -o /dev/null ||
    die "origin asset missing: $asset"
done
echo "PHOENIX_LOCAL_ASSETS_AND_HEADERS=PASS"

if [[ "$#" -ge 1 && "$1" == "public" ]]; then
  [[ "$(docker inspect -f '{{.State.Status}}' phoenix-prod-cloudflared 2>/dev/null)" == "running" ]] ||
    die "dedicated tunnel container is not running"
  [[ "$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project"}}' phoenix-prod-cloudflared)" == "phoenix-prod" ]] ||
    die "tunnel not PHOENIX-owned"

  curl --fail --silent --show-error --location --max-time 20 \
    https://phoenx.live/ -o "$work/public.html" -D "$work/public-headers" ||
    die "public HTTPS not reachable"
  grep -Fq 'Go live.' "$work/public.html" ||
    die "wrong content served by public hostname"
  grep -Fq '<link rel="canonical" href="https://phoenx.live/">' "$work/public.html" ||
    die "public canonical mismatch"
  for site in craniumtek.com morningbreaks.online ibayong.com flashdate.online; do
    code="$(curl --silent --show-error --location --max-time 20 \
      -o /dev/null -w '%{http_code}' "https://$site/" 2>/dev/null)" ||
      die "other production website failed: $site"
    [[ "$code" == "200" ]] || die "other production website returned $code: $site"
    printf 'PASS: %s returned HTTP 200\n' "$site"
  done
  echo "PHOENIX_PUBLIC_ACCEPTANCE=PASS"
  echo "CROSS_PROJECT_PUBLIC_SMOKE=PASS"
else
  echo "PHOENIX_LOCAL_ACCEPTANCE=PASS"
  echo "PHOENIX_PUBLIC_ACCEPTANCE=NOT_CHECKED"
fi
echo "NO_OTHER_WORKLOADS_OR_DNS_CHANGED=TRUE"
