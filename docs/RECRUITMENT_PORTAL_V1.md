# PHOENIX Careers V1 — gated applicant intake and accounts

Status: source-only implementation; NOT LIVE / NOT DEPLOYED / NOT PRODUCTION VERIFIED.

## Role included

Videographer / Video Editor, full-time on-site, Ortigas, Pasig City. The role includes video editing, live-selling frames/overlays, and OBS or TikTok LIVE Studio familiarity.

## Applicant and recruiter scope

- Visitors see the job at /careers. By default, registration and application calls to action are disabled.
- Applicants can register, verify email, sign in, reset passwords, submit one application per role and read only their own application status.
- Applications ask for mobile, city, experience, optional portfolio URL, salary and start date, plus a PDF résumé (5 MB max).
- Verified authorized recruiters can review submissions, download private files and update statuses with immutable status audit rows.
- Laravel CSRF, session authentication, rate limits, encrypted password hashes, email verification, unique user/job index, private disk, and server-side staff checks are prerequisites.

## Default OFF launch gate

RECRUITMENT_ACCEPTING_APPLICATIONS=false is the default. Never enable before all gates below pass. This feature is stacked on feat/phx-visual-first-public-v1 pending the Laravel foundation PR.

## Blockers before applicants may use the live service

1. Merge/port to the approved current Laravel foundation; add reviewed composer.lock; verify versions and dependency integrity.
2. Verify dedicated PHOENIX PostgreSQL migrations and live email verification/password recovery with real mail delivery. No production log-only email mailer.
3. Verify independent session/security controls: TLS, APP_URL, CSRF, rate limiting, secure cookie, trusted proxies, abuse controls, no user enumeration and account recovery.
4. Review CV upload protection with private storage, MIME checks, malware scanning/quarantine, access logging and retention-based deletion. Run negative tests.
5. Publish complete Philippine applicant privacy disclosures, data controller contact, lawful basis, purpose, actual retention policy, processors/transfers, request workflow and deletion response.
6. Provision staff identities through authorized operator workflow, enforce MFA and prove applicant registration cannot grant recruiter role.
7. Test registration, login, verification, file upload, recruiter RBAC, password reset, mobile/browser journeys and backup/restore in staging. Record exact evidence.
8. Diagnose current public phoenx.online A.I.D.A redirect (PR #26) and separately authorize any DNS/ingress correction with rollback proof.
9. Pass security and deployment gates for verified application server. Only then enable applicant collection via private production environment configuration, never via Git.

No automated application email or interview scheduling is claimed in V1. Status is available from the applicant dashboard.
