# PHOENIX Brand Portal — Onboarding V1
**Status:** IMPLEMENTED CONTRACT / NOT A LIVE USER FEATURE  
**Issue:** #29  
**Contract:** `config/brand-onboarding-v1.json`  
**Scope:** PHOENIX-owned client accounts, brand onboarding, document review, and operations handoff, initially for Live Selling Operations and Account Handler services.

## Product purpose
Client organizations sign into the PHOENIX app, register one or more brands, and supply the business information, source-of-truth documents, approvals and channel access PHOENIX needs to deliver agreed services. After review, onboarding seeds human-owned work in PHOENIX. The brand can monitor missing requirements, progress, approvals and operational reports without repeated ad-hoc chats.

This contract is *not* permission to collect real documents now. The current repository has a separate static public site and an incomplete historical Laravel app scaffold. A verified secure authenticated backend is a prerequisite.

## Personas and access
| Persona | Minimum authorized capability |
|---|---|
| Brand owner | Verify legal/brand authority, invite/revoke brand members, approve the agreed scope, view own brands |
| Brand admin | Complete questionnaires, upload/update own brand files, designate approvers within approved authority |
| Brand contributor | Edit assigned draft sections only |
| Brand finance approver | Approve financial or budget requests only within explicit delegated limits |
| PHOENIX super admin | Manage system policy; audited break-glass access only |
| PHOENIX operations manager | Review approved brand scope, assign internal teams, see assigned operational work |
| PHOENIX account handler | Manage listings, catalog, order and fulfillment operations for assigned stores within grants |
| PHOENIX creator/live lead | Manage hosts, scripts, samples, schedules, live QA and assigned sessions |
| PHOENIX content lead | Access approved creative briefs, product images, content approvals |
| PHOENIX media buyer | Access approved channel scopes and ad budgets; request higher-spend human approval |
| PHOENIX compliance reviewer | Review verification, product-category documents and claims without automatically publishing or approving restricted items |
| PHOENIX finance | Access contract/fee data needed for invoices and reconciliations, not unrestricted operational docs |

One person can belong to multiple organizations with separate grants. Every request, query and object lookup must enforce `organization_id` and, where applicable, `brand_id`. UUIDs alone are not access controls. Audit all document views/downloads, approval decisions and membership changes.

## Proposed product surfaces
- Public site: `/brands` explainer + explicit **Request onboarding** CTA, *not* a real submission/upload form until secured.
- Secure app: `app.phoenx.online/register`, `/login`, `/brands`, `/brands/{brand}/onboarding`, `/brands/{brand}/documents`, `/brands/{brand}/requests`, `/brands/{brand}/operations`.
- PHOENIX staff: `app.phoenx.online/operations/onboarding`, `/operations/brands/{brand}` and scoped task queues.
- No separate auth database in the public static deployment. All app endpoints require verified server-side authentication.

## Guided onboarding
Version 1 defines **8 sections, 65 question keys, 13 document categories** in the JSON contract:
1. Company identity and authorized contacts.
2. Brand, products, claims and regulatory risk.
3. Marketplace shops, official delegated access and existing restrictions.
4. Stock ownership, warehouses, fulfillment, returns and city distributors.
5. Live selling, creator/affiliate operations, training and sample stock.
6. Content, approved assets, ad platforms, budget and approval authority.
7. Contracted services, reporting cadence, targets and escalation contacts.
8. Requirement checklist, accurate-information attestation, privacy notice and scoped authorization.

### Interaction requirements
- Ask service selection early and use it to show relevant conditional sections. Always allow review/edit before submission.
- Save each answer server-side with validation and tenant scope; maintain a `draft` until explicit submit. Offline/browser-local drafts are never a substitute for the server.
- Mobile-first stepper; completion state, document badges, help text, accessible labels and graceful resumes; use progressive disclosure and prefill verified non-sensitive data.
- Capture units explicitly (PHP, weight, pieces, time zone Asia/Manila). Ask for percentage/commission fields only after commercial scope is clear.
- Maintain a versioned snapshot at each submission/re-submission, so changes made after review do not silently alter earlier approval evidence.
- No custom arbitrary HTML or executable content in responses or staff rendering; encode output and validate size/content.
- Requiredness applies only when relevant: no unnecessary personal identity documents, no forced sensitive information, no blanket requirement for every document type.

### Brand-specific conditional module: Alphagenix / KAYAMO
- Health-related SKU/claims questions and manual regulatory review as applicable; uploads for applicable product evidence and approved labels/claims, not an assumption that every product has a particular permit.
- Territory-aware city distributor roster, legal stock owner, authorized selling channels, price parity/minimum approved prices, discount controls and returns liability.
- Main-office live selling order allocation/crediting rules must be contractually approved; no assumed direct order diversion from stock-owning city distributors.
- Distinguish inventory held by KAYAMO HQ, independent city distributors, consignment partners and samples. Do not combine physical stock in a single unqualified balance.
- Official TikTok Shop sub-accounts and scoped permissions; never ask client for login passwords, recovery codes, MFA OTPs or bank passwords.

## Data model (candidate)
- `organizations` — contracting legal entities, own client memberships and document access policies.
- `brands` — one or more brands per organization, with separate questionnaires and services.
- `organization_memberships` — user ID, organization ID, role, invite status, invitation expiry and audit fields.
- `brand_onboardings` — brand ID, questionnaire version, status, revision, submitted/reviewed timestamps and reviewers.
- `brand_onboarding_answers` — onboarding ID, question key, JSON value, version, actor and timestamps; server validates contract keys and data types.
- `brand_documents` — organization/brand/onboarding IDs, type, private object key, MIME, SHA-256, size, scanner/verifier status, version, uploader, expiration, retention policy.
- `brand_platform_connections` — platform, brand/store IDs and **authorization status/limited token reference** only; secrets kept separately in a secrets manager, never in the repo or logs.
- `brand_approval_requests` — action, proposed change, permission scope, spend (when relevant), requested/approved/rejected by, timestamps and immutable evidence.
- `brand_onboarding_events` — append-only audit events (actor, tenant, object, action, IP where lawful/necessary, timestamp, correlation ID).
- `brand_operations_tasks` — brand and workstream IDs, assignee/role, priority, due date, status, source evidence and completion.
- `brand_distributor_policies` — territory, independent stock owner, allowed channel, price rules, attribution and fulfillment routing.
- `brand_service_engagements` — services, statement of work version, effective dates, operational limits, human approval matrix.

Use PostgreSQL, strict FK/uniqueness where safe, authorization policies at the application boundary and database isolation protections where justified. Do not build a complete ERP in V1.

## Workflow states
`draft -> submitted -> under_review -> approved -> activated` with `needs_information` loop and `rejected` terminal/manual appeal. Transition to activated **only after** validated contract scope, access, required docs, compliance, and human approval. If the contract or restricted-category requirements change, request re-review.

Separate **document** lifecycle: `quarantined -> scanning -> ready_for_review -> approved`; branches to `rejected` or `expired`. Uploaded material cannot be served while quarantined or unscanned.

### Task handoff by PHOENIX pillar
| Pillar | Task creation after explicit approval |
|---|---|
| Store & Marketplace Growth | Create store/setup checklist, catalog/image upload, pricing and promotions, approved user invitations, stock/fulfillment coordination |
| Creator, Affiliate & Talent | Host sourcing/training, affiliate agreements, sample release requests, commission setup |
| Content & Creative | Product shoot, scripts, live frames, thumbnails, short-form assets, brand approvals |
| Performance Marketing & Ads | Ad account access request, media plan, budget approval, creative test and performance reporting |
| Live Selling Operations | Live-room readiness, equipment/OBS setup, schedule, host/moderator roles, promo scripts and QA |
| Commerce Intelligence / Finance | SKU economics and approved KPI definitions, GMV reporting, settlement/commission reconciliation, reporting cadence |

