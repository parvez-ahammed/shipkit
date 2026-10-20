---
name: find-ux-gaps
description: >-
  Finds usability gaps and pre-release rough edges in an existing app (from source, plus the browser
  when it runs) and turns them into evidence-backed tickets, written to markdown and filed to GitHub,
  GitLab, Jira or Azure DevOps only after a yes. Use for "find UX gaps", "file UX tickets", "what
  should we polish before launch". Not for a screenshot-backed QA/UX report without tickets (use
  audit-app) or a review of one branch's diff (use review-branch).
argument-hint: "[--agents N] [--issues M] [--scope <area>] [--tracker <name>] [--dry-run]"
license: MIT
---

# find-ux-gaps

Fan out read-only UX auditors across an app, then turn what survives into tickets: a markdown file
first, and issues in the project's tracker once the user confirms.

**Core principle: partition before you parallelise.** Auditors given the same app
independently converge on the same two or three loudest problems. Ten unpartitioned
agents return ten copies of "add pagination", not thirty findings. The orchestrator's
real job is dividing the app into separate territories.

## Arguments

`/find-ux-gaps [--agents N] [--issues M] [--scope <area>] [--tracker <name>] [--out <file>] [--dry-run]`

| Flag | Default | Meaning |
|---|---|---|
| `--agents N` | 3 | Parallel auditors. One territory each. |
| `--issues M` | 3 | Issues per auditor. Total = N x M. |
| `--scope` | whole app | Restrict to one area, for example `checkout`. |
| `--tracker` | detected | `github`, `gitlab`, `jira`, `azure-devops` or `markdown` (file only). Detected from the git remote; ask when unclear. |
| `--out` | `ux-improvements.md` | Where the triaged issues are written. Always written, whatever the tracker. |
| `--dry-run` | off | Write the markdown file, file nothing, do not ask to file. |

Bare invocation means 3 agents, 3 issues each, 9 issues. Plain-language counts count:
"use 10 subagents to find 30 issues" is `--agents 10 --issues 3`.

## Workflow

### 1. Ground yourself (orchestrator, before dispatching)

- Find the binding design system: `DESIGN.md`, `STYLEGUIDE.md`, a Figma export, or the
  design section of `CLAUDE.md`. Auditors skip this unless told to, then file issues that
  contradict house style.
- Inventory the routes, feature folders, and shared component layer.
- Note which tracker the project uses (git remote host, `.github/`, `.gitlab-ci.yml`, links in the
  README). Do not create labels or touch the tracker yet; that waits for step 6.

### 2. Partition into N disjoint territories

Carve by **user journey**, not by file type. Each territory gets its own screens, its own
backing endpoints, and a one-line charter. Territories must not share a primary screen.

**Small app (one to three screens)?** Screens cannot be split, so partition by **axis**
instead: (a) task flow and feedback (loading, success, errors, double submit), (b) input and
validation, (c) accessibility and responsive layout, (d) copy, trust and empty states. Every
auditor may read every file but owns one axis. If even that gives fewer than two sensible
territories, skip the fan-out and audit the app yourself in one pass against the same contract;
the partition rule exists to stop duplicate findings, not to force subagents.

A reliable ordering for a CRUD-plus-pipeline product, take the first N:

1. First run, sign-in, empty states
2. The primary list or table surface
3. The dashboard and health
4. The main authoring or configuration flow
5. Connecting external accounts, OAuth, credentials
6. Debugging and observability, where users go when something broke
7. Rules, ordering, precedence
8. Settings, admin, roles
9. Accessibility and interaction states across everything
10. Trust, privacy disclosure, and interface copy

Territories 9 and 10 are cross-cutting on purpose: they read the same files as everyone
else but judge a different axis, so they do not collide.

**Assign every shared component to exactly one owner.** Disjoint screens are not enough.
The real collision vector is the shared layer: the table primitive, the empty state, the
toast helper. Whoever owns the table owns "add pagination"; everyone else may cite it as
evidence but may not make it the subject of a finding. Name the owner in every prompt.

**Verify the app is really down before telling agents it is.** One `curl` against the dev
server settles it. Agents told "the app cannot run" will not try, so a wrong assumption
here costs you the whole browser dimension.

### 3. Dispatch all N in one message

