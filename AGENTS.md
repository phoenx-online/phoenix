# AGENTS.md — PHOENIX

## Canonical preflight

Before material planning, coding, runtime, CI/CD, DNS, database, or deployment work, read:

1. `SOURCE_OF_TRUTH.md`
2. `DEV_RUNTIME_BASELINE.md`
3. `MIGRATION_PLAN.md`
4. `SECURITY_AUDIT.md`
5. `docs/GRAPH_ENGINEERING.md`
6. `config/agent_graph.php`

Do not treat the legacy scaffold as automatically authoritative.

## Independence boundary

PHOENIX is a separate product boundary. Do not use MBG, iBayong, or Craniumtek application databases, runtime secrets, storage, deployment jobs, or product-specific domain models as PHOENIX internals.

Cross-product interaction must use an explicit API, event, webhook, or documented import/export contract.

## Graph Engineering rule

New AI-assisted workflows must use the Graph Engineering pattern:

- AI nodes reason, classify, plan, summarize, or recommend.
- Deterministic functions own canonical writes and calculations.
- Policy gates enforce scope, RBAC, security, financial, and release rules.
- Human gates own material judgment and exceptions.
- Verification independently checks side effects.
- Retries are bounded and writes are idempotent or deduplicated.
- Graph state must support exact resume.
- No AI node receives unrestricted production shell, database, secrets, payment, DNS, or deployment authority.

## Current priority

The V1 product wedge is Live Selling Operations. Graph work should strengthen that wedge and the required foundation rather than expanding PHOENIX into a general ERP or consumer marketplace.

## Production rule

No production deployment, production DNS activation, real-money workflow, or automatic deployment from `main` is authorized merely because a graph contract exists. Existing source-of-truth gates remain authoritative.

## Production Delivery Completion Standard

Before production-bound release work, read `docs/PRODUCTION_DELIVERY_COMPLETION_STANDARD_V1.md` and `config/production-delivery-standard.json`.

A feature is not complete merely because code or CI is complete. Production-bound work closes only after the exact accepted release is safely promoted through existing project gates, verified in production, observable, recoverable, and evidenced.

Use build-once/promote-the-same-artifact where an immutable artifact exists. Record exact source SHA and artifact digest when applicable. AI may diagnose or fix a failed gate but may never waive it. Convert recurring deployment failure classes into deterministic automation instead of normalizing repeated manual repair.
