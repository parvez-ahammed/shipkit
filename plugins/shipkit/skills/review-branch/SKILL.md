---
name: review-branch
description: >-
  Reviews a branch, diff or pull request with parallel reviewer seats (backend, frontend,
  architecture, tests, QA, text, new dependencies), a refutation pass and one severity-ranked punch
  list. Use for "review my PR", "code review this branch", "what will be flagged", "what should be
  tested in this PR", "post these findings to PR 123". Say `advanced` for a deep review, `comment`
  to post verified findings to the PR. Use it on small PRs too. Not for testing a running app (use
  test-branch or audit-app) or judging a shipped feature (use grill-feature).
argument-hint: "[PR number | branch] [advanced] [comment]"
license: MIT
compatibility: "Requires git and a sub-agent (Agent) tool for the parallel seats. Comment mode needs the PR host's CLI signed in: gh (GitHub), az with the azure-devops extension (Azure DevOps) or glab (GitLab). Builds use the project's own toolchain."
---

# review-branch

Six independent reviewer seats review a diff in parallel, plus a seventh dependency seat that runs
only when the diff adds a library. This skill is the orchestrator: it reads the diff, routes it to
the seats that apply, collects their results, removes duplicates, tries to refute every serious
finding, and returns one severity-ranked punch list.

The value is the structure around the reading: an ownership split so two seats never report the same
thing twice, severity floors that social pressure cannot lower, a concrete failure scenario on every
finding, and a refutation pass that kills confident-but-wrong findings before the author pays for them.

The seats are **not** separate skills. Each is a rubric under `references/`, passed to a sub-agent by
this orchestrator. A seat run alone reports without the ownership split, the severity floors or the
verify pass, and a partial review gets mistaken for a full one. The entry point is always this skill.
Every `references/` and `assets/` path in this file is relative to `${CLAUDE_SKILL_DIR}`.

## Project rules (read before every review)

A reviewer that does not know the project's conventions and deliberate decisions produces false
positives. Before routing, read every one of these that exists:

1. `.claude/review-rules.md` - the dedicated file for this skill.
2. `CLAUDE.md` / `AGENTS.md` at the repo root and in the folders the diff touches.
3. `.claude/rules/*.md` that cover changed files, and any style guide those files point to.

Pass the paths of every file found to **every seat**, and tell each seat to read them before its own
rubric. A project rule wins over a generic rubric. Record in the report which files were read, or
"none found".

`assets/review-rules.template.md` shows what a project can declare (base branch, build commands,
whether the reviewer may run builds, critical paths, house style, intentional behaviours). If the
repo has no rules file and a false positive was one a rule would have prevented, suggest adding one.

**An intentional-behaviour entry is not a blanket pass.** Do not report the behaviour it describes,
but confirm the code still does exactly what the entry says. Drift from the recorded decision is a
finding.

## Modes

Read the mode from the user's words. When nothing says otherwise, run **self-review**.

| The user says | Mode | Seats | Where the findings go |
|---|---|---|---|
| "review my PR", "review this branch", "what will be flagged" | **self-review** (default) | all 6 | punch list in chat + HTML report |
| "QA this", "what should be tested", "what regressions" | **self-review** | all 6 | same - QA is a seat, not a separate run |
| "advanced mode", "deep review", "full review before PR", "review with everything" | **advanced** | all 6 + 4 external rubrics | punch list in chat + HTML artifact |
| "review PR 123 and comment", "comment mode" | **comment** | all 6 | punch list, then the survivors are posted to the PR |
| "post these findings to PR 123" (findings already in hand) | **comment-only** | none | straight to the commenting flow |
| "code review only", "skip QA" | **code-only** | 4 code seats | punch list in chat |
| "QA only", "just the test cases" | **qa-only** | QA seat | HTML report |
| "review the copy", "check the wording" | **text-only** | text seat | rewrite table in chat |

Modes compose: "advanced review of PR 123, comment mode" runs the advanced flow, then posts the
survivors through `references/commenting.md`.

