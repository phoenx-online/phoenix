# PHOENIX Source of Truth

Status: APPROVED BASELINE — PHX-M0.6

## Product identity

- Product name: **PHOENIX**
- Primary domain: **phoenx.live**
- Category: **Live Commerce Growth Operating System**
- Positioning: One system for stores, creators, content, media buying, live selling, attribution, finance, and profitable growth.
- Technology / engineering incubator: **Craniumtek Solutions Inc.**

PHOENIX is a separate product boundary. It is not a module of Craniumtek corporate systems, Morning Breaks Global, or iBayong.

## Canonical GitHub identity

- GitHub organization display name: **PHOENIX**
- GitHub organization handle: **`phoenx-online`**
- Canonical repository: **`phoenx-online/phoenix`**
- Repository numeric ID: **`1094814392`**
- Default branch: **`main`**
- Current repository visibility: **public** pending a deliberate visibility decision

The native GitHub transfer and repository rename are complete. Both the former personal path `melvin826/phoenix-enterprise-core` and the pre-rename organization path `phoenx-online/phoenix-enterprise-core` resolve to the canonical repository.

## Separation policy

PHOENIX SHALL have independent:

- GitHub organization and canonical repository
- application source tree
- database
- authentication and authorization boundary
- runtime secrets
- storage volumes / object storage
- Docker project / containers
- CI/CD pipeline and self-hosted runner
- logging and observability boundary
- backups and restore procedures
- deployment lifecycle

Cross-product interaction with Craniumtek, Morning Breaks Global, and iBayong SHALL use explicit APIs, events, webhooks, imports/exports, or other documented integration contracts. Shared application tables or shared runtime secrets are prohibited.

## Relationship to other products

### Craniumtek Solutions Inc.
Craniumtek is PHOENIX's technology / engineering incubator and may own, build, operate, support, or commercialize PHOENIX. PHOENIX remains product-operationally independent.

### Morning Breaks Global
MBG is an external client/integration from PHOENIX's perspective. MBG-specific teachers, students, classes, packages, and education workflows SHALL NOT become PHOENIX domain models.

### iBayong
iBayong is an external marketplace/integration from PHOENIX's perspective. iBayong buyer, seller, marketplace listing, and marketplace transaction records SHALL remain in iBayong. PHOENIX may consume approved commerce data only through documented integration contracts.

## Six product pillars

1. **Store & Marketplace Growth** — products, catalogs, listings, inventory, offers, orders, marketplace operations and growth.
2. **Creator, Affiliate & Talent Network** — creators, live sellers, affiliates, recruitment, product matching, commissions and performance.
3. **Content & Creative Production** — briefs, scripts, UGC, video, assets, approvals, publishing and creative performance.
4. **Performance Marketing, Paid Ads & Media Buying** — media plans, budgets, bidding, amplification, pacing, optimization, attribution, ROAS, CAC, CPO and GMV.
5. **Live Selling Operations** — hosts, schedules, products, scripts, studio operations, live sessions, traffic amplification, QA and conversion.
6. **Commerce Intelligence, Finance & Attribution** — revenue, costs, commissions, settlements, attribution, profitability, forecasting and executive reporting.

## V1 wedge

The deepest V1 capability is **Live Selling Operations**, connected to creators, content, media buying, products/orders, and an attribution ledger. PHOENIX should not attempt to become a general ERP or consumer marketplace in V1.

## Canonical shared PHOENIX entities

- organizations
- brands
- stores
- marketplaces
- products
- catalogs
- inventory
- creators
- affiliates
- hosts
- campaigns
- content_assets
- live_sessions
- media_plans
- ad_campaigns
- media_budget_ledger
- orders
- attributions
- commissions
- settlements
- costs
- revenue

## Architecture baseline

Target application architecture:

- Laravel modular monolith
- PostgreSQL authoritative database
- Redis for cache / queues / locks where justified
- browser-responsive operations interface / PWA first
- object storage for media/evidence
- Docker-isolated environments
- self-hosted GitHub Actions for controlled CI/CD
- separate DEV, staging, and production runtime boundaries

The existing November 2025 scaffold is historical and is NOT automatically authoritative for runtime architecture. In particular, the current `docker-compose.yml`, `Dockerfile`, `.env.example`, old Nginx files, and any legacy deploy material require explicit modernization before runtime use.

The obsolete GitHub Actions workflow that auto-deployed every `main` push to a DigitalOcean droplet as `root` has been physically removed. No automatic deployment from `main` is currently authorized.

## Owner domain change — November 1, 2026

The owner selected **phoenx.live** as PHOENIX's primary canonical website domain, replacing the former phoenx.online identity. This is an identity and migration decision, **not evidence that DNS cutover, production launch, or legacy-domain deletion has been executed**.

- Do not delete, cancel, or repurpose the old registration until ownership and all traffic, mail, auth, integrations, callbacks, SSL, and other service dependencies have been audited.
- Public inspection on the decision date found the old hostname returning an A.I.D.A console login rather than the expected PHOENIX landing page. Identify that service's owner and avoid displacing it.
- No production activation is authorized by this domain-identity edit alone.
- Follow `docs/domain-migration-2026-11-01.md` for cutover, checks, rollback, and retirement.

## Domain baseline

Primary product/domain identity:

- `phoenx.live` — public product domain
- `www.phoenx.live` — public marketing site if required
- `app.phoenx.live` — application
- `api.phoenx.live` — API when required
- `admin.phoenx.live` — platform administration when separately justified

The intentional spelling difference is authoritative: the **product/brand is PHOENIX**, while the **domain is phoenx.live**.

Subdomains SHALL only be activated when the corresponding service exists and is independently secured.

## DEV runtime baseline

Independent DEV preparation SHALL follow `DEV_RUNTIME_BASELINE.md`.

Key rules:

- use a PHOENIX-only Linux/service account where practical
- canonical DEV checkout path: `/home/projects/phoenix` unless the verified development host requires another documented path
- Docker project namespace: `phoenix-dev`
- PostgreSQL database: `phoenix_dev`
- Redis isolated to PHOENIX DEV
- PHOENIX-only secrets and environment files
- self-hosted GitHub Actions runner dedicated to PHOENIX DEV
- no GitHub-hosted runner requirement for normal PHOENIX CI/CD
- no MBG, iBayong, or Craniumtek production credentials, volumes, databases, or deployment jobs
- no production deployment until a separate production gate is approved and verified

## Current migration state

Completed:

1. PHOENIX organization created.
2. GitHub integration connected to `phoenx-online`.
3. Native repository transfer completed without changing repository ID.
4. Repository renamed to the canonical `phoenx-online/phoenix` path.
5. PR and branch continuity verified.
6. Obsolete automatic DigitalOcean deployment workflow removed.
7. Old personal and pre-rename repository paths resolve to the canonical repository.

Pending deliberate decisions / work:

- repository visibility review: keep public or change to private
- modernization of the legacy application/runtime scaffold
- independent DEV host verification and bootstrap
- self-hosted PHOENIX DEV runner setup
- test/CI baseline
- staging architecture
- production architecture and capacity gate
- DNS activation only after a real secured target exists

No production deployment is authorized by this source of truth.
