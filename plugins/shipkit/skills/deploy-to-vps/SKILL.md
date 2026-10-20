---
name: deploy-to-vps
description: >-
  Sets up push-to-deploy CI/CD (GitHub Actions over SSH) for a containerized app on a VPS, with Caddy
  HTTPS, DNS, OAuth redirect wiring and server hardening, plus honest health checks. Use for "deploy
  my app to a VPS", "move off Heroku/Render/Fly", "point my domain at my server", "harden my Ubuntu
  box", "add Caddy in front of my container", redirect_uri_mismatch, stuck ACME certs, "my deploy is
  green but the app is down", "make the health check honest", "add a readiness probe" (Kubernetes probes too). Not
  for writing Kubernetes manifests or serverless deploys.
license: MIT
compatibility: "Requires a GitHub repo with Actions, an Ubuntu LTS VPS reachable over SSH, and Docker + compose on the VPS. gh CLI recommended for secrets and run watching. migrate-secrets.ps1 needs PowerShell 7 (pwsh); migrate-secrets.sh is the bash equivalent."
---

# Deploy any containerized app to a VPS (CI/CD + OAuth + DNS/TLS + hardening)

Generic, vendor-neutral workflow for putting a Dockerized app on a plain VPS with a
**push-to-deploy** GitHub Actions pipeline, automatic HTTPS via **Caddy**, a real
domain through **any DNS provider**, OAuth/OIDC redirect setup, and **baseline
hardening**. The same flow works whether the app is Node.js, Python, Go, .NET, or
anything that runs in a container, and whether the host is Hetzner, DigitalOcean,
Contabo, Oracle, a cloud VM, or a bare box you SSH into.

Not for Kubernetes clusters, serverless, or multi-node fleets: this is one box running
`docker compose`. CI is GitHub Actions; on GitLab CI / other runners the same steps
(render env, rsync over SSH, `compose up`, probe) port directly, but the YAML does not.

The deep value is the **gotchas** in each phase reference - they produce green pipelines or
"looks fine" states that are actually broken. Read them before writing config.

## What stays the same across every stack

Only three things vary per project; everything else in this skill is identical:

1. **The Dockerfile(s)** and the app's **listen port** - runtime-specific. See
   `references/runtimes.md` for Node/Python/Go/.NET Dockerfile + port + healthcheck
   notes.
2. **The config/env keys** the app reads (e.g. `DATABASE_URL` for Node/Prisma vs
   `ConnectionStrings__DefaultConnection` for .NET) - rendered into the env file by CI.
3. **The provider consoles** (OAuth client, DNS zone) - same concepts, different UI.

The pipeline, compose layout, Caddy, health-check strategy, secret flow, and
hardening are **the same every time**. That is why this is a skill.

## Architecture

```
GitHub (main) --push--> GitHub Actions
                          | render .env from GitHub Secrets (single source of truth)
                          | rsync source + deploy assets over SSH (deploy key)
                          v
   VPS (hardened: non-std SSH port, fail2ban, firewall):
        Caddy (:80/:443 auto-TLS) -> app:PORT
        worker (optional, headless)     |
                                        v
                       external/managed DB or co-hosted DB container
   DNS/CDN (Cloudflare proxied by default) -> hides origin; firewall locks origin to it.
   Frontend (if separate) stays on its host; only its API base URL is repointed.
```

## Order of operations (do not reorder)

1. **VPS + pipeline + hardening** - app building, running, health-passing on the box,
   reachable internally; box hardened. No domain needed yet.
   See `references/phase1-vps-cicd.md` and `references/vps-hardening.md`.
2. **OAuth/OIDC** - register new redirect URIs *before* cutting over, or login breaks
   the instant you flip. See `references/phase2-oauth.md`.
3. **DNS + TLS** - point the domain, issue the cert, verify externally, cut over,
   decommission the old backend. See `references/phase3-dns-tls.md`.

Templates to copy live in `${CLAUDE_SKILL_DIR}/assets/`: `docker-compose.yml`, `Caddyfile`,
`deploy-to-vps.yml`, `migrate-secrets.sh` / `migrate-secrets.ps1` (PaaS->GitHub secrets,
bash or pwsh), `harden.sh`.

For the health endpoint itself (what `/health` vs `/readyz` should assert, liveness vs
readiness, container and Kubernetes probes), read `references/health-checks.md`. Endpoint
snippets per framework are in `references/readiness-by-framework.md`.

---

## Phase 1 - VPS + self-running CI/CD (+ hardening)

Goal: `git push` to `main` rebuilds and restarts the app on the VPS, secrets injected
from GitHub Secrets, gated by an honest health check - on a hardened box.

1. **Provision** any Ubuntu LTS VPS. **Harden it first** (see
   `references/vps-hardening.md`): create a non-root sudo user, key-only SSH on a
   **non-standard port**, **fail2ban**, a firewall (UFW/nftables) allowing only the
   SSH port + 80/443. Doing this before exposing services avoids a window of a
   wide-open box.
2. **Install Docker + compose** (`get.docker.com`; add the user to `docker`).
3. **CI deploy key**: dedicated SSH key, public half in the VM `authorized_keys`,
   private half in GitHub secret `VPS_SSH_KEY`; `VPS_HOST`, `VPS_USER`,
   `VPS_SSH_PORT` and the pinned host key `VPS_KNOWN_HOSTS` as GitHub variables.
