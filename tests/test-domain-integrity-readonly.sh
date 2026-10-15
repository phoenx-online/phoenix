#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT="deploy/diagnose-domain-integrity-readonly.sh"
test -f "$SCRIPT"
bash -n "$SCRIPT"

required=(
  'PHOENIX_DOMAIN_DIAGNOSTIC_V1'
  '127.0.0.1:$EXPECTED_PORT'
  'com.docker.compose.project'
  'cloudflared tunnel ingress validate'
  'cloudflared tunnel ingress rule https://phoenx.online'
  'cloudflared tunnel ingress rule https://www.phoenx.online'
  'PHOENIX_DOMAIN_DIAGNOSTIC=PASS'
  'PHOENIX_DOMAIN_DIAGNOSTIC=FAIL'
)
for marker in "${required[@]}"; do
  grep -Fq "$marker" "$SCRIPT"
done

forbidden=(
  'docker compose up'
  'docker compose down'
  'docker restart'
  'systemctl restart'
  'systemctl reload'
  'systemctl start'
  'systemctl stop'
  'cloudflared tunnel route'
  'useradd '
  'usermod '
  'chown '
  'chmod '
  'rm -'
  'mv '
  'cp '
  'sed -i'
  'tee '
  'git push'
)
for marker in "${forbidden[@]}"; do
  if grep -Fq "$marker" "$SCRIPT"; then
    printf 'forbidden mutating command found: %s\n' "$marker" >&2
    exit 1
  fi
done

# Ignore the only approved output suppression target and shell here-strings,
# then reject any remaining stdout append or file-output redirection.
NORMALIZED="$(sed -E 's/[0-9]*>\/dev\/null//g; s/<<<.*$//g' "$SCRIPT")"
if grep -Eq '(^|[^>])>>|(^|[^<>])>[[:space:]]*[^&]' <<<"$NORMALIZED"; then
  printf 'unexpected filesystem output redirection found\n' >&2
  exit 1
fi

printf 'PHOENIX_READONLY_DIAGNOSTIC_SOURCE=PASS\n'
