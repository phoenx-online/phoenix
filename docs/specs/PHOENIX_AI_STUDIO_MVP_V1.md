# PHOENIX AI Studio V1 — Architecture & Delivery RFC
Status: PLANNED / DOCUMENTATION ONLY
Date: 2026-11-17 PHT
Parent tracking: https://github.com/phoenx-online/phoenix/issues/42
Related pilot: https://github.com/phoenx-online/phoenix/issues/41

## 1. Objective and non-goals

Build a PHOENIX-owned, brand-scoped AI presenter video workflow inside the existing Content & Creative Production pillar. One authorized creator can prepare a script, choose a consented avatar or provider-supplied licensed avatar, render one 15–30 second talking-head video, review it and download the locked final export. Do not copy HeyGen proprietary software, UI assets, pricing or models.

The V1 outcome is one *demonstrable, independently verified* draft-to-render-to-QA flow in isolated DEV. It does not imply public release, client data intake, paid API activation, or automatic social publishing.

Out of scope: public creator SaaS, live/real-time avatar agents, unrestricted voice cloning, training custom high-fidelity foundation models, bulk generation, marketplace auto-publishing, ads purchasing, unlicensed model hosting, video editing suite replacement.

## 2. Design principles

- Graph Engineering: agent helps with storyboard and script; deterministic services own persistence, rights checks, billing limits, job dispatch, retry and audit.
- Real product imagery must remain faithful. Never use generated packaging as evidence of an actual commercial SKU.
- Use PHOENIX's existing brand roles/tenancy work (#29/#35). Do not invent a new authentication silo.
- Storage is private. Access is brand- and role-scoped with signed, short-lived downloads.
- Licensing: verify both program code AND model weights/dependencies for commercial use before installation.
- Personal likeness and voice require explicit, verifiable consent, limited scope, revocation and deletion paths.
- No public promotion or generation for sale until merchant, claims, rights, platform and human approvals pass.

## 3. Initial user experience

**Screen A — Content Studio list:** brand, brief, format, rights status, render budget, job status, last edit.
**Screen B — New AI video:** brand -> 9:16 template -> consented avatar -> verified script -> language/voice -> preview/cost estimate.
**Screen C — Render job:** one authorization dialog; queue position/status, provider job identifier, elapsed time, cost estimate and failure reason.
**Screen D — Review:** original brief, final locked script, media-rights links, render preview, version and technical QA; approve/rework buttons.
**Screen E — Approved file:** download authorized MP4, captions, link to audit/approval evidence; publish only manually via authorized account handler in V1.

V1 workflow:
DRAFT -> CLAIMS_RIGHTS_CHECK -> SCRIPT_REVIEW -> APPROVED_TO_RENDER -> QUEUED -> RUNNING -> RENDERED -> QA_PENDING -> QA_PASS -> RELEASE_REVIEW -> APPROVED_AS_ASSET.
Alternate states: HOLD, REWORK, FAILED, CANCELLED, REVOKED. Never automatically transition to PUBLISHED based on rendering success.

## 4. Minimal data contract (subject to current schema audit)

Prefer extending existing entities only after inspection:
- Existing organization/brand, staff membership, content_assets, content briefs.
- `ai_video_projects`: brand_id, brief_id, creator_id, version, format, title, approved_script_ref, avatar_consent_ref, template_ref, status, generated_at, created_at.
- `ai_video_jobs`: project_id, render_version, provider, provider_job_id (nullable), idempotency_key unique, requested_cost_ceiling, measured_cost, status, attempts, queued_at, started_at, completed_at, failure_code.
- `ai_media_permissions`: brand_id, asset_id, owner identity reference (private), consent proof pointer, allowed operations, allowed platforms, expiry/revoked timestamps.
- `ai_review_events`: project/job version, reviewer_id, decision, gate type, evidence URI, timestamp. Immutable append-only review events preferred over mutable approval flags.

Do not add these tables automatically before auditing current migrations. Keep minimal slice; avoid financial-transaction abstractions not needed for limited generation cost.

## 5. Provider adapter

The browser never receives provider API keys. Laravel service calls a provider adapter through a restricted worker. Initial interface:

```php
interface AvatarVideoProvider {
    public function estimate(RenderRequest $request): EstimatedCost;
    public function submit(RenderRequest $request, string $idempotencyKey): ProviderJob;
    public function status(string $providerJobId): ProviderStatus;
    public function cancel(string $providerJobId): ProviderCancelResult;
    public function result(string $providerJobId): RenderArtifact;
}
```

Provider adapter returns normalized status, provider reference, duration, cost evidence and output file URL/handle. Download provider artifacts into private PHOENIX storage after malware/media format checks. Authenticate and verify webhooks if offered; fallback to bounded polling. Never treat a vendor callback as authority to publish.

