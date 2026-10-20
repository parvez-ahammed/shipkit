---
name: simplify-code
description: >-
  Make one file, module, layer slice or duplication cluster simpler by actually removing over-
  engineering, dead code, duplication and wrong-layer code, in one behavior-preserving change
  verified by the repo's gates. Use for "simplify this", "clean up this module", "remove dead or
  duplicate code", "these two modules do the same thing". Not for comment-only cleanup (use trim-
  comments), bugs (use fix-bug) or a smell report without edits (use refactor).
argument-hint: "[file | folder | module | duplication cluster]"
license: MIT
---

# simplify-code - less code, same behavior

Make ONE target simpler in a single behavior-preserving change set that the repo's gates verify. You
are removing complexity, not redesigning. The best simplification deletes code that never needed to
exist; the next best collapses duplication so a future change is a one-place edit.

**Iron Law:** if a change is not obviously behavior-identical and the gates cannot prove it, it does
not land. Flag it instead.

Two guardrails sit above everything:

1. **Minimalism applies to features and architecture, never to protection.** Validation at a trust
   boundary, data-loss handling, tenant isolation, auth and token state, error handling for real
   external failures, and security checks are never on the chopping block.
2. **Smaller because unnecessary, not golfed.** The win is removing code, not compressing readable
   code into a clever one-liner. If the shorter form is harder to follow, keep the longer one.

Not for: bugs or wrong results (use `fix-bug`); design-pattern decisions (use `refactor`); comment-only
cleanup (use `trim-comments`); finding what to share across a backlog of features (use
`find-shared-code`). If you find a defect while simplifying, report it and route it; do not "fix" it here.

## Before you start

- **Read the project rules:** `CLAUDE.md` / `AGENTS.md` / `CONTRIBUTING.md`, architecture or
  conventions docs. Layering rules, "classes by convention", formatter bans and off-limits paths
  override this file. Simplifying must not drift the architecture.
- **Detect the stack and the layout** from the repo (`package.json`, `*.csproj`, `pyproject.toml`,
  `go.mod`, `Cargo.toml`, `pom.xml`, `build.gradle`, `Gemfile`, `composer.json`). Find where layers
  live; do not assume a folder structure.
- **Find the gates** (see Verify). If none exist for the target, most cuts become flag-only.
- **Optional sibling:** `refactor` for a cited smell pass, safe step-by-step mechanics on
  anything bigger than a delete, or a score of whether a shared abstraction is justified. All optional; this skill works without them.

## The checklist (walk top-down; the highest rung that applies wins)

1. **Does it need to exist at all?** Dead exports, unreachable branches, unused params and locals,
   abstractions with one caller, config for things that never vary, defensive checks for states the
   type system or an upstream validator already forbids. Delete.
2. **Does it duplicate something that exists?** Another module, a shared helper, a framework or base
   class member. Call the existing thing instead of keeping a second copy.
3. **Can the platform do it?** The standard library, the framework, the ORM or query builder, the
   validation library, a global error handler. Drop the hand-rolled version.
4. **Can it be one clear expression?** A loop that is a map / filter / reduce, a manual null-walk that
   is optional chaining, a try/catch that only rethrows. Collapse only when the result is clearer.
5. **Right level of abstraction?** Code at the wrong layer (a controller assembling queries, a
   service touching HTTP request objects, a UI component doing data fetching the project puts in a
   hook or store, a low-level detail inside a high-level step). The cut is to **relocate** within the
   target's own slice, not to delete. Moving logic into another module is a second target: defer it.
6. **Efficiency, only if provably identical.** N+1 queries, the same record fetched twice in one
   request, independent awaits run in series, a value recomputed that is already in scope, a React
   component recomputing on every render what is constant. Land it only when the result is the same
   (rows, order, errors) and a test proves it: an existing covering test, or a characterization test
   you add in the same change. Otherwise defer and flag; that is the normal outcome for this rung.
7. **Otherwise keep it, minimally.** If it survives the checklist it is real. Move on.

