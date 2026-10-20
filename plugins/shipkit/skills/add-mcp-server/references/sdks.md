# Official MCP SDKs per stack

Use the official SDK for the app's language and mount the server inside the existing web app,
at `/mcp`, with the Streamable HTTP transport in stateless mode. Registry versions below were
checked on 2026-10-18. **Before writing code, check the current version and API** with context7
(`/modelcontextprotocol/<lang>-sdk`) or the SDK site linked from modelcontextprotocol.io/docs/sdk:
the TypeScript and Python SDKs both changed their package layout in their 2.x releases, and most
online examples still show the 1.x API.

## Contents

1. Table
2. TypeScript
3. Python
4. C# / ASP.NET Core
5. Go
6. Java / Kotlin
7. Other languages

## 1. Table

| Stack | Package (checked version) | Server + tool API | Stateless Streamable HTTP | Auth helpers |
| --- | --- | --- | --- | --- |
| TypeScript / Node | `@modelcontextprotocol/server` 2.3 (+ `@modelcontextprotocol/node`, `@modelcontextprotocol/express`); 1.x was `@modelcontextprotocol/sdk` 1.32 | `new McpServer({...})`, `server.registerTool(name, {description, inputSchema: z.object(...), annotations}, handler)` | `createMcpHandler(factory)` per request; 1.x: `StreamableHTTPServerTransport({ sessionIdGenerator: undefined })` | `requireBearerAuth`, `mcpAuthMetadataRouter`, `getOAuthProtectedResourceMetadataUrl` (express package) |
| Python | `mcp` 2.3 (`pip install "mcp[cli]"`); types in `mcp-types` | `MCPServer` from `mcp.server.mcpserver` (replaces 1.x `FastMCP`), `@mcp.tool(annotations=ToolAnnotations(...))` | `mcp.streamable_http_app(stateless_http=True, json_response=True)` (Starlette app, mount in FastAPI/Starlette) | `token_verifier=` (`TokenVerifier.verify_token`) + `AuthSettings(issuer_url, resource_server_url, required_scopes, validate_token_resource)` |
| C# / .NET | `ModelContextProtocol.AspNetCore` 2.2 | `AddMcpServer(o => o.ServerInstructions = ...)`, `[McpServerToolType]` class, `[McpServerTool(ReadOnly = true, ...)]` methods | `.WithHttpTransport(o => o.SessionMode = HttpServerSessionMode.Stateless)`, `app.MapMcp("/mcp")` | `AddAuthentication().AddMcp(o => o.ResourceMetadata = ...)`, `McpAuthenticationDefaults`, `RequireAuthorization()`, `.WithRequestFilters(f => f.AddCallToolFilter(...))` |
| Go | `github.com/modelcontextprotocol/go-sdk` v1.8 | `mcp.NewServer(...)`, `mcp.AddTool(server, &mcp.Tool{...}, handler)` (schema inferred from the input struct) | `mcp.NewStreamableHTTPHandler(getServer, &mcp.StreamableHTTPOptions{Stateless: true})` | `auth.RequireBearerToken(verify, &auth.RequireBearerTokenOptions{Scopes, ResourceMetadataURL})`; `req.Extra.TokenInfo` in handlers |
| Java | `io.modelcontextprotocol.sdk:mcp` 2.1 (2.2 in milestones); Spring: `spring-ai-starter-mcp-server-webmvc` | `McpServer.sync(transport).serverInfo(...).build()`, `addTool(SyncToolSpecification)` | `HttpServletStreamableServerTransportProvider` or the stateless transport; Spring AI starter properties | Spring Security resource server in front of `/mcp` |
| Kotlin | `io.modelcontextprotocol:kotlin-sdk-server` 0.15 | `Server(...)`, `addTool(...)` | Ktor plugin | Ktor auth in front |
| Rust | `rmcp` 3.6 | `#[tool]` macros | streamable HTTP server feature | tower middleware |
| Ruby | `mcp` gem 1.8 | `MCP::Server`, `MCP::Tool` | Rack app | Rack middleware |
| PHP | `mcp/sdk` 0.8 (Tier 3) | check the SDK docs | check the SDK docs | framework middleware |

