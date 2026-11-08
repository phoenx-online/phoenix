#!/usr/bin/env bash
# Read-only, targeted preflight for isolated Server 1 PHOENIX public release.
set -Eeuo pipefail
die() { printf 'PHOENIX_SERVER1_PREFLIGHT=BLOCKED: %s\n' "$*" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$*"; }

[[ "$#" -ge 1 && "$#" -le 2 ]] || die "usage: preflight-readonly.sh web|tunnel [deployment.env]"
MODE="$1"
[[ "$MODE" == "web" || "$MODE" == "tunnel" ]] || die "mode must be web or tunnel"
ENVFILE="${2:-/srv/phoenix/deployment.env}"

[[ "$(hostname -s)" == "craniumtek" ]] || die "wrong production host"
[[ "$(id -u)" -eq 0 ]] || die "run under sudo"
command -v docker >/dev/null || die "Docker is missing"
command -v ss >/dev/null || die "ss is missing"
docker info >/dev/null 2>&1 || die "cannot inspect Docker engine"
docker compose version >/dev/null 2>&1 || die "Compose plugin is missing"
[[ -r "$ENVFILE" ]] || die "deployment.env not readable"

get_config() { grep -E "^$1=" "$ENVFILE" | tail -n 1 | cut -d= -f2- || true; }
REL="$(get_config PHOENIX_RELEASE_DIR)"
CONF="$(get_config PHOENIX_NGINX_CONFIG)"
WEB_IMAGE="$(get_config PHOENIX_NGINX_IMAGE)"
TUNNEL_IMAGE="$(get_config PHOENIX_CLOUDFLARED_IMAGE)"
[[ "$REL" =~ ^/srv/phoenix/releases/[0-9a-f]{40}$ ]] || die "unexpected release directory"
SHA="$(basename "$REL")"
[[ "$CONF" == "/srv/phoenix/config/$SHA/default.conf" ]] || die "unexpected NGINX config path"
[[ "$WEB_IMAGE" =~ ^[a-zA-Z0-9./:_-]+@sha256:[a-f0-9]{64}$ ]] ||
  die "NGINX image must use exact pullable sha256 digest"
[[ "$TUNNEL_IMAGE" =~ ^[a-zA-Z0-9./:_-]+@sha256:[a-f0-9]{64}$ ]] ||
  die "cloudflared image must use exact pullable sha256 digest"
[[ "$(cat "$REL/RELEASE_SHA" 2>/dev/null)" == "$SHA" ]] || die "release marker mismatch"

for asset in index.html styles.css site.js favicon.svg robots.txt sitemap.xml; do
  [[ -s "$REL/$asset" && ! -L "$REL/$asset" ]] || die "missing or unsafe asset $asset"
  [[ "$(stat -c '%u' "$REL/$asset")" == 0 ]] || die "asset $asset not root owned"
done
[[ -s "$CONF" && ! -L "$CONF" ]] || die "NGINX config missing or symlinked"
grep -Fq '<link rel="canonical" href="https://phoenx.live/">' "$REL/index.html" ||
  die "wrong public canonical URL"
grep -Fq 'Go live.' "$REL/index.html" || die "wrong PHOENIX website"
grep -Fq 'listen 8080 default_server;' "$CONF" || die "NGINX 8080 config missing"
grep -Fq "frame-ancestors 'none'" "$CONF" || die "security headers missing"

COMPOSE="$(dirname "$CONF")/compose.yml"
[[ -s "$COMPOSE" && ! -L "$COMPOSE" ]] || die "Compose config absent"
docker compose --env-file "$ENVFILE" -f "$COMPOSE" config --quiet ||
  die "Compose validation failed"

for container in phoenix-prod-web phoenix-prod-cloudflared; do
  if docker container inspect "$container" >/dev/null 2>&1; then
    project="$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project"}}' "$container")"
    [[ "$project" == "phoenix-prod" ]] ||
      die "container $container belongs to another project"
  fi
done
if docker network inspect phoenix_prod_ingress >/dev/null 2>&1; then
  project="$(docker network inspect -f '{{index .Labels "com.docker.compose.project"}}' phoenix_prod_ingress)"
  [[ "$project" == phoenix-prod ]] || die "network name collision"
fi
listener="$(ss -ltn '( sport = :8096 )' | sed -n '2,$p')"
if [[ -n "$listener" ]]; then
  docker ps --format '{{.Names}} | {{.Ports}}' |
    grep -Eq '^phoenix-prod-web \| .*127\.0\.0\.1:8096->8080/tcp' ||
      die "8096 used by a non-PHOENIX process"
fi

available_kib="$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)"
disk_kib="$(df -Pk /srv/phoenix | awk 'NR==2 {print $4}')"
[[ "$available_kib" =~ ^[0-9]+$ && "$available_kib" -ge 1048576 ]] || die "less than 1GiB RAM available"
[[ "$disk_kib" =~ ^[0-9]+$ && "$disk_kib" -ge 2097152 ]] || die "less than 2GiB disk free"
if command -v vmstat >/dev/null; then
  samples="$(vmstat 1 4 | tail -n 3 | awk '{ if ($7 > 0 || $8 > 0) bad=1 } END { print bad+0 }')"
  [[ "$samples" == 0 ]] || die "active swapping detected; capacity review required"
fi
pass "host, capacity, image identity, source SHA, assets and network ownership"

if [[ "$MODE" == "tunnel" ]]; then
  TOKEN="/srv/phoenix/secrets/tunnel-token"
  [[ -s "$TOKEN" && ! -L "$TOKEN" ]] || die "dedicated tunnel token missing"
  [[ "$(stat -c '%u' "$TOKEN")" == "65532" ]] ||
    die "token must be owned by cloudflared UID 65532"
  [[ "$(stat -c '%a' "$TOKEN")" == "400" ]] || die "token mode must be 0400"
  [[ "$(stat -c '%u' /srv/phoenix/secrets)" == 0 ]] ||
    die "secrets directory ownership mismatch"
  pass "dedicated PHOENIX tunnel token file restrictions"
fi

echo "PHOENIX_SERVER1_PREFLIGHT=PASS"
printf 'CHECKED_MODE=%s\n' "$MODE"
printf 'RELEASE_SHA=%s\n' "$SHA"
echo "NO_DOCKER_SERVICES_OR_DNS_CHANGED=TRUE"
