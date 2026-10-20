# Testing and connecting clients

A green unit suite proves little here. The server is done when a real client has listed the
tools, called them with a real token, and the figures match the app's own screens.

## Contents

1. Automated tests
2. Local walkthrough with curl and the MCP Inspector
3. Connecting each client
4. What to report

## 1. Automated tests

Drive the server through an MCP client (the official SDK's client in your test project), not by
calling tool methods directly; that is the only way binding, annotations and auth are exercised.

Per tool:
- Returns the expected figures for seeded data, and equals the matching report endpoint for the
  same scope and days (call both in the test).
- A scope the token cannot read answers exactly like a scope that does not exist.
- A user without the tool's permission gets the refusal result, and an audit row `refused`.
- Bad dates, too-long ranges, ambiguous names: a plain error result, audit row `rejected`.
- An id sent as a JSON number and as a string both work.
- No personal data in the output.

Whole server:
- `tools/list`: every tool has `readOnlyHint: true`; the server instructions are present.
- Nothing is written: checksum (or row-count and max-updated) every table except the audit and
  `last_used_at` before and after a run of every tool.
- No token, wrong token, revoked, expired, a token for another tenant, an app session cookie, a
  general API key: all 401 with the `resource_metadata` challenge (and `error="invalid_token"`
  when a token was sent).
- Feature off: 403 before any token check.
- GET and DELETE `/mcp`: 405.
- Rate limit: N made-up tokens from one IP stop at the per-IP limit (429).

OAuth:
- Metadata documents have the fields in auth.md section 4, with this host's URLs.
- Registration refuses non-https non-loopback redirects, fragments, too many URIs.
- Authorize: unknown client or unregistered redirect shows an error page (no redirect); missing
  or `plain` PKCE refused; wrong `resource` refused; signed out goes to login and back; non-owner 403.
- Token: code single use; wrong verifier, client, redirect or resource refused; second redemption
  revokes what the first issued; refresh rotates; a rotated refresh token presented again revokes
  the connection; a refresh token is 401 as a bearer on `/mcp`; a code from another tenant refused.
- Form-urlencoded token requests accepted (and JSON if you support it).

## 2. Local walkthrough with curl and the MCP Inspector

Run the app on a free port, bound to both loopbacks if hostnames like `*.localhost` are used
(browsers resolve them to `::1` first). Replace `<base>` with e.g. `http://acme.localhost:8190`.

1. Challenge:
   ```bash
   curl -i -X POST <base>/mcp -H "Content-Type: application/json" \
     -H "Accept: application/json, text/event-stream" -d "{}"
   ```
   Expect 401 and `WWW-Authenticate: Bearer ... resource_metadata="..."`. If `*.localhost` does
   not resolve for curl, add `--resolve acme.localhost:8190:127.0.0.1`.
2. Metadata: `curl <base>/.well-known/oauth-protected-resource/mcp` and
   `curl <base>/.well-known/oauth-authorization-server`.
3. Register a public client:
   ```bash
   curl -X POST <base>/oauth/register -H "Content-Type: application/json" \
     -d '{"client_name":"Local Inspector","redirect_uris":["http://localhost:6274/oauth/callback"],"token_endpoint_auth_method":"none"}'
   ```
4. PKCE pair: verifier = 43+ random URL-safe characters; challenge = BASE64URL(SHA-256(verifier)).
   ```bash
   node -e "const c=require('crypto');const v=c.randomBytes(32).toString('base64url');console.log(v, c.createHash('sha256').update(v).digest('base64url'))"
   ```
5. Open in a browser:
   `<base>/oauth/authorize?response_type=code&client_id=<id>&redirect_uri=http%3A%2F%2Flocalhost%3A6274%2Foauth%2Fcallback&code_challenge=<challenge>&code_challenge_method=S256&state=xyz&resource=<url-encoded base>/mcp`
   Sign in, tick a scope, approve. The browser lands on the callback with `code`, `state`, `iss`.
6. Exchange:
   ```bash
   curl -X POST <base>/oauth/token -d grant_type=authorization_code -d code=<code> \
     -d code_verifier=<verifier> -d client_id=<id> \
     --data-urlencode redirect_uri=http://localhost:6274/oauth/callback
   ```
7. Call a tool with the MCP Inspector CLI:
   ```bash
   npx @modelcontextprotocol/inspector --cli <base>/mcp --transport http \
     --method tools/list --header "Authorization: Bearer <access_token>"
   npx @modelcontextprotocol/inspector --cli <base>/mcp --transport http \
     --method tools/call --tool-name sales_summary --tool-arg project=1 \
     --tool-arg from=2026-10-01 --tool-arg to=today \
     --header "Authorization: Bearer <access_token>"
   ```
   Or the browser Inspector (`npx @modelcontextprotocol/inspector`, transport Streamable HTTP,
   the URL); its auth settings can run steps 1-6 itself ("Quick OAuth Flow"). Inspector flags
   change between majors; run `npx @modelcontextprotocol/inspector --help` if one is refused.
8. Refresh with `-d grant_type=refresh_token -d refresh_token=<refresh> -d client_id=<id>`;
   the old refresh token must now answer `invalid_grant`. Revoke the connection on the settings
   screen; the next `/mcp` call must be 401.

With an API key instead, skip 2-6 and pass the key in the `Authorization` header.

## 3. Connecting each client

- **Claude Code** (OAuth): `claude mcp add --transport http acme https://app.example.com/mcp`,
  then `/mcp` inside Claude Code to sign in (opens the browser, catches a loopback callback).
  With an API key:
  `claude mcp add --transport http acme https://app.example.com/mcp --header "Authorization: Bearer <key>"`.
  Add `--scope project` to write it to `.mcp.json` for a team, but then reference the key through
  an environment variable (`"Authorization": "Bearer ${ACME_MCP_KEY}"`), never commit it.
- **claude.ai / Claude Desktop / mobile**: Settings > Connectors > Add custom connector, paste
  the `/mcp` URL, connect, approve on the consent page. Needs public HTTPS reachable from
  Anthropic's egress range.
- **ChatGPT**: developer mode, add a connector / app with the `/mcp` URL and OAuth. Needs public
  HTTPS; a tunnel works for testing only.
- **VS Code / GitHub Copilot**: `.vscode/mcp.json` with `"type": "http"`, `"url"`, and `headers`
  carrying the key from an input variable.

To test hosted clients before production, put a staging instance on a real HTTPS domain with a
test tenant. Do not point a hosted assistant at production data until the owner has approved
which data leaves the app.

## 4. What to report

- Each client: verified (with the command and the result line) or **unverified** and why
  (typically: hosted clients need public HTTPS).
- The tool list with the report each one was checked against.
- Any data left behind by the test (audit rows, registered clients, tokens) and how to remove it.
