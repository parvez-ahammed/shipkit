---
name: groom-issue
description: >-
  Scores a tracker issue or milestone for build readiness (gaps, undeclared blockers, stale paths),
  rewrites it into one self-contained plan after a yes, or writes a read-only brief in build order.
  Use for "groom #42", "is this issue ready", "re-groom the milestone", "brief me on milestone 3".
  Not for building it (suggest the /shipkit:deliver-issue command).
argument-hint: "[issue number | URL | milestone name] [apply | dry-run | brief]"
license: MIT
compatibility: "Reads and writes issues through the tracker's CLI or API: gh (GitHub), glab (GitLab), az boards (Azure DevOps) or a Jira CLI/API. Without one, works from pasted issue text and writes markdown."
---

# groom-issue - make an issue buildable from its body alone

An issue is a plan that someone (often an agent) will pick up cold. It is **ready** when that person
can build it end to end from the body alone. Anything they would have to ask, guess or discover
mid-build is a defect, and an **undeclared blocker** is the most expensive one.

**Core principle:** score first, write second, and write only after the user says yes. An open
question is better than an invented answer: an invented answer looks final and misleads the builder.

## When to use / not use

- Use when: grooming one issue or a milestone; checking an issue before work starts; re-scoring after
  an edit; re-grooming an old issue buried under layered reviews.
- Also use for: a stakeholder briefing of a milestone, phase, label or issue list (brief mode).
- Not for: building the issue (`/shipkit:deliver-issue`, or `build-story` / `fix-bug` directly).

## Before you start

1. **Read the project's `CLAUDE.md`, `CONTRIBUTING`, and any rules or architecture doc.** Project rules
   override this file.
2. **Find the tracker.** `git remote -v` tells you the host. Map the commands:

   | Tracker | Read | Write body (only after a yes) |
   |---|---|---|
   | GitHub | `gh issue view <n> --json number,title,body,labels,milestone,state` | `gh issue edit <n> --body-file <tmp>` |
   | GitLab | `glab issue view <n>` | `glab issue update <n> --description "$(cat <tmp>)"` |
   | Azure DevOps | `az boards work-item show --id <n>` | `az boards work-item update --id <n> --description "<html>"` |
   | Jira | the Jira CLI or REST `GET /rest/api/3/issue/<key>` | REST `PUT` on the same resource |
   | none / offline | pasted text | write `groomed/issue-<n>.md` locally |

3. **Find the gold standard.** Look for a project template, in this order: a path the user names;
   `.github/ISSUE_TEMPLATE/*` (feature or implementation template), `.gitlab/issue_templates/*`,
   `docs/**/issue*template*`, `docs/**/*definition-of-ready*`; a reference issue that `CLAUDE.md` or
   `CONTRIBUTING` names as the model. If one exists, its section list and required fields are the
   target shape, and the rubric is mapped onto its sections. If none exists, use the built-in shape in
   `${CLAUDE_SKILL_DIR}/references/living-document.md`. Say which one you used in the output.
4. **Find the gate commands.** Read CI config (`.github/workflows/*`, `.gitlab-ci.yml`,
   `azure-pipelines.yml`), `package.json` scripts, `Makefile`, `pyproject.toml`, `*.csproj`, `go.mod`.
   The Verification block in a groomed issue quotes these literally, never paraphrased.

## Modes

| Mode | Trigger | Writes |
|---|---|---|
| **score** (default) | "groom #42", "is it ready" | nothing; prints the record |
| **apply** | "groom and fix #42", "apply" | shows the new body (or a diff), waits for an explicit yes, then writes |
| **dry-run** | "groom to files", "dry-run" | local markdown only, `groomed/issue-<n>.md` (ask before creating the folder) |
| **brief** | "brief me on", "exec summary", "what is in this phase", "explain the plan" | nothing; a briefing in build order. Follow `${CLAUDE_SKILL_DIR}/references/brief.md` instead of the Process below |

No mode word means **score**, unless the ask is for a summary or briefing, which means **brief**. "Groom #42" alone never writes. If the issues come from a file on
disk (an export, a pasted list) instead of a tracker, score works the same and apply falls back to
dry-run, since there is nothing to write back to.

Labels (`needs-decision`, `ready`), comments and body edits are all outward actions: show exactly
what will be sent and wait for a yes. A yes for one issue is not a yes for the next one, unless the
user says "apply to all" for a named set.

## Process

1. **Read** the issue in full, including comments when reviews were pasted there.
2. **Classify:** feature, epic, bug, spike/test-debt, or meta/tracking. Meta issues get `N/A - meta`
   and are not edited. Rules per type are in `${CLAUDE_SKILL_DIR}/references/rubric.md`.
3. **Check freshness.** Every file path, symbol, version and "X was removed" claim is checked against
   the live repo with search and read. A path that no longer exists is a cited defect.
4. **Reconcile** layered or contradicting reviews before scoring (precedence rules in
   `${CLAUDE_SKILL_DIR}/references/living-document.md`). You score the reconciled single version,
   not the pile.
5. **Score** each applicable rubric dimension 0-2 with a one-line reason
   (`${CLAUDE_SKILL_DIR}/references/rubric.md`). Rate the security surface HIGH or LOW.
6. **Hunt undeclared blockers:** blocked-by issues that are missing, closed when the issue says open
   (or the reverse), sequencing that contradicts the milestone, a required account, key, migration or
   upstream change the issue never mentions.
7. **External paid dependency?** If the issue relies on a third-party paid API or sets a price the
   user pays, run the web check in `${CLAUDE_SKILL_DIR}/references/external-dependency-check.md`.
8. **Verdict** READY / NEEDS WORK / NOT READY with the score.
9. **Apply mode only:** draft the rewritten body in the target shape, keep everything already correct,
   move superseded lines to the Decision Log, turn every gap you cannot fill from the repo, docs or
   sibling issues into an `OPEN QUESTION` with a `Default if unanswered:` line. Re-score the draft.
   Show it. Write only after a yes, through a temp file, never a huge inline argument. Then re-read
   the issue from the tracker to confirm the write landed.

## Output

Per issue:

```
#<n> <title>
Type: feature | epic | bug | spike | meta
Shape: project template <path> | built-in living document
Score: <total>/<applicable max>  Verdict: READY | NEEDS WORK | NOT READY
Security surface: HIGH | LOW  (<one-line reason>)
Weak dims: <dim# + one-line gap, or "none">
Undeclared blockers: <list, or "none">
Freshness: verified <YYYY-MM-DD> | stale claims: <list, or "none">
Reconciled: <conflicts resolved, or "none">
External dependency: NONE | <provider> - <ready | not ready: why>
Action: scored only | proposed body shown, awaiting yes | written (sections: ...) | dry-run file <path> | N/A meta
```

For a milestone, end with a table: issue, type, score, verdict, top gap, action. Then a suggested
build order if dependencies make one obvious (or offer brief mode).

## Common mistakes

| Mistake | Fix |
|---|---|
| Treating a declared blocker as "not ready" | Declared blockers are fine. Undeclared ones are the defect. |
| "Already built" taken as done | Existing code is a baseline; the issue still needs review and test criteria for it. |
| Inventing scope to reach READY | The score reflects the issue. Gaps become questions, not features. |
