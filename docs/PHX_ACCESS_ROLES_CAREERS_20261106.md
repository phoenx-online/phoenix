# PHOENIX access, roles, and Careers launch contract (2026-11-06)

**Source-planning and feature-branch work only. Nothing in this document implies working production accounts, owner activation, or live applicant intake.**

Tracker: #35. Existing source depends on #20 (Laravel public foundation), #28 (disabled-by-default applicant registration and recruiter UI), #32 (canonical phoenx.live) and #34 (isolated production tunnel).

## Current verified source and security caveat

- The legacy `main` branch includes an unsafe `AdminUserSeeder.php` with a known hard-coded credential. **Never run it.** The recruitment feature branch is a separate, incomplete Laravel foundation and does not contain that file.
- The recruitment branch has a `users.role` string with `applicant` default and narrowly recognizes `recruiter`/`admin` for recruitment review. This is **not** a complete multi-role, tenant-scoped authorization model.
- Application registration is intentionally blocked with `RECRUITMENT_ACCEPTING_APPLICATIONS=false` until verified storage, privacy, malware scanning, outbound email, HTTPS, backup/restore and MFA.
- New job catalog entry: Live Seller / Live Commerce Host, Ortigas; full-time, 6-hour office presence (4.5 hours live, 1.5 hours content/moderation) and ₱25k starting basic plus incentives/bonuses. Videographer / Video Editor listing is retained.

## Role catalog and enforcement target

This is an **acceptance matrix, not currently provisioned accounts**. Give each staff member only capabilities for their job, scoped to their employing PHOENIX organization or assigned client brand.

| Role | Required scope | Example allowed actions | Sensitive access not granted by default |
|---|---|---|---|
| `super_admin` | Entire PHOENIX platform | Owner approvals, role policies, emergency user suspension, platform configuration | Access to external ventures' databases or secrets |
| `platform_admin` | PHOENIX platform | Manage operational users and configuration within policy | Promote themselves to owner; bypass MFA |
| `operations_manager` | Organization | Assign campaigns, studio shifts and teams, view KPI reports | Owner/security and payout controls |
| `recruiter` | Organization | Review candidates, download private CVs and update audited hiring stages | Platform owner access, brand finance |
| `studio_manager` | Studio or organization | Schedule live sessions, supervise host/moderator rosters | Client billing and owner access |
| `live_seller` | Assigned live sessions | See own assignments and product scripts, enter session notes | Unassigned client, private applicant data |
| `moderator` | Assigned live sessions | Assist comments, escalation and session checklists | Client finance and other brands |
| `videographer`, `video_editor`, `content_creator` | Assigned creative work | Upload drafts, use briefs, request approvals | Unrelated assets and applicant data |
| `account_handler` | Assigned client/brand/store | Catalog, orders, coordination, promos, marketplace operations | Other brands or owner controls |
| `media_buyer` | Assigned ad accounts | Campaign planning, approved budgets and reporting | Global budgets and unauthorized spends |
| `creator_affiliate_manager` | Assigned programs | Talent onboarding, affiliate program operations | Payroll and unrelated client data |
| `inventory_fulfillment` | Assigned warehouse/store | Inventory counts, order and shipment status | Full financials and global user management |
| `customer_support` | Assigned stores | Work on authorized cases and orders | Full CVs, owner controls |
| `finance_analyst` | Assigned organization/brand | Read settlements, invoice and margin reports | Change payout accounts without separate approval |
| `auditor` | Explicit read-only scope | Review logs and approved reports | Write/update/delete actions |
| `brand_admin` | Own brand tenant | Invite/manage their brand staff within allowed permission list | PHOENIX internal users or another brand |
| `brand_staff` | Own brand tenant | Limited assigned catalog and performance views | PHOENIX-wide administration |
| `applicant` | Own account | Register, submit an application, read own status | Recruiter tools and other candidates |

Implement permissions through explicit server-side policies, organizational memberships and audit rows. A user's account can eventually have multiple scoped memberships; avoid relying on a single global `users.role` field for cross-brand authorization. All permissions must be denied by default.

## Activation order / minimum proof

1. **Identity and governance.** Confirm the owner's actual account and staff email addresses through a private trusted channel. Never create public/default passwords or post invite tokens in issues.
2. **Complete auth.** Independent PHOENIX database and verified email; secure session cookies and password recovery; mandatory MFA for `super_admin`, `platform_admin`, `recruiter`, `finance_analyst` and other privileged roles.
3. **Roles.** Build scoped roles and permissions, tenant membership, acceptance-based invitations, suspension, audit trails and no-last-owner-loss controls. A pending invitation grants no permissions.
4. **Recruitment.** Use existing #28 code; keep intake OFF until resume malware quarantine, actual privacy notice/controller contact, documented retention/deletion, verified mail, 2-tenant isolation and negative tests.
5. **Release.** Exact-head dependency lock and CI, PostgreSQL migration plus rollback, staging E2E across roles and mobile, backups/restore, signed HTTPS and dedicated tunnel checks.
6. **Owner sign-off.** Verify URL, deployment SHA, account MFA, role tests and privacy/security evidence before enabling staff access or accepting applications.

## Explicit blockers

- Complete approved Laravel foundation, mail, PostgreSQL and upload safety not production-verified.
- Privileged MFA and organization/brand-scoped RBAC not implemented.
- Owner identity/verified staff roster not provided as trusted credentials. Do not guess email addresses.
- The domain and tunnel work remain draft and cannot be assumed live.
- No production account, login or applicant data should be claimed or created from this branch alone.

**Release statuses as of this document:** Careers job catalog source change proposed; account/role activation NOT DONE; applicant registrations disabled; staging and production verification NOT DONE.
