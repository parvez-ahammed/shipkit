# Authentication: API keys and OAuth 2.1

Two ways in. Both produce the same token record, so scope, permissions, audit, the settings
screen and "disconnect" work the same for both.

| Client | Way in |
| --- | --- |
| Claude Code, MCP Inspector, VS Code / Copilot, scripts | API key in `Authorization: Bearer ...`, or OAuth (Claude Code runs a browser sign-in with `/mcp`) |
| claude.ai (web, Desktop, mobile, Cowork) custom connector | OAuth 2.1 (DCR or CIMD). A static header is a limited beta for organisation Owners only |
| ChatGPT connector / app | OAuth 2.1 (CIMD preferred, DCR accepted), or no auth for public data |

Check the current client docs before building; the details below were checked in October 2026:
Claude - claude.com/docs/connectors/building/authentication; ChatGPT -
developers.openai.com/apps-sdk/build/auth; spec - modelcontextprotocol.io (authorization).

## Contents

1. The token record
2. API keys
3. The 401 challenge
4. OAuth endpoints
5. Rules per endpoint
6. Reuse detection
7. Client-specific requirements
8. Using an existing IdP instead
9. Pitfalls found in review

## 1. The token record

One table (per tenant if the app is database-per-tenant):

- `token_hash` unique = `sha256(tenant_id + "|" + token)`. Never store the token. Binding the
  hash to the tenant means a token cannot work on another tenant even if a database is restored
  or cloned there.
- `token_hint` (last 4 characters) so the owner can tell connections apart.
- `user_id` (the token runs with this user's permissions), `scope_ids` (null = all of the
  user's), `read_only` (true for every MCP token), `name`, `created_at`, `expires_at`,
  `revoked_at`, `last_used_at`.
- For OAuth: `oauth_client_id`, `refresh_token_hash` (unique), `refresh_expires_at`,
  `previous_refresh_token_hash` (unique, for reuse detection), `oauth_code_id`.

On every request: look up the hash, check not revoked/expired, check the user still exists and
has not "signed out everywhere" or changed password since the token was made, then narrow scope:
`effective = token.scope_ids INTERSECT user's current scope_ids`. The user losing a branch must
remove it from the token on the next call, not at the next login.

Prefixes make leaked tokens greppable and stop confusion: `<app>k_` API key, `<app>a_` access,
`<app>r_` refresh, `<app>c_` code. Accept only access tokens and API keys as bearers on `/mcp`;
a refresh token presented as a bearer is 401.

## 2. API keys

- Made by the owner on a settings screen ("Connect your assistant"): name, scopes (tick at least
  one), lifetime (30 / 90 / 365 days). Shown once, with copy-paste commands for each client.
- Accepted on `/mcp` only. The app's other API keys and session cookies are 401 on `/mcp`; an MCP
  key is 401 on the rest of the API. Separate audiences: a leaked MCP key cannot reach the rest of the API.
- If the app already has general API keys, add `read_only` and `scope_ids` to them as well:
  default new keys to read-only, keep existing keys' behaviour (null = full), and enforce
  read-only with one middleware that refuses every non-GET (and owner-only endpoints) with 403.
- Who may create keys (owner only, or managers for their own scopes) is a business decision.
  Build the mechanism so a key's scopes must be a subset of its maker's; let the owner decide.

## 3. The 401 challenge

Every unauthenticated or invalid request to `/mcp`:

```
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Bearer realm="<app>", error="invalid_token",
  resource_metadata="https://<host>/.well-known/oauth-protected-resource/mcp", scope="mcp:read"
```

(`error="invalid_token"` only when a token was sent.) Claude ignores this header on a 200, so the
status must be 401. A feature-flag "off" is 403 with your normal error body, checked before the
token so a disabled tenant does not start an OAuth dance.

## 4. OAuth endpoints

| Step | Endpoint | Spec |
| --- | --- | --- |
| Protected resource metadata | `GET /.well-known/oauth-protected-resource` and `/.well-known/oauth-protected-resource/mcp` | RFC 9728 |
| Authorization server metadata | `GET /.well-known/oauth-authorization-server` | RFC 8414 |
| Dynamic client registration | `POST /oauth/register` (JSON) | RFC 7591 |
| Authorize + consent | `GET/POST /oauth/authorize` | OAuth 2.1, PKCE (RFC 7636), RFC 8707 `resource`, RFC 9207 `iss` |
| Token | `POST /oauth/token` (form-urlencoded; also accept JSON) | OAuth 2.1 |
| Revoke | `POST /oauth/revoke` | RFC 7009 |

Protected resource metadata:

```json
{ "resource": "https://<host>/mcp",
  "authorization_servers": ["https://<host>"],
  "scopes_supported": ["mcp:read"],
  "bearer_methods_supported": ["header"] }
```

Authorization server metadata must include `issuer`, `authorization_endpoint`, `token_endpoint`,
`registration_endpoint` (DCR), `revocation_endpoint`, `response_types_supported: ["code"]`,
`grant_types_supported: ["authorization_code","refresh_token"]`,
`code_challenge_methods_supported: ["S256"]`,
`token_endpoint_auth_methods_supported` (include `"none"`),
`authorization_response_iss_parameter_supported: true`, `scopes_supported`. For CIMD add
`client_id_metadata_document_supported: true`.

In a multi-tenant app with a host per tenant, each tenant host is its own issuer
(`https://<tenant-host>`). Nothing crosses hosts.

## 5. Rules per endpoint

**Register (DCR).** Redirect URIs: https, or http only on `localhost`, `127.0.0.1`, `[::1]`; no
fragment; cap the count (10). Auth methods: `none` (public, PKCE only), `client_secret_post`,
`client_secret_basic` (the RFC default when omitted; return the secret once, store its hash).
Rate-limit per IP. Registered clients pile up (Claude registers on every fresh connection):
prune ones with no tokens after a while, or offer CIMD.

**Authorize.**
- Require `code_challenge` with `code_challenge_method=S256`. Refuse `plain`.
- Unknown `client_id` or an unregistered `redirect_uri`: show an error page, NEVER redirect.
  Every other error goes back to the redirect URI with `error`, `state` and `iss`.
- `resource`, if sent, must equal this server's `/mcp` URL exactly.
- Loopback redirect URIs match with the port ignored (RFC 8252 7.3), for both `127.0.0.1` and
  `localhost`.
- Signed out: send to the app's login with a return URL, then back. Signed in without the right
  role: a clear "owner only" page (403).
- The consent page names the client and the redirect host, says which data will go to the
  assistant's vendor, lets the user tick scopes (at least one), and has Approve / Deny.
  CSRF-protected, `X-Frame-Options: DENY` (or CSP `frame-ancestors 'none'`), `Cache-Control:
  no-store`. Hand back with a page that navigates (meta refresh or a link) rather than a form post,
  so a CSP `form-action` rule cannot block an `http://localhost` callback.
- Codes: random, stored hashed, single use, 5 minutes, bound to client, redirect URI, challenge,
  resource, user and ticked scopes.

**Token.**
- `authorization_code`: verify the code (hash), not used, not expired, same client, same
  redirect URI, `BASE64URL(SHA256(code_verifier)) == code_challenge`, same resource. Mark it used
  with a conditional update (`WHERE used_at IS NULL`) so a race cannot redeem it twice.
- `refresh_token`: same client, not expired, user not signed out since. Rotate on every use: issue
  a new refresh token in the same response, store the old hash in `previous_refresh_token_hash`.
- Access tokens short (1 hour), refresh tokens long and sliding (90 days from last use). These are
  technical defaults; say so.
- Errors are RFC 6749 codes: `invalid_grant` for any bad/expired/reused code or refresh token
  (Claude depends on this), `invalid_client`, `invalid_request`, `unsupported_grant_type`.
- Respond fast: Claude gives discovery, registration and token endpoints 10 seconds, refresh 30.

**Revoke.** Accept an access or refresh token belonging to the calling client; always 200.

**CORS.** The metadata, register, token and revoke endpoints answer any origin and the OPTIONS
preflight (the browser Inspector runs the flow from a page). Expose `WWW-Authenticate` on `/mcp`
if browsers call it. No CORS on authorize/consent.

## 6. Reuse detection

- A code presented a second time means it leaked: refuse it AND revoke every token issued from it
  (RFC 6749 4.1.2). Keep the code row (with `used_at`) long enough to detect this.
- A refresh token that was already rotated, presented again, means one of two holders stole it:
  refuse it AND revoke the whole connection (OAuth 2.1 refresh rotation). The client signs in again.
- A code or refresh token from another tenant's host is refused (the tenant-bound hash does this).

## 7. Client-specific requirements

Claude (all surfaces):
- Hosted redirect URI: `https://claude.ai/api/mcp/auth_callback`. Claude Code: loopback
  `http://localhost:<port>/callback` or `http://127.0.0.1:<port>/callback`, any port.
- Uses CIMD only if metadata has both `client_id_metadata_document_supported: true` and `"none"`
  in `token_endpoint_auth_methods_supported`; else DCR.
- Requests the `scope` from your 401, else `scopes_supported`; appends `offline_access` if you list it.
- Uses only the first `authorization_servers` entry.
- Calls come from Anthropic's published egress range (allowlist it in any WAF in front of the MCP
  server AND the authorization server).