No Agent tool, or the dispatch hits a concurrency or agent cap? Do not wait in a queue or retry in
a loop. Run the remaining territories yourself, one after another, with the same prompt and
contract, and say in the report which ones ran inline.

Every auditor prompt carries, in this order:

1. What the product is, in two sentences.
2. Read the design system file first. It is binding. Drift from it is itself a defect.
3. This territory's charter and its explicit file list.
4. Whether the app runs. If it does not, say so: audit by reading code, and every claim
   becomes a code-reading inference.
5. Read-only. Modify nothing. File nothing. Return findings only.
6. Research requirement: name 3 to 6 real comparable products and require at least 2
   verified patterns with URLs. Without named comparables, agents cite nothing.
7. Exactly M issues. Highest value first.
8. The output contract below, verbatim.

### 4. The output contract

Give auditors the shape of the answer, not a list of things to avoid. State it as a
recipe they fill in:

```
### ISSUE 1
title: <imperative, <=70 chars>
labels: ux, <area>, <p1|p2|p3>
area: <territory>
problem: <3-5 sentences, grounded in code>
evidence:
- <path:line> <what the code does>
- <path:line> <...>
why_it_matters: <user impact + comparable pattern with URL>
proposal: <scoped, names the files to touch, respects the design system>
acceptance:
- [ ] <verifiable>
- [ ] <verifiable>
effort: S|M|L
```

Severity: p1 blocks or badly confuses on a main path. p2 is real friction. p3 is polish
that raises perceived quality.

### 5. Triage

When all agents report:

- **Dedup.** Same root cause from two territories becomes one issue crediting both.
- **Drop the unevidenced.** No `path:line`, no issue.
- **Demote feature requests.** "Polish what exists" is the brief. A proposal that invents
  a new screen or feature is either rescoped or dropped.
- **Verify a sample.** Open 3 or 4 cited lines yourself. Auditors that cannot run the app
  occasionally misread control flow.
- Every body ends with a line saying how it was audited (source only, or source plus a
  browser pass) and the commit SHA, so a reader knows what to verify before implementing.
- Write all surviving issues to `--out` (default `ux-improvements.md`), one `### ISSUE` block
  each in the contract format, plus a short list of what was merged and dropped and why.

### 6. Confirm, then file

Filing creates public or team-visible records under the user's name, so it never happens by default.

1. Show the user a table: number, title, labels, severity, effort, and the target (tracker and
   repo or project). Say which labels do not exist yet.
2. Ask: file all, file some (by number), or none. Only an explicit yes in this conversation counts.
   With `--dry-run`, `--tracker markdown`, or no answer, stop here: the markdown file is the result.
3. File only the confirmed issues. Write each body to a temp file first; bodies hold backticks
   and code blocks that break shell quoting.
   - **GitHub:** `gh issue create --title "<title>" --body-file <body.md> --label <l1> --label <l2>`.
     Create missing labels first, with `gh label create`, only if the user agreed to them.
   - **GitLab:** `glab issue create --title "<title>" --description "$(cat <body.md>)" --label "<l1>,<l2>"`.
   - **Jira:** the Jira REST API (`POST /rest/api/3/issue`) or the team's Jira CLI; map severity
     to priority and labels to labels.
   - **Azure DevOps:** `az boards work-item create --type Issue --title "<title>" --description "<html>"`
     (use the work item type the project's process has, for example Bug or Product Backlog Item;
     the description field takes HTML, so convert the body first).
   - **Anything else:** hand over the markdown file.

Report back: issues filed with numbers or links (or the markdown path), what was merged, what was
dropped and why.

## Quick reference

| Situation | Do this |
|---|---|
| App cannot run locally | Audit from source. Say so in every issue body. |
| App does run | Add a browser pass; screenshots beat prose. |
| No design system file | Say so; auditors judge internal consistency instead. |
| No tracker, or not a git repo | Run the audit, write the markdown file, offer to file later. |
| No web search available for comparables | Name the comparables from knowledge, mark patterns "unverified", drop the URL requirement. |
| Fewer than N sensible territories | Reduce N, or partition by axis (small app). Say why. Do not split one screen in two. |
| Subagents unavailable or capped | Run the territories inline in sequence. Same contract. |
| User wants a specific count | N x M must equal it. Adjust M, not the partition. |
