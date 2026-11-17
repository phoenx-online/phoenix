# PHOENIX AI Studio — Local Video Editing Proof of Concept

**Status:** Isolated developer prototype. This is NOT a public PHOENIX feature and does NOT use generative AI, call Kling/Runway/Google Flow, authenticate users, store customer assets, or publish content.

## Purpose

Implement the smallest testable piece of the PHOENIX Content Studio roadmap: real product photo -> multi-scene editable shot list -> local H.264 MP4 -> independent QA/approval. It simulates camera push/detail effects using FFmpeg. Original package details come from the source photograph, not regenerated synthetic packaging.

## Run in a trusted isolated development environment

Requires Python 3.10+, `ffmpeg` compiled with `libx264` and `drawtext`, and DejaVuSans font at `/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf`.

```bash
cd prototypes/ai-studio-local
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