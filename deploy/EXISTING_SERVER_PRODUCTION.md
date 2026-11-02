# PHOENIX Production on Existing Craniumtek Server

Canonical target:

- host: `craniumtek`
- role: production only
- Linux user: `phoenix-prod`
- runner: `craniumtek-phoenix-prod`
- runner labels: `self-hosted`, `linux`, `x64`, `phoenix-prod`
- deployment root: `/srv/phoenix`
- Docker project: `phoenix-prod`
- container: `phoenix-prod-web`
- local listener: `127.0.0.1:8096`
- public domains: `phoenx.live`, `www.phoenx.live`
- source repository: `phoenx-online/phoenix`

## Domain cutover safety gate

This runbook targets **phoenx.live**, but no new public DNS or tunnel route should be activated without first verifying ownership of the old hostname, the currently observed A.I.D.A login, and any mail/auth dependencies. See `docs/domain-migration-2026-11-01.md`.

The exact active tunnel, DNS provider, PHOENIX production container, runner state, and rollback plan must be verified on the host before changing routes. Do not remove a previously existing hostname until dependency checks pass.

## Why this replaces the DigitalOcean workflow

PHOENIX production belongs on the existing Craniumtek production server. The older `craniumtek-lab-01` machine remains DEV/STAGING/CI/QA and must not become the public PHOENIX production host.

The public launch is intentionally static first. It does not promote the unfinished PostgreSQL/Laravel DEV runtime or its database into production.

## One-time host bootstrap

Run on `craniumtek` with administrative authority:

```bash
sudo useradd --create-home --shell /bin/bash phoenix-prod 2>/dev/null || true
sudo usermod -aG docker phoenix-prod

sudo install -d -o phoenix-prod -g phoenix-prod -m 0755 /srv/phoenix
sudo install -d -o phoenix-prod -g phoenix-prod -m 0755 /home/phoenix-prod/actions-runner

sudo -u phoenix-prod docker ps >/dev/null
ss -lntp | grep ':8096' || true
```

The port check must show that 8096 is unused before first deployment.

## Runner registration

Register a repository-scoped self-hosted runner from:

`phoenx-online/phoenix → Settings → Actions → Runners → New self-hosted runner`

Install it under:

`/home/phoenix-prod/actions-runner`

Use runner name:

`craniumtek-phoenix-prod`

Add custom label:

`phoenix-prod`

Install/start the runner service as `phoenix-prod`, never as root.

## Dedicated PHOENIX Cloudflare Tunnel (proposed separation; operator-controlled)

**The owner requested a separate PHOENIX tunnel on November 2, 2026.** Do not attach `phoenx.live` to the existing `craniumtek-production` tunnel. Cloudflare currently shows that shared tunnel as Healthy with 16 apps, and the separate `ibayong-production` tunnel as Healthy with 3 apps. Do not alter/restart either connector.

### Prerequisites — all must pass

1. Confirm the exact host, resources, backup and rollback readiness. A rootless or least-privilege dedicated runtime is preferred. The first static-only bootstrap still needs root and Docker permissions review; do not blindly promote it into routine production CI.
2. Start `phoenix-prod-web` on its private Docker Compose network and verify the 8096 loopback listener returns the exact static PHOENIX page from an immutable release. Verify network name with `docker network ls`; do not assume it.
3. From Cloudflare **Networking → Tunnels**, create a *separate, remotely managed* tunnel named `phoenix-production`. Install its connector as a separate isolated Docker container/process joined **only to the PHOENIX application network**. Cloudflare's conventional `cloudflared service install` must not be run a second time against the server's existing system service. Use the token-file mechanism with narrowly readable secret file; never print/paste the token into source code or incident reports.
4. Add the PHOENIX route on the new tunnel: `phoenx.live` → `http://phoenix-prod-web:80` over that verified PHOENIX-only network. If `www.phoenx.live` is necessary, enable/test it separately and redirect to apex. This origin target is an architectural goal, **not proof that the network already exists**.
5. Cloudflare's current apex zone contains **two proxied A records** (`54.149.79.189`, `34.216.117.25`). Back them up and resolve the conflicts as part of one controlled DNS cutover after the origin and independent tunnel are healthy; point apex via CNAME to the **actual newly created tunnel UUID** (or allow Cloudflare's published-route flow to create it). Never guess the UUID or point PHOENIX at the existing shared tunnel.
6. Confirm HTTPS 200 with correct PHOENIX content, TLS and canonical link; smoke-test all 16 Craniumtek routes, the 3 iBayong routes and other project websites for no regression. Record release SHA/digest, tunnel/route evidence (no secrets), rollback and owner approval.
7. Keep `phoenx.online` intact until unrelated A.I.D.A login owner and its mail/auth/callback dependencies have been identified; no registrar cancellation or old DNS deletion in this migration.

Cloudflare references:
- https://developers.cloudflare.com/tunnel/get-started/
- https://developers.cloudflare.com/cloudflare-one/troubleshooting/tunnel/
- https://developers.cloudflare.com/tunnel/concepts/routing/
- https://developers.cloudflare.com/tunnel/reference/run-parameters/

Strategic checklist and business release gates: https://github.com/phoenx-online/phoenix/issues/33.

## Production acceptance

Production is GREEN only when all are true:

1. the workflow runs on `craniumtek-phoenix-prod`;
2. exact release SHA is recorded at `/srv/phoenix/RELEASE_SHA`;
3. `phoenix-prod-web` is healthy enough to return the PHOENIX landing page locally;
4. `127.0.0.1:8096` returns HTTP 200;
5. `https://phoenx.live/` returns HTTP 200 and contains “Live Commerce Growth Operating System”;
6. no MBG, Craniumtek, FlashDate, iBayong, or DEV/STAGING path is modified.
