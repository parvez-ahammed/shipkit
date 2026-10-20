# The living document: target shape, re-grooming and write-back

Contents: Built-in target shape; Re-grooming (refresh, reconcile, collapse); Decision log; Write-back protocol.

Read when there is no project template (the built-in target shape), when an issue carries layered or
contradicting reviews, or before writing a body back to the tracker.

## Built-in target shape

A groomed issue is one current source of truth, not a transcript of every review that touched it.
The reader must never reconcile two paragraphs that disagree. Scale each block to the issue: a small
issue may have one-line blocks, but the order and the freshness line stay.

```
# <Title>

> **Code state (verified YYYY-MM-DD):** entry points and real file paths the work touches, what was
> removed or renamed, schema state. Re-checked against the live repo on every groom; date bumped.

> **Security (YYYY-MM-DD)** - only when the surface is HIGH
> Surface: HIGH. Threats, required mitigations, security acceptance criteria.

> **External dependency (YYYY-MM-DD)** - only when a paid third-party service or a user price is involved
> Provider, cited price + access date, availability, prerequisites ready / not ready.

> **Implementation notes (YYYY-MM-DD)** - only when library or API call shapes matter
> Verified call shapes with the doc source and version.

Required reading: <project rules file(s)>

## Context / problem          (dim 1)
## Scope / deliverables       (dim 2)
## Technical approach         (dim 6: new vs edited files, what is reused)
## Acceptance criteria        (dim 3: numbered, binary, each bound to a named test)
## Build sequence             (ordered small steps, failing test first, each lands green)
## Test plan                  (dims 4 + 5: happy path and failure modes)
## Verification               (literal gate commands + new test paths)
## Out of scope               (dim 8)
## Dependencies               (dim 7: blocked by / blocks)
## Effort + open decisions    (dim 9: each OPEN QUESTION has "Default if unanswered:")

## Decision log               (only when something was superseded or contested)
```

Every block maps to a rubric dimension, so the shape and the score are one system. Missing data is
`[PENDING]` or an `> **OPEN QUESTION:** ...` callout. Never a fabricated answer, and never a blank
heading: a blank heading reads as "nothing needed here", which is a different and wrong claim.

## Re-grooming: refresh, reconcile, collapse

The usual failure: an issue groomed months ago, then layered with a product note, a security note and
two engineering reviews on different dates. Some now contradict each other or point at files that
moved. Every re-groom does three things.

**1. Refresh.** Re-check the code state line against the live repo: every path, version, branch and
"X was removed" claim. Fix what moved, drop what is no longer true, bump the date. A code state line
not checked this pass means the whole issue is treated as stale.

**2. Reconcile by precedence, not by deletion.** When two layers disagree, resolve to one line in the
right section:

- **Recency:** a newer dated note supersedes an older one on the same point.
- **Authority by domain:** security notes win on security; engineering wins on architecture and file
  layout; product or business wins on scope and what ships; tooling notes win on versions. A newer
  note outside its domain does not silently override an in-domain one; report the conflict.
- **Unresolved:** if recency and authority genuinely conflict (a product scope cut vs a security
  mandate), do not pick a winner. Raise an `OPEN QUESTION` naming both sides, with a default.

Never drop the losing line silently: the builder loses the why, and the next reviewer re-argues it.
Move it to the Decision log.

**3. Collapse duplicates.** Identical text: keep one. Overlapping but different: merge into the
strongest single statement. The body shrinks; the information does not.

### Decision log format

One line per decision. An audit trail, not a discussion.

```
## Decision log
- 2026-01-15: Dropped "cache tokens in the browser for speed" (product note 2025-11), superseded by
  the security mandate (server-side tokens only). Authority: security.
- 2026-01-15: batch size 50 vs 20 unresolved (performance note vs cost cap) -> OPEN QUESTION.
```

## Write-back protocol

- **Confirm first.** Show the full proposed body, or a diff against the current one for long issues,
  and the exact command. Write only after an explicit yes.
- Read the current body immediately before writing; if it changed since you read it, re-merge and show
  the user again.
- Write through a temp file in the session scratch area (`gh issue edit <n> --body-file <tmp>`), never
  a huge inline argument (quoting and length limits break it).
- Do not invent scope. If a gap cannot be filled from the repo, the docs or sibling issues, it becomes
  an `OPEN QUESTION` with a default.
- Do not edit meta or tracking issues.
- Keep an existing security block. Add one only when the surface is HIGH and none exists. An older
  security line overruled by a newer in-domain security note goes to the Decision log; a non-security
  note never overrides a security mandate.
- Bump the code state date on every write, because the write implies you re-checked the repo.
- Match the project's writing rules (punctuation, tone, no tool attribution lines unless the project
  uses them).
- After writing, re-read the issue from the tracker and confirm the new body is there.
