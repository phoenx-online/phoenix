# PHOENIX primary domain transition: phoenx.live

**Owner decision:** 2026-11-01 (Philippines time)
**Intent:** make `https://phoenx.live/` the canonical PHOENIX public website and decommission the previous `phoenx.online` domain after a safe transition.
**State:** Cloudflare zone activated and existing tunnel confirmed healthy (2026-11-02 owner evidence). PHOENIX origin, tunnel route, TLS end-to-end, production release, redirects and old-domain removal remain **unverified/not performed**.

## Important discovery

On 2026-11-01 a public fetch of `https://phoenx.online/` landed on an **A.I.D.A Console Login**, not the expected PHOENIX static landing page. Do **not** delete or change this old zone, tunnel, email, redirects, or registration until the operator identifies who operates A.I.D.A and whether it legitimately depends on the domain. This check is separate from the PHOENIX website.

## Verified owner evidence — 2026-11-02 (PHT)

- Screenshot of Cloudflare DNS for `phoenx.live` shows **Full DNS setup** and exactly two **proxied A records** at the zone apex: `54.149.79.189` and `34.216.117.25`. These are **not the intended Cloudflare Tunnel CNAME**; do not remove or replace them until the PHOENIX origin is healthy and the change is scheduled.
- Tunnel dashboard shows `craniumtek-production` **Healthy** with **1 replica** and **16 published apps**. `ibayong-production` is Healthy with 3 apps. An older tunnel `Craniumtek` is Down with no routes. Preserve both healthy tunnels and all existing routes.
- Owner's Server 1 output: no `phoenix`/port 8096 container detected, and `sudo ss -ltnp '( sport = :8096 )'` found **no listener**. Port 8096 appears available, but there is **no PHOENIX production origin yet**.
- This evidence confirms Cloudflare zone and production tunnel health **only**. New website HTTPS and PHOENIX public HTTP 200 remain unverified.

### Required safe order following this evidence

1. Determine whether the `craniumtek-production` tunnel connector runs on the host network or in an isolated Docker network. A route of `http://localhost:8096` works **only when localhost from the connector reaches the intended origin**; do not assume it works for a bridged container. Do not print tokens or full tunnel configuration in logs.
2. Deploy the immutable PHOENIX static page locally using an isolated `phoenix-prod-web` container; preserve the shared server's existing ports, processes, networks and sites. Verify port 8096 returns HTTP 200 and the correct page.
3. On the **healthy `craniumtek-production` tunnel**, add a `Published application` route for apex `phoenx.live` to the network-reachable PHOENIX origin. Do not create a new tunnel or modify unrelated 16 routes. Cloudflare may automatically create a DNS CNAME; resolve any conflict with existing apex A records deliberately rather than attempting both records together.
4. Verify HTTPS 200, content, canonical link and unrelated sites. Optionally add `www` with a tested redirect and proper DNS.
5. Keep legacy `phoenx.online` and its A.I.D.A console untouched pending ownership and dependency inventory.

**Important:** `deploy/bootstrap-existing-prod-host.sh` now avoids changing/restarting the shared Cloudflare tunnel; production routing is a separate manual gate.

## Canonical identity

- Brand: PHOENIX
- Website: `https://phoenx.live/` (target)
- Optional `www.phoenx.live` should 301 to the canonical apex once tested
- Other app/API/admin hostnames: **not activated** until there is an independently secured running service
- GitHub organization and repository remain `phoenx-online/phoenix`, which are repository identities, not website addresses

## Preflight / safety gate

1. Identify registrar owner and DNS authority for **both** domains. Export/record all DNS records, especially MX, SPF, DKIM, DMARC, TXT verification, A/AAAA/CNAME, CAA, and any subdomains.
2. Confirm whether any domain email mailboxes/aliases, OAuth callbacks, SSO, payment/webhook callbacks, cookies, CDN, customer links, or third-party integrations need migration. If yes, migrate and test those before cutover.
3. Determine ownership of the A.I.D.A login seen on the old hostname; do not interrupt it. Preserve relevant backups and identify the responsible business.
4. On Server 1 `craniumtek`, verify PHOENIX production listener `127.0.0.1:8096` is the intended `phoenix-prod-web` (do **not** assume it is). Confirm CPU/memory, logs, tunnel owner/service, release SHA, SSH privileges, backup/rollback route and that other services will remain untouched.
5. Do not enter production secrets into the repository, a public issue, or this runbook.

## New domain DNS / tunnel steps (operator-run, gated)

1. In Spaceship **Advanced DNS**, confirm that `phoenx.live` has the intended DNS authority. If moving to Cloudflare full DNS, add the zone to the **correct Cloudflare account**, record its assigned nameservers, then change Spaceship nameservers accordingly. Preserve/recreate any active records before switching DNS authority.
2. Using the existing Cloudflare Tunnel, add hostname routes for `phoenx.live` (and optional `www.phoenx.live`) to the verified PHOENIX static origin, `http://localhost:8096`. Keep any unrelated tunnel routes unchanged. Never expose production port 8096 publicly.
3. Create Cloudflare DNS records that point to the existing named tunnel (normally a CNAME to its exact `<tunnel-UUID>.cfargotunnel.com`; do not guess the UUID). Do not mix unsupported cross-account tunnel DNS.
4. Validate the tunnel config **before** a controlled reload, confirm HTTPS certificates and routing, and verify that other projects still resolve.
5. Merge and explicitly dispatch `.github/workflows/deploy-public-site.yml` only after its production gates and target domain are ready. A merge alone must not deploy production.

## Verification

- `https://phoenx.live/` returns HTTPS 200, displays PHOENIX and “Live Commerce Growth Operating System”, and has a canonical URL pointing to the new domain.
- `https://www.phoenx.live/` if offered returns the appropriate TLS-secure 301 to the apex (or is intentionally not activated).
- PHOENIX’s local 8096 listener and immutable `/srv/phoenix/RELEASE_SHA` match the deployed release.
- Smoke tests include desktop/mobile, contact forms/login if any, redirect loops, mixed content, mail (if any), integrations, and absence of private credentials.
- Compare status of Craniumtek, MBG, iBayong, FlashDate, and other shared tunnel routes; no impact is permitted.
- Record exact date, release SHA, test evidence, and rollback configuration. Do not state production verified until actual checks pass.

## Decommission previous domain (only after verified migration)

1. Verify the new domain is live and all old-domain dependencies have been removed or explicitly migrated.
2. Check whether the A.I.D.A console or another service still uses the previous domain; obtain its owner-approved migration before touching it.
3. If appropriate, use an HTTPS **301 redirect** on old website paths during the migration period (only if old service owner approves); redirects do not require deleting the domain. Avoid breaking auth or mail.
4. When there is proven no remaining dependency and the owner still wants to retire the registration, turn off renewal or request cancellation through **the registrar that owns that registration**, and remove obsolete DNS only once safe. Registration cancellation is separate from deleting a GitHub document or a DNS record.
5. Confirm the old hostname no longer supports sensitive logins, callbacks, mail, or services before allowing registration to lapse. Beware of domain takeover and impersonation risk.

## Rollback

Keep backed-up old tunnel and DNS state, revert only PHOENIX-owned new hostname rules, redeploy the previous verified PHOENIX release SHA if needed, and test all shared sites. Do not automatically restore or modify unrelated A.I.D.A records.
