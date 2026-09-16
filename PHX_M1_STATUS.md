# PHX-M1 — Independent DEV Foundation

Status: **IN PROGRESS — repository foundation prepared; fresh host evidence required before runtime start**

## Objective

Execute the approved PHX-M1 sequence:

1. verify the older development server
2. modernize the Laravel scaffold
3. establish an isolated PostgreSQL + Redis DEV stack
4. register a PHOENIX-only self-hosted runner
5. start DEV privately and pass health tests

No production deployment or DNS cutover is part of PHX-M1.

## Intended DEV host

Canonical intended older DEV host: **`craniumtek-lab-01`**.

Recent prior audit evidence recorded for this machine:

- role: shared development/lab only; not production
- OS: Ubuntu 26.04.1 LTS / Ubuntu 26.04 family
- CPU: 2 cores
- RAM exposed to OS: approximately 6.4 GiB
- swap: 4 GiB
- root filesystem: approximately 458 GiB total with approximately 409 GiB free at the prior audit
- storage: 500 GB Seagate ST9500325AS mechanical SATA HDD
- prior SMART evidence: short/long tests completed without error, with historical disk-health warnings that mean this machine must not hold sole backups
- Docker: 29.1.3 at prior audit
- separate DEV accounts: `ibayong` and `phoenix`
- expected PHOENIX paths: `/home/phoenix/projects` and `/home/phoenix/private`
- expected iBayong paths: `/home/ibayong/projects` and `/home/ibayong/private`
- heavy build jobs should be serialized because this is a 2-core, limited-RAM development machine

This evidence is useful baseline context but does **not** replace a fresh read-only verification immediately before starting PHOENIX containers.

## Fresh host gate

Run from the intended host:

```bash
cd /home/phoenix/projects/phoenix
bash scripts/verify-dev-host.sh
```

The verifier is read-only. It records current hostname, OS, CPU, RAM/swap, free disk, Docker/Compose access, containers, listening ports, account boundaries, runner processes, backup signals, and best-effort SMART health.

PHOENIX runtime startup remains blocked if the verifier reports any critical failure.

## Repository modernization completed on PHX-M1 branch

Prepared on `phx-m1-dev-foundation`:

- corrected Composer PSR-4 namespace and canonical package identity
- modern Laravel application bootstrap (`artisan`, `bootstrap/app.php`, HTTP entrypoint)
- canonical PHOENIX brand configuration
- PostgreSQL database configuration
- isolated Redis cache/queue configuration
- DEV-safe file sessions
- container-friendly logging
- writable Laravel runtime directory placeholders
- `/healthz` application health endpoint through Laravel bootstrap
- PHPUnit health/identity smoke tests
- `Dockerfile.dev` with PostgreSQL + Redis extensions
- `compose.dev.yml` with project-scoped services and no public database/Redis ports
- app HTTP bound to loopback only (`127.0.0.1`)
- generated DEV-only secrets helper
- DEV up/down/health scripts
- manual-only self-hosted CI workflow using `phoenix-dev` runner label

## Obsolete execution paths physically removed on PHX-M1 branch

The following historical runtime/deployment paths were removed from the current branch rather than merely hidden:

- root `Dockerfile` using PHP 8.2 + MySQL extensions
- root `docker-compose.yml` using MariaDB, literal example passwords, fixed container names, and host ports 80/443
- `deploy/deploy-enterprise.sh`, which performed host package upgrades, root-level deployment and destructive `/var/www/phoenix` replacement assumptions
- `deploy/nginx_phoenix.conf`

Git history preserves the old material for audit/recovery; it is no longer an executable current path.

## DEV stack boundary

Current target services:

- application: Laravel / PHP DEV container
- database: PostgreSQL 18, internal Docker network only
- Redis: Redis 7, internal Docker network only
- application host port: loopback-only, default `127.0.0.1:18080`
- Docker Compose project: `phoenix-dev`
- database: `phoenix_dev`
- DB user: `phoenix_dev`
- secrets: generated locally into ignored `.env.dev`, mode 600

No MBG, iBayong or Craniumtek database, Redis, secrets, volumes or deployment jobs are used.

## Self-hosted runner gate

The repository is currently **public**. Do **not** register the PHOENIX self-hosted runner yet.

Reason: a self-hosted runner attached to a public repository increases exposure to untrusted contribution/workflow scenarios. The initial workflow is therefore `workflow_dispatch` only and cannot auto-run on pull requests.

Before runner registration, either:

1. make the repository private (recommended for the current unreleased commercial product), then verify GitHub App access; or
2. explicitly approve a public-source security model with runner groups, contribution restrictions and workflow approval rules.

Runner registration also requires a short-lived GitHub registration token that is not exposed by the current connector and must be obtained through GitHub's repository Actions runner setup UI.

## Private DEV startup gate

After fresh host verification is GREEN and repository/runner exposure is resolved:

```bash
cd /home/phoenix/projects/phoenix
bash scripts/make-dev-env.sh .env.dev 18080
bash scripts/dev-up.sh .env.dev
```

Then require:

```bash
bash scripts/dev-health.sh .env.dev
```

Expected GREEN evidence:

- PostgreSQL `pg_isready` passes
- Redis returns `PONG`
- Laravel `/healthz` returns HTTP 200
- PHOENIX home page tests pass
- no service binds public 80/443
- no MBG/iBayong/Craniumtek credential dependency

## Remaining PHX-M1 gates

- fresh `craniumtek-lab-01` verification output
- branch runtime build/test on the real host
- repository visibility decision before self-hosted runner registration
- PHOENIX-only runner registration as non-root user
- manual self-hosted CI GREEN
- private DEV restart/recreate test
- DEV database backup/restore smoke test

Only after all are GREEN should PHX-M1 be merged/closed and staging design begin.