ChatGPT:
- Needs public HTTPS (a temporary tunnel is fine for developer-mode testing, not for submission).
- Advertise S256; CIMD preferred, DCR accepted.
- Echo `resource` into the issued token (audience) and check it on `/mcp`.
- Allowlist its redirect URIs, which differ with and without issuer identification (check the
  Apps SDK auth page for the current exact URLs).

## 8. Using an existing IdP instead

If the app already uses an OAuth/OIDC provider (Auth0, Entra ID, Keycloak, Cognito, ...), make
`/mcp` a resource server only: serve protected resource metadata pointing at the IdP, validate
JWT access tokens (issuer, audience = your `/mcp` URL, expiry, scope), and map the subject to your
user. Check the IdP supports DCR or CIMD and PKCE S256 for public clients; many need a setting or
an API call to allow DCR. Entra ID needs the MCP URL registered as an Application ID URI on a
verified domain. Most SDKs ship helpers for this path (see sdks.md).

## 9. Pitfalls found in review

- Rate limiter keyed only by bearer value: each fake token got a fresh bucket. Chain a per-IP
  window first (it runs before authentication), then per token.
- Token hash not bound to the tenant: isolation silently rested on "database per tenant" alone.
- Code reuse and refresh reuse refused but did not revoke what was issued.
- `resource_metadata` built from the internal scheme/host behind a proxy (`http://10.0.0.5`):
  apply forwarded headers before building any URL.
- The SPA fallback answered GET `/mcp` with HTML; answer GET/DELETE 405 in stateless mode.
- Consent page framed or cached; no CSRF token.
- A token's scopes checked only when it was made, not on every request.
- The token endpoint parsed only JSON: it must accept `application/x-www-form-urlencoded`
  (registration uses JSON). JSON-only parsing gives 415 and a silent connection failure.
- A 401 without `WWW-Authenticate: Bearer resource_metadata="..."`: hosted clients never find
  the authorization server ("Couldn't reach the MCP server").
- `resource` differed from the URL the user typed (path included).
