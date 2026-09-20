# Google Antigravity Visual QA Task — PHOENIX

Use this task only against a URL and environment the operator has authorized.

## Mission

Inspect the **actual website**, not only source code. Behave like a real user and compare what is visible/usable with the intended capability.

1. Read `journeys.json` and visit each enabled journey.
2. Capture a screenshot at every meaningful checkpoint.
3. Record a browser walkthrough when recording is available.
4. Check navigation, responsive layout, loading/error states, labels, buttons, forms, empty states and user feedback.
5. Note broken links, unexpected redirects, inaccessible controls, obvious visual regressions, console-visible failures and capability claims that do not match actual behavior.
6. Re-test the failing step once to distinguish a repeatable defect from a transient failure.
7. Produce PASS/FAIL per journey with the exact URL, timestamp and concise reproduction steps.

## Safety boundary

- Production: **read-only exploration only**. Do not submit forms, create records, upload files, send messages, change settings, trigger payments, or alter accounts.
- DEV/STAGING: state-changing tests require explicit synthetic test data and existing project authorization.
- Never expose or store credentials in screenshots, recordings, prompts or repository files.
- Never bypass authentication/RBAC or existing release gates.
- A visual-agent opinion cannot waive Playwright, application, security, release, backup or human-approval failures.

## Required evidence

- journey name
- exact tested URL
- desktop screenshot
- mobile screenshot where relevant
- recording where available
- observed result
- expected result
- PASS/FAIL
- reproducible steps for every failure
