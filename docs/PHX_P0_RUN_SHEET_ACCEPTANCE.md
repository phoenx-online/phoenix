# PHOENIX P0 — Live Session Run Sheet Acceptance V1

Status: engineering acceptance contract; not production proof.

## Purpose
Define the minimum deterministic operator lifecycle for a pilot live-commerce session without fabricating merchants, creators, sales, revenue, or campaign results.

## State machine
DRAFT -> READY -> LIVE -> COMPLETED -> REVIEWED

CANCELLED is terminal and may be entered only from DRAFT or READY.

## Acceptance rules
- DRAFT -> READY requires authenticated operator, tenant/store context, scheduled start, responsible operator, and non-empty run-sheet checklist.
- READY -> LIVE requires the same tenant/store context and an explicit start action; no automatic transition.
- LIVE -> COMPLETED requires explicit stop/end action and end timestamp.
- COMPLETED -> REVIEWED requires an evidence note. Unknown metrics remain UNKNOWN; they must never be synthesized.
- Skip transitions (for example DRAFT -> LIVE or READY -> COMPLETED) are rejected.
- A session cannot change tenant/store ownership after creation.
- Repeated transition requests must be idempotent or safely rejected and must not duplicate effects.
- Every accepted transition records actor, previous state, next state, and timestamp in an audit trail.

## Isolation / Issue #99
This contract grants no production, DNS, root, secret, runner-token, cross-project filesystem, database, or deployment authority. DEV/STAGING/CI must use PHOENIX-specific identity, paths, network, database role/credentials, volumes, logs, backups, health/readiness, and runner labels.

## Deterministic test gate
A future implementation is not accepted until automated tests prove:
1. all valid transitions;
2. all prohibited skip transitions;
3. CANCELLED terminal behavior;
4. tenant/store immutability;
5. authentication requirement;
6. UNKNOWN metric behavior;
7. transition audit evidence;
8. idempotent/rejected duplicate actions.

Production remains unproven until DEV -> tests -> STAGING -> acceptance -> exact SHA/artifact -> PROD -> smoke -> monitoring -> rollback is evidenced.
