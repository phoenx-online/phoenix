# PHOENIX isolated production launch — owner-approved plan, execution gated

**Decision:** 2026-11-02 PHT. **Canonical domain:** `phoenx.live`. **Do not touch:** current `craniumtek-production` tunnel (16 apps), `ibayong-production` tunnel (3 apps), legacy `phoenx.online` A.I.D.A, any other Docker project, or existing DNS routes.

**Deployment state:** SOURCE-ONLY. None of these instructions represent a real server deployment or Cloudflare tunnel creation. The dedicated Cloudflare tunnel is `phoenix-production`, not Craniumtek's existing production tunnel. Use manual operator approval for server and DNS cutover.

## Architecture

- Server 1 `craniumtek` hosts **static public site first**, Compose project `phoenix-prod`.
- `web`: unprivileged NGINX on port 8080 inside container; diagnostics via host loopback `127.0.0.1:8096` only. Immutable release directory is mounted read-only.
- `tunnel`: isolated Cloudflare `cloudflared` container and **remotely-managed dedicated tunnel**, no host tunnel service installation or restart, no host TCP listener.
- Both services share only the `phoenix_prod_ingress` Docker bridge network. Cloudflare published application service URL must be **`http://web:8080`** (not host-local `localhost:8096`, which resolves inside the connector container).
- Limit: independent containers, network, token, release, logs and rollout; still shares Server 1 kernel, Docker daemon, electricity, Internet, and Cloudflare account.
- No Laravel, database, client accounts, uploads, brand documents, or privileged application sessions in the public-site launch.

## Pre-cutover gates (stop on any failure)

1. Fresh Server 1 capacity check: memory, swap, CPU, disk, Docker networks/volumes, port 8096; verify other 16+3 routes before touching PHOENIX. Prior screenshot: port 8096 was empty; fresh verification is mandatory.
2. Inspect owner/admin permissions and Docker group access; do not give an untrusted PR runner production Docker privileges. Keep production launch operator-controlled. Use audited exact commit SHA and reviewed image digests.
3. Verify the Cloudflare zone `phoenx.live` and export DNS records. On 2026-11-02 the apex had two proxied A records `54.149.79.189` and `34.216.117.25`. These must be saved for rollback, and removed only during controlled cutover.
4. Do not delete or redirect `phoenx.online` until A.I.D.A ownership, mail, OAuth, cookies, callbacks, payment/webhook dependencies, and domain impersonation risk are resolved.
5. Back up all PHOENIX files to be replaced; no changes to shared cloudflared/Compose files.

## Prepare exact release (Server 1, operator only)

Clone or fetch the exact approved PHOENIX commit from `phoenx-online/phoenix`. The current GitHub PR branch is **not a production approval**. Run these commands from a checkout at that exact SHA, after manual source review:

```bash
set -Eeuo pipefail
test "$(hostname -s)" = "craniumtek"
RELEASE_SHA="$(git rev-parse HEAD)"
test -z "$(git status --porcelain --untracked-files=no)"
test "$RELEASE_SHA" = "$(git rev-parse --verify HEAD)"
grep -Fq '<link rel="canonical" href="https://phoenx.live/">' public-site/index.html
sudo install -d -m 0755 /srv/phoenix/releases
sudo install -d -m 0755 "/srv/phoenix/releases/$RELEASE_SHA"
sudo install -o root -g root -m 0644 public-site/index.html "/srv/phoenix/releases/$RELEASE_SHA/index.html"
sha256sum "/srv/phoenix/releases/$RELEASE_SHA/index.html"
sudo install -d -o root -g root -m 0700 /srv/phoenix/secrets
```

For the two image fields in `deployment.env`, select approved, up-to-date upstream images and record **exact pullable `@sha256:<64 hex>` digest references**. Do not use only `:latest` in production. Example commands to inspect images, after separately reviewing their version and provenance:

```bash
docker pull nginxinc/nginx-unprivileged:stable-alpine
docker image inspect -f '{{json .RepoDigests}}' nginxinc/nginx-unprivileged:stable-alpine
docker pull cloudflare/cloudflared:2026.10.0
docker image inspect -f '{{json .RepoDigests}}' cloudflare/cloudflared:2026.10.0
```

Copy `deploy/phoenix-prod/deployment.env.example` to `/srv/phoenix/deployment.env` (mode `0600`, root-owned); edit its **three non-secret fields** to include the reviewed release path and exact image digests. Use a secure editor such as `sudoedit /srv/phoenix/deployment.env`. Do not commit this file.

