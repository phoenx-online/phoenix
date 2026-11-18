# PHOENIX execution checkpoint — 2026-10-05

## Authority and priority
PHOENIX — Live Commerce Growth Operating System. Canonical repo: phoenx-online/phoenix.
Lower priority than FlashDate. Preserve isolation from all other portfolio projects.
Work first → verify → report → continue. Use Melvin's EXECUTION UPDATE format.
This checkpoint grants no visibility, runner-registration, root, DNS, production, credential, spending or ownership authority.

## Verified source state
- main: d7a98ddb4f0ec4bcb54afc407fc7a580b8cf414f.
- PHX-M1 PR #8: c9f5a7c1e1dfc9f9229c4fa88313430efe9956d1; PostgreSQL mount fix exists.
- PR #20 visual-first public candidate advanced from 860e8e1d to b728f2eee28d280e2ab2ba79adf9687bd95c4796.
- Last observed existing-server production run 36519962624: completed/cancelled; previously queued.
- Prior public-site run 36519346846: completed/failure.
- Repository visibility verified public on this execution.
- Production and live website acceptance: UNVERIFIED. Do not infer an outage or deployment from these workflow results.
- PHX-M1 real-host successful retry, migrations, Redis/app health, restart/recreate, backup/restore: UNVERIFIED.

## Implemented this execution
Branch: fix/visual-failure-evidence-20261005.
Code commit: ca78ad66bb356a2cac140f1f9003d25c18eb2723.
File: qa/visual/tests/actual-user-visual.spec.mjs.
Previously, a failed navigation/HTTP/body/screenshot assertion exited before diagnostics.json attachment.
Now try/catch/finally records completion/failure diagnostics and rethrows the original error; journey metadata is recorded before navigation.
Validation: Node syntax PASS; isolated mocked behavioral checks PASS for success, HTTP 503, navigation exception, uncaught page error.
These are harness checks, not browser, staging, CI or production acceptance.
Abrupt process termination cannot guarantee a finally attachment.

## Open blockers
1. Owner trust decision: repository is public; existing M1 runner-registration gate remains unresolved. Recommended: private commercial implementation, then an explicitly authorized isolated runner strategy. Do not change visibility/register runners automatically.
2. Host access/evidence: this execution has GitHub access, no established authorized PHOENIX host execution channel. Real-host retry/acceptance requires that channel or operator evidence. Never reuse another project's runner.
3. Production readiness: cancelled/failed deployment evidence does not prove the listener, tunnel, exact deployed SHA or public health.
4. Source-of-truth drift: main documents prohibit automatic production pushes, while deploy-public-site.yml has a main push trigger. Prepare policy reconciliation for review; no implicit production authorization. Do not merge code touching public-site/deploy paths without accounting for that trigger.

## Resume in order
1. Recover current branch/PR/run state; inspect this draft's diff and any newer evidence. Complete dedicated-runner browser acceptance when authorized and available.
2. Reconcile delivery policy and static public-launch authorization in a reviewed branch, keeping DEV product runtime separate from static marketing launch.
3. Accept PHX-M1 corrected PostgreSQL mount on the real DEV host using fresh evidence, then verify stacked tenant/session/attribution/profitability PRs #14–16.
4. Continue truthful prototype/product proof and pilot operator preparation without fabricating merchants, creators, revenue or customers.

## State vocabulary
PLANNED / IN PROGRESS / IMPLEMENTED / TESTED / DEPLOYED / PRODUCTION VERIFIED are distinct.
Use LIVE PRODUCT / PROTOTYPE / CONCEPT / PLANNED capability labels.
Visual loop: Plan → Create → Go Live → Sell → Measure → Improve.
