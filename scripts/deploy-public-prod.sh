#!/usr/bin/env bash
set -Eeuo pipefail
echo "BLOCKED: legacy PHOENIX deploy script is retired; it lacks the approved dedicated-tunnel release gates." >&2
echo "See deploy/phoenix-prod/README.md for the isolated PHOENIX production plan." >&2
echo "No production data, containers, tunnel or DNS changed." >&2
exit 64
