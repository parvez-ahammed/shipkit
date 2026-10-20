---
name: add-mcp-server
description: >-
  Adds an MCP server to an existing app, any stack, so its owner can ask Claude (Code, claude.ai,
  Desktop) or ChatGPT about their own data: read-only tools on the app's own report queries, scope
  checks, scoped API keys, OAuth 2.1, tested with the MCP Inspector. Use for "MCP-ify my app",
  "mcpify", "add an MCP server", "expose my data to ChatGPT", "make a custom connector", "claude.ai says
  couldn't reach the MCP server". Not for calling an LLM from the app, or hosting (use deploy-to-vps).
argument-hint: "[app path | which data to expose]"
license: MIT
compatibility: "Needs the app's own toolchain and the official MCP SDK for its language. Testing uses Node 22+ (npx @modelcontextprotocol/inspector) and curl. claude.ai and ChatGPT connectors need the app on public HTTPS."
---

# add-mcp-server - let the owner ask Claude about their own data

MCP-ifying an app means: an HTTP endpoint (`/mcp`) that speaks the Model Context Protocol, a
small set of tools that answer questions from the app's data, and a way in for each kind of
client. The app calls no LLM. The owner's assistant does the talking and calls your tools.

The hard part is not the SDK. It is that an assistant will happily quote whatever a tool returns,
so a tool that re-derives a figure, leaks another tenant's row or accepts a write is worse than no
tool. This skill encodes the order that avoids that: read-only first, the app's own queries, the
app's own scope rules, then auth, then the clients.

## When to use / not use

- Use when an existing app (any language) should be reachable from Claude Code, Claude Desktop,
  claude.ai or ChatGPT, for questions over its data ("how did we do yesterday", "what is low").
- Use when a connector fails to connect (discovery, OAuth, 401 loops) and you own the server.
- Don't use for calling an LLM from inside the app, for a local stdio tool for your own dev
  workflow (a plain `claude mcp add` of an existing server is enough), or for write/agent actions
  before the read-only server is shipped and audited.

## Workflow

### 1. Inventory before code

Read the project rules file (`CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`) and find:

- **The questions the owner asks.** Five to ten real ones. Each becomes at most one tool.
- **The query that already answers each one** - the report, dashboard or export the app already
  shows. Note its file and function. A tool with no existing query behind it is a design decision
  for the owner, not something to invent.
- **The scope model**: tenant (database, schema or column), organisation, branch/location, user
  permissions. Find the one function the app uses to narrow queries to what a user may see.
- **The auth model**: sessions, API keys, an existing OAuth server or IdP.
- **Time**: the app's local-day rule (tenant time zone). Tools must use it, never server time.

Write the tool list (name, question, source query, permission) and confirm it with the user
before building. Cheap to change now, expensive after clients have cached the schema.

### 2. Design the tools - read `${CLAUDE_SKILL_DIR}/references/tools.md`

It ends with the tool gotchas (argument binding, report drift, personal data); read them too.

Non-negotiables:

1. **Read-only.** Every tool annotated `readOnlyHint: true`, `destructiveHint: false`. No write
   paths in v1. Prove it with a test that checksums every other table before and after.
2. **Reuse, never re-derive.** Call (or extract and share) the exact query the app's own report
   runs. If the tool and the report can disagree, they will. Add a test that compares the tool's
   figure with the report endpoint's for the same days.
3. **Scope on every call.** Resolve tenant from the host or token, intersect the token's scope
   with the user's CURRENT scope per request, check the permission per tool. An out-of-scope id
   must answer exactly like a missing one.
4. **Server instructions that forbid invention**, for example: "Read-only figures from <app>.
   Call list_<things> first. Dates are local dates. Quote every figure; do not estimate or invent
   figures, and say so when a tool returns no data."
5. **Plain, self-describing output**: JSON text with currency, date range, and a `note` that says
   what a figure includes and excludes. Errors are tool results the model can act on, not 500s.
6. **Audit every call** (user, token, tool, arguments, rows, outcome), including calls whose
   arguments failed to bind.

### 3. Pick the SDK and transport - read `${CLAUDE_SKILL_DIR}/references/sdks.md`

Use the official SDK for the app's language and **Streamable HTTP, stateless**: each POST
resolves its tenant and token afresh and nothing is kept between requests, which is what a
multi-tenant web app wants. Mount it inside the existing app (same host, same DI, same DB
access), at `/mcp`. Verify the SDK's current package name and API with the docs (context7 or the
SDK site) before writing code; several SDKs had breaking major versions in 2026.

### 4. Authentication - read `${CLAUDE_SKILL_DIR}/references/auth.md`

Read its section 9 (pitfalls) before building: wrong 401 header, `resource` mismatch, proxy URLs, rate limit keys, tenant-bound hashes, 405 for GET/DELETE, form-urlencoded token endpoint.

Two ways in, both landing on the same token record, scope and audit:

- **Scoped API keys** for Claude Code, the Inspector, VS Code and scripts: made by the owner on a
  settings screen, shown once, stored hashed, read-only, limited to chosen scopes, with expiry and
  instant revoke. Accepted on `/mcp` only.
- **OAuth 2.1** for claude.ai, Claude Desktop and ChatGPT, which accept no pasted key: protected
  resource metadata (RFC 9728) named in the 401, authorization server metadata (RFC 8414), dynamic
  client registration (RFC 7591) and/or Client ID Metadata Documents, PKCE S256, `resource`
  binding (RFC 8707), single-use codes, rotating refresh tokens, and reuse detection that revokes.

If the app already has an OAuth/OIDC provider, use it as the authorization server and make `/mcp`
only a resource server. Build one only when there is none.

Ship API keys first; they unblock Claude Code testing while OAuth is built.

### 5. Prove it locally - read `${CLAUDE_SKILL_DIR}/references/testing.md`

1. Tests per tool: figures equal the report's, out-of-scope branch/tenant refused, missing
   permission refused, bad arguments rejected and audited, nothing written.
2. Auth tests: no token / wrong / revoked / expired / other tenant's token = 401 with the
   `resource_metadata` challenge; code reuse and refresh reuse revoke.
3. MCP Inspector (CLI and browser), then `claude mcp add --transport http <name> <url>` and a
   real question in Claude Code.
4. claude.ai and ChatGPT need a public HTTPS URL. If you could not test them, say **unverified**.

### 6. Hand over

Document for the owner: the URL, how to add it in each client, which data leaves the app (it goes
to the assistant's vendor as part of the conversation - say so on the consent page and settings
screen), how to revoke, and what was not verified.

## Reference map

- `references/tools.md` - read when designing or reviewing tools: naming, descriptions, argument
  shapes, output shape, errors, audit, the ChatGPT `search`/`fetch` pair.
- `references/auth.md` - read when building API keys or the OAuth 2.1 server, or debugging a
  connector that will not sign in.
- `references/sdks.md` - read when picking the SDK; per-language package, transport and auth helpers.
- `references/testing.md` - read before calling it done: test list, Inspector and curl walkthrough,
  client setup commands.
