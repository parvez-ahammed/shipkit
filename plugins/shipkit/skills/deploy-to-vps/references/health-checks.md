# Honest health checks

Read this when adding or fixing the app's health endpoint, or when a deploy is green while
the app is down. It also applies outside a VPS: Kubernetes probes and container HEALTHCHECKs.

A health endpoint is only worth as much as what it asserts. The classic, expensive
footgun: `/health` returns `200 "OK"` the instant the process boots - before the DB is
connected, before config is loaded - so the deploy gate goes green, the orchestrator
marks the pod ready, traffic flows, and every request 500s. A green pipeline that lies.

The goal: make the check assert real state, and wire it so the gates mean something.

## Liveness vs readiness (use both, for different things)

- **Liveness** - "is the process running?" Cheap, no dependencies. If it fails, the
  orchestrator restarts the container. Must NOT depend on the DB, or a DB blip
  restart-loops your app.
- **Readiness** - "can it actually serve a request right now?" Checks the things a real
  request needs: database reachable, required config present, downstream/cache up if the
  app can't function without them. If it fails, the orchestrator stops sending traffic
  (but doesn't restart).

Deploy gates and load-balancer routing should key off **readiness**. Restart policies
key off **liveness**.

## What a readiness check must actually touch

Assert the dependencies a request genuinely needs - and only those:

- **Database**: a real round-trip, e.g. `SELECT 1` / `db.ping()` / EF `CanConnectAsync`.
  Not "is a connection string configured" - actually open a connection.
- **Required config/secrets**: fail if a must-have env var is empty (the empty-DB-URL
  case that still "boots").
- **Critical downstreams**: only if the app is non-functional without them. A flaky
  optional cache should make readiness `degraded`, not `unhealthy` - don't fail the whole
  service for a non-critical dependency.

Keep it fast (sub-second, short timeouts) and side-effect free. Cache the result for a
few seconds if probes are frequent.

## Wiring it into the gates (where honesty pays off)

1. **Post-deploy gate** (CI): probe **readiness** after deploy and fail the deploy if it
   doesn't pass. This is the whole point - see the gotchas, they're what make the probe
   itself honest.
2. **Container HEALTHCHECK / orchestrator probe**: point liveness + readiness at the
   right endpoints with sane `interval`/`timeout`/`retries` and a `start_period` long
   enough to cover boot + first DB connect.
3. **Don't let optional-dependency flap fail a deploy** during the startup window;
   retry across it (background-job frameworks report unhealthy for ~15-30s at boot).

## Gotchas (these make the probe itself lie or break)

- **Hardcoded 200**: the original sin. If `/health` doesn't touch a dependency, it only
  proves the process is up - that's liveness, don't treat it as readiness.
- **Slim runtime images have no `curl`/`wget`**: a `HEALTHCHECK` shelling out to them
  marks the container permanently unhealthy. Disable that and probe externally (a curl
  sidecar on the network), or add a tiny built-in checker.
- **Host allowlists reject internal probes** (HTTP 400 "Invalid Hostname") - .NET
  `AllowedHosts`, Django `ALLOWED_HOSTS`, Rails `config.hosts`. Send the real `Host`
  header on the probe.
- **Gate on the status code, not the body.** Readiness returns 503 when a dependency is
  down, so `curl -sf` is the gate. If you also check the body, anchor it: `grep -i healthy`
  matches `Unhealthy`, `^healthy` does not.
- **"Degraded" is 200 by default in some frameworks** (ASP.NET Core maps `Degraded` to
  HTTP 200 with body `Degraded`). A status-only gate passes it; a `^healthy` body gate
  fails it. Decide which you want and make the probe match.
- **`localhost` resolves to `::1` first** in Node 17+, many Alpine images and some curl
  builds. An app listening on `0.0.0.0` (IPv4 only) then refuses the probe and the container
  stays unhealthy. Probe `127.0.0.1` inside the container, or bind the app to `::`.
- **Rolling deploys answer from the old container.** A post-deploy probe can get 200 from the
  version you are replacing. Return the commit SHA from the endpoint and match it.
- **Liveness that checks the DB**: a transient DB blip then restart-loops the app. Keep
  the DB check in readiness, not liveness.
- **Probe timeout shorter than a cold dependency**: cross-region DB latency can exceed a
  tight probe timeout and flap. Match the timeout to reality; retry.

## Implementation

Most frameworks have a health-checks library; prefer it over hand-rolling. See
`${CLAUDE_SKILL_DIR}/references/readiness-by-framework.md` for ready/live endpoint snippets in Node,
Python, Go, and .NET, plus the matching deploy-probe and HEALTHCHECK wiring.

Out of scope: uptime monitoring and alerting from outside (use a monitoring service), and
load testing.
