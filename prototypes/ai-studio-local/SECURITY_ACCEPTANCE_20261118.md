# PHOENIX AI Studio — Local acceptance and security review (18 Nov 2026)

**Status:** TEST SOURCE IMPLEMENTED / ISOLATED LOCAL TESTS PASS. NOT MERGED, NOT DEPLOYED.
**Scope:** Stacked PRs #45 (scene editor) → #46 (bounded localhost queue) → #47 (AI-plan validation) → this PR.
**Product boundary:** PHOENIX only. No Craniumtek/MBG/iBayong media, databases, secrets or runtime are in scope.

## What was independently checked

The seven Python source/test files needed for the existing unit, queue and HTTP smoke suites were reconstructed in an isolated review container and matched to their GitHub **blob SHAs** from PR #47 head `8f4c78cf033fe9c63c4fd2f406457021819ff990`:

| Path under `prototypes/ai-studio-local/` | Blob SHA |
| --- | --- |
| `server.py` | `71c5efcc115b956e16c12d980cf2d140242dbccb` |
| `studio_jobs.py` | `5f1a958db416cd0e0b89a45949972473c27504bf` |
| `editing_plan.py` | `383b33f1ef24339a178ce053df1788115c8ba84f` |
| `tests/test_server.py` | `60aa23d7d36d09f5210e180146a68b9399da59e6` |
| `tests/test_jobs.py` | `93add4736760ac03bae94a327f99098df179bd12` |
| `tests/test_editing_plan.py` | `0e9a9ca4cc3425d1cc4f42bda555373fa7031ba8` |
| `tests/smoke_http.py` | `493cce695704b3e214ece329e7b963011a47aaff` |

The new `test_plan_render_pipeline.py` was executed alongside those files in the same local test workspace.

### Test evidence — local container, not Server 2

- `python3 -m unittest discover -s tests -v`: **20 tests PASS** (17 existing + 3 new).
- `python3 tests/smoke_http.py`: **PASS**, including denied missing rights, rejected paid provider, disabled legacy endpoint, idempotency and returned H.264 MP4.
- New plan→queue→FFmpeg test: synthetic FFmpeg-created blank image, 2 scene plan, 2-second H.264 output at 360×640, zero-cent cost, queue status DONE, no source image included in status, duplicate idempotency accepted and conflicting duplicate rejected.
- FFmpeg/FFprobe available in isolated reviewer environment. **The test only asserts file format/duration; it does not perform perceptual visual verification or external content QA.**
- No OpenAI inference, provider billing, voice model, external network request, customer upload, marketplace publish or production deployment occurred.

Run these tests at the exact PR head in **isolated Server 2 DEV** before changing the implementation's TESTED status. The reconstructed fixture environment is not proof of Server 2 deployment.

## Security review and release blockers

| Layer | Evidence-based observation | Gate |
| --- | --- | --- |
| PR #45 input | Image extension + magic-header checks; actual decoding happens in FFmpeg | Add media quarantine, actual decoder checks, resource/pixel limits, malware scanning for untrusted uploads |
| PR #45 FFmpeg | Child process timeout and simple render limits exist; no OS-level process sandbox | Container/cgroup/seccomp/AppArmor constraints, read-only filesystem where practical, CPU/memory/process/time caps |
| PR #45 HTTP | Loopback host/origin checks; **no** user identity or tenant access control | No LAN/public proxy or client ingestion; first verify #29/#35 auth and brand scope |
| PR #46 queue | One running, two pending, max 20 retained; thread and temp files | Persistent reconciled queue, crash restart and interruption tests before production |
| PR #46 rights | Boolean acknowledgment, **not verified signed media consent** | Independent rights/claim/performer approvals and versioned ledger |
| PR #47 plans | Allowlisted style/duration/caption schema; model result never controls spend/rights | Check actual OpenAI API structured output semantics later; keep AI untrusted |
| Workflow | No merchant, brand-regulatory or owner approval service | Fail closed for publication; separate reviewers and immutable approved version |
| Secrets/billing | No API secrets and paid providers disabled | Budget authorization, scoped secrets, licensed adapters only after independent approval |
| Source-of-truth | Older docs name `phoenx.online` while owner later selected `phoenx.live` | Treat newer canonical-domain decision as intended; verify routing before any deployment or DNS action |

The PR chain is not ready to merge into public production. Review of these files is **not** a security penetration test, CI pass, staged restore exercise or evidence of real-device acceptance.

## Immediate next action

1. Peer-review the parent PRs and this bounded regression; do not auto-merge.
2. On Server 2, perform read-only preflight: hostname, Docker resources, existing projects, FFmpeg availability, free disk and backup status; do not disturb other stacks.
3. Fetch exact PR head and run the full test suite and HTTP smoke with **synthetic/rights-cleared media** in a restricted local environment. Confirm health, no public ports, output isolation and that current PHOENIX DEV is unaffected.
4. Implement upload quarantine and worker sandboxing **before** any brand or customer media.
5. Integrate into authenticated, tenant-scoped Creative Studio only after #29/#35 foundations; separately authorize any paid OpenAI API calls.
6. Maintain `PLANNED → SOURCE IMPLEMENTED → TESTED (exact branch) → DEPLOYED → PRODUCTION VERIFIED` status evidence. Human review blocks publishing.

This note preserves PHOENIX's approved Graph Engineering boundaries: agents propose; deterministic functions validate/execute; policy and human gates retain authority.
