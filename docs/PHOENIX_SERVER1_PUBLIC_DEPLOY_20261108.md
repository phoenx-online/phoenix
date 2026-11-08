# PHOENIX: Server 1 public website + dedicated Cloudflare Tunnel

**Approved approach:** 2026-11-08 PHT: run new bounded PHOENIX workloads on existing Server 1, not Cloudflare Pages. Public \`https://phoenx.live\` serves the eight informational role pathways from public-site/ without secure logins. Private Laravel platform remains a later release.

**Source status:** Proposed deployment scripts; not proof of a live Server 1 release or Cloudflare configuration. This branch is stacked on public website PR #37 and does not require merging legacy PHP/main admin code into production.

## Boundaries

- Host: \`craniumtek\` only, Docker Compose project \`phoenix-prod\`.
- Web: \`phoenix-prod-web\`, unprivileged NGINX at \`127.0.0.1:8096\`, image digest pinned, static six assets and separate config mounted read-only, maximum 128MiB RAM/0.4 CPU.
- Edge: \`phoenix-prod-cloudflared\`, dedicated remotely managed \`phoenix-production\` tunnel, private token read from file, maximum 256MiB RAM/0.5 CPU.
- Both on \`phoenix_prod_ingress\`; Cloudflare origin service hostname **\`http://web:8080\`**, not \`localhost:8096\` from connector.
- No Postgres, Redis, Laravel, hiring forms, OTPs, payments, CVs, marketing analytics, client document intake or production Docker runner. Public site only.
- **Never** edit/restart the shared \`cloudflared.service\` (16 Craniumtek routes) or \`cloudflared-ibayong.service\` (3 iBayong routes). Do not use \`cloudflared service install\` a second time.

## Pre-release facts / stop conditions

Last owner memory audit Nov 4: Server 1 6.2GiB available RAM and 1.6GiB swap free, with zero live swap in/out samples; this is a historical point-in-time snapshot. Always rerun the targeted preflight; reject active swapping, RAM/disk thresholds, port or Docker-network conflicts, missing release files, unpinned image refs or an unexpected container owner.

The old \`phoenx.online\` Cloudflare zone was removed November 4; registrar/email/auth/webhook dependencies remain separately unverified. Never delete registration/old systems in this deployment.

## Stage a pinned, immutable public website (no Docker/DNS changes)

1. Review the exact PR head SHA and code in GitHub. Verify exact SHA and CI on the **Server 1 PR** before selecting it for live deploy.
2. On Server 1, stage the web files with the pinned script. Replace SOURCE_SHA below with the exact **40-character approved PR head**; do not run mutable branch code:
   
   \`\`\`bash
   set -Eeuo pipefail
   SHA="SOURCE_SHA"
   test "$SHA" != "SOURCE_SHA"
   curl -fsSL "https://raw.githubusercontent.com/phoenx-online/phoenix/$SHA/deploy/phoenix-server1/prepare-static-release.sh" \
     -o /tmp/phoenix-prepare-public.sh
   bash -n /tmp/phoenix-prepare-public.sh
   sudo bash /tmp/phoenix-prepare-public.sh "$SHA"
   \`\`\`

   Expect \`PHOENIX_STATIC_RELEASE=PASS\`, \`/srv/phoenix/releases/$SHA\` with \`index.html\`, \`styles.css\`, \`site.js\`, \`favicon.svg\`, \`robots.txt\`, \`sitemap.xml\`, and the pinned \`/srv/phoenix/config/$SHA\` for NGINX/Compose/preflight/smoke/env template.
   
3. Review provenance/security of NGINX unprivileged and Cloudflare tunnel images. Pull approved versions and read their actual pullable immutable digests. **No invented digests**:
   
   \`\`\`bash
   sudo docker pull nginxinc/nginx-unprivileged:stable-alpine
   sudo docker pull cloudflare/cloudflared:latest
   sudo docker image inspect -f '{{json .RepoDigests}}' nginxinc/nginx-unprivileged:stable-alpine
   sudo docker image inspect -f '{{json .RepoDigests}}' cloudflare/cloudflared:latest
   \`\`\`
   
   Do not use floating image references for the actual Compose production deployment; choose the correct repo+digest for host architecture. Record reviewed version and scan/release provenance. Latest tags above are **discovery only**, not acceptance.

4. Install and edit the non-secret root-owned environment file. Replace all placeholders with exact SHA and digests:
   
   \`\`\`bash
   sudo install -o root -g root -m 0600 \
     "/srv/phoenix/config/$SHA/deployment.env.example" \
     /srv/phoenix/deployment.env
   sudoedit /srv/phoenix/deployment.env
   \`\`\`

## Local website acceptance

5. With the exact configured environment file, run preflight and start **only** PHOENIX's web container:
   
   \`\`\`bash
   CONF="/srv/phoenix/config/$SHA"
   sudo bash "$CONF/preflight-readonly.sh" web
   sudo docker compose --env-file /srv/phoenix/deployment.env \
     -f "$CONF/compose.yml" up -d --no-deps web
   sudo bash "$CONF/smoke-readonly.sh"
   \`\`\`
   
   Require \`PHOENIX_SERVER1_PREFLIGHT=PASS\` and \`PHOENIX_LOCAL_ACCEPTANCE=PASS\`. If the web container is unhealthy, inspect **only** its status/logs and diagnose NGINX image/config permissions. Do not proceed to DNS. The loopback web port is not publicly accessible.

## Dedicated PHOENIX tunnel, then controlled apex DNS

6. In the Cloudflare account containing \`phoenx.live\`: Networking → Tunnels → Create tunnel → Cloudflared. Name it **\`phoenix-production\`**. Choose the remotely managed Docker option. **Do not run the suggested Docker command with the token in its command line** and never paste or email the token.
7. Install the new tunnel's token **via a hidden interactive prompt** on Server 1:
   
   \`\`\`bash
   sudo install -d -o root -g root -m 0700 /srv/phoenix/secrets
   sudo bash -c 'umask 077; read -r -s -p "PHOENIX tunnel token: " TOKEN; printf "\n"; test -n "$TOKEN" || exit 1; printf "%s" "$TOKEN" > /srv/phoenix/secrets/tunnel-token; unset TOKEN; chown 65532:65532 /srv/phoenix/secrets/tunnel-token; chmod 0400 /srv/phoenix/secrets/tunnel-token'
   \`\`\`
   
   The official \`cloudflared\` token-file option requires version 2025.4.0 or later; the connector runs as UID 65532 in this design. File-backed Compose secrets are bind mounts: an \`uid\` declaration by itself cannot remap their ownership. If the token is unreadable inside the connector, **stop and diagnose**, not \`chmod 644\`.

8. Launch the connector after its separate preflight:
   
   \`\`\`bash
   sudo bash "$CONF/preflight-readonly.sh" tunnel
   sudo docker compose --env-file /srv/phoenix/deployment.env \
     -f "$CONF/compose.yml" up -d --no-deps tunnel
   sudo docker ps --filter name=phoenix-prod
   \`\`\`
   
   Confirm the **new** \`phoenix-production\` tunnel shows **Healthy** in Cloudflare; do not change \`craniumtek-production\` or \`ibayong-production\`.

9. **Separate DNS cutover:** Export/screenshot the actual current \`phoenx.live\` zone before changes. Prior November 2 screenshot contained two proxied apex A records (\`54.149.79.189\`, \`34.216.117.25\`); recheck, don't assume unchanged. Add the apex **Published application** to the new \`phoenix-production\` tunnel, pointing to **\`http://web:8080\`**. Resolve conflicting apex A records during this controlled step. Cloudflare should associate the apex CNAME with the actual new tunnel ID; don't invent or reuse an old tunnel UUID.
10. Once Cloudflare shows tunnel healthy and hostname routing active:
   
   \`\`\`bash
   sudo bash "$CONF/smoke-readonly.sh" public
   \`\`\`
   
   Require HTTPS 200, correct PHOENIX content/canonical, existing Craniumtek/MBG/iBayong/FlashDate sites HTTP 200 and working role selectors on mobile. Record release SHA/image digests, tunnel identifier (not token), DNS before/after, health logs without secrets and rollback evidence.

## Rollback

- If local web fails, stop **only** \`phoenix-prod-web\` and leave unrelated Compose projects untouched.
- If PHOENIX tunnel fails, disable the PHOENIX published route and stop **only** \`phoenix-prod-cloudflared\`.
- If apex DNS fails after cutover, revert **only** the new \`phoenx.live\` records from recorded before-state; note the old records may not serve a valid PHOENIX website. Never restart shared Cloudflare units.
- Do not advertise a working private portal or accept personal/regulated client documents until secure authorization, privacy and storage tests pass.

## Official references

- https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/configure-tunnels/run-parameters/
- https://docs.docker.com/compose/how-tos/use-secrets/
- https://github.com/nginx/docker-nginx-unprivileged