Tier 1 SDKs (TypeScript, Python, C#, Go, Rust, Ruby) track the spec closely; Tier 2/3 may lag.
If the app's language has only a weak SDK, a small sidecar in a Tier 1 language that calls the
app's existing read-only API with a scoped key is acceptable, but the tools must still call the
app's own report endpoints, never the database directly.

## 2. TypeScript (2.x)

```ts
import { McpServer, createMcpHandler } from '@modelcontextprotocol/server';
import { toNodeHandler } from '@modelcontextprotocol/node';
import { createMcpExpressApp, requireBearerAuth, mcpAuthMetadataRouter,
         getOAuthProtectedResourceMetadataUrl } from '@modelcontextprotocol/express';
import * as z from 'zod/v4';

const mcpUrl = new URL('https://app.example.com/mcp');

function buildServer({ authInfo }) {
  const server = new McpServer(
    { name: 'acme-app', version: '1.0.0' },
    { instructions: 'Read-only figures from Acme. Call list_projects first. Quote figures; never estimate or invent them.' });
  server.registerTool('sales_summary', {
    title: 'Sales summary',
    description: 'Orders and net sales for one project over a date range (local dates).',
    inputSchema: z.object({ project: z.union([z.number(), z.string()]), from: z.string(), to: z.string() }),
    annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false },
  }, async (args) => runTool('sales_summary', authInfo, args)); // runTool: scope, permission, shared query, audit
  return server;
}

const app = createMcpExpressApp({ host: '0.0.0.0', allowedHosts: ['app.example.com'] });
app.use(mcpAuthMetadataRouter({ oauthMetadata, resourceServerUrl: mcpUrl }));
const auth = requireBearerAuth({ verifier: { verifyAccessToken }, requiredScopes: ['mcp:read'],
  resourceMetadataUrl: getOAuthProtectedResourceMetadataUrl(mcpUrl), expectedResource: mcpUrl });
const node = toNodeHandler(createMcpHandler(buildServer));
app.all('/mcp', auth, (req, res) => void node(req, res, req.body));
```

Check where the constructor takes `instructions` in the installed version; on 1.x it is the
second argument's `instructions` field as well.

## 3. Python (2.x)

```python
from mcp.server.mcpserver import MCPServer
from mcp.server.auth.settings import AuthSettings
from mcp_types import ToolAnnotations

mcp = MCPServer(
    "acme-app",
    instructions="Read-only figures from Acme. Call list_projects first. Quote figures; never estimate or invent them.",
    token_verifier=AppTokenVerifier(),   # verify_token(token) -> AccessToken | None, from your token table
    # auth=AuthSettings(issuer_url=..., resource_server_url="https://app.example.com/mcp",
    #                   required_scopes=["mcp:read"], validate_token_resource=True)
)

READ_ONLY = ToolAnnotations(readOnlyHint=True, destructiveHint=False, idempotentHint=True, openWorldHint=False)

@mcp.tool(title="Sales summary", annotations=READ_ONLY)
async def sales_summary(project: int | str, from_: str, to: str) -> dict:
    """Orders and net sales for one project over a date range (local dates)."""
    return await run_tool("sales_summary", project=project, from_=from_, to=to)

asgi_app = mcp.streamable_http_app(streamable_http_path="/mcp", stateless_http=True, json_response=True)
# FastAPI/Starlette: mount asgi_app and run its lifespan (session manager) with the host app's.
```

Check the exact `MCPServer.__init__` auth parameter name in the installed version. The separate
`fastmcp` package on PyPI is a third-party project, not the official SDK.

## 4. C# / ASP.NET Core

```csharp
services.AddMcpServer(o =>
    {
        o.ServerInfo = new() { Name = "Acme", Version = "1.0" };
        o.ServerInstructions = "Read-only figures from Acme. Call list_projects first. Quote figures; never estimate or invent them.";
    })
    .WithHttpTransport(o => o.SessionMode = HttpServerSessionMode.Stateless)
    .WithTools<AcmeTools>()
    .WithRequestFilters(f => f.AddCallToolFilter(next => async (request, ct) =>
    {
        try { return await next(request, ct); }
        catch (Exception e) when (e is not OperationCanceledException and not McpException)
        { return await AuditRejectedArguments(request, e, ct); } // binding failures never reach the tool
    }));

app.MapMethods("/mcp", ["GET", "DELETE"], () => Results.StatusCode(405)); // stateless: no stream, no session
app.MapMcp("/mcp").RequireAuthorization(McpPolicy).RequireRateLimiting(McpRateLimit);

[McpServerToolType]
public sealed class AcmeTools(ToolRunner run, ReportQueries reports)
{
    [McpServerTool(Name = "sales_summary", Title = "Sales summary", ReadOnly = true, Destructive = false, Idempotent = true, OpenWorld = false)]
    [Description("Orders and net sales for one project over a date range (local dates).")]
    public Task<CallToolResult> SalesSummary(JsonElement project, string from, string to, CancellationToken ct) => ...;
}
```

Tool classes resolve from the request's DI scope in stateless mode, so they get the request's
tenant DbContext and user. Type id parameters as `JsonElement` to accept numbers and strings.
For a JWT IdP, `AddAuthentication().AddJwtBearer(...).AddMcp(o => o.ResourceMetadata = new() {
AuthorizationServers = { issuer }, ScopesSupported = ["mcp:read"] })` serves the metadata and the
challenge; with your own tokens, write an authentication handler whose challenge sets the
`WWW-Authenticate` header in auth.md section 3.

## 5. Go

```go
server := mcp.NewServer(&mcp.Implementation{Name: "acme-app", Version: "1.0.0"},
    &mcp.ServerOptions{Instructions: "Read-only figures from Acme. ... never estimate or invent them."})
mcp.AddTool(server, &mcp.Tool{
    Name: "sales_summary", Description: "Orders and net sales for one project over a date range.",
    Annotations: &mcp.ToolAnnotations{ReadOnlyHint: true, IdempotentHint: true},
}, salesSummary) // func(ctx, *mcp.CallToolRequest, SalesArgs) (*mcp.CallToolResult, SalesOut, error)

handler := mcp.NewStreamableHTTPHandler(func(r *http.Request) *mcp.Server { return server },
    &mcp.StreamableHTTPOptions{Stateless: true})
protected := auth.RequireBearerToken(verifyToken, &auth.RequireBearerTokenOptions{
    Scopes: []string{"mcp:read"},
    ResourceMetadataURL: "https://app.example.com/.well-known/oauth-protected-resource/mcp",
})(handler)
mux.Handle("/mcp", protected)
```

Check `ServerOptions` and `ToolAnnotations` field names (some hints are pointers) in the
installed version. The handler rejects loopback requests with a non-localhost `Host` (DNS
rebinding protection); keep it on and send the right Host in tests.

## 6. Java / Kotlin

Spring Boot: the Spring AI MCP server starter (`spring-ai-starter-mcp-server-webmvc` or
`-webflux`) with `@Tool`/`@McpTool` annotated beans and `spring.ai.mcp.server.protocol=STATELESS`
(check the property name for your Spring AI version); protect `/mcp` with Spring Security's OAuth2
resource server. Plain Java: `io.modelcontextprotocol.sdk:mcp` with
`HttpServletStreamableServerTransportProvider` (or the stateless servlet transport) registered
as a servlet. Kotlin/Ktor: `io.modelcontextprotocol:kotlin-sdk-server` and its Ktor integration.
The Java SDK is Tier 2 and Kotlin Tier 3: check that the release you pick supports the current
protocol version and the authorization spec.

## 7. Other languages

PHP (Laravel/Symfony), Rust, Ruby, Swift: see the SDK list at modelcontextprotocol.io/docs/sdk.
Whatever the SDK, the same shape holds: one stateless POST `/mcp` route inside the app, auth
middleware in front that produces the 401 challenge, tools that call the app's existing queries.
