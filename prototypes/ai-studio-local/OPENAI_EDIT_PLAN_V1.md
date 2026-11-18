# PHOENIX AI Studio — OpenAI Editing Plan Contract V1

**Status:** SOURCE IMPLEMENTED / LOCAL UNIT TESTED ONLY. This is a draft-only source slice stacked on PR #46, which itself depends on PR #45. Do not merge, expose publicly, upload client assets, or deploy because this file exists.

## Decision (18 November 2026)

Use OpenAI as a **planning assistant**, not a shell-enabled video editor. The model can propose constrained scene order, shot style, duration and on-screen captions. The trusted application validates that proposal and separately supplies an approved real source image, operator rights acknowledgment, zero-cost ceiling and idempotency key. FFmpeg performs deterministic rendering in the existing localhost prototype.

The API call is **NOT** implemented or made in this change. No API key is needed. The module is deliberately not connected to the current browser route.

## Trust boundaries

1. AI proposal: `schema_version` plus `scenes` only. A scene contains `style`, `seconds`, `caption`. **No** shell command, provider choice, price, rights flag, publishing permission or remote URL is accepted in the plan.
2. Local validation: `validate_edit_plan` enforces allowlisted styles, 1–6 scenes, 1–6 seconds per scene, 24 seconds total, 90-character caption limit, and no control characters. Extra keys are rejected.
3. Independent human gate: the caller supplies real reference media, confirms its authorized use and signs off copy/claims before a preview job. The validator does **not** grant legal/merchant/regulatory permission.
4. Deterministic job: `build_local_preview_job` emits the current PR #46 `local_ffmpeg` queue contract, requiring exact 0-cent maximum and safe idempotency key. Existing image parsing and rights/cost checks remain in place.
5. Independent QA: output stays internal, watermarked and unavailable for publishing.

## Example model output (safe internal demonstration only)

```json
{
  "schema_version": "phoenix.edit_plan.v1",
  "scenes": [
    {"style": "hero", "seconds": 2, "caption": "Product photo — internal concept"},
    {"style": "detail", "seconds": 3, "caption": "Use verified packaging photo"},
    {"style": "closing", "seconds": 2, "caption": "Approval pending"}
  ]
}
```

This example is not a healthcare claim or a product advertisement.

## Example local integration (future caller; does not run automatically)

```python
from editing_plan import validate_edit_plan, build_local_preview_job

model_response = {"schema_version": "phoenix.edit_plan.v1", "scenes": [
    {"style": "hero", "seconds": 2, "caption": "Internal concept"}
]}
reviewed = validate_edit_plan(model_response)
# The current app must independently verify claims/rights and obtain operator approval.
job = build_local_preview_job(
    model_response,
    image_data_url=approved_local_data_url,
    rights_confirmed=True,  # trusted operator confirmation, NEVER model output
    idempotency_key="internal-test-0001",
    max_cost_cents=0
)
# Only after a secure caller exists: submit(job) through the existing local queue.
```

The example variable `approved_local_data_url` must be supplied by an authorized local operator. No remote URL or public network call is supported.

## Local test command

```bash
cd prototypes/ai-studio-local
python3 -m unittest discover -s tests -p 'test_editing_plan.py' -v
```

Initial isolated local result: **7 tests PASS** for this new module. This is **not** exact-checkout branch CI, a full FFmpeg integration test, or Server 2 acceptance. The remaining suite and negative end-to-end tests must be re-run after branch checkout before accepting this PR.

## Before any API-enabled iteration

- Confirm OpenAI plan schema against the selected API model and current documentation.
- Add *server-side* credentials and an approved spending budget only after separate authorization. ChatGPT Plus is not a free production API quota.
- Use private test media and no customer/regulated product files until secure user auth, tenant isolation, image quarantine, malware scanning, and worker resource limits are verified.
- Preserve signed client/brand/regulatory, merchant, talent/voice and owner approvals. AI cannot self-approve claims or publish posts.
- Confirm that PRs #45 and #46 are reviewed and merged safely before deriving an integrated DEV feature. No Server 1 production changes.

Tracks #41, #42 and #44. The current V1 priority remains Live Selling Operations; the editor is a scoped creative-support slice, not a new public application.