Begin with an isolated fake/stub provider for tests. Only connect a billed provider after budget authorization and consent are proven. HeyGen API is an option, *not* a required dependency. The standard HeyGen Creator subscription and HeyGen API credits are distinct billing products.

## 6. Implementation boundary and runtime

Browser UI -> Laravel app -> PostgreSQL canonical metadata + private object storage -> Redis-backed job worker if justified -> provider API -> private media QA -> human approval. Server 2 is DEV/STAGING candidate; Server 1 is production-only and requires its own capacity, security and release checks. No unverified GPU inference on the production host. Existing GTX 1650 4GB live-production PC is not adequate evidence for high-fidelity diffusion avatar generation at scale.

Provider choice is reversible: swap behind adapter. Never load prompt inputs containing private customer information, unapproved brand secrets or sensitive employee records into third-party APIs without applicable terms and approvals.

## 7. Guarded operations

- Direct actor (authenticated creator) requests render of immutable script/media version.
- Policy gate checks media rights, consent, review approvals, ceiling vs available project budget, allowed provider, valid marketplace/product restrictions when applicable.
- Transactional DB insert records `QUEUED`, a unique idempotency key, immutable script hash and an estimated maximum charge before dispatch.
- Worker performs bounded retries and reconciliation; avoid duplicate paid submit after ambiguous timeout unless vendor API guarantees idempotency or canonical reconciliation succeeds.
- Provider output is untrusted; verify audio/video duration, codec, format, resolution, absence of external leaks, transcription accuracy, face consent and disclosure needs.
- Independently approved final file can be downloaded, but publishing is reserved for client-authorized operator.
- Consent revocation blocks future renders and triggers data retention/deletion workflow, including provider-side deletion when contract/API supports it.

## 8. QA gates and negative tests

1. Non-brand staff GET/POST/edit/render/download attempts return forbidden without leaking private metadata.
2. Editor cannot self-approve policy or client regulatory material; no privilege escalation.
3. Missing consent, revoked consent or unlicensed avatar blocks render.
4. Missing verified SKU claims or final creative approval blocks product promotion.
5. Repeated render button and duplicated webhook cannot generate multiple billable jobs.
6. Provider timeout/429/cancellation produce bounded state, explicit user message and reconciliation evidence.
7. Failed render never produces an approved video; no automatic publish.
8. Expired download token, oversized file, unsupported media, malware finding block exposure.
9. Signed cost ceiling is enforced before submit; measured vs billed cost reconciled.
10. Rejected or revised script produces new version and invalidates affected approvals.
11. Demo runs on test fixtures without real user/brand photos or private customer data.
12. Exact code SHA, CI test report, staged video evidence and rollback plan accompany next release review.

Record each test as PASS, FAIL, NOT_RUN or N/A with reason. Do not claim successful video output until it is actually rendered and inspected.

## 9. Licensing / provider due diligence

- HeyGen official API can render avatars and translators for pay-as-you-go credits; verify current API terms, avatar consent mechanisms, output ownership, data retention, disclosure and rate/credit limits.
- MuseTalk publishes MIT code and model weights generally permitted for commercial use, but external dependencies require independent review. It is not HeyGen-equivalent and published lip-sync limitations remain.
- LivePortrait's MIT code license specifically warns that bundled InsightFace models are noncommercial; replace that component and confirm all dependencies before commercial use.
- Voice models such as F5-TTS may have commercial-code/noncommercial-checkpoint split. Commercial training/use must not assume MIT code alone covers pretrained weights.

## 10. Release plan (status gates)

- PLANNED: RFC, acceptance and budget scope agreed.
- IN PROGRESS: dev branch and private fixture setup.
- IMPLEMENTED: stub/adapter/UI/schema/approval gates committed.
- TESTED: negative isolation, QA, idempotency, failure and media smoke tests pass on exact SHA.
- DEPLOYED: isolated staging, not production.
- PRODUCTION VERIFIED: later approval after capacity, security, DNS, backups and rollback.
- REVENUE READY / REVENUE VALIDATED: distinct merchant funding and actual paid fulfilled production proof; video output alone is not revenue.

## 11. Pilot and next engineering tasks

- Establish the initial five controlled Content Studio assignments from #41; use AI avatar script testing only with permissioned non-selling or fully approved materials.
- Verify repo's actual executable branch/auth models and existing pending PRs before coding.
- Implement provider stub with no paid rendering first.
- Evaluate one funded provider against realistic talking head quality and cost metrics on a consented test asset.
- Compare against licensing-safe self-hosted lip-sync as a separate technical spike; no unapproved hardware purchases.

**Current state:** documentation/design only. Not coded, not tested, not deployed.
