# Designing the tools

A tool is a question the owner already asks, answered by a query the app already runs, inside
the scope the caller already has. Everything below serves those three rules.

## Contents

1. Choosing tools
2. Names, titles and descriptions
3. Arguments
4. Output
5. Errors and refusals
6. One runner for every tool
7. Audit
8. ChatGPT: search and fetch
9. Review checklist
10. Gotchas

## 1. Choosing tools

- Start with 5-10 read-only tools. Typical first set for a business app:
  - `list_<scopes>` (branches, projects, workspaces) - always first; returns ids, names and each
    scope's local "today". Every other tool takes one of these ids.
  - a summary over a date range (`sales_summary`, `usage_summary`)
  - a comparison of two days or periods (`compare_days`)
  - a ranking (`top_items`)
  - a breakdown the app already reports (by payment method, by tax rate, by status)
  - "what needs attention now" (`low_stock`, `open_orders`, `overdue_invoices`)
  - a lookup by name (`menu_lookup`, `find_customer` - mind personal data)
- One tool per question, not one tool per table. A generic `run_sql` or `query(entity, filter)`
  tool bypasses scope, permissions and the report's business rules. Never ship one.
- A question with no existing query behind it (a forecast, a margin the app does not compute)
  is a product decision. Ship the tool only when the app has the figure; until then, have it say
  plainly "No forecast is available" rather than estimate.
- Writes come later, one at a time, behind a separate scope, with confirmation and audit. Not in v1.

## 2. Names, titles and descriptions

- `snake_case` verbs or nouns the owner would use: `sales_summary`, `top_dishes`, `low_stock`.
- `title` is the human label clients show in the approval prompt.
- The description is the only manual the model reads. Say: what it returns, the unit and
  currency, the date convention, the limits (max range), what is included and excluded, and
  which tool to call first. Example:
  "Sales for one branch over a date range (inclusive): orders, items sold and net sales, in
  total and per day. Dates are the branch's local dates (YYYY-MM-DD, or today / yesterday). At
  most 366 days. Net sales exclude service charge, tips and delivery fees."
- Annotate every tool: `readOnlyHint: true`, `destructiveHint: false`, `idempotentHint: true`,
  `openWorldHint: false` (it reads only your system). Clients use these to skip confirmation and
  ChatGPT requires `readOnlyHint` on read-only tools.

## 3. Arguments

- Ids: accept a number OR a string, and a name as well as an id (exact name first, then a unique
  partial match; ambiguous = an error that lists the candidates). Clients and the Inspector send
  numbers as JSON numbers; a strict string parameter fails inside the SDK before your code runs.
- Dates: `YYYY-MM-DD` plus `today` / `yesterday`, resolved in the scope's time zone using the
  app's own time helper. Never the server clock. Cap ranges (366 days is a good default).
- Optional scope argument: if the caller can see exactly one scope, default to it; otherwise
  require it and say "call list_<scopes>".
- Limits: a small default (10) and a hard max (25-50). Large dumps cost the user tokens and leak
  more than the question needed.

## 4. Output

- Return JSON as text content (most portable), with relaxed escaping so apostrophes and non-ASCII
  names stay readable. Optionally also `structuredContent` with an `outputSchema`.
- Always echo the resolved scope (`{"branch": {"id": 2, "name": "Main"}}`), the resolved dates,
  and the currency. The model then cannot misattribute a figure.
- Add a short `note` field with the definition of the figure ("net_sales is the sum of stored
  line subtotals on completed, not voided sales, less returns").
- Figures come from stored values (stored totals, stored tax, stored line subtotals). The tool may
  add, subtract and rank what the shared query returns; it must not recompute a price, tax or
  total from rates. Round exactly as the report rounds (same mode, same places).
- No personal data by default: no customer or staff names, phones, emails, addresses or free-text
  notes. Counts and names of things (products, branches, tables) are fine.

## 5. Errors and refusals

Return them as tool results with `isError: true` and a sentence the model can act on:

| Case | Message shape |
| --- | --- |
| Unknown or out-of-scope id | "No branch 'X' is available to this connection. Call list_branches." (identical for both cases) |
| Missing permission | "This connection is not allowed to use top_dishes: its user lacks reports.view." |
| Bad argument | "from must be YYYY-MM-DD, today or yesterday." |
| Argument could not bind | "The arguments for X could not be read. Check them against the input schema." |
| Unexpected failure | "The app could not answer that just now. Please try again." (log the exception, never return it) |

Protocol errors (unknown tool, malformed JSON-RPC) stay protocol errors; let the SDK answer them.

## 6. One runner for every tool

Put the shared steps in one function every tool calls, so no tool can forget one:

```
run(toolName, arguments, permission, body):
    if permission and not user.can(permission): audit(refused); return error
    try:
        result, rows = body()          # resolves scope + dates through shared helpers
        audit(completed, rows); return text(json(result))
    except ToolError as e:  audit(rejected, e); return error(e.message)
    except Exception as e:  log(e); audit(failed, type(e)); return error(generic)
```

Plus a call-tool filter/middleware (most SDKs have one) that catches binding failures before the
runner and routes them to `audit(rejected)`.

## 7. Audit

One row per call: time, user, token id and name, client (API key or OAuth client), tool,
arguments, rows returned, outcome (`completed`, `rejected`, `refused`, `failed`). Write nothing
else. Update a token's `last_used_at` at most once a minute so the audit is not a write storm.

## 8. ChatGPT: search and fetch

ChatGPT connectors work with any read-only tools in developer mode. Its company-knowledge and
deep-research features look for two tools with fixed shapes: `search(query)` returning a list of
`{id, title, url}` results and `fetch(id)` returning one document. Add them only if the owner
wants those features; map them onto the same scoped queries (for example, search over product
names, fetch a product's sheet). Check the current shapes in the OpenAI Apps SDK docs.

## 9. Review checklist

- [ ] Every tool cites the existing query it calls; no tool computes a money/tax figure itself.
- [ ] A test compares each figure tool with the matching report endpoint for the same days.
- [ ] Every tool annotated read-only; no repository write reachable from a tool.
- [ ] Scope resolved per request from host/token and narrowed to the user's current scope.
- [ ] Out-of-scope and missing ids return the same message.
- [ ] Server instructions forbid estimating or inventing figures.
- [ ] Dates use the app's time-zone helper.
- [ ] No personal data in any output.
- [ ] Every call, including unbindable ones, writes exactly one audit row.

## 10. Gotchas

- **The SDK's argument binder fails before your code runs.** Clients send `branch: 2` as a JSON
  number where you typed a string; the SDK returns a generic "error invoking tool" and your audit
  never sees it. Accept number-or-string for ids, and add a call-tool filter that turns binding
  failures into a plain, audited error.
- **A "matches the report" claim is only true if a test compares them.** Tools copied from report
  code drift: rounding, refund handling, voided rows, day boundaries in the wrong zone.
- **Personal data.** Return aggregates and names of things, not customer or staff names, phones or
  notes, unless the owner explicitly decides otherwise. Whatever a tool returns leaves your system.
