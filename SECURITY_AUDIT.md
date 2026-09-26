# PHOENIX Security Audit

Status: **PHX-M1 — DEV foundation hardening in progress**

## Scope

This audit covers `phx-m1-dev-foundation` in the canonical repository `phoenx-online/phoenix`. It focuses on repository execution risk, DEV isolation, secrets, and CI/CD safety. It is not a production penetration test and does not authorize production.

## Resolved execution risks

The current PHX-M1 branch physically removes these superseded paths:

- `.github/workflows/deploy.yml` — already removed in PHX-M0.5; no automatic main-to-DigitalOcean deployment remains
- root `Dockerfile` — removed; it used the historical PHP 8.2/MySQL runtime
- root `docker-compose.yml` — removed; it used MariaDB, literal example passwords, fixed container names and public 80/443 bindings
- `deploy/deploy-enterprise.sh` — removed; it upgraded the host, used `/var/www/phoenix`, contained destructive clone assumptions and production-like root operations
- `deploy/nginx_phoenix.conf` — removed; it represented an obsolete host/domain layout
- `database/seeders/AdminUserSeeder.php` — removed; it contained the hardcoded example admin password `password123` and referenced a non-canonical legacy user model

Git history preserves these artifacts for audit, but they are no longer executable current paths.

## Modernized DEV controls

PHX-M1 adds:

- PostgreSQL as the authoritative DEV database
- Redis isolated inside the PHOENIX DEV Docker network
- loopback-only application host binding by default
- no host PostgreSQL or Redis port publication
- project-scoped Compose naming; no fixed global `container_name`
- generated local DEV secrets in ignored `.env.dev`
- mode 600 on generated DEV environment files
- no production secrets in templates
- `/healthz` Laravel health endpoint
- PHPUnit smoke tests
- read-only DEV host verifier
- manual-only self-hosted CI workflow
- dedicated `phoenix-dev` runner label

## P0/P1 open gates

### P0 — Fresh host verification before execution

The intended older DEV host is `craniumtek-lab-01`. Prior evidence is acceptable planning context but not sufficient to start a new stack. Run `scripts/verify-dev-host.sh` immediately before bootstrap and stop on critical failures.

### P0 — Public repository + self-hosted runner exposure

The repository is currently public. Do not register the PHOENIX self-hosted runner until repository visibility is changed to private or a deliberate public-source runner security model is approved.

The prepared `ci-dev.yml` is therefore `workflow_dispatch` only. It does not automatically execute untrusted pull-request code.

### P1 — Repository history exposure

Historical commits contain known placeholder/example credentials such as `changeme`, `rootpass`, and `password123`. Current PHX-M1 files remove those executable examples, but history remains public while the repository remains public.

No evidence in the current review proves those placeholders were live credentials. Nevertheless, never reuse them, and rotate any credential if external evidence shows it was ever deployed.

### P1 — Docker privilege boundary

A self-hosted runner user with Docker access effectively has powerful host capabilities. Treat the runner as trusted-code execution, keep it repository-scoped, run it as the `phoenix` user rather than root, and never expose unrelated product or production secrets to it.

### P1 — Older mechanical disk

The intended DEV host uses an older mechanical HDD with historical SMART warnings. Prior short/long tests completed without error, but PHOENIX DEV must not treat that machine as the sole backup location. A current SMART/backup check remains part of the host gate.

## Secrets policy

- no real secrets in Git
- no production secrets in DEV
- generated PHOENIX-only DB/application credentials
- private env files, mode 600 where practical
- no shared MBG/iBayong/Craniumtek credentials
- no registration token stored in repository or retained documentation
- rotate any credential proven to have been exposed

## CI/CD policy

- self-hosted PHOENIX DEV runner only after the exposure gate
- repository-level runner initially
- non-root runner account
- no automatic production deployment from `main`
- CI uses isolated `phoenix-ci-*` project namespaces and ephemeral local env files
- CI cleanup removes containers, volumes and ephemeral env material
- staging and production require separate later gates

## Runtime isolation policy

PHOENIX DEV must have independent:

- Linux account/path boundary
- Docker project/network/volumes
- PostgreSQL database/user/volume
- Redis volume/namespace
- secrets
- logs
- backups
- self-hosted runner

Shared physical DEV hardware with iBayong is permitted only while these boundaries and resource limits remain intact. Production resources are out of scope.

## Current acceptance sequence

1. Fresh host verification.
2. Review warnings/current workload.
3. Build PHX-M1 branch privately on `craniumtek-lab-01`.
4. Generate DEV secrets locally.
5. Start `phoenix-dev` stack and pass PostgreSQL/Redis/HTTP gates.
6. Run Laravel migration + PHPUnit smoke tests.
7. Resolve repository visibility before runner registration.
8. Register PHOENIX-only runner.
9. Run manual self-hosted CI and verify cleanup.
10. Perform restart/recreate and DEV backup/restore smoke test.

## Production authorization

**NONE.** No production deployment, DNS cutover, production credentials, or cross-product runtime sharing is authorized by PHX-M1.
