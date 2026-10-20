# Finder prompts

Contents:
- Per-smell finders (one target slice)
- Duplication finder (one per module pair)

Read when running the survey step. Each charter is read-only and owns one smell class. For a small
target, run the charters yourself in sequence. For a large slice with the Agent tool available,
launch finders in ONE message so they run in parallel, at most four, grouping related charters (for
example dead code + duplication, expression + platform, layer + efficiency); a read-only search or
code-review agent type is enough. Without it, run each charter yourself in sequence. Either way you
are the only writer, so there is no edit conflict and the gates run once over one diff.

Fill `<target>` with the files of the slice and `<stack notes>` with what you detected (language,
framework, ORM, validation library, error-handling convention, project rules that forbid a cut).

Every finder returns lines in this shape so triage is mechanical:

```
- file:line-range | <smell> | "<one-line evidence quote>" | proposed cut | risk: safe-delete | behavior-preserving | needs-judgment
```

Return nothing for a class with no hits. Never report formatting or style nits.

## Per-smell finders (one target slice)

**Dead code**
```
Read-only, do not edit. Target: <target>. Stack: <stack notes>.
Find dead code ONLY: unused exports (search the symbol across the whole repo, report only if it has
zero call sites outside its own file and tests), unreachable branches, unused params and locals,
abstractions with exactly one caller. Watch for dynamic use (reflection, string-based DI, routing by
name, framework conventions, public package API) and mark those needs-judgment. Ignore interfaces
that back dependency injection.
```

**Over-abstraction**
```
Read-only, do not edit. Target: <target>. Stack: <stack notes>.
Find over-engineering ONLY: speculative generics or interfaces, wrappers that only delegate,
indirection with one caller, options or config for things that never vary, factories that build one
type. Give the simpler concrete form. Do NOT flag shapes the project mandates or DI interfaces.
```

**Hand-rolled platform**
```
Read-only, do not edit. Target: <target>. Stack: <stack notes>.
Find logic the language, framework or libraries already provide ONLY: loops that are map / filter /
reduce / comprehension, manual deep copy, manual null-walks, filtering / paging / counting in memory
after a broad fetch that the ORM or query can do, re-validating input already validated at the
boundary, bespoke response or error shaping that a shared helper already owns. Name the replacement.
```

**Needless error handling**
```
Read-only, do not edit. Target: <target>. Stack: <stack notes>.
Find try/catch (or equivalent) that adds nothing ONLY: blocks that just rethrow, catch-log-rethrow
where a global handler already logs, wrappers around every handler when a global error handler owns
that job. Do NOT flag handling that maps, retries, cleans up, or protects a trust boundary.
```

**Bloaters**
```
Read-only, do not edit. Target: <target>. Stack: <stack notes>.
Find functions or components over ~40 lines doing more than one thing, 4+ positional params, and
data clumps (the same field group passed together). Propose extraction or a parameter object. Prefer
collapsing to a pipeline when the body is one transformation.
```

**Efficiency**
```
Read-only, do not edit. Target: <target>. Stack: <stack notes>.
Find redundant work ONLY: N+1 (a query or remote call awaited inside a loop over rows), the same
record fetched twice in one request path, independent awaits in series, a value recomputed that is
already in scope, expensive work repeated on every UI render. For each say whether the cheaper form
is provably identical (same rows, order, errors) and name the covering test, or mark needs-judgment.
A version that returns WRONG results is a bug: report it separately, do not propose a cut.
```

**Wrong layer**
```
Read-only, do not edit. Target: <target>. Stack: <stack notes>. Layering rules: <from project docs>.
Find code at the wrong level ONLY: transport or UI code doing data access, business logic touching
request / response objects, format validation in a service that belongs at the route or form
boundary (ownership and authorization stay in the service), a low-level detail inside a high-level
step. Name which layer should own it. The cut is to relocate, not delete. Note if the move leaves
the target slice (defer) or crosses into code no gate covers.
```

When a finder flags a small self-contained constant, regex or helper, search its body repo-wide:
identical copies often sit in unrelated modules. Report every `file:line` as a dedup candidate, but
put it in Deferred; it is a separate change.

## Duplication finder (one per module pair)

```
Read-only, do not edit. Compare <module A files> and <module B files>. Stack: <stack notes>.
Find genuinely duplicated logic ONLY: identical or near-identical functions, the same query shape,
copy-pasted mapping or validation, two differently named helpers with the same body. For each pair
give both file:line ranges side by side, a similarity note (identical | near |
same-intent-different-code), and whether it is one shared responsibility or two domain-specific
things that only look alike. Do NOT propose deduping things that serve different domains.
```

Triage these with the SKILL's "Duplication across modules" steps 2 to 5.
