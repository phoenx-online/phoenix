# PHOENIX DEV Runtime Baseline

Status: APPROVED PREPARATION BASELINE — execution requires host verification

Domain identity updated November 1, 2026; this document is a DEV baseline, not a production cutover authorization.

## Purpose

Define the minimum isolation, cost, safety, and reproducibility rules for the first independent PHOENIX development environment.

This document does **not** authorize production deployment.

## Canonical source

- Repository: `phoenx-online/phoenix`
- Default branch: `main`
- Product: PHOENIX
- Domain: `phoenx.live`

Only the canonical repository may be used as the source for the new PHOENIX runtime.

## Development host

The intended development host must be verified before bootstrap. The older server may be used for PHOENIX DEV if its capacity and isolation gates pass, but this document does not infer a hostname or approve an unverified machine.

Before execution, record:

- hostname
- OS/version
- CPU count/load
- RAM and swap
- free disk space and filesystem
- Docker Engine and Compose versions
- existing services/containers
- listening ports
- backup capacity
- current GitHub self-hosted runners

Do not disturb MBG, iBayong, Craniumtek, or other existing workloads to create PHOENIX DEV.

## Filesystem and account boundary

Preferred DEV layout:

- Linux/service account: `phoenix`
- source checkout: `/home/projects/phoenix`
- private runtime/secrets root: `/home/phoenix-private` or another root-owned/PHOENIX-only path documented during host bootstrap
- backup root: PHOENIX-specific and not shared with another product repository

If the verified host requires another layout, document the exception before use.

## Container namespace

Use a dedicated Docker Compose project name:

`phoenix-dev`

Container, network, and volume names must not collide with MBG, iBayong, Craniumtek, or any production service.

Avoid fixed global `container_name` values unless there is a concrete operational need; Compose project scoping should provide isolation.

## Application baseline

Target architecture:

- Laravel modular monolith
- current supported PHP version compatible with the selected Laravel baseline
- PostgreSQL as the authoritative database
- Redis 7+ for cache, queues, locks, or sessions only where justified
- browser-responsive web/PWA surface first
- object storage abstraction for media/evidence

The current historical `docker-compose.yml`, `Dockerfile`, and `.env.example` must be modernized before runtime use.

## DEV database

Use a dedicated development database, for example:

- database: `phoenix_dev`
- application DB user: `phoenix_dev`

Never reuse MBG, iBayong, Craniumtek, staging, or production database credentials.

PostgreSQL should not be publicly exposed. Bind only within the Docker network or to loopback for explicitly justified local administration.

## Redis

Redis must be PHOENIX DEV-only.

Do not reuse another product's Redis instance, namespace, credentials, or persistent volume unless a later architecture decision explicitly approves a safely isolated shared service.

## Secrets

Rules:

- no real secrets in Git
- no production secrets in DEV
- use PHOENIX-only credentials
- environment files on the host should be readable only by the PHOENIX service account and administrators who require access
- use file mode `600` for private environment files where practical
- rotate any credential if there is evidence it was previously exposed

`.env.example` must contain placeholders only and must not be treated as a deployable environment file.

## Network exposure

DEV should not bind public ports 80/443 directly by default.

Preferred order:

1. private/loopback access for initial bootstrap
2. authenticated tunnel or reverse proxy only when remote testing is required
3. dedicated DEV hostname only after TLS and access controls are ready

Do not point `phoenx.live` or production-facing subdomains at DEV.

## GitHub Actions

Use a dedicated self-hosted runner for PHOENIX DEV.

Recommended labels:

- `self-hosted`
- `linux`
- `x64`
- `phoenix-dev`

Runner rules:

- service account isolated from MBG/iBayong/Craniumtek production users
- no root runner
- no blanket access to unrelated secrets
- no production deployment permission
- workflows should use explicit PHOENIX runner labels
- avoid GitHub-hosted runners as the normal PHOENIX CI/CD path unless an explicit later decision justifies cost and security implications

## Branch and deployment policy

- `main` is canonical source, not an automatic deployment trigger
- feature/fix branches should use PR review/verification before merge
- no workflow may deploy production merely because `main` changed
- DEV deployment/refresh must be explicit and reversible
- staging and production need separate workflows, secrets, runners, and approval gates

## Initial DEV health gate

Before calling DEV operational, require evidence for:

- application boots successfully
- database migrations run cleanly on a fresh empty PostgreSQL database
- Redis connectivity is healthy if enabled
- no service depends on MBG/iBayong/Craniumtek credentials
- health endpoint or equivalent application smoke check passes
- logs are writable without world-writable permissions
- restart/recreate works from source + environment + documented data seed
- no host public port collision
- backup/restore strategy for DEV database is documented

## Next implementation sequence

1. Verify the intended DEV host.
2. Audit the historical Laravel scaffold for completeness and upgrade requirements.
3. Replace legacy MariaDB/MySQL assumptions with PostgreSQL.
4. Replace the legacy Compose definition with an isolated `phoenix-dev` stack.
5. Create placeholder-only DEV environment template.
6. Add application health and smoke tests.
7. Register the dedicated self-hosted runner.
8. Add CI that tests but does not deploy production.
9. Bring up DEV privately.
10. Only after DEV is green, design staging.

## Explicit prohibitions

Until superseded by an approved ADR or source-of-truth change:

- no shared MBG/iBayong/Craniumtek database
- no shared runtime secrets
- no root SSH deployment workflow
- no automatic deployment from `main` to production
- no reuse of the historical MariaDB `changeme`/`rootpass` configuration as runtime credentials
- no production DNS cutover
