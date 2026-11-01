# PHOENIX — Live Commerce Growth Operating System

PHOENIX is an independent Craniumtek-incubated product for stores, creators, content, media buying, live selling, attribution, finance, and profitable growth.

- **Product / brand:** PHOENIX
- **Primary domain:** `phoenx.live`
- **Canonical GitHub organization:** `phoenx-online`
- **Canonical repository:** `phoenx-online/phoenix`
- **Technology / engineering incubator:** Craniumtek Solutions Inc.

The spelling difference between **PHOENIX** and `phoenx.live` is intentional.

## Domain migration notice

As of November 1, 2026 the approved canonical PHOENIX domain is **https://phoenx.live/**. This repository change does not by itself activate public DNS, transfer existing email/auth records, or decommission the previous domain. See [domain migration runbook](docs/domain-migration-2026-11-01.md).

## Current authority

Read these before using any historical runtime or deployment artifact:

- `SOURCE_OF_TRUTH.md`
- `MIGRATION_PLAN.md`
- `DEV_RUNTIME_BASELINE.md`
- `SECURITY_AUDIT.md`
- `docs/decisions/ADR-0001-product-independence.md`

## Product boundary

PHOENIX is operationally separate from:

- Craniumtek corporate systems
- Morning Breaks Global
- iBayong

Integrations must use explicit APIs, events, webhooks, imports/exports, or documented contracts rather than shared application databases, runtime secrets, or deployment jobs.

## Repository status

The original personal repository was transferred natively into the dedicated PHOENIX organization and renamed to this canonical repository. GitHub repository ID `1094814392` was preserved through transfer and rename, along with branch and PR continuity.

The obsolete historical GitHub Actions workflow that auto-deployed every `main` push to a DigitalOcean droplet has been removed.

## Runtime warning

The remaining November 2025 Docker, MariaDB/MySQL, Nginx, environment, and deployment artifacts are historical. They are **not approved as the current PHOENIX runtime definition** and must be modernized before execution.

The approved target architecture is a Laravel modular monolith with PostgreSQL, Redis where justified, Docker-isolated environments, self-hosted GitHub Actions, and separate DEV/staging/production boundaries.

No production deployment or DNS cutover is authorized by the current repository state.
