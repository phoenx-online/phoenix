# PHOENIX Self-Hosted Runner

Status: **PREPARED — registration blocked until host verification + repository exposure decision**

## Security gate first

The canonical repository is currently public. Do not attach the PHOENIX DEV machine as a self-hosted runner while this remains an unreviewed public-repository execution surface.

Recommended PHX-M1 decision: make `phoenx-online/phoenix` private while PHOENIX is unreleased commercial software. After the visibility change, re-verify the GitHub App connection before registering the runner.

If PHOENIX intentionally remains public later, design a dedicated public-source runner security model before enabling automatic workflows.

## Scope

Register the runner at the **repository level**, not as an organization-wide runner, for the initial PHX-M1 environment. This gives the narrowest access boundary for the current single canonical repository.

Target labels:

- `self-hosted`
- `linux`
- `x64`
- `phoenix-dev`

Target host/account:

- host: `craniumtek-lab-01`
- Linux user: `phoenix`
- runner root: `/home/phoenix/actions-runner`
- source checkout used by human DEV work: `/home/phoenix/projects/phoenix`

Never run the runner service as root.

## Registration

After the fresh host gate passes and the repository exposure decision is complete:

1. Open `phoenx-online/phoenix` in GitHub.
2. Go to **Settings → Actions → Runners → New self-hosted runner**.
3. Choose **Linux** and **x64**.
4. GitHub will display the current runner package URL and a short-lived registration token.
5. Log in to `craniumtek-lab-01` as the `phoenix` user.
6. Follow GitHub's generated download/extract instructions inside `/home/phoenix/actions-runner`.
7. During `config.sh`, configure this runner for the PHOENIX repository and add the custom label `phoenix-dev`.
8. Install/start the runner service under the `phoenix` account using the service command supplied by GitHub's runner package.
9. Verify GitHub shows the runner as **Idle** before triggering PHOENIX DEV CI.

Do not paste the registration token into source control, issues, PRs, chat logs intended for retention, shell history beyond what GitHub's setup requires, or environment templates.

## Permissions

The `phoenix` runner user should have only the privileges required for PHOENIX DEV:

- read/write its own PHOENIX project/private directories
- Docker access on the DEV machine
- no MBG/iBayong/Craniumtek production secrets
- no root SSH deployment capability
- no production DNS/cloud credentials
- no production backup repository credentials

Because Docker group membership is effectively host-elevated capability, treat runner workflows as trusted-code execution. This is another reason not to attach this runner to an unreviewed public contribution surface.

## Workflow activation

PHX-M1 initially defines `.github/workflows/ci-dev.yml` as `workflow_dispatch` only. This is deliberate.

After the repository is private, the host is verified, the runner is registered, and the manual CI run is GREEN, a later small change may add `pull_request` triggers for trusted branches.

Do not add automatic production deployment to this runner.

## First runner acceptance

Trigger **PHOENIX DEV CI** manually and require:

- checkout succeeds
- ephemeral `.env.ci` is generated locally and removed after the run
- Compose config validates
- PostgreSQL + Redis start in an isolated project namespace
- Laravel boots
- `php artisan migrate --force` succeeds against the ephemeral PostgreSQL database
- PHPUnit smoke tests pass
- `/healthz` returns HTTP 200
- CI stack and volumes are removed in the final cleanup step

After the run, verify there is no lingering `phoenix-ci-*` stack and no CI environment file left in the worktree.
