# Seat prompts

Contents:

- [Base seat prompt (step 3)](#base-seat-prompt-step-3)
- [Adversarial prompt (step 5)](#adversarial-prompt-step-5)
- [Worked example](#worked-example)
- [Investigation method (paste into every seat prompt)](#investigation-method-paste-into-every-seat-prompt)

Templates for the `Agent` calls in steps 3 and 5 of `../SKILL.md`. Sub-agents see only what you pass
them, so fill every placeholder and paste the full **Investigation method** from the end of this file.

## Base seat prompt (step 3)

```
Read the reviewer rubric at <SKILL_DIR>/references/<seat>.md and review the diff
<base>...HEAD against it. That file IS your rubric - read it before judging anything.
Project rules to read first, they override the rubric: <paths, or "none found">.
Shared rules every seat follows - read these too: <SKILL_DIR>/references/severity-floors.md,
<SKILL_DIR>/references/ownership-split.md, <SKILL_DIR>/references/comment-quality.md.
(Tests seat: the unit-test hard rule is blocking. Return the
`Unit test rule: PASS | FAIL | N/A - <reason>` line first.)
Diff name-status (already classified, do not redo): <paste>
Investigation method (follow before judging changed lines): <paste all 9 points>

Use WebSearch / WebFetch (or any docs tool you have). Any claim about an external system
or library - syntax, operators, status codes, paging, limits, version floors - must be
checked against the vendor's own documentation and the URL cited. No web access: the
claim is a Question. Do not infer a third party's contract from
this repo's internal consistency. Uncited external claims go under Questions.
Output: STRICTLY the orchestrator's contract - Severity / Action / Issue / Failure / Fix.
A finding without a concrete Failure line is a Question.
Rank by severity; never drop a high or med to stay brief. Skip low nits if long.

Read-only: do not change the working tree, the index, HEAD or branch state. Use git show,
git diff, git log. For another revision, `git worktree add` a temp dir. The orchestrator
runs the builds; you do not.

Do not dispatch subagents. You are one seat and you review your whole scope yourself. If
the scope is too large for one pass, do several passes and say so.
```

**Extra lines for the QA seat:**

```
Retrieve the ticket and its comments with the project's tracker tool (see project rules:
gh issue view, az boards work-item show, a Jira or Linear CLI or MCP server). The acceptance
criteria are what you grade coverage against. If the project keeps working notes (plans,
decisions) in a folder, read them; if that folder is gitignored, ripgrep skips it, so use
`rg --no-ignore` or `grep -rn`. Diff each recorded decision against what the commit does - a
shipped change that contradicts a decision is a `high` and no code seat can see it.
Number findings Q-1, Q-2, ... The orchestrator runs the adversarial pass; you do not.
Return, in order: impact map, requirement coverage, findings, test cases, what you could
not reach.
```

**Extra lines for the text seat:**

```
Your scope is every string a human reads. Read each changed string in its rendered context
- open the component, the resource file, the email template - because a label judged
without its control is judged blind. Grep the repo for the existing term before proposing
a new one; one concept, one word. Every finding carries the literal before -> after
rewrite; a text finding without a rewrite is a Question. Return the
`Text: PASS | FAIL - <reason>` line first, then findings, then the rewrite table as
`file:line | before | after`.
```

## Adversarial prompt (step 5)

Give one fresh agent with no prior context the name-status diff, the acceptance criteria, the
numbered `Q-n` findings, every `high` text finding with its rewrite, and:

```
Two jobs, in order.

1. REFUTE. For each numbered finding, try to prove it wrong. Open the files. A finding
   survives only if you trace the failing path end to end yourself. Return for each:
   CONFIRMED (cite file:line) / REFUTED (cite what disproves it) / UNPROVEN (name the
   step you could not verify). Default to REFUTED when the evidence is ambiguous.
2. FIND WHAT WAS MISSED. Assume the first reviewer anchored on the changed files and the
   happy path. Look at: the untouched analogue branch (other integration, other party,
   other role), the second run of every create/persist flow, the second element of every
   collection, and the destructive path (delete / overwrite / cancel / rollback).

Return findings in the Severity / Action / Issue / Failure / Fix shape. Do not restate
confirmed findings as new ones.

For text findings, judge the REWRITE as well as the complaint. A rewrite that is longer
than its control, invents a term the app does not use, is wrong about what the code does,
or reads as marketing is REFUTED even when the complaint was fair - say which half failed
and propose the shorter true string.
```

## Worked example

```
M  src/Api/Permissions/ReportAccessPolicy.cs
M  src/Domain/Accounts/ApiKey.cs
M  web/src/features/files/FilesTab.tsx
A  web/src/features/files/UploadFailureAlert.tsx
```

Routing: backend (server code), frontend (`web/`), architecture, tests and QA always; text (the new
alert has user-visible strings). No manifest changed, so no dependency seat. Six `Agent` calls in one
message, builds started in the same message.

```
Summary: 7 findings - 1 high, 4 med, 2 low. 4 files. Seats: backend, frontend, architecture,
tests, QA, text. Project rules: .claude/review-rules.md. Build: api OK, web not run (project rules).
Unit test rule: FAIL - ReportAccessPolicy change has no test.

### [Severity: high] [Action: Required] src/Api/Permissions/ReportAccessPolicy.cs:42
**Issue:** The check verifies the organisation only; the user id is never checked.
**Failure:** User B in the same organisation calls GET /reports/{id} for user A's private
report -> 200 with A's data.
**Fix:** Check the report owner's user id before the organisation match.
```

## Investigation method (paste into every seat prompt)

The diff is where a review *starts*. Most bugs that survive review are not wrong changed lines; they
are correct-looking lines whose context the diff does not show. Before judging the changed lines:

1. **Open every method the diff calls, copies or adapts.** State its precondition; confirm it holds in
   the new caller. Catches a bulk method called per item, logic for one integration reused for
   another, a storage or lifecycle mismatch.
2. **Grep for sibling implementations of any rule the diff touches** (validation, format, status,
   permission). They must agree. A file-name rule enforced one way on upload and another way later is
   a user-facing bug.
3. **Load the global contract before judging a local handler.** Error notifications, query caching,
   auth and logging are often central; a local addition on top duplicates them.
4. **Check every integration / storage mode / role branch the change implies**, not only the one in
   the diff. A change on one branch usually has an analogue on the others.
5. **For any create / persist / import flow, reason about the second run** (re-upload, re-save). Does
   it self-heal, or handle only the first time?
6. **Instantiate the second element, not only the second run.** For every collection the diff
   touches, name each place it takes the *first*, the *primary* or the *only* member: `.First()`,
   `[0]`, a field assigned per iteration instead of accumulated, a list rebuilt instead of appended, a
   file written per item to one key, an id taken from the primary. For each, state the two-element
   scenario that breaks it and whether a test covers it. "It loops" is not an answer; read what the
   loop body writes *to*. This is the most expensive miss class in practice: one feature was reopened
   three times running because each fix handled one more object type (the first type, then a
   second, then a third) and nobody wrote the list down.
7. **Verify every external-system claim against vendor documentation** before writing it as a
   finding, and cite the URL. "Every sibling uses this form, so this one is wrong" is a Question.
8. **Apply the simplification lens.** Could a reframing delete a whole branch, helper layer or kind
   of complexity while keeping behaviour? Is this a thin wrapper that adds indirection without an
   invariant? Did feature-specific logic leak into a shared path? A working design that a smaller one
   replaces is still a finding (architecture owns the call).
9. **Re-open the source for every inherited claim** - a dev note, an earlier report, an "accepted" or
   "do not re-raise" label, a previous verifier's "clean". Which file and line did you open this round?
   If none, it is a Hypothesis.

If confirming a finding needs a file the diff did not include, read it. A reviewer that reads only
the diff reproduces the author's blind spots.
