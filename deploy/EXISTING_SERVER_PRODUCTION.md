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

## Existing Cloudflare Tunnel route

Add these ingress routes to the existing production tunnel, preserving all current Craniumtek/MBG/Cranium AI/FlashDate routes:

```yaml
- hostname: phoenx.live
  service: http://localhost:8096
- hostname: www.phoenx.live
  service: http://localhost:8096
```

Keep the fallback rule last. Validate before restart:

```bash
sudo cloudflared tunnel ingress validate
curl --fail http://127.0.0.1:8096/
```

Then reload/restart the existing cloudflared service using the same service ownership already used on `craniumtek`.

## Production acceptance

Production is GREEN only when all are true:

1. the workflow runs on `craniumtek-phoenix-prod`;
2. exact release SHA is recorded at `/srv/phoenix/RELEASE_SHA`;
3. `phoenix-prod-web` is healthy enough to return the PHOENIX landing page locally;
4. `127.0.0.1:8096` returns HTTP 200;
5. `https://phoenx.live/` returns HTTP 200 and contains “Live Commerce Growth Operating System”;
6. no MBG, Craniumtek, FlashDate, iBayong, or DEV/STAGING path is modified.
