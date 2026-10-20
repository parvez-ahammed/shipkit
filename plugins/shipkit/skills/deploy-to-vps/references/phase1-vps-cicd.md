# Phase 1 - VPS + self-running CI/CD (detailed)

Concrete command sequences. Templates are in `assets/`.

## Contents

1. Provision + Docker
2. CI deploy key
3. deploy/ assets
4. The workflow
5. Secrets into GitHub
6. Push + iterate (and the symptom map)
7. Phase 1 gotchas

## 1. Provision + Docker

Ubuntu LTS VM. **Harden it first** (`references/vps-hardening.md`: non-root user,
key-only SSH on a non-standard port, fail2ban, default-deny firewall) before exposing
anything - a fresh box on port 22 gets brute-forced within minutes. Then install
Docker (over your custom SSH port; `-t` so sudo can prompt for the password you set
with `passwd`):

```bash
ssh -t -p $SSH_PORT user@VM "curl -fsSL https://get.docker.com | sudo sh && \
  sudo usermod -aG docker \$USER && sudo systemctl enable --now docker && \
  docker --version && docker compose version"
```

Sizing: app + worker + Caddy about 1-1.5 GB; pick 2 GB+. Put the VM near the **DB**.

## 2. CI deploy key (GitHub Actions -> VM)

Generate a dedicated key, install the public half on the VM, store the private half
as a GitHub secret. Keep it separate from your personal key.

```bash
ssh-keygen -t ed25519 -f ./deploy_key -N "" -C "gh-actions-deploy"
PUB=$(cat ./deploy_key.pub)
ssh -p $SSH_PORT user@VM "mkdir -p ~/.ssh && chmod 700 ~/.ssh && \
  grep -qxF '$PUB' ~/.ssh/authorized_keys 2>/dev/null || echo '$PUB' >> ~/.ssh/authorized_keys; \
  chmod 600 ~/.ssh/authorized_keys"
ssh -p $SSH_PORT -i ./deploy_key user@VM "echo OK"   # verify before storing
gh secret   set VPS_SSH_KEY  -R OWNER/REPO < ./deploy_key
gh variable set VPS_HOST     -R OWNER/REPO --body "VM_IP"
gh variable set VPS_USER     -R OWNER/REPO --body "user"
gh variable set VPS_SSH_PORT -R OWNER/REPO --body "49222"   # your custom SSH port
# Pin the host key so CI never trusts a swapped one. Compare the fingerprint with
# `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` run on the VM's console first.
ssh-keyscan -p $SSH_PORT -t ed25519 VM | gh variable set VPS_KNOWN_HOSTS -R OWNER/REPO
rm -f ./deploy_key ./deploy_key.pub              # don't leave the private key on disk
```

## 3. deploy/ assets

Copy `assets/docker-compose.yml` and `assets/Caddyfile` into `deploy/`. Adapt:
- build context + Dockerfile names, the API listen port (compose `expose` + Caddy
  `reverse_proxy` target + the health-check URL),
- the domain in the Caddyfile,
- `.gitignore` the rendered secrets file: `echo 'deploy/app.env' >> .gitignore`.

## 4. The workflow

Copy `assets/deploy-to-vps.yml` to `.github/workflows/`. Adapt `API_BASE`/`API_HOST`,
`REMOTE_DIR`, the `Render app.env` env keys (match your framework's config keys),
and `SVC`/`PORT`/`HEALTH_PATH`/`EXPECT` at the top of the health-check script (compose
service name, listen port, readiness path, expected body; `EXPECT=` gates on HTTP 2xx
only, which suits JSON health responses). The Host header comes from `API_HOST`, and the compose network is read off the
running container, so neither needs editing.

## 5. Secrets into GitHub

List what's there: `gh secret list -R OWNER/REPO`. Anything the backend needs that
isn't present (very commonly the **DB connection string** and provider tokens, if
they only lived in the old PaaS store) must be added. `assets/migrate-secrets.sh`
(bash, reads a dotenv export) or `assets/migrate-secrets.ps1` (pwsh, Azure example)
shows the source->gh loop - run it yourself (safety layers block an assistant from
reading prod secret values).

