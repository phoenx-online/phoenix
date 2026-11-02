#!/usr/bin/env bash
# Read-only preflight. Does not create directories, run containers or change DNS.
set -Eeuo pipefail

die() { printf 'PHOENIX_PREFLIGHT=BLOCKED | %s\n' "$*" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$*"; }

HOST_EXPECTED="craniumtek"
COMPOSE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/compose.yml"
ENV_FILE="${1:-/srv/phoenix/deployment.env}"
TOKEN_FILE="/srv/phoenix/secrets/tunnel-token"

[[ "$(hostname -s)" == "$HOST_EXPECTED" ]] || die "wrong host; expected craniumtek"
command -v docker >/dev/null || die "Docker not installed"
command -v ss >/dev/null || die "ss is required"
docker info >/dev/null 2>&1 || die "Docker daemon inaccessible"
docker compose version >/dev/null 2>&1 || die "Docker Compose plugin missing"
[[ -f "$COMPOSE_FILE" ]] || die "compose definition missing"
[[ -r "$ENV_FILE" ]] || die "deployment.env missing or unreadable"

# Read literal simple KEY=VALUE fields without executing shell from an env file.
get_env() {
  local key="$1"
  grep -E "^${key}=" "$ENV_FILE" | tail -n1 | cut -d= -f2- || true
}
RELEASE_DIR="$(get_env PHOENIX_RELEASE_DIR)"
NGINX_IMAGE="$(get_env PHOENIX_NGINX_IMAGE)"
TUNNEL_IMAGE="$(get_env PHOENIX_CLOUDFLARED_IMAGE)"
RELEASE_SHA="${RELEASE_DIR##*/}"

[[ "$RELEASE_DIR" =~ ^/srv/phoenix/releases/[0-9a-f]{40}$ ]] ||
  die "release directory must be /srv/phoenix/releases/<40-char SHA>"
[[ "$NGINX_IMAGE" =~ ^[A-Za-z0-9_./:-]+@sha256:[0-9a-f]{64}$ ]] ||
  die "nginx image must be pinned to an immutable sha256 digest"
[[ "$TUNNEL_IMAGE" =~ ^[A-Za-z0-9_./:-]+@sha256:[0-9a-f]{64}$ ]] ||
  die "cloudflared image must be pinned to an immutable sha256 digest"
[[ -f "$RELEASE_DIR/index.html" ]] || die "immutable release index.html missing"
grep -Fq 'Live Commerce Growth Operating System' "$RELEASE_DIR/index.html" ||
  die "PHOENIX branding marker missing"
grep -Fq '<link rel="canonical" href="https://phoenx.live/">' "$RELEASE_DIR/index.html" ||
  die "canonical phoenx.live URL missing"

[[ -f "$TOKEN_FILE" && -s "$TOKEN_FILE" ]] ||
  die "dedicated tunnel token file missing"
[[ "$(stat -c '%u' "$TOKEN_FILE")" == "65532" ]] ||
  die "token file must be owned by cloudflared nonroot UID 65532"
[[ "$(stat -c '%a' \"$TOKEN_FILE\")" == "400" ]] ||
  die "token file must have mode 0400"

for service in phoenix-prod-web phoenix-prod-cloudflared; do
  if docker container inspect "$service" >/dev/null 2>&1; then
    project="$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project"}}' "$service" 2>/dev/null || true)"
    [[ "$project" == phoenix-prod ]] ||
      die "container name $service is owned by different project"
  fi
done

# For a new deployment, 8096 must be unused. When running an already-owned
# PHOENIX web service this check permits a controlled update to its own listener.
if ss -ltn '( sport = :8096 )' | tail -n +2 | grep -q '[^[:space:]]'; then
  docker ps --format '{{.Names}} | {{.Ports}}' |
    grep -Eq '^phoenix-prod-web \| .*127\.0\.0\.1:8096->8080/tcp' ||
    die "8096 is occupied by an unexpected process"
fi

mem_kb="$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)"
disk_kb="$(df -Pk /srv/phoenix | awk 'NR==2 {print $4}')"
[[ "$mem_kb" =~ ^[0-9]+$ && "$mem_kb" -ge 524288 ]] ||
  die "less than 512 MiB available RAM; capacity review required"
[[ "$disk_kb" =~ ^[0-9]+$ && "$disk_kb" -ge 1048576 ]] ||
  die "less than 1 GiB free disk on /srv/phoenix; capacity review required"

docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" config --quiet ||
  die "Docker Compose configuration failed validation"

pass "host, Docker/Compose, 8096 ownership, minimum capacity"
pass "SHA-scoped PHOENIX HTML and canonical domain"
pass "immutable image digests and dedicated nonroot tunnel token"
pass "PHOENIX-only Compose definition validates"
printf 'PHOENIX_PREFLIGHT=PASS\n'
printf 'RELEASE_SHA=%s\n' "$RELEASE_SHA"
printf 'NO_SERVICES_OR_DNS_CHANGED=TRUE\n'