4. **`deploy/` assets**: `docker-compose.yml` + `Caddyfile` (templates in `assets/`).
   The app exposes its port only on the compose network; Caddy is the only thing
   publishing 80/443.
5. **Workflow** `assets/deploy-to-vps.yml`: on push to `main` touching the app/deploy
   paths - render `.env` from secrets, rsync to the box (over the custom SSH port),
   `docker compose up -d --build`, then honest health check. `.gitignore` the
   rendered env.
6. **Secrets into GitHub**: anything the app needs that isn't already a GitHub secret
   (commonly the DB URL + provider tokens if migrating off a PaaS) - add it.
   `assets/migrate-secrets.sh` (bash) or `assets/migrate-secrets.ps1` (pwsh) shows the
   source->`gh secret set` loop.
7. **Push, `gh run watch`, iterate** until the health check is green *and honest*.

**Read `${CLAUDE_SKILL_DIR}/references/phase1-vps-cicd.md` before starting Phase 1: it holds the commands and the Phase 1 gotchas (Compose `$` mangling, dishonest green deploys, slim images, host allowlists, startup flapping).**

---

## Phase 2 - OAuth / OIDC redirect URIs

Do this **before** repointing the frontend. See `references/phase2-oauth.md`.

Universal across providers (Google, GitHub, Microsoft/Entra, Auth0/Okta, Discord,
generic OIDC): the callback URL changes when the host changes, and the provider only
accepts redirect URIs registered **exactly** on the **specific client** the app uses.

1. **Read the exact `redirect_uri` the app actually emits** - don't guess. Hit the
   login-initiation endpoint and parse the authorize URL's `client_id` + `redirect_uri`.
2. Open the OAuth client matching that **exact `client_id`** (apps often have separate
   clients for login vs each connector) and add the redirect URI
   **character-for-character** (scheme, host, no trailing slash, lowercase),
   **alongside** the old host's.
3. **Save** the form and expect **propagation delay**; retry in **incognito**.

`redirect_uri_mismatch` is almost always wrong-client or a typo, not your code.

---

## Phase 3 - DNS + TLS (proxied by default), cutover, decommission

See `references/phase3-dns-tls.md`. **Default to a proxied/CDN setup to hide the
origin IP** (recommended practice), with a firewall that
locks the origin to the CDN's IP ranges. Plain DNS-only is the simpler fallback but
exposes your server IP.

1. **DNS record** `name -> VPS IP`. Recommended: **Cloudflare proxied (orange cloud)**
   so visitors see Cloudflare's IP, not yours.
2. **TLS with a proxied origin**: Caddy's HTTP-01 challenge **won't validate behind
   the proxy**. Use the **DNS-01 challenge** (Caddy built with `caddy-dns/cloudflare`
   + a scoped API token) or a **Cloudflare Origin Certificate** with SSL mode
   **Full(strict)**. (Plain DNS-only/grey cloud + HTTP-01 is the simple alternative
   that exposes the IP.)
3. **Lock the origin to the CDN.** Proxying hides the IP from web visitors, but the box
   is still directly reachable (and SSH is never proxied). Restrict the firewall so
   80/443 accept **only Cloudflare's IP ranges**, and SSH only from your IP/VPN - then
   scanning the IP reveals nothing. **Caddy runs in Docker, and Docker-published ports
   bypass plain UFW rules** - use `ufw-docker` + `ufw route` rules or a Cloudflare
   Tunnel. See `references/vps-hardening.md` section 5.
4. **Verify externally**, **cut the frontend over** (new API base URL + redeploy;
   confirm CORS), then **decommission** the old backend once login + data are verified.

**Before step 1, read `${CLAUDE_SKILL_DIR}/references/phase3-dns-tls.md`: it holds the Phase 3 gotchas (staging cert fallback, Docker bypassing UFW, two-switch cutover) and the decommission checklist. Run that checklist before deleting anything old.**

---

## Safety gates

Ask the user before each step that changes something outside the repo: running commands on the
server (including `harden.sh`, which changes SSH), setting GitHub secrets or variables, pushing to
`main` (it starts a deploy), editing DNS or OAuth clients, and deleting old resources. Say what
the step does and what it can break first. Never print or log secret values.

## Safety during migrations

Reading prod secret values out of a PaaS, deleting prod resources, and force-pushing
may be blocked by an automated safety layer - correctly. When blocked, hand the exact
command to the user to run in their own session. Keep the old backend running until
the new path is proven; delete last.

## Reference map

- `references/phase1-vps-cicd.md` - provisioning, deploy key, workflow, debug map
- `references/vps-hardening.md` - fail2ban, SSH port, firewall, Cloudflare origin lockdown
- `references/runtimes.md` - per-stack Dockerfile + env keys (Node, Python, Go, .NET)
- `references/phase2-oauth.md` - exact redirect-uri matching across providers
- `references/phase3-dns-tls.md` - proxied + DNS-01 / origin cert; other DNS providers
- `references/health-checks.md` - what readiness must assert, probe wiring, probe traps
- `references/readiness-by-framework.md` - ready/live endpoint snippets for Node, Python, Go, .NET
