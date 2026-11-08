#!/usr/bin/env bash
# Stage only immutable PHOENIX public static website assets on Server 1.
# No containers, Cloudflare config, DNS, user accounts or other ventures are changed.
set -Eeuo pipefail
die() { printf 'PHOENIX_STATIC_RELEASE=BLOCKED: %s\n' "$*" >&2; exit 1; }

test "$(hostname -s)" = "craniumtek" || die "wrong server"
test "$(id -u)" -eq 0 || die "run with sudo"
test "$#" -eq 1 || die "usage: prepare-static-release.sh <approved-40-character-source-SHA>"
SHA="$1"
[[ "$SHA" =~ ^[a-f0-9]{40}$ ]] || die "invalid source SHA"

command -v curl >/dev/null || die "curl missing"
command -v install >/dev/null || die "install missing"
ROOT="/srv/phoenix"
RELEASES="$ROOT/releases"
CONFIGS="$ROOT/config"
REL="$RELEASES/$SHA"
CONF="$CONFIGS/$SHA"

for p in "$ROOT" "$RELEASES" "$CONFIGS"; do
  [[ ! -L "$p" ]] || die "refusing symlinked PHOENIX directory"
done
[[ ! -e "$REL" && ! -L "$REL" ]] || die "release already exists, cannot overwrite"
[[ ! -e "$CONF" && ! -L "$CONF" ]] || die "configuration already exists, cannot overwrite"

# Only previously absent PHOENIX-scoped directories may be created.
install -d -o root -g root -m 0755 "$ROOT" "$RELEASES" "$CONFIGS"
TEMP_REL="$(mktemp -d "$RELEASES/.pending-release.XXXXXXXX")"
TEMP_CONF="$(mktemp -d "$CONFIGS/.pending-config.XXXXXXXX")"
cleanup() {
  case "$TEMP_REL" in "$RELEASES"/.pending-release.*) rm -rf -- "$TEMP_REL" ;; esac
  case "$TEMP_CONF" in "$CONFIGS"/.pending-config.*) rm -rf -- "$TEMP_CONF" ;; esac
}
trap cleanup EXIT

fetch() {
  local source_path="$1" dest="$2"
  curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 \
    --connect-timeout 8 --max-time 35 \
    "https://raw.githubusercontent.com/phoenx-online/phoenix/$SHA/$source_path" -o "$dest" ||
      die "download failed: $source_path"
  test -s "$dest" || die "empty file: $source_path"
  chmod 0644 "$dest"
}

for asset in index.html styles.css site.js favicon.svg robots.txt sitemap.xml; do
  fetch "public-site/$asset" "$TEMP_REL/$asset"
done
fetch "deploy/phoenix-server1/nginx.conf" "$TEMP_CONF/default.conf"
fetch "deploy/phoenix-server1/compose.yml" "$TEMP_CONF/compose.yml"
fetch "deploy/phoenix-server1/preflight-readonly.sh" "$TEMP_CONF/preflight-readonly.sh"
chmod 0755 "$TEMP_CONF/preflight-readonly.sh"

grep -Fq '<link rel="canonical" href="https://phoenx.live/">' "$TEMP_REL/index.html" ||
  die "wrong canonical domain"
grep -Fq 'Go live.' "$TEMP_REL/index.html" || die "unexpected homepage content"
grep -Fq 'role-based accounts are not active' "$TEMP_REL/index.html" ||
  die "required private-account warning absent"
test "$(grep -o 'data-audience=' "$TEMP_REL/index.html" | wc -l)" -eq 8 ||
  die "not all eight stakeholder role choices present"
grep -Fq 'listen 8080 default_server;' "$TEMP_CONF/default.conf" ||
  die "wrong nginx internal port"
grep -Fq "frame-ancestors 'none'" "$TEMP_CONF/default.conf" ||
  die "missing security header config"

printf '%s\n' "$SHA" > "$TEMP_REL/RELEASE_SHA"
chmod 0644 "$TEMP_REL/RELEASE_SHA"
chown -R root:root "$TEMP_REL" "$TEMP_CONF"

# The two directories are scoped to this never-before-used SHA.
mv -- "$TEMP_CONF" "$CONF"
mv -- "$TEMP_REL" "$REL"
printf 'PHOENIX_STATIC_RELEASE=PASS\n'
printf 'RELEASE_SHA=%s\n' "$SHA"
printf 'RELEASE_DIR=%s\n' "$REL"
printf 'NGINX_CONFIG=%s/default.conf\n' "$CONF"
sha256sum "$REL/index.html" "$REL/styles.css" "$REL/site.js" "$CONF/default.conf"
printf 'CONTAINERS_DNS_AND_SHARED_TUNNELS_UNCHANGED=TRUE\n'
