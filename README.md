# PHOENIX — Live Commerce Growth Operating System

PHOENIX is an independent Craniumtek-incubated product for stores, creators, content, media buying, live selling, attribution, finance, and profitable growth.

- **Product / brand:** PHOENIX
- **Primary domain:** `phoenx.online`
- **Canonical GitHub organization:** `phoenx-online`
- **Canonical repository:** `phoenx-online/phoenix`
- **Technology / engineering incubator:** Craniumtek Solutions Inc.

The spelling difference between **PHOENIX** and `phoenx.online` is intentional.

## Current authority

Read these first:

- `SOURCE_OF_TRUTH.md`
- `PHX_M1_STATUS.md`
- `DEV_RUNTIME_BASELINE.md`
- `SECURITY_AUDIT.md`
- `MIGRATION_PLAN.md`
- `docs/decisions/ADR-0001-product-independence.md`

## Product boundary

PHOENIX is operationally separate from Craniumtek corporate systems, Morning Breaks Global, and iBayong. Integrations must use explicit APIs, events, webhooks, imports/exports, or documented contracts rather than shared application databases, runtime secrets, or deployment jobs.

## PHX-M1 development baseline

The historical MariaDB/Droplet execution paths have been removed from the current PHX-M1 branch. The new DEV foundation is:

- Laravel modular monolith
- PostgreSQL 18 authoritative DEV database
- Redis 7 for isolated cache/queue use
- `Dockerfile.dev` + `compose.dev.yml`
- loopback-only application exposure by default (`127.0.0.1:18080`)
- generated PHOENIX-only DEV secrets
- `/healthz` application health endpoint
- PHPUnit smoke tests
- PHOENIX-only self-hosted runner target (`phoenix-dev` label)

Fresh host verification is required before starting containers. See `PHX_M1_STATUS.md` and run `scripts/verify-dev-host.sh` on the intended older DEV server.

## Quick DEV sequence after host gate

```bash
bash scripts/make-dev-env.sh .env.dev 18080
bash scripts/dev-up.sh .env.dev
bash scripts/dev-health.sh .env.dev
```

Do not point `phoenx.online` at DEV. No production deployment or DNS cutover is authorized by the current repository state.
