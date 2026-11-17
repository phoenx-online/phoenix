# PHOENIX public-first launch — phoenx.live
Status: source prepared / public domain NOT YET VERIFIED
Decision: owner requested universal public access first on 2026-11-08 PHT.

## What this publishes
A static public marketing website at https://phoenx.live/ with:
- PHOENIX brand story and six service pillars.
- Eight role-selected **public information** pathways for brands, clients, business partners, investors, agents, affiliates/creators, staff/live sellers, and operators/admins.
- Mobile layout, accessible anchors, keyboard-usable navigation, original CSS product illustration.
- No analytics, cookies, forms, data uploads, payments, or login UI. No false claims of live platform features.
- Restrictive Cloudflare Pages \`_headers\`, canonical URL, sitemap, robots, SVG favicon.
- Pure HTML/CSS/JS. No Composer, PostgreSQL, Redis, PHP, Node build, external scripts or environment secrets are required for the public website.

**Do not advertise role-based account access as active.** Those require the audited Laravel app, data protection, verified owner activation and MFA, tenant scoped permissions, tests and a separate rollout. This site serves public information to everyone, not a functioning login or private portal.

## Chosen fast launch architecture
- **Apex \`phoenx.live\`: Cloudflare Pages** (Git-integrated static-only publication, no origin server requirement).
- **Later \`app.phoenx.live\`: isolated, separate PHOENIX Cloudflare Tunnel and secure app** after production release gates.
- Keep shared \`craniumtek-production\` / \`ibayong-production\` tunnels unchanged.
- Existing draft PR #34 was originally designed for an apex tunnel. Its DNS/cutover instructions are **superseded for the public apex** by this public-first Pages strategy. Adapt PR #34 to a future \`app\` hostname only after separate security review; no automatic tunnel creation, app deployment or domain switching now.
- The old \`phoenx.online\` Cloudflare zone was deleted November 4 (Cloudflare email). Do not assume its registrar registration was canceled; audit old mail/auth/webhook dependencies separately.

## Pre-launch source checks
1. Open the proposed public website PR and review changed paths. Do **not** merge any unsafe legacy admin seeder, platform, or application code just to publish this website.
2. Require \`PHOENIX_PUBLIC_SITE_LAUNCH_SOURCE=PASS\` in GitHub Actions on the exact commit SHA, with \`scripts/verify-public-pages.py\` and \`node --check public-site/site.js\`.
3. Public git repo is currently used. Keep **Cloudflare Pages Build command: \`exit 0\`**, **Build output directory: \`public-site\`**, **Root directory: \`/\`**, **Framework preset: None**. No env secrets or install commands. Use this isolated launch branch as production source until an explicit, audited merge plan is approved.
4. Test with the \`*.pages.dev\` URL first, including mobile, keyboard access, role buttons, no broken images/assets, browser devtools errors, response headers. No sensitive uploads anywhere in this flow.

## User's Cloudflare dashboard steps (requires account access)
1. Sign into the **Cloudflare account that currently holds the active \`phoenx.live\` zone**.
2. Open **Workers & Pages → Create → Pages → Connect to Git** (interface labels may vary). Select GitHub organization \`phoenx-online\` and repository \`phoenix\`; grant access to only the repository needed.
3. **Project name:** \`phoenix-public\` (choose an available name). **Production branch:** \`launch/phoenx-live-public-20261108\`. **Framework preset:** None; **Build command:** \`exit 0\`; **Build output directory:** \`public-site\`; **Root:** \`/\`. Leave all secrets blank.
4. Deploy. Record the **actual** provider-issued \`*.pages.dev\` address; don't guess it. Check HTTP 200, site copy, eight role selectors, CSS/JS/favicon, mobile and desktop, no browser console errors.
5. On **that Pages project → Custom domains → Set up a domain**, enter \`phoenx.live\` and follow the exact DNS/verification prompts. Cloudflare may create the correct proxied CNAME automatically **after** domain association.
6. Snapshot the current \`phoenx.live\` DNS zone before editing. The last owner screenshot from Nov 2 showed two proxied apex A records \`54.149.79.189\` and \`34.216.117.25\`; do not assume they still exist. Identify and deliberately resolve conflicting records when Cloudflare prompts; preserve unrelated TXT/MX/CAA/verification records. Do **not** point the apex to the planned \`phoenix-production\` Tunnel as well.
7. Wait for Cloudflare custom domain status **Active**, HTTPS certificate valid, and \`https://phoenx.live/\` returns HTTP 200 with the correct PHOENIX page. Only then advertise the domain to partners.
8. Optional: add \`www.phoenx.live\` as a second custom domain or create a verified redirect to the apex, once the root is working.
9. Record Pages project, custom-domain status, production branch and commit, screenshot of DNS records, site smoke checks. Do not post Cloudflare tokens, registrar credentials or DNS API secrets in GitHub.

**Alternative if Git integration is inaccessible:** Cloudflare Pages Direct Upload supports drag-and-drop a static folder/ZIP, but a Direct Upload project cannot later be converted in place to Git integration. Default to Git integration for PHOENIX continuous delivery.

Official docs:
- https://developers.cloudflare.com/pages/framework-guides/deploy-anything/
- https://developers.cloudflare.com/pages/configuration/custom-domains/
- https://developers.cloudflare.com/pages/get-started/direct-upload/

## Public cutover acceptance
- [ ] Pages \`*.pages.dev\` exact commit serves correct PHOENIX HTML and CSS/JS.
- [ ] All eight role options operate and are readable on mobile and desktop.
- [ ] No login, upload, payment, account signup or implicit portfolio-stats claims are advertised as functioning.
- [ ] \`https://phoenx.live/\` HTTP 200, valid TLS, canonical, SEO assets and restrictive headers.
- [ ] Existing Craniumtek, Morning Breaks, iBayong, FlashDate sites remain healthy.
- [ ] Capture exact deployed git commit, public URL evidence, DNS snapshot and rollback plan.
- [ ] Optional staff/agent/brand portal buttons remain non-existent until their data systems are verified.

Rollback: restore previous apex records from the captured current zone state if needed, or roll back the Pages deployment to the prior verified commit. Never restart or change Craniumtek/iBayong tunnels as part of Pages rollback.

## Follow-on role portal architecture (not launched)
- \`app.phoenx.live\`: approved PHP/Laravel platform with verified staff/brand/client/partner scoped tenant memberships and MFA.
- Public request/access flows only after company contact mechanism, privacy policy, legitimate notices, consent, retention, and abuse controls are tested.
- \`investors.phoenx.live\` or restricted investor room only after real legal/finance material permissions.
- Creator/affiliate and agent commissions only after written program terms, exact attribution and funding/settlement controls.

Last known production evidence: Server 1 memory audit Nov 4 showed 6.2 GiB available RAM and no observed active swapping; not a live/current host guarantee. Pages public web hosting avoids using Server 1 at all.
