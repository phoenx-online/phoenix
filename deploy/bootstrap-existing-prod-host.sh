#!/usr/bin/env bash
set -Eeuo pipefail
echo "BLOCKED: legacy PHOENIX bootstrap must not run on shared Server 1." >&2
echo "This legacy bootstrap previously created/replaced containers and is not the approved isolated-tunnel rollout." >&2
echo "Use deploy/phoenix-prod/README.md and preflight-readonly.sh after review and operator approval." >&2
echo "No production service or Cloudflare tunnel was changed." >&2
exit 64
