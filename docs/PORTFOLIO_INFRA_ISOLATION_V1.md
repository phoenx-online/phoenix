# PHOENIX Portfolio Infrastructure Isolation V1

Status: repository-side readiness contract only. This document does not authorize runner registration, production mutation, DNS changes, repository visibility changes, credential changes, or external publication.

## Purpose

Keep PHOENIX logically isolated while sharing only approved host-level infrastructure under Craniumtek portfolio infrastructure Issue #99.

## Required project boundaries

PHOENIX must have its own:
- Linux service/deployment identity on DEV/STAGING and PROD.
- Source/deployment paths.
- Compose project namespace and application network.
- Database, DB role and credentials.
- Environment/secrets boundary.
- Volumes/uploads, logs and retention rules.
- Backup set plus documented restore procedure.
- Health/readiness checks.
- Project-specific self-hosted runner labels and deployment authority.

Generic cross-project runner targeting is not an acceptable final state.

## Delivery evidence

A production candidate is complete only when evidence links establish:
1. DEV exact commit identity.
2. Deterministic tests.
3. STAGING acceptance.
4. Same exact SHA/artifact promoted to PROD.
5. Public/customer route smoke where intended.
6. Health/readiness and observability.
7. Backup/restore proof.
8. Rollback capability and post-deploy smoke.

## Resource discipline

Measure CPU/RAM/container usage before assigning limits. Build, browser and queue workloads should remain dormant when idle. Required customer-facing services must not be shut down merely to save power.

## Trust boundary

Do not attach a privileged self-hosted runner while repository/runner trust remains unresolved. Never reuse another project's application credentials, database, filesystem, runner identity or deployment authority.

## Stop conditions

Stop and escalate before any destructive production migration, runner-token use, root/bootstrap action, DNS/Cloudflare mutation, credential/ownership change, irreversible cleanup, spending, or external publication.