Reviewers must see missing items and risk flags. PHOENIX account handlers receive only approved fields, approvals and attachments needed for their responsibilities. Background task creation is deterministic/idempotent, with unique event/source keys; AI can help summarize or spot missing items but cannot approve budgets, compliance, credentials or settlements.

## Document and privacy protection — mandatory gates
- Provide a privacy notice explaining collection purposes, recipients, lawful basis per data category, retention schedule and request rights; obtain consent when legally necessary, not as an indiscriminate substitute for all lawful bases. Use Philippine DPA (RA 10173) and NPC IRR as release review sources.
- Private object storage only, no anonymous URLs, temporary downloads authorized on every request, encryption at rest/in transit, tenant-bound keys, safe filenames and isolated malware quarantine/scanning.
- Allow PDF/JPG/PNG/CSV/XLSX per schema, maximum 20 MiB by default, explicit server validation, content inspection, rate limits and storage quotas. Reject executable scripts/macros/unsafe formats; CSV formula injection protection before exports.
- Do not solicit passwords, OTPs, tokens, bank login details, personal IDs, or scans of sensitive identity records unless a justified legal/compliance workflow is separately designed.
- Granular approvals/roles, account verification, MFA for privileged roles, rate limits, session expiry and revocation, audit and incident handling.
- Document lifecycle controls: requested, supplied, quarantine/scan, reviewer decision, redaction where possible, expiry reminders, retention/deletion, legal hold only when authorized.
- Health-related products require claim, listing, advertising and seller eligibility review by authorized humans; never auto-publish or auto-amplify restricted claims based on LLM text.

## Engineering milestones / release gates
**M0 — Current branch:** versioned questionnaire/document contract, product architecture and acceptance criteria. This is a foundation artifact, not a running portal.
**M1 — Secure app foundation:** complete runnable Laravel bootstrap, verified PostgreSQL migration, auth, email verification, membership policies, secure private storage and malware pipeline. Separate app routing from static landing page.
**M2 — Brand draft onboarding:** organization/brand CRUD, dynamic conditional questionnaire, save/resume, validations and isolated document review.
**M3 — PHOENIX review and delivery:** review queues, missing-info requests, approval audit, role assignment and deterministic operation task handoff.
**M4 — Client pilot:** test with synthetic data first, then explicitly authorized Alphagenix/KAYAMO pilot, regulatory review and city distributor protections.
**M5 — Public launch:** staging evidence, accessibility/mobile E2E, cross-tenant tests, backup/restore, rollback and security/privacy approval before production cutover.

### Staging end-to-end acceptance
- Brand A owner/member and PHOENIX assigned staff can access only Brand A; Brand B responses, private files, URLs, search, exports and tasks remain inaccessible.
- Brand can register/invite, verify email, complete conditional questionnaire, save/resume, submit, receive missing-info request, upload new version, resubmit and see status; incomplete required legal/commercial fields block approval.
- Malware-like upload and unsupported file types are rejected/quarantined; signed links expire; no raw storage path exposed.
- Internal review and task creation are idempotent and audit-logged; no unauthorized ad spend, listing promotion or financial action.
- Revoking member or shop delegation immediately cuts new access; historical approval evidence remains audit-consistent.
- Fresh PostgreSQL migration, rollback, backend tests, UI tests and deployment smoke pass with immutable commit/digest evidence.

## Current dependency / visibility blocker
On 2026-11-01, externally requesting `https://phoenx.online` returned an **A.I.D.A Console Login** redirect at `/login`, not the PHOENIX public preview shown in the current repository. Verify Cloudflare/domain origin routing, current production source, ownership, TLS and any overlapping application before sending client onboarding traffic. Do not publish collection endpoints or change DNS automatically.

## Non-goals for first release
- No payments or financial settlements without a separate approved workflow.
- No password/OTP collection for third-party marketplaces.
- No auto-approval of regulated health claims, brand contracts, or budget changes.
- No cross-product databases or shared tenant secrets.
- No implicit production deployment from this contract.
