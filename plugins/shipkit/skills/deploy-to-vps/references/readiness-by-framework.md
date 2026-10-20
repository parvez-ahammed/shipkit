# Readiness / liveness snippets by framework

Pattern in every stack: a cheap `/healthz` (liveness, no deps) and a `/readyz`
(readiness, touches the DB + required config). Bind to `0.0.0.0`. Return 200 only when
the dependency check truly passes; 503 otherwise.

## Contents

- Node.js (Express)
- Python (FastAPI)
- Go
- .NET (ASP.NET Core)
- Deploy probe (CI) - the honest gate
- Container HEALTHCHECK / compose
- Kubernetes

## Node.js (Express)

```js
app.get("/healthz", (_req, res) => res.status(200).send("healthy")); // liveness

app.get("/readyz", async (_req, res) => {                            // readiness
  try {
    if (!process.env.DATABASE_URL) throw new Error("missing DATABASE_URL"); // required config
    await db.query("SELECT 1");                 // real round-trip
    res.status(200).send("healthy");
  } catch (e) {
    res.status(503).send("unhealthy: " + e.message);
  }
});
```
Prisma: `await prisma.$queryRaw\`SELECT 1\``. Use a 1-2s timeout on the query.

## Python (FastAPI)

```python
@app.get("/healthz")
async def live(): return PlainTextResponse("healthy")

@app.get("/readyz")
async def ready():
    try:
        await database.execute("SELECT 1")
        return PlainTextResponse("healthy")
    except Exception as e:
        return PlainTextResponse(f"unhealthy: {e}", status_code=503)
```
Django: `django-health-check` package, or a view running `connection.cursor().execute("SELECT 1")`.

## Go

```go
mux.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) {
    w.Write([]byte("healthy"))
})
mux.HandleFunc("/readyz", func(w http.ResponseWriter, r *http.Request) {
    ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
    defer cancel()
    if err := db.PingContext(ctx); err != nil {
        http.Error(w, "unhealthy: "+err.Error(), http.StatusServiceUnavailable)
        return
    }
    w.Write([]byte("healthy"))
})
```

## .NET (ASP.NET Core)

```csharp
builder.Services.AddHealthChecks()
    .AddCheck("self", () => HealthCheckResult.Healthy())          // liveness
    .AddNpgSql(connString, name: "db");                           // readiness (real connect)

app.MapHealthChecks("/healthz", new() { Predicate = c => c.Name == "self" });
app.MapHealthChecks("/readyz");   // includes db
```
`AddNpgSql` comes from the `AspNetCore.HealthChecks.NpgSql` package (sibling packages
exist for SqlServer, MySql, Redis...); without a package, `AddDbContextCheck<T>()` from
`Microsoft.Extensions.Diagnostics.HealthChecks.EntityFrameworkCore` does a real connect.
Returns 200 "Healthy" / 503 "Unhealthy", and **200 "Degraded"** by default - a
`^healthy` body gate fails on Degraded while a status-only gate passes it. Remember
`AllowedHosts` rejects probes without the right Host header.

## Deploy probe (CI) - the honest gate

Probe **readiness** after deploy; a curl sidecar avoids the no-curl-in-image problem and
carries the real Host header. Retry across the startup window. The gate is the **HTTP status
code**: readiness returns 503 when a dependency is down, and `curl -f` fails on it. Add a
body check only to reject a 200 `Degraded` (see .NET above), and then anchor it.

```bash
for i in $(seq 1 25); do
  if docker run --rm --network "$NET" curlimages/curl -sf --max-time 5 -o /dev/null \
       -H "Host: your.domain" http://app:8080/readyz; then
    echo ready; exit 0
  fi; sleep 6
done
echo "not ready"; docker compose logs --tail=60 app; exit 1
```

**Rolling or blue-green deploy?** A ready answer can come from the OLD container that is still
serving. Have the endpoint return the build's commit SHA (for example from a `GIT_SHA` env var
baked in at build time) and make the probe check that it equals the SHA being deployed.

## Container HEALTHCHECK / compose

If the runtime image lacks curl/wget, disable the Dockerfile HEALTHCHECK
(`healthcheck: { disable: true }` in compose) and rely on the external probe, OR add a
tiny built-in checker. Give `start_period` enough room for boot + first DB connect so
the startup window doesn't flap.

When the image does have a client (or you add one), point the container check at
**liveness**, not readiness - Swarm and other orchestrators replace unhealthy containers
(plain `docker compose` only reports the state and gates `depends_on: condition:
service_healthy`), and a DB blip must not trigger a replacement:

```yaml
healthcheck:
  test: ["CMD", "curl", "-fsS", "http://127.0.0.1:8080/healthz"]   # or wget -qO- ...
  interval: 15s
  timeout: 3s
  retries: 3
  start_period: 40s
```

Node images without curl can use `["CMD", "node", "-e", "fetch('http://127.0.0.1:8080/healthz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"]` (Node 18+).

## Kubernetes

```yaml
livenessProbe:  { httpGet: { path: /healthz, port: 8080 }, initialDelaySeconds: 10 }
readinessProbe: { httpGet: { path: /readyz,  port: 8080 }, periodSeconds: 5 }
```
Liveness on `/healthz` (no deps - a DB blip must not restart the pod); readiness on
`/readyz` (gates traffic).
