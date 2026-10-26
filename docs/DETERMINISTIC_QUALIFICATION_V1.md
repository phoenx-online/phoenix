# PHOENIX Deterministic Qualification V1

Status: repository-side qualification contract for the current revenue-capable V1 candidate.

## Objective

Qualify PHOENIX changes deterministically without weakening the project isolation and runner trust boundary.

## Required gates

1. Identify the exact candidate commit SHA.
2. Run deterministic application tests against that exact candidate.
3. Record the test command, result, and evidence URL or artifact.
4. Perform DEV health/readiness checks using PHOENIX-only configuration.
5. Promote the same exact SHA/artifact to STAGING only after tests pass.
6. Record STAGING acceptance evidence.
7. Production remains gated until explicit production authority and all Issue #99 isolation requirements are satisfied.
8. After any authorized production promotion, require smoke, monitoring, backup/restore evidence, and rollback capability.

## Runner trust rule

Do not attach or target a generic/shared privileged self-hosted runner merely to obtain a green check. A PHOENIX runner must have project-specific labels, paths, credentials and deployment authority. Until that trust boundary is verified, use repository-safe qualification methods only.

## Minimum deterministic test scope

- application boots in the intended engineering environment;
- public homepage renders;
- Visual-First truth labels remain present;
- Live Selling Operations is represented as the V1 wedge without claiming unverified production capability;
- health/readiness behavior is deterministic where implemented;
- no test requires credentials or resources owned by another portfolio project.

## Evidence record

For each candidate record:

- exact commit SHA;
- test command/workflow identity;
- status and conclusion;
- environment;
- date/time;
- artifact/log URL where available;
- known gaps;
- promotion decision.

No candidate is called release-qualified solely because code exists or a pull request is mergeable.

## Stop conditions

Stop and escalate rather than bypass controls if qualification would require:
- another project's runner, credentials, database, filesystem or deployment authority;
- repository visibility changes;
- runner registration tokens;
- production/root/DNS changes;
- spending or external publication.

This document does not authorize merge, production deployment, DNS, credentials, runner registration, repository visibility changes, spending or external publication.
