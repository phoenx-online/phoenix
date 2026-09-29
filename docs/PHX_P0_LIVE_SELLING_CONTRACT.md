# PHX-P0 Live Selling Revenue Contract

Status: IMPLEMENTATION CONTRACT — Issue #11

This contract narrows the approved PHOENIX V1 wedge into the first revenue-capable vertical slice. `SOURCE_OF_TRUTH.md` remains authoritative.

## Product boundary

PHOENIX owns this slice independently. No Morning Breaks Global, iBayong, or Craniumtek application table, secret, database, storage volume, runtime, or authentication boundary may be reused.

## Pilot outcome

A tenant operator can configure one store, products and host, schedule and complete a live-selling session, record attributable commerce results, and inspect session-level revenue and profitability evidence.

## Minimum domain

Every tenant-owned row MUST carry `organization_id` and be authorized against the authenticated organization.

- `organizations`: tenant root.
- `brands`: tenant brand identity.
- `stores`: selling channel/store under a brand.
- `products`: tenant product/SKU with active state.
- `hosts`: live seller/creator identity.
- `live_sessions`: store + host + schedule + lifecycle.
- `live_session_products`: products assigned to a session.
- `orders`: external or manually captured commerce result; external references are idempotent per store.
- `attributions`: immutable attribution of an order amount to a live session.
- `costs`: session-scoped operating cost entries.

## Money and time invariants

- Store money as integer minor units; never floating point.
- Store an explicit ISO-4217 currency code with monetary records.
- Persist timestamps in UTC; presentation may localize them.
- Revenue for a session = sum of attributable order minor units for accepted orders.
- Cost for a session = sum of session cost minor units.
- Profit = revenue - cost.
- An order may not be attributed beyond its accepted monetary amount.
- Retrying the same external order ingestion or attribution command MUST NOT duplicate revenue.

## Live-session state machine

States: `draft`, `scheduled`, `live`, `completed`, `cancelled`.

Allowed transitions:

- draft -> scheduled
- draft -> cancelled
- scheduled -> live
- scheduled -> cancelled
- live -> completed
- live -> cancelled

`completed` and `cancelled` are terminal for V1. Invalid transitions MUST fail deterministically without mutation.

## Tenant and authorization gates

- Every read and mutation is scoped by authenticated `organization_id`.
- Foreign tenant identifiers MUST behave as unavailable to the caller and MUST NOT leak row contents.
- Cross-tenant assignment (for example, tenant A session to tenant B product/host/store) MUST fail.
- Protected mutations require an authenticated authorized operator.
- Tenant-isolation and authorization denial paths require automated tests before runtime acceptance.

## Deterministic acceptance suite

1. Migrations apply from an empty PostgreSQL database.
2. Required foreign keys, uniqueness constraints and money checks are database-enforced where practical.
3. Tenant A cannot read/update/delete tenant B brand, store, product, host, session, order, attribution or cost.
4. Invalid live-session lifecycle transitions fail without mutation.
5. Replayed external-order ingestion remains idempotent.
6. Replayed attribution remains idempotent.
7. Revenue/cost/profit calculations use integer arithmetic and match fixtures exactly.
8. `/healthz` remains GREEN.
9. No cross-product runtime dependency is introduced.

A repository-only review may validate design and static code. Runtime GREEN requires these tests on the isolated PHOENIX DEV environment; AI may repair failures but may never waive a gate.

## Delivery graph

`source SHA -> deterministic build -> immutable artifact digest -> DEV verification -> staging verification -> production approval/capacity gate -> production controller -> post-deploy smoke -> keep or rollback`

Build once and promote the same immutable artifact. Release evidence MUST record source commit SHA and artifact digest. Build/test runners MUST NOT hold production deployment authority. Production remains prohibited until the Craniumtek production-server capacity gate is GREEN and the production controller is separately authorized.

## Pilot completion evidence

The first revenue-capable release is not complete until evidence contains:

- exact source SHA;
- immutable artifact digest;
- migration/test results;
- tenant-isolation results;
- lifecycle/idempotency/calculation results;
- DEV and staging smoke results;
- production capacity/approval evidence;
- production smoke result if deployment is authorized;
- rollback result when a post-deploy gate fails.
