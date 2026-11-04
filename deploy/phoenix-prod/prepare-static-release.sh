#!/usr/bin/env bash
# Prepare PHOENIX-only immutable static web files. Does not run Docker or change DNS.
set -Eeuo pipefail
die() { printf 'PHOENIX_RELEASE_PREP=BLOCKED: %s\n' "$*" >&2; exit 1; }

test "$(hostname -s)" = craniumtek || die "wrong host"
test "$(id -u)" -eq 0 || die "run with sudo/root"
SHA="$1"
[[ "$SHA" =~ ^[0-9a-f]{40}$ ]] || die "exact approved 40-hex source SHA required"
command -v curl >/dev/null || die "curl not installed"

ROOT="/srv/phoenix"
REL="$ROOT/releases/$SHA"
[[ ! -e "$REL" && ! -L "$REL" ]] || die "release directory already exists; refuse overwrite"
[[ ! -L "$ROOT" && ! -L "$ROOT/releases" ]] ||
  die "PHOENIX release root contains a symbolic link; refuse to follow"
if [[ -e "$ROOT" && ! -d "$ROOT" ]]; then
  die "/srv/phoenix exists but is not a directory"
fi

# Only PHOENIX-owned paths are created. Never run this as a periodic job.
install -d -o root -g root -m 0755 "$ROOT" "$ROOT/releases"
tmp="$(mktemp "$ROOT/releases/.pending.XXXXXXXX")"
trap 'rm -f "$tmp"' EXIT
url="https://raw.githubusercontent.com/phoenx-online/phoenix/$SHA/public-site/index.html"
curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 \
  --connect-timeout 8 --max-time 30 "$url" -o "$tmp" ||
  die "immutable source fetch failed"

test -s "$tmp" || die "fetched HTML is empty"
grep -Fq 'Live Commerce Growth Operating System' "$tmp" ||
  die "expected PHOENIX content missing"
grep -Fq '<link rel="canonical" href="https://phoenx.live/">' "$tmp" ||
  die "canonical domain mismatch"

# Ensure identical file is a normal static HTML payload, not a redirect/login page.
head -c 128 "$tmp" | grep -iq '<!doctype html' ||
  die "static HTML doctype missing"

install -d -o root -g root -m 0755 "$REL"
install -o root -g root -m 0644 "$tmp" "$REL/index.html"
printf '%s\n' "$SHA" > "$REL/RELEASE_SHA"
chmod 0644 "$REL/RELEASE_SHA"
sha256sum "$REL/index.html"

printf 'PHOENIX_STATIC_RELEASE_PREP=PASS\n'
printf 'RELEASE_SHA=%s\n' "$SHA"
printf 'RELEASE_DIR=%s\n' "$REL"
printf 'DOCKER_TUNNELS_AND_DNS_UNCHANGED=TRUE\n'
