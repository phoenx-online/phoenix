# PHOENIX AI Studio — Local Video Editing Proof of Concept

**Status:** Isolated developer prototype. This is NOT a public PHOENIX feature and does NOT use generative AI, call Kling/Runway/Google Flow, authenticate users, store customer assets, or publish content.

## Purpose

Implement the smallest testable piece of the PHOENIX Content Studio roadmap: real product photo -> multi-scene editable shot list -> local H.264 MP4 -> independent QA/approval. It simulates camera push/detail effects using FFmpeg. Original package details come from the source photograph, not regenerated synthetic packaging.

## Run in a trusted isolated development environment

Requires Python 3.10+, `ffmpeg` compiled with `libx264` and `drawtext`, and DejaVuSans font at `/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf`.

```bash
# From the downloaded ZIP, after extraction:
cd phoenix_ai_studio_prototype
# Or, inside the GitHub repo:
# cd prototypes/ai-studio-local
python3 server.py
# Open http://127.0.0.1:8766 in the same computer's browser
```

Upload a real product photo (PNG/JPEG/WebP, max 8 MB). Adjust scenes, durations, caption fields. Click **Export internal MP4**. The output is a 720×1280 silent MP4 with a mandatory **INTERNAL CONCEPT — NOT APPROVED FOR PUBLICATION** watermark. Max 6 scenes / 24 seconds. The server binds ONLY to `127.0.0.1`, and request origin/host, type and size are checked. Media is deleted from temporary disk after processing; the final file downloads to the user's device. Do not use sensitive client data in this MVP.

## Tests

```bash
python3 -m unittest discover -s tests -v
```

Tests cover malicious/invalid input refusal, duration ceiling, file type verification, and an actual FFmpeg 9:16 MP4 smoke export. No production application routes, databases, CI/CD or DNS are modified.

## Known limitations and next gates

- Visual preview uses an HTML image and simple transforms; final MP4 is rendered by FFmpeg and may differ slightly. No actual AI generation, avatars, background replacement, text-to-video, multi-reference keyframes, effects marketplace, voice, timeline video editing or project persistence.
- The endpoint is local and single-user; **do not deploy publicly**, reverse-proxy it, or treat it as authenticated client file storage. Security approval is needed before even considering network access.
- Validate media decoding and enforce CPU/memory/process quotas in a sandboxed worker before accepting untrusted uploads from users. Files are temporary, but this prototype is NOT hardened against resource exhaustion or malformed image codecs.
- To join the Laravel application later, reimplement protected upload/quarantine and brand-scoped file/role policies from #29/#35. Retain #41 client-regulatory and merchant publication gates.
- Add a licensed commercial provider adapter only after approving API terms, cost ceilings, brand/model usage rights and retry protection. Until then this is a local product-motion editor rather than an AI generator.

Tracks issue #44, with source intent from #42 and #41. Proposed future promotion requires exact-SHA tests, security/tenant proof, independent staging, backup/rollback and owner release approval. **Never deploy it to Server 1 directly.**

## V0.2 local queue extension (17 November 2026)

The queue workflow is deliberately **not cloud AI generation** and **not integrated with Laravel authentication**. It remains localhost-only and intended for non-sensitive test media; brand scopes, tenant isolation, database-backed durability, malware scanning, provider contracts and cost-ledger settlement are still pending.

- `studio_jobs.py` provides a single FFmpeg preview worker with a queue of two pending requests, and at most three queued/running requests.
- Every job requires `provider=local_ffmpeg`, `rights_confirmed=true` and `max_cost_cents=0`. Nonzero budgets and external AI providers fail closed.
- A repeat request with the same idempotency key and identical content returns the existing job; conflicting content with the same key returns HTTP 409.
- `POST /api/jobs` creates the zero-cost job (HTTP 202); `GET /api/jobs/{id}` reports status; `GET /api/jobs/{id}/video` downloads completed MP4s. `POST /api/render` is disabled (HTTP 410) to avoid bypassing gates.
- Jobs are ephemeral; rendered files expire 15 minutes after completion and the server removes the temporary root when shut down. At most 20 jobs are retained per process. Results remain watermarked internal concepts.
- The UI requires rights acknowledgment before queueing; shows actual job state and downloads only after completion.

Run checks:

```bash
python3 -m unittest discover -s tests -v
python3 tests/smoke_http.py
# UI syntax check:
# extract the inline <script> to a .js file and run: node --check file.js
```

### Tests performed on 17 November 2026

- 10/10 Python unit/integration tests PASS (including actual FFmpeg H.264 export).
- HTTP smoke PASS (health, rights rejection, cloud disabled, legacy endpoint gone, idempotency, queue -> MP4 720x1280).
- Node syntax check PASS.
- Manual visual UI QA via browser: separate evidence needed if not explicitly recorded.

### Not yet implemented / release blockers

- **No** actual Runway/Kling/Google model provider or paid API requests, model key storage, cloud upload, or generative AI.
- **No** signed rights proofs, multi-user auth, tenant policy, regulatory or merchant release, production publishing, persistent job reconciliation, commercial billing or subscriptions.
- **No** OS-level cgroup/seccomp worker isolation or malware scan. The local worker is a Python thread executing FFmpeg; do not call it a production-isolated process.
- **No** deployment to Server 2 or Server 1. An authenticated PHOENIX app foundation (#29/#35 and foundation PRs) must be verified before integration.
- FFmpeg timeouts and the queue capacity constrain the preview, but these controls alone are not sufficient for hostile uploads or production usage.

Track: #44 (unified creative studio) and #45 (prototype). The next step is a deliberately small Laravel integration only after its authentication and brand scope gates are available, followed by a provider-neutral *stub* with approved budget/consent recording. No paid provider may be turned on by default.