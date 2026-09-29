# Production Delivery Completion Standard V1

Status: Approved cross-project engineering baseline  
Effective: 2026-09-22 PHT

## Purpose

AI-assisted coding can produce changes faster than a human can safely qualify and release them. The delivery system must therefore optimize not only for coding speed, but for deterministic verification and safe production promotion.

A feature is **not complete when code is written**.

A production-bound feature is complete only when the exact accepted release is:

1. implemented as the smallest useful vertical slice;
2. verified by deterministic affected-module tests;
3. qualified by the applicable synthetic/user-facing acceptance;
4. promoted through the project's authorized staging/release path;
5. identified by exact source commit SHA and, when an immutable artifact exists, artifact digest;
6. protected by rollback or forward-repair readiness appropriate to its risk;
7. deployed only through the project's existing production authority gate;
8. verified after deployment with bounded smoke/health checks;
9. observable enough to detect introduced failures;
10. recoverable without improvising an unsafe production repair; and
11. accompanied by release evidence sufficient to reproduce what was shipped and why it was accepted.

## Build once, promote the same release

Where the project produces a deployable artifact, build it once from the accepted source and promote that same immutable artifact through qualification and production.

Do not rebuild materially different artifacts for staging and production.

Release identity should be recorded as:

- source commit SHA;
- artifact/image digest when applicable;
- migration/schema state when applicable;
- configuration version or non-secret configuration contract when materially relevant.

## Verification graph

Default release graph:

`requirement → implementation → affected tests → synthetic acceptance → staging acceptance → rollback/backup readiness → production authority gate → promotion → post-deploy verification → evidence → close`

Independent read-only or non-mutating verification may run in parallel. Shared-core writers, migrations, financial mutations, irreversible actions, and production deployment remain serialized behind the appropriate gates.

## AI authority rule

AI may diagnose failures, propose or implement source-controlled fixes, run authorized non-destructive verification, and improve the delivery system.

AI must not:

- waive a failed gate;
- claim success from code generation alone;
- bypass authentication, RBAC, security, migration, financial, backup, privacy, or production authority controls;
- turn a staging pass into implicit production authorization;
- use unrestricted production shell/database/secrets/DNS/payment authority;
- conceal an unresolved failure by weakening tests.

## Failure-to-automation rule

Repeated failures must become engineering inputs.

When the same class of failure recurs, prefer a permanent deterministic control such as:

- runner health/preflight checks;
- environment-parity checks;
- dependency/build reproducibility;
- migration preflight;
- automated synthetic acceptance;
- artifact/SHA verification;
- smoke tests;
- observability/alerting;
- rollback validation;
- resumable/idempotent deployment steps;
- evidence capture.

Do not normalize repeated manual repair as the release process.

## Fast shipping without weak shipping

Optimize for time to **safe user value**, not time to generated code.

Prefer:

- one production-critical candidate at a time;
- smallest complete vertical slices;
- affected-module tests first;
- reusable canonical acceptance;
- build-once/promote-same-artifact;
- automatic evidence generation;
- bounded retries;
- automatic recovery only where authority and safety permit;
- immediate continuation to the next highest-value user bottleneck after production verification.

## Project-specific boundary

No production deployment or DNS activation is authorized by this standard. Preserve PHOENIX-only runtime, database, secrets, runner, observability, backup, and deployment boundaries.

This standard is additive. If a project-specific canonical security, data, role, migration, backup, acceptance, or production gate is stricter, the stricter project-specific rule remains authoritative.

## Definition of CLOSED

For production-bound work, documentation, code completion, CI activity, or staging success alone is not CLOSED.

CLOSED means the accepted production release is verified, observable, recoverable, and evidenced.

For work that is explicitly non-production by scope (research, planning, prototype, local-only scaffold, documentation-only change), closure must be stated as that narrower scope and must never be represented as a deployed capability.