**Never split a review across two invocations.** A separate QA step ran on a small fraction of
branches - the ones where somebody remembered. `code-only` is for a deliberate second look after
fixes, not a default.

**In comment mode the review target is not your branch.** Take the base from the PR, not from
`<default-branch>...HEAD`, and never assume the author is the user. The review writes public text on
someone else's work, so it goes through `references/commenting.md` and never posts directly.

## Advanced mode

Advanced mode is this skill, not a separate one. The playbook is `references/advanced-mode.md`; load
it only in this mode. It adds a strict base-resolution and diff-dump phase, four external rubrics
(`references/external-rubrics.md`), a dedicated adversarial round on every `high`, and one HTML
artifact. It costs several times a normal review.

Run it when **either** is true:

1. **The user asked** ("advanced", "deep review", "full review", "review with everything"). This
   always wins, even on a small diff.
2. **The change is critical**: it moves, transforms, schedules or authorizes real user data, whatever
   its size. The diff touches integrations with external systems, data sync and transfer, mapping and
   transformation, persistence and migrations, auth / permissions / multi-tenancy, background work,
   rollout paths (backfill, overwrite, republish, changed contract) or destructive paths (delete,
   purge, cancel, rollback). Also critical: a long-lived or large branch, a security fix, a public API
   shape change, any diff whose failure is silent (wrong data written, not a crash), and the project's
   own critical paths. `references/advanced-mode.md` has the table with typical shapes.

