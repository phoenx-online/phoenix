# Actual-User Visual Verification V1

This directory is the deterministic browser-evidence layer for **PHOENIX**.

## Purpose

A feature is not considered visually verified merely because code exists. This harness opens the actual reachable website in real Chromium, performs configured read-only journeys, and records evidence.

Evidence produced per run:

- full-page screenshots at every configured checkpoint
- full browser video for Desktop Chrome, Android emulation, and mobile-WebView-like emulation
- Playwright trace
- HTML test report
- console-error, page-error, and failed-request diagnostics
- exact Git commit SHA, target environment, URL and run timestamp

## Zero-cost-first rule

Normal execution uses the project's dedicated self-hosted runner (`self-hosted, linux, x64, phoenix-dev`) and the official Playwright container. The workflow does **not** upload evidence to GitHub artifact storage by default. Evidence is retained locally under the runner account's `~/visual-evidence/` directory.

Playwright is pinned to `@playwright/test 1.63.0`.

## Safety

- Default journeys are read-only GET/navigation checks.
- Production requires an explicit read-only acknowledgement.
- Never put usernames, passwords, tokens or signed URLs in `base_url`, `paths`, `journeys.json` or Git.
- State-changing flows belong in isolated DEV/STAGING tests with synthetic accounts and explicit deterministic cleanup.
- This verification layer never waives existing security, RBAC, migration, finance, backup, release, or human-approval gates.
- Mobile-WebView-like emulation is useful visual evidence but does not replace any project-specific real-device acceptance requirement.

PHOENIX production is not authorized. This lane is DEV-first and must use the dedicated `phoenix-dev` runner defined by the runtime baseline.

## Run

From GitHub Actions, manually start **Actual User Visual Verification V1** and provide a URL reachable from the dedicated runner.

For local execution:

```bash
cd qa/visual
npm install
BASE_URL="https://example.test" TARGET_ENVIRONMENT=staging npm test
```

Optional route override:

```bash
VISUAL_PATHS="/,/pricing,/contact" BASE_URL="https://example.test" TARGET_ENVIRONMENT=staging npm test
```

## Google Antigravity

Use `ANTIGRAVITY_TASK.md` after the deterministic Playwright run for intelligent exploratory inspection. Antigravity is a complementary QA reviewer; it is not allowed to convert a failing deterministic gate into PASS.
