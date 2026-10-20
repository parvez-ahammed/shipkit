---
name: deliver-issue
description: >-
  Takes a tracker issue (an issue number or URL) or a whole milestone to a review-ready pull request:
  groom, approved plan, build, review. Push, PR and merge each wait for a yes. Use for "deliver #42",
  "implement #42", "pick an issue and ship it", "work through milestone 3". Not for grooming alone
  (use groom-issue) or a story described in chat (use build-story).
argument-hint: "[issue number | URL | milestone name] [unattended]"
license: MIT
disable-model-invocation: true
compatibility: "Needs git. Tracker access through gh (GitHub), glab (GitLab), az boards / az repos (Azure DevOps) or a Jira CLI/API; without one, works from pasted issue text and stops before PR steps. Uses the project's own build and test toolchain."
---

# deliver-issue - one issue at a time, from backlog to review-ready PR

The spine workflow. It takes an issue and moves it through five phases, calling a sibling skill at
each one. It orchestrates; it does not repeat what those skills do. When a phase says "run
`groom-issue`", invoke that skill and follow it.

**Core principle:** rework is the most expensive outcome, so all judgment goes up front. By the time
code is written, every question that would change what gets built is answered. After the plan is
approved, the build runs without stopping unless a gate fails or a new outcome-changing unknown
appears. Nothing leaves the machine (push, PR, issue comment, label, merge) without a yes.

## When to use / not use

- Use when: an issue or a milestone is to be delivered, not just discussed.
- Not for: grooming only (`groom-issue`); a summary (`groom-issue` brief mode); a feature with no issue
  (`build-story`); a bug report with no issue (`fix-bug`).

## Before you start

1. **Read the project's `CLAUDE.md`, `CONTRIBUTING`, and rules docs.** Project rules override this file.
2. **Detect the setup:** tracker from `git remote -v`; stack, test runner and gates from CI config,
   `package.json`, `*.csproj`, `pyproject.toml`, `go.mod`, `Makefile`; the branch flow from the docs
   or recent history (`git log --merges --oneline -20`, `git branch -r`). Note the integration branch
   PRs target, and whether the repo merges with merge commits, squash or rebase. If unclear, ask once.
3. **Never build on the default or release branch.** Work on a feature branch or the agreed
   integration branch.

## The spine rules

1. **Never guess across an outcome-changing unknown.** If a choice would change what gets built and
   the issue, code and docs cannot settle it, stop and ask. Reversible choices (a helper name, an
   internal shape) proceed and get a note in the PR. Test: would the user be unhappy to find you guessed?
2. **Never write a third-party API call from memory.** Check the current call shape in the library's
   or vendor's docs (a docs lookup tool, or the official site) for the version the repo pins. If the
   project keeps a list of deprecated-to-current API replacements, check it, and add a line when you
   replace one.
3. **Groom until ready, then stop.** Over-grooming a ready issue wastes time and invites scope creep.
4. **One issue at a time.** Several issues or a milestone run serially: finish one (landed or
   explicitly parked) before starting the next. Parallel half-built issues cause conflicts.
5. **Outward actions need a yes.** Show what will be sent (branch, commits, PR title and body,
   comment text, label, merge method) and wait. A blanket yes is valid only when the user gives it
   explicitly, scoped to named actions and branches ("push and open PRs to `develop`, do not merge");
   record it in the final report.

## Phases

### 1. Pick and groom

- **Pick.** If the user names the issue, use it. If they say "pick one", choose the lowest-numbered
  open issue on the active milestone with no unmet blocked-by and no `needs-decision` label; state the
  pick and why in one line.
- **Triage.** Bug -> the build phase uses `fix-bug`. Feature, chore, refactor -> `build-story`. Read
  the blocked-by chain; do not deliver an issue whose dependency is unbuilt.
- **Pressure-test** with the review lenses that apply (`${CLAUDE_SKILL_DIR}/references/review-lenses.md`):
  product, engineering, UX, developer experience, security, test. Skip any a prior groom already folded in.
- **Run `groom-issue`** on the result. Proposed body edits go to the user for a yes like any other
  write. The issue is groom-complete when `groom-issue` rates it READY and no outcome-changing unknown
  remains.
- **Park, don't guess.** A surviving outcome-changing unknown: propose a `needs-decision` label and a
  question comment (with a yes), report NEEDS_CONTEXT, and stop (or, in milestone mode, move on).

### 2. Plan (the approval gate)

Turn the groomed issue into a short, ordered plan: approaches considered (two or three, with the one
you recommend and why), files to create vs edit (reuse first), the build sequence with a failing test
per step, and the gate commands that prove done. Present it. **The user approves the plan, not the
diff.** After approval, phases 3-4 run hands-free until a gate fails or a new unknown appears. In
unattended mode the plan is written to the run notes instead of blocking.

### 3. Build

Create the branch (`feat/<issue>-<slug>` off the integration branch, or the milestone branch). Run
`build-story` with the approved plan as its input; the plan's steps are the task list, so its task-pick
gate is already answered by the plan approval. For a bug, run `fix-bug`. Follow the project's rules
throughout. If the project has a feature-flag layer, new user-facing surfaces land behind it, off by
default, and both states are checked (flag off: invisible; flag on: works).

Run the project's gates exactly as CI runs them (typecheck, lint, tests, build). A failing gate is a
stop, not a warning. Commit locally with the project's message convention, referencing the issue.

### 4. Review

Run `review-branch` on the branch against its base (`advanced` for auth, payments, data migration,
background jobs or destructive paths). Fix every finding at or above the project's bar (default:
medium and up) and re-run the gates. Optional: `test-branch` for running-app evidence when there is a
UI or API surface to exercise; offer it, and run it when the issue touches a user flow. For an
epic-sized feature, `grill-feature` checks the promise, not just the tests.

### 5. Ship (each step needs a yes)

1. Merge or rebase the latest base into the branch per the repo's convention; re-run the gates.
2. **Push** - show branch and commits, wait for yes.
3. **Open the PR** - show title, body (summary, acceptance-criteria trace, test evidence, review
   result, release notes) and target branch; wait for yes. Open as draft if any finding is still open.
4. **Comment on the issue** with the PR link - show text, wait for yes.
5. **Merge** only if the user asks or pre-authorized it, with the repo's merge method. Merging into an
   integration branch often does not auto-close the issue; close it (with a yes) when the criteria are met.

GitLab: `glab mr create`. Azure DevOps: `az repos pr create`. No tracker CLI: print the PR text and stop.

## Milestone mode

For "deliver the milestone": order with `groom-issue` brief mode's build waves (or the dependency sort
its `references/brief.md` describes), run phases 1-4 per issue serially, and land them on one integration branch or one branch
per issue, as the user chooses. Unattended runs, skip rules, batch PR and the handoff report are in
`${CLAUDE_SKILL_DIR}/references/milestone-mode.md`. Read it before starting a milestone.

## Output

End every issue with one status line and the handoff:

- **DONE** - gates green, review clean, PR opened (or merged if authorized), criteria met.
- **DONE_WITH_CONCERNS** - landed with a named caveat (flaky test, follow-up issue proposed).
- **BLOCKED** - could not finish; name the blocker and what was reverted or left.
- **NEEDS_CONTEXT** - stopped on an outcome-changing question; quote it with your default.

Then: branch, commits, PR link (or "not opened, awaiting yes"), gate results quoted from the actual
run, review summary, and anything not done.