## Create independent Cloudflare tunnel and token

Inside the **same Cloudflare account holding `phoenx.live`**, open **Networking → Tunnels → Create tunnel**. Choose **Cloudflared**, name `phoenix-production`, and select **Docker**. Create the tunnel **without** adding or modifying any Craniumtek or iBayong routes.

The dashboard presents a connector installation command containing the tunnel token. **Do not execute the token-in-command form** and do not paste the token into ChatGPT, GitHub, shell history, chat, screenshots or logs. Instead, copy only the token value, and enter it at a hidden interactive prompt on Server 1:

```bash
sudo install -d -o root -g root -m 0700 /srv/phoenix/secrets
sudo bash -c 'umask 077; read -r -s -p "Paste PHOENIX-only tunnel token: " token; printf "\n"; printf "%s" "$token" > /srv/phoenix/secrets/tunnel-token; unset token; chown 65532:65532 /srv/phoenix/secrets/tunnel-token; chmod 0400 /srv/phoenix/secrets/tunnel-token'
```

Cloudflare's official distroless `cloudflared` image runs as UID 65532. The host directory is 0700/root-owned, and the token file is 0400/65532-owned to let only the dedicated container user read it after Docker's mount. If user namespaces or secret mount semantics prevent this, **stop and diagnose**, do not broaden token permissions. Only the isolated PHOENIX connector should receive the secret.

Run **read-only preflight** from the same reviewed checkout, with the token and `deployment.env` installed:

```bash
sudo bash deploy/phoenix-prod/preflight-readonly.sh /srv/phoenix/deployment.env
```

Require `PHOENIX_PREFLIGHT=PASS` and `NO_SERVICES_OR_DNS_CHANGED=TRUE` before starting anything.

## Start only PHOENIX containers (not a shared tunnel)

```bash
sudo docker compose --env-file /srv/phoenix/deployment.env -f deploy/phoenix-prod/compose.yml up -d --no-deps web
curl --fail --silent --show-error http://127.0.0.1:8096/ |
  grep -F 'Live Commerce Growth Operating System'
sudo docker compose --env-file /srv/phoenix/deployment.env -f deploy/phoenix-prod/compose.yml up -d --no-deps tunnel
sudo docker ps --filter name=phoenix-prod
```

Confirm `phoenix-prod-web` is healthy, `phoenix-prod-cloudflared` exists and `phoenix-production` is **Healthy** in the dashboard. If not, diagnose **only** the PHOENIX containers; never restart the server's shared cloudflared service. Check that Docker's `web` service name resolves over `phoenix_prod_ingress` from the new connector (the published route is `http://web:8080`).

## Controlled domain cutover (separate approval gate)

Only when the PHOENIX origin and new tunnel are confirmed healthy:

1. Export the `phoenx.live` zone records and save screenshots of both existing apex A records. Record their exact original values and proxy settings.
2. On **phoenix-production → Published applications**, configure hostname `phoenx.live` to service `http://web:8080`. During this controlled action, remove the conflicting two apex A records, and ensure the apex becomes the correct proxied CNAME for the **new** tunnel's actual UUID (Cloudflare may create it when the hostname is published). Never guess the tunnel UUID.
3. Verify TLS, HTTPS 200, exact page content, `rel=canonical`, and `www` separately only if a redirect is deliberately configured.
4. Run the read-only post-cutover smoke check on Server 1. All four other project public websites must still respond.
5. Record the deployed exact release SHA, image digests, verification evidence and rollback plan. Only then mark **PRODUCTION VERIFIED**.

## Rollback

If PHOENIX fails: revert **only** the `phoenx.live` published-app route and DNS records using the captured before-state; remove the PHOENIX-only tunnel route if needed and restore the original apex A records. Stop only `phoenix-prod` services if necessary. Do not stop/reconfigure `craniumtek-production`, `ibayong-production`, `phoenx.online`, unrelated databases, or other Compose projects. Preserve PHOENIX evidence/logs without copying secrets.

Do not cancel the old `phoenx.online` registration until dependency audit and approved retirement are complete.

## References

- https://developers.cloudflare.com/tunnel/get-started/
- https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/configure-tunnels/run-parameters/
- https://github.com/phoenx-online/phoenix/issues/33
- https://github.com/phoenx-online/phoenix/pull/32
