---
name: refactor
argument-hint: "[file, directory, or symbol] [optional: smell, refactoring or pattern]"
description: >-
  Find code smells, plan safe refactoring steps, or score whether a design pattern (Factory,
  Strategy, Adapter, Observer, ...) fits, with file:line evidence and an APPLY / CONSIDER / REJECT
  verdict. Report and plan only, no edits. Use for "find code smells", "what is wrong with this
  code", "how do I extract this method", "should I use a strategy here", "refactor this". Not for
  making the cleanup (use simplify-code) or layer rules (use enforce-clean-architecture).
license: MIT
---

# refactor - smells, mechanics and pattern fit

Answer refactoring and design-pattern questions with cited evidence and a scored verdict. The
catalogs (refactoring.guru's 22 smells, Fowler's refactorings, the GoF patterns) live in
`references/`; read only the file the question needs. A pattern is recommended only when a site
meets explicit, scored preconditions. Never apply a pattern for its own sake.

## Step 1: pick the mode

| Intent | Trigger phrases | Mode | Read |
|--------|-----------------|------|------|
| Find problems | "find smells", "what is wrong with", "what should I clean up" | **smells** | `smells.md` (+ `smells-bloaters.md` / `smells-couplers.md` when that group hits) |
| Fix a known smell | "how do I extract this method", "this class is too big", "replace this conditional" | **mechanics** | `refactorings.md` (+ `refactorings-composing-methods.md` / `refactorings-simplifying-conditionals.md`) |
| Is pattern X right here | "should I use a Factory here", "is Strategy a fit" | **score** one site | the one `patterns-<family>.md` |
| Where can I use a pattern | "scan for pattern opportunities" | **smells** sweep, then **score** each candidate site | `smells.md`, `linkage-map.md`, then the pattern files |
| Vague "make this better" | "refactor this", "improve this design" | **smells**, then branch on what it finds | as above |

All files are in `${CLAUDE_SKILL_DIR}/references/`. Pattern families: creational (object
construction), structural (composition and interfaces), behavioral (interaction and
responsibility). Unsure which family? `linkage-map.md` maps each symptom to a candidate pattern
and its file; if two families fit, score both and let the scores decide.

If the intent is truly ambiguous, ask one short question. Otherwise pick the mode and go.

## Step 2: do the work

- **smells:** follow `smells.md`. A bug is not a smell: report it under `BUGS` and point to
  `fix-bug`.
- **mechanics:** follow `refactorings.md`. Every plan rests on its SAFETY RULE (a test run after
  each small step).
- **score:** follow `verdict-format.md` and the pattern entry. The VERDICT line shows the
  arithmetic `(score N / threshold M)` and any veto or downgrade.

All of it runs inline. This is reading and scoring a few files; it needs no subagents.

## Step 3: report

Every finding uses this shape:

```
TARGET: path/to/File.ext:Symbol
FINDING: <smell, or pattern opportunity>
EVIDENCE: file:line - <what was seen>
VERDICT: APPLY | CONSIDER | REJECT   (pattern: score N / threshold M)
RECOMMENDATION: <refactoring or pattern, or the simpler idiom> - <one line>
NEXT: <e.g. "mechanics: Extract Method", "score Facade", "fix-bug", "leave as is">
```

- Put `BUGS` first if there are any, then APPLY, then CONSIDER, then the REJECTs collapsed (show
  them: what was considered and why it was vetoed is the trust signal).
- Within a verdict, order by score, or by how much the smell blocks change.
- If one site scores APPLY for two patterns (Strategy vs State, say), show both and the one
  precondition that separates them. Never pick one silently.
- If nothing qualifies, say the code is clean here. Do not invent a smell or a pattern fit.
- For a chained plan (Extract, then Move, then delete the old copy), use the `STEP n of N`
  shape in `refactorings.md`, with the characterization tests first.

## Hard rules

- No edits to the user's working tree. The user approves, then follows the mechanics or asks
  `simplify-code` to make the change. To prove a plan holds, dry-run it in a throwaway copy.
- Evidence is mandatory: no `file:line`, no finding.
- A hard veto wins: any anti-indicator means REJECT, whatever the score.
- YAGNI: if a pattern adds more complexity than the problem it solves, cap it at CONSIDER and
  say why. Simple, stable code stays simple.
- Scope: only the files the user points at. Exception: to call something Dead Code, Lazy Class
  or Shotgun Surgery, search the whole repo for its callers; report only findings in the target.
- Not this skill: which layer code belongs in (`enforce-clean-architecture`), a branch or PR
  review (`review-branch`), comment-only cleanup (`trim-comments`).

## References

| File | Read when |
|------|-----------|
| `smells.md` | finding smells: 22-smell triage table, verdict rubric, report rules |
| `smells-bloaters.md`, `smells-couplers.md` | a Bloater or Coupler hits and you need signs and fix detail |
| `refactorings.md` | giving mechanics: the full catalog, SAFETY RULE, plan output shape |
| `refactorings-composing-methods.md`, `refactorings-simplifying-conditionals.md` | deep mechanics for Extract Method family and conditional refactorings |
| `patterns-creational.md` | Factory Method, Abstract Factory, Builder, Prototype, Singleton |
| `patterns-structural.md` | Adapter, Bridge, Composite, Decorator, Facade, Flyweight, Proxy |
| `patterns-behavioral.md` | Strategy, State, Command, Observer, Chain, Template Method, Visitor, Mediator, Iterator, Memento |
| `patterns-strategy-state-command.md` | scoring Strategy, State or Command, or any classic confusion |
| `verdict-format.md` | scoring any pattern: the scored-precondition schema and rules |
| `linkage-map.md` | choosing which refactoring or pattern a symptom points to |
