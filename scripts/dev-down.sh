#!/usr/bin/env bash
set -Eeuo pipefail

ENV_FILE="${1:-.env.dev}"
if (( $# > 0 )); then shift; fi

[[ -f "$ENV_FILE" ]] || { echo "Missing $ENV_FILE" >&2; exit 1; }

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

export PHOENIX_ENV_FILE="$ENV_FILE"

docker compose --project-name phoenix-dev --env-file "$ENV_FILE" -f compose.dev.yml down "$@"
