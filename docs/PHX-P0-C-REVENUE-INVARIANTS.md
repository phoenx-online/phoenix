# PHX-P0-C Revenue Invariants

Status: implementation gate

These invariants apply to the Live Selling Operations V1 commerce slice and MUST be enforced deterministically before the slice can be considered runtime GREEN.

## Tenant isolation

- Every order, attribution, cost, live session, store, and product is owned by exactly one `organization_id`.
- Cross-tenant references MUST fail at the database or authorization boundary.
- No query may infer tenant ownership from an external reference alone.

## Money and currency

- Monetary values use integer minor units only.
- Currency is an explicit three-letter ISO code.
- An attribution currency MUST equal its order currency and live-session reporting currency.
- A cost included in session profitability MUST use the same reporting currency; conversion is out of scope for V1.
- Negative order and cost amounts are invalid. Attribution amounts must be positive.

## Attribution conservation

For each order, the sum of accepted attribution amounts MUST NOT exceed the order amount.

This invariant requires a transaction-safe application service because it spans multiple rows. The service MUST lock the relevant order/attribution set before validating and writing. Retries must be safe and deterministic.

## Idempotency

- Imported orders are idempotent by `(organization_id, store_id, external_ref)`.
- Session/order attribution is unique by `(organization_id, live_session_id, order_id)`.
- Reprocessing the same external event MUST not increase revenue twice.

## Session profitability

For one tenant, one session, and one currency:

`attributed_revenue_minor = SUM(attributions.amount_minor)`

`cost_minor = SUM(costs.amount_minor)`

`profit_minor = attributed_revenue_minor - cost_minor`

No floating-point arithmetic is permitted.

## Deterministic verification gate

Before runtime GREEN, automated tests MUST prove:

1. same-tenant order attribution succeeds;
2. cross-tenant order/session attribution fails;
3. attribution currency mismatch fails;
4. attribution above remaining order amount fails;
5. duplicate external order import is idempotent;
6. duplicate session/order attribution does not double-count;
7. profitability uses exact integer arithmetic;
8. concurrent attribution attempts cannot over-attribute an order;
9. migration up/down/up succeeds on PostgreSQL;
10. `/healthz` remains GREEN after migrations.

AI may diagnose or propose fixes for a failed gate, but MUST NOT waive any gate.

## Release evidence

A releasable build records source commit SHA and immutable artifact digest. The same artifact is promoted through DEV and staging. Production remains gated by the PHOENIX capacity/owner approval boundary and is controlled separately from build/test runners. Post-deploy smoke failure requires rollback rather than gate waiver.
