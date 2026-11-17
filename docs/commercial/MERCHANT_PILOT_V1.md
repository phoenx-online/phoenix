# PHOENIX — merchant pilot V1
Status: DRAFT / PLANNED SERVICE — not a public offer, live software claim or signed commitment.
Owner directive: 2026-10-05 MASTER CHATGPT WORK — REVENUE FINISH MODE.
Priority: fifth, after Craniumtek, MBG, iBayong and FlashDate.

## Commercial objective
One real merchant commercially commits, pays an approved pilot fee, completes the agreed session, receives an evidence-backed report, and decides whether to renew.
No merchant, payment or delivery is currently verified by this document.

## Smallest proposed offer
“Plan one live-selling session. Connect its orders and costs. Understand the result and the next action.”

Proposed scope: one merchant, one store/channel, one currency and one live session.
Service-assisted delivery may use merchant-authorized exports and an operator-maintained ledger; this does not imply a working PHOENIX application.
Start only after a named operator, merchant consent, written scope, price and payment terms are approved.
Do not sell unavailable software access or unapproved host/studio/advertising services.

Plan → Create → Go Live → Sell → Measure → Improve

| Step | Deliverable | Acceptance evidence |
| --- | --- | --- |
| Plan | Session brief: objective, owner, channel, date, products, costs | Merchant confirms brief and scope |
| Create | Product/run-of-show sheet and order-source plan | Merchant checks SKU, price, stock and host rights |
| Go Live | Merchant-led session with agreed operator support | Session URL/ID and timestamps, or authorized private evidence |
| Sell | Session-associated order ledger | Merchant source records; fulfilment/refund status included |
| Measure | Revenue, attributable contribution and data-quality report | Every input traceable; calculations reconciled |
| Improve | Debrief and one next-session recommendation | Merchant acknowledges delivery and renewal decision |

## Intake — copy for each prospective merchant
- Merchant legal/trading name, authorized contact and preferred channel.
- Store/channel URL; products/SKUs; trading currency.
- Current live-selling problem; desired outcome; existing host/operator.
- Proposed session timing; verified stock and fulfilment owner.
- Available order/export sources and access rights.
- Available product costs, platform/payment fees, host/creator costs and session costs.
- Cancellation/refund handling and reporting cutoff.
- Approved pilot scope, fee, taxes if applicable, payment recipient, due date and refund terms.
- Delivery operator, capacity confirmation and merchant consent.
- Status: inquiry / qualified / scope agreed / commercially committed / paid / delivered / renewal.
Collect only necessary merchant/business information. Prefer exports over passwords; never collect credentials in this document.

## Go/no-go checklist
Proceed only when:
- Merchant confirms authority to share the records and use any supplied media.
- Operator can perform all promised work and has confirmed capacity.
- Price, payment method, scope and cancellation terms are explicitly accepted.
- Data sources allow meaningful reconciliation; limitations are disclosed.
- Merchant owns inventory, sales channel, payments and fulfilment unless separately agreed.
If data is missing, narrow the report; do not claim profitability or certain attribution.

## Results ledger — required fields
Order: merchant/store ID, source system, source order ID, currency, paid timestamp, session ID, attribution basis, collected amount, refunded amount, fulfilment status, source reference.
Costs: cost ID, currency, category, amount, incurred timestamp, session allocation basis, source reference, completeness status.
Use integer minor units with the currency's correct precision. Never combine currencies without an approved conversion policy.
Deduplicate by merchant + source + order ID. Changes and refunds must retain their source and audit history.

### Attribution
Classify orders as direct session evidence / merchant-reported / unattributed.
Direct evidence requires an approved session-specific code, link, source session identifier or equivalent traceable record.
Time proximity alone does not prove attribution. Merchant-reported orders remain explicitly labeled.
Keep direct and reported totals separate; disclose late orders and the reporting cutoff.

### Calculations and truthful labels
For each currency and attribution class:
- Net collected sales = collected amounts minus recorded refunds.
- Contribution = net collected sales minus verified applicable product costs, fees, creator/host costs and session costs.
- State treatment of discounts, tax, delivery charges, returns and overhead in the scope.
- If material costs are unknown, show net collected sales and KNOWN costs; label contribution/profitability INCOMPLETE.
- Do not equate GMV, ordered sales, collected cash and fulfilled sales.
- Keep PHOENIX pilot fee/revenue separate from merchant sales.
- Contribution is not net accounting profit or proof that PHOENIX caused incremental sales.

## Final merchant report
1. Session identity and agreed objective.
2. Source coverage, cutoff and completeness.
3. Orders and net collected sales by attribution class and fulfilment status.
4. Verified costs and contribution, or explicit INCOMPLETE label.
5. Exceptions: duplicates, refunds, unmatched records, missing inputs.
6. One operational improvement for the next session.
7. Delivery acknowledgement and renewal decision.
Use actual evidence only. Any sample/demo report must be visibly labeled SAMPLE.

## Owner decisions before selling
Recommended delivery mode: a limited service-assisted pilot, while the product remains PROTOTYPE/PLANNED.
Melvin must approve a named delivery operator and capacity, pilot price, authorized payment recipient/method and contract/refund terms.
Do not choose a public fee without delivery-cost and merchant-discovery evidence.
Public intake destination/contact must be verified before adding a customer CTA.

## Resume and next execution
1. Verify the contact/intake destination and operator capacity; implement a draft merchant inquiry CTA on the existing visual-first candidate when grounded.
2. After discovery, prepare a priced scope for owner approval; never send externally without authorization.
3. Test a clearly labeled synthetic ledger, then reconcile one consenting merchant's real session records.
4. Record first commercial commitment/payment/delivery only when authoritative evidence exists.
5. Keep PHX-M1/runner gates tracked, but do not make completion of the full platform a prerequisite for a safely deliverable service pilot.

## Evidence at preparation
main: d7a98ddb4f0ec4bcb54afc407fc7a580b8cf414f.
public-site/index.html has no merchant inquiry form/link or pilot offer.
Visual evidence fix remains draft PR #24; runtime/production acceptance remains separate.
This file is prepared commercial scope, not merchant validation.