**Surgical-change discipline** runs through all of it: make the smallest diff that removes the
complexity; state each assumption you rely on ("this branch is unreachable because the schema
rejects X"); name the success check up front (gates green, public surface identical). If you cannot
say how you will prove a change is safe, do not make it.

## Workflow

1. **Pick one target and state it.** A file, a module, one layer slice of one feature (for example
   its route + service + repository, or its page + hook + API client), or a named duplication
   cluster. Edits across that slice are in scope; another feature's files are a second target.
   **Boy-scout mode** (reached mid-task while editing for another reason): the target is the code
   your diff touches, not the whole file, and the cleanup goes in that task's commit and branch.
2. **Survey (read-only).** The charters are in `${CLAUDE_SKILL_DIR}/references/finder-prompts.md`.
   **Small target (under ~500 lines, or one to three files): run the charters yourself in
   sequence.** Subagents cost more than they find at that size. Only for a larger slice, and only if
   the Agent tool is available, dispatch finders in one message so they run in parallel, at most
   four at once (group related charters into one finder). If a dispatch fails or hits an agent cap,
   run the missing charters yourself; do not retry in a loop. Finders report, they never edit.
3. **Triage.** Merge reports, drop false positives (see Leave these), rank by value and risk: deletes
   and dedup first, expression collapses next, relocations after, shared abstractions last and only
   when scored. `${CLAUDE_SKILL_DIR}/references/smell-to-cut.md` maps each smell to its cut.
4. **Cut, smallest diff first.** Keep the public surface identical: route shapes, response bodies,
   exported types and signatures, component props, CLI flags, event names. An export with zero
   callers anywhere in the repo (search proves it) is dead code, not public surface, and may be
   deleted. The exception is a package other repos consume (a published library, an SDK, a plugin
   API): there an export is public surface even with no local callers, so defer it.
5. **Verify.** Re-check the touched code for the smell, then run every gate and read every exit code.
6. **Stop when the safe backlog runs out.** No marginal changes; report what remains.
7. **Report** (shape below). Make one focused local commit if the user wants a commit; stage only the
   intended files, never `git add -A`. Never push, open a PR, or merge without an explicit yes.

## Duplication across modules ("two modules do the same thing")

1. **Detect.** Compare module pairs for identical or near-identical private functions, the same query
   shape, copy-pasted mapping or validation, two differently named helpers with the same body.
   Return both `file:line` ranges side by side with a similarity note.
2. **Confirm it is real.** Two short functions that look alike but serve different domains are not
   duplication. Deduping them couples modules that should stay independent. Collapse only when it is
   one responsibility that got copied.
3. **Choose the home.** Pure, domain-free logic goes to the project's shared utilities location.
   Shared domain behavior goes to one owning module that the others call. Follow the project's
   placement rules.
4. **Score before abstracting.** If collapsing needs a new pattern (shared skeleton with a varying
   step, swappable algorithm, adapter over a subsystem), score it first, for example with `refactor`.
   A wrong abstraction is worse than the duplication.
5. **Cross-module dedup is its own change.** It touches two or more modules at once; do it as a
   separate, serial change, not inside another target.

## Leave these (not complexity)

- Defensive code at a trust boundary: input validation, external provider responses, expired or
  revoked tokens, reconnect states, real-world records in odd states.
- Shapes the project mandates (for example "services are classes", "every repository has an
  interface"). Turning those into free functions is a violation, not a cleanup.
- Interfaces that back dependency injection or test seams, even with one implementation today.
- Integration engines the project says to reuse as-is (auth flows, payment or OAuth adapters).
- Coincidental similarity across domains.
- Schema, migrations, generated code, vendored code, lockfiles.

## Verify with the repo's own gates

Look at the project `CLAUDE.md`, then CI config (`.github/workflows/*`, `.gitlab-ci.yml`,
`azure-pipelines.yml`), then manifest scripts and `Makefile`. Run what CI runs for the touched area:
codegen if any, typecheck / build, lint, project-specific checks, tests. Examples:
`npm run typecheck && npm run lint && npm test`, `dotnet build && dotnet test`,
`go vet ./... && go test ./...`, `cargo clippy && cargo test`, `ruff check . && mypy . && pytest`.

- Run each gate on its own and read its exit code; a pipe through `tail` masks failure. Never claim
  green without running them.
- Do not run a formatter the project does not already enforce; it buries the real diff.
- Do not add to a lint suppression baseline.
- If you removed a code path that had a test, removing the test is part of the same change, and the
  report says why that behavior is gone.
- If the project says not to run the build or suite locally, give the exact commands and mark the
  result unverified.

## Output

```
SIMPLIFY-CODE REPORT
Target:    <what, and why this target>
Cuts:      - <file:line> <what was removed / collapsed / moved> (<rung>, risk: safe-delete | behavior-preserving)
Net:       <-n / +n lines> (a description, not a goal)
Public surface: unchanged | <what changed and why it is safe>
Deferred:  - <file:line> <smell> - <why not here: no covering test | needs scored abstraction | cross-module | possible bug -> fix-bug>
Gates:     <command> -> exit <code>, one line each, or "unverified: <why>"
Status:    DONE | DONE_WITH_CONCERNS | BLOCKED
```

The Deferred list is the hand-off to the next pass so it starts from the real frontier. If the
project keeps a notes or backlog file for this, offer to append it there.