When criticality triggers it and the user did not ask, **say so in one line before starting** ("this
touches the sync engine, running advanced mode"). If the user says do it normally, do it normally.

Everything below applies in advanced mode too. Advanced mode changes the flow, not the standards.

## Scope determination

| Seat rubric | Runs when | Scope |
|---|---|---|
| `references/seat-backend.md` | server-side code, build files, migrations changed | hygiene, naming, DRY, async, perf micro-patterns, logging, ORM traps; sync and backward-compatibility rules |
| `references/seat-architecture.md` | **always** | boundaries, business-logic correctness, authorization, cardinality, destructive paths, simplification |
| `references/seat-tests.md` | **always** (any behaviour change) | the unit-test hard rule, plus test quality |
| `references/seat-frontend.md` | UI code changed | rendering perf, state, data fetching, design system, UI fitness and conformance |
| `references/seat-qa.md` | **always** (any behaviour change) | impact beyond the diff, requirement coverage, user-facing defects, test cases |
| `references/seat-text.md` | **always** when a string a human reads changed | misreadable labels, jargon, failures with no cause or next action, house style; literal rewrites |
| `references/seat-dependency-licence.md` | **only** when the diff adds a dependency | licence, free for closed-source commercial use, price, redistribution duty |

Invoke every applicable row. Architecture, tests and QA are mandatory on every non-skipped PR; QA is
dropped only in `code-only` mode. The text seat runs whenever a shipped string changed, also on a
"pure backend" PR: an error message in a service is user-visible text. The dependency seat is driven
by an added package (a new entry in `package.json`, `*.csproj`, `Directory.Packages.props`,
`pyproject.toml`, `requirements*.txt`, `go.mod`, `Cargo.toml`, `Gemfile`, `pom.xml`,
`build.gradle`, and so on), not by folders, and stays silent otherwise.

Which folders count as backend and frontend comes from the project rules. Without them, infer from
the file types and say what you inferred.

## Skip rules

- Only `.gitignore` / `.editorconfig` / personal IDE config changed -> no review. Report "no in-scope
  changes" and flag any personal IDE file that slipped into the diff.
- Only docs or images -> architecture (doc naming, broken references) **plus text**, which owns the
  wording.
- Only shared config / infrastructure-as-code -> architecture only.
- Anything else -> follow the table.

A skipped review reports `Unit test rule: N/A`. Nothing else may skip the tests seat: a diff small
enough to look exempt is exactly the diff that ships an untested branch. The same holds for QA - a
one-line change that alters what a user sees still has consequences and an acceptance criterion.

## Ownership split (avoid double-flagging)

Backend owns micro / hygiene, architecture owns macro / structure. Tests own anything about whether a
change is verified. QA owns what a user experiences, what the ticket asked for, and what breaks in
files the diff never touched. Text owns the words. The full table is in
`references/ownership-split.md`; read it before step 4 (dedupe). When one finding maps to two axes,
architecture wins, shown once at the higher severity.

## Output contract - every seat returns this shape

```
### [Severity: high | med | low] [Action: Required | Consider | Nit] [path/to/file.ext]:[line]
**Issue:** one-sentence problem.
**Failure:** concrete inputs or state -> the wrong output, crash, or loss. Required on high and med.
**Fix:** one-sentence corrective.
```

Severity:
- **high** - correctness bug, perf regression on a hot path, security or permission gap, data loss,
  public API break, compile error.
- **med** - naming, DRY, DTO shape, repo hygiene, dead code, divergence between two paths.
- **low** - formatting, comment style, blank lines. Comment findings are grouped per file, never one
  per line.

Severity says how bad. **Action says what the author must do**, and they are different axes. A `high`
the author may legitimately defer is `Consider`; a `low` that blocks (a lint gate, a typo in a
persisted enum name) is `Required`.

- **Required** - fix before merge, or defer explicitly with a reason in the PR.
- **Consider** - worth doing, author's call.
- **Nit** - optional; the author may ignore it silently.

**The Failure line is the filter.** A finding without a concrete failure scenario is not a finding.
"This could be a problem" and "consider whether this handles X" make a punch list unreadable. If you
cannot write the inputs and the wrong result, you have a question: put it under Questions, or read
one more file until it becomes a finding. Quantify when the claim is quantitative ("N+1 across ~200
rows adds a round trip per row"), and check the number first. `low` findings are exempt because
formatting has no failure mode, which is also why they never lead a report.

### Hard rules and verification (blocking)

Read `references/severity-floors.md` at step 3, before collecting results. It holds the rules the
orchestrator enforces on every review, whatever the diff size: external-system claims need a vendor
citation; unit tests are mandatory (a behaviour change with no test is `high` / Required and the
verdict is **Not ready**); authorization gaps and silent data loss are floored at `high`; and the
verification questions the tests seat answers (each unanswered one is a `high`). Every report carries:

```
Unit test rule: PASS | FAIL | N/A - <reason>
Verification: revert-test <name> | NONE; UI flow exercised | not run
```

## Compile gate - run it, do not reason about it (blocking, `high`)

A missing type, a renamed class or a signature drift in a shared library is found by the compiler in
seconds and missed by a careful reader, because the diff shows the call site, which looks reasonable.

- **Map every changed project to every build target that includes it** (solution, workspace, package,
  module) and build **each**. A shared library used by two apps is built twice, and the app nobody has
  open (a desktop host, a worker, a CLI) is the one that breaks.
- Run the builds **in parallel with the seats**. Report one line: `Build: api OK, worker FAIL (1
  error)`. **Any compile error is a `high`**, quoted verbatim with its `file:line`, and it leads the
  punch list.
- **If the project rules say the user runs builds**, do not run them. Read the changed code with a
  compiler's eye and report `Build: not run (project rules)`.

Use the build commands from the project rules. Without them, discover the build files near the
changed paths and say which commands you chose.

## Verify your own findings before reporting

Run this after merge and dedupe, before emitting. For **every `high`**, and every `med` whose Failure
line rests on a file nobody opened: try to *refute* it. Default to refuted when unsure. Open the file
the claim was inferred from. Check whether the missing guard exists one layer up, whether the caller
already filters the case, whether a global contract covers it.

- **CONFIRMED** - you read the path end to end and the failure holds.
- **PLAUSIBLE** - the shape is right but one step is unread. Name the step in the finding.

Drop anything refuted. Do not downgrade it to `low` to keep the work: a wrong `low` still costs a
read. If you refute more than half of one seat's `high` findings, say so - that is a signal about the
seat's prompt, not the diff.

**A claim that survived verification can still be false.** A "checked, clean" is the least-checked
claim of all, because nobody re-verifies a clearance. When a finding or a clearance reached you from
an earlier verifier, re-read the source yourself; do not re-read the last verifier.

## Comment quality - every seat judges the comments in its own files

There is no comment seat: a comment can only be judged next to the code it sits above. Every seat
judges each added or edited comment on necessity, language (Simplified Technical English) and
structure, with `references/comment-quality.md`. Comment findings are grouped per file, never one per
line. A deleted comment that carried a safety reason is `med` / `Required`.

## Effort levels

`quick`, `standard` (default), `deep`, `advanced`. When the user names a level, read
`references/effort-levels.md`. `quick` still runs the tests seat, and the text seat on any changed
string.

## Investigation method

Every seat prompt carries a nine-point investigation method (open every method the diff calls, grep
for sibling rules, check the second run and the second element, verify external claims against vendor
docs, re-open the source of every inherited claim). It lives in `references/seat-prompts.md`; paste it
in full into each seat prompt. A reviewer that reads only the diff reproduces the author's blind spots.

## Orchestration flow

0. **Confirm the seat rubrics exist before promising a review.** A clean punch list from seats that
   never ran reads as coverage:

   ```bash
   SKILL_DIR="${CLAUDE_SKILL_DIR}"   # if empty: the absolute path of the folder holding this SKILL.md
   for s in architecture backend frontend tests qa text dependency-licence; do
     test -s "$SKILL_DIR/references/seat-$s.md" || echo "MISSING SEAT: $s"
   done
   ```

   A missing applicable seat is a `high` on its own, named as `Reviewers unavailable: <names>`. Never
   proceed quietly with fewer.

1. **Read the project rules** (see above) and **detect the base.**
   - Local branch: find the default branch (the project rules, or
     `git symbolic-ref --short refs/remotes/origin/HEAD` minus its `origin/` prefix; if that is unset,
     run `git remote set-head origin --auto` first), then `git fetch origin --quiet` and
     `git diff --name-status $(git merge-base HEAD origin/<default>)...HEAD`. Use `origin/<default>`,
     not the local branch: a stale local base fills the diff with other people's merged work.
   - Pull request: take the base from the PR (see `references/commenting.md` for the GitHub, Azure
     DevOps and GitLab commands).

   Check that the commit list looks like *one* piece of work. If it does not, ask which ref is the
   real base. Cache the name-status list.

2. **Classify scope** with the table above. Apply skip rules first. In the same pass, map changed
   projects to build targets (compile gate), decide **advanced vs standard**, and check whether any
   dependency was added. If advanced: announce it in one line, read `references/advanced-mode.md`, and
   follow its phases in place of steps 3-8. Steps 0-2 and step 9 are shared.

3. **Spawn the seats in parallel - one assistant message, several `Agent` calls.** Start the builds in
   the same message. Read `references/severity-floors.md` and `references/seat-prompts.md` (the base
   seat prompt, the extra lines for the QA and text seats, and the full **Investigation method** to
   paste into each prompt; sub-agents see only what you pass them). Every seat reads its own rubric by
   absolute path, plus the project rules, `references/severity-floors.md`,
   `references/ownership-split.md` and `references/comment-quality.md`. Never run seats one after
   another: wall-clock time is the slowest seat, not the sum.

   The **dependency seat** gets the base prompt plus the list of added packages per manifest and the
   project's distribution model from the project rules (closed-source SaaS, installed app, open
   source library). Without it, assume closed-source commercial software shipped to customers and
   say so.

4. **Collect, dedupe, merge.**
   - Same `(file, line, issue)` from two seats -> keep one, attribute to the owner per the split.
   - Anything about a missing or weak test -> the tests seat.
   - Anything about the wording of a user-visible string -> the text seat; carry its rewrite verbatim.
     Never paraphrase a proposed string.
   - If tests returned `FAIL`, its finding leads the list with any compile error; verdict `Not ready`.
   - Group by severity (high -> med -> low), then by file.

5. **Adversarial pass on the QA and text findings.** These two seats reason about consequences and
   readers rather than lines, so they are the most exposed to a confident error. Spawn **one fresh
   agent with no prior context** with the adversarial prompt in `references/seat-prompts.md`. It
   refutes each numbered finding, looks for what the seats missed (the untouched analogue branch, the
   second run, the second element, the destructive path), and judges each text rewrite as well as
   the complaint.

   Merge honestly. REFUTED findings are **dropped**, with a one-line note in the report saying what
   disproved them - that tells the reader the report was checked. UNPROVEN drops to Hypothesis and
   never leads. New adversary findings join the list. When the adversary is right and you were wrong,
   say so plainly.

6. **Write the HTML report** from `assets/report-template.html`, as `references/report-output.md`
   describes (default location `.reviews/<branch>/review.html`). Skip this step in `code-only` mode.
   Open the report for the user when done (`start`, `open` or `xdg-open` by OS).

7. **Return the punch list.** Read `references/review-discipline.md` first. Order by leverage, not by
   file: correctness and data loss, then security, then structure, then missed simplifications, then
   the rest. A report that opens with formatting teaches the author to skim.

   Open with **Strengths** - two or three specific things done well, with `file:line`. Vague praise is
   worse than none. Then the summary line: counts per severity and action, files touched, seats run,
   project rules read, build result, verification line, how many findings the verify pass refuted.

   Close with a **merge verdict**: `Ready to merge` / `Ready with fixes` / `Not ready`, plus one or two
   sentences of reasoning. **A tests `FAIL` forces `Not ready`.** **A text `FAIL` forces at most
   `Ready with fixes`**, naming the failing strings as the fixes. End with a one-line **structural
   verdict**: does the diff leave the local architecture better, neutral or worse? A missed dramatic
   simplification, an unjustified file-size jump, special-case branches scattered across paths, or a
   hacky abstraction are presumptive blockers. "It works" is not approval when a smaller shape was
   clearly available.

   **Closure gate.** A `Not ready` verdict ends with a ledger, one row per `high` and `med`:
   `Id | Severity | Owner | State`, where State is `fixed` (commit), `posted` (PR thread), `asked`
   (link to the product owner question), or `deferred` (follow-up issue). A PR should not leave draft
   while a `med` or higher finding has no state. A report that stays on the local disk closes nothing.

8. **Append the blind-spot footer** from `references/report-output.md`, tailored to the diff: this is
   a static review, so name what it cannot see (run-only behaviour, missing requirements, edge
   firewall).

9. **Comment mode only - post the survivors.** Stop and re-read the punch list first: you are about to
   write on someone else's work. Read `references/commenting.md` and follow it. It carries the 90%
   confidence gate, the independent re-verification agent, the comment budget, the
   Commentator / Severity / Concern format, the voice rules, and the per-host posting commands.

   - **Send:** `high` and `med` findings that survived the verify and adversarial passes, each with its
     `file:line` and concrete Failure line.
   - **Do not send:** Hypothesis or UNPROVEN items, anything without a Failure line, formatting nits,
     the Strengths section, the merge verdict.

   The flow confirms with the user before anything is posted. Do not pre-approve on their behalf. In
   every other mode, stop at step 8. Never post to a PR unless the user asked for comment mode.

## Rationalizations and disagreements

`references/review-discipline.md` lists the rationalizations this review does not accept (they apply
to the reviewer's own reasoning as much as the author's) and the order that settles a disagreement.
Read it before writing the verdict, and whenever the author pushes back.

## Honesty rules

- **Do not soften.** Calling a production bug a "minor concern" gets it deferred. Severity is a
  technical judgement, not a social one.
- **Do not pad.** A short accurate report beats a long one. Volume is not thoroughness.
- **Say what you did not check.** "UI flow not run", "did not open the export branch", "PLAUSIBLE,
  one step unread".
- **Accept an override gracefully** when the author has context you lack. Record it and do not
  re-argue next round - but still re-check an "accepted" item against the source each round.