## 6. Push + iterate

```bash
git add deploy .github/workflows/deploy-to-vps.yml .gitignore
git commit -m "ci: add VPS deploy pipeline"   # use -m flags; never bash @'...'@
git push origin main
gh run watch $(gh run list --workflow=deploy-to-vps.yml -L1 --json databaseId -q '.[0].databaseId')
```

When a run fails, SSH in and reproduce the exact failing probe - don't guess:

```bash
ssh -p $SSH_PORT user@VM 'cd ~/app/deploy && docker compose ps && \
  NET=$(docker inspect -f "{{range \$k, \$v := .NetworkSettings.Networks}}{{\$k}} {{end}}" $(docker compose ps -q api) | cut -d" " -f1) && \
  docker run --rm --network "$NET" curlimages/curl:8.23.0 -s -H "Host: your.domain" \
    -o /dev/null -w "code=%{http_code}\n" http://api:8080/health && \
  docker compose logs --tail=40 api'
```

Map the symptom to the gotcha in "Phase 1 gotchas" below:
- `http_code=400 Invalid Hostname` -> missing Host header / AllowedHosts.
- `wget: not found` / container `unhealthy` -> slim image; disable Dockerfile
  healthcheck, probe externally with a curl sidecar.
- `ConnectionString ... not been initialized` -> the secret is empty in GitHub.
- `/health` returns `Healthy` but app is broken -> liveness-only endpoint; add a
  readiness/DB check.
- pipeline green but the app does nothing -> same; the health gate was dishonest.

## Phase 1 gotchas (these will bite you)

- **Secrets with `$` get mangled by Compose interpolation.** Compose substitutes
  `${VAR}` in the compose file, and Compose v2 **also interpolates unquoted `env_file:`
  values** - so `p@$$w0rd` arrives as `p@$w0rd` and `ab$cd` as `ab`. Render the app's
  real keys into an env file and load it with the long syntax
  `env_file: [{ path: ./app.env, format: raw }]` (Compose 2.30+), which passes values
  **literally** (as the template does). Don't map secrets through
  `environment: KEY: ${SECRET}`. Check with `docker compose version`.
- **A green deploy can be a lie.** Many `/health` endpoints are **liveness only**  - 
  200 the moment the process boots, without touching the DB. Gate on **both** liveness
  *and* a readiness signal (grep logs for a DB-connection fatal, or hit an endpoint
  that exercises the DB). Else an app with an empty DB URL "passes".
- **Slim runtime images have no `wget`/`curl`.** A Dockerfile `HEALTHCHECK` using
  `wget` marks the container permanently `unhealthy` on images that lack it. Disable
  it in compose (`healthcheck: { disable: true }`) and probe **externally** from the
  workflow with a throwaway curl container on the compose network:
  `docker run --rm --network <proj>_<net> curlimages/curl -sf http://api:PORT/health`.
- **Host allowlists reject internal probes (HTTP 400 "Invalid Hostname").** If the
  framework enforces allowed hosts (.NET `AllowedHosts`, Django `ALLOWED_HOSTS`,
  Rails `config.hosts`), an internal probe to `http://api:PORT` carries Host `api` and
  is rejected. Send the real host header: `-H "Host: your.domain"`.
- **Anchor the health match.** `grep -qi healthy` matches `Unhealthy`. Use
  `grep -qi '^healthy'` or check the HTTP status.
- **Background-job frameworks flap at startup** (Hangfire/Celery/BullMQ) for ~15-30s
  while storage settles. Make the probe a retry loop, not a single shot.
- **Full-history secret scanners differ on push vs dispatch.** Gitleaks on `push`
  scans new commits; on `workflow_dispatch` it scans **full history** and trips old
  committed example secrets, failing the run. Prefer push-triggered deploys; add a
  `.gitleaksignore` for accepted historical findings (rotate anything real).
- **Building commit messages in bash: never `@'...'@`.** That is not a here-string in
  bash - it injects a literal `@` into the subject. Use repeated `-m` flags.
