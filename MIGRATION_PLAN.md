# PHOENIX GitHub Organization + Domain Migration Plan

Status: PHX-M0.6 — repository migration complete; DEV preparation next

## Canonical identity

- Product / brand: **PHOENIX**
- Primary domain: `phoenx.live`
- GitHub organization display name: **PHOENIX**
- GitHub organization handle: **`phoenx-online`**
- Canonical repository: **`phoenx-online/phoenix`**
- Repository numeric ID: **`1094814392`**
- Default branch: `main`

The product/brand spelling and domain spelling are intentionally different and must not be normalized automatically.

## November 2026 primary-domain decision

Primary PHOENIX domain is now **phoenx.live**. The former registration must be inventoried and retired only after the new public website is verified and the A.I.D.A console currently observed at the old hostname has been identified and protected. The change must not automatically deactivate legacy DNS, email, or app logins. See `docs/domain-migration-2026-11-01.md`.

## Gate 1 — Create organization

**COMPLETED.** The organization exists at `github.com/phoenx-online`.

## Gate 1A — Connect GitHub integration

**COMPLETED.** The GitHub app/connector is installed and authorized for `phoenx-online`.

## Gate 2 — Transfer canonical repository

**COMPLETED.** GitHub native transfer moved:

`melvin826/phoenix-enterprise-core`

into:

`phoenx-online/phoenix-enterprise-core`

The repository numeric ID remained `1094814392`, confirming continuity rather than recreation.

## Gate 2A — Remove obsolete executable deployment path

**COMPLETED.** `.github/workflows/deploy.yml` was physically removed before further main-branch development.

That historical workflow had automatically deployed every `main` push to a DigitalOcean droplet using a GitHub-hosted runner, root SSH, legacy `/var/www/phoenix` assumptions, and permissive deployment commands. It is not part of the current PHOENIX architecture.

## Gate 3 — Preserve repository history

**VERIFIED for the available continuity signals.**

Verified after transfer:

- repository numeric ID unchanged
- default branch preserved
- commit history remains visible from the November 2025 initial commit onward
- expected branches preserved
- PRs #1 through #6 preserved
- former personal repository path resolves to the canonical repository chain
- no destructive history rewrite performed

Tag enumeration was not independently available through the current connector action set. No destructive tag operation is authorized.

## Gate 4 — Rename repository to canonical name

**COMPLETED.** Repository renamed from:

`phoenx-online/phoenix-enterprise-core`

to:

`phoenx-online/phoenix`

## Gate 4A — Post-rename verification

**COMPLETED.** Verified:

- repository owner is `phoenx-online`
- repository name is `phoenix`
- repository ID remains `1094814392`
- default branch remains `main`
- branches remain intact
- PR history remains intact
- old personal URL resolves to `phoenx-online/phoenix`
- pre-rename organization URL resolves to `phoenx-online/phoenix`
- `SOURCE_OF_TRUTH.md` remains present
- `.github/workflows/deploy.yml` is absent
- repository remains public pending an explicit visibility decision

## Gate 5 — Independent DEV preparation

**CURRENT ENGINEERING GATE.** Follow `DEV_RUNTIME_BASELINE.md`.

Before starting an executable DEV runtime:

1. Verify the intended development host and available CPU, RAM, storage, Docker, network, and backup capacity.
2. Confirm PHOENIX gets an isolated Linux/service account or equivalent least-privilege boundary.
3. Clone only the canonical repository `phoenx-online/phoenix`.
4. Use a PHOENIX-only project path, database, Redis boundary, secrets, Docker namespace, runner, logs, and backups.
5. Modernize the legacy runtime scaffold before bringing it up.
6. Replace MariaDB/MySQL assumptions with the approved PostgreSQL baseline unless a later ADR supersedes this decision.
7. Do not expose DEV directly on public ports 80/443 by default.
8. Use self-hosted GitHub Actions for PHOENIX CI/CD; do not reintroduce GitHub-hosted deployment jobs as the default path.
9. Add a test/health gate before any staging or production environment is considered.

## Gate 6 — Repository visibility decision

**PENDING DELIBERATE OWNER DECISION.** The repository is currently public.

Do not change visibility automatically. Before choosing public vs private, review:

- whether any current or historical files expose internal architecture that should not be public
- whether secrets were ever committed historically
- intended open-source/commercial licensing strategy
- whether public source materially helps customer acquisition or product trust
- whether private source better protects unreleased commercial implementation

If visibility changes, verify repository access, GitHub App access, Actions, forks, and external links afterward.

## Gate 7 — Staging

**NOT STARTED.** Staging requires:

- modernized application scaffold
- green DEV tests
- independent secrets
- staging database and Redis
- isolated staging Docker project
- staging self-hosted runner or an explicitly approved isolated runner strategy
- rollback and backup/restore evidence

## Gate 8 — Production

**NOT AUTHORIZED.** Production requires a separate capacity and security gate.

Production must not reuse MBG or iBayong credentials, database volumes, deployment jobs, or application secrets. Shared physical hardware may be considered only if resource capacity, blast-radius isolation, backups, monitoring, and rollback are verified.

## Gate 9 — Domain activation

Use `phoenx.live` as the primary public domain only after the corresponding secured runtime exists.

Recommended mapping:

- `phoenx.live` / `www.phoenx.live` -> public site
- `app.phoenx.live` -> application
- `api.phoenx.live` -> API only when required
- `admin.phoenx.live` -> administration only when a separate surface is justified

Before DNS cutover:

- confirm registrar and DNS-provider control
- configure TLS
- verify origin isolation
- verify canonical redirects
- ensure no existing service is displaced
- complete application health checks and rollback preparation

## Explicit non-goals for PHX-M0.6

- no production deployment
- no DNS cutover
- no MBG changes
- no iBayong changes
- no Craniumtek production changes
- no activation of the historical Docker/deploy scaffold without modernization
