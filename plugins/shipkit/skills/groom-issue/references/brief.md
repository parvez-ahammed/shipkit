# Brief mode - the forest, not the trees

Each groomed issue is a dense plan written for a builder. Read end to end, ten of them are exhausting.
Brief mode turns N issues into one briefing that someone can read in a few minutes and use to decide
order, spot risk and explain the milestone to others.

**Core principle:** an executive reads for decisions, risk and order, not implementation detail. Lead
with what each issue achieves and why it matters; demote the how. The brief is a lens on the issues as
written. It does not edit them, re-groom them or invent scope.

## When to use

- A milestone, phase, label or explicit list needs a stakeholder-level summary; or, before
  `deliver-issue` runs a milestone, to agree the build order. Not for one issue (just read it).
- If most issues are ungroomed (no scope, no acceptance criteria, stale paths), say so up front and
  recommend scoring them first. A brief of vague issues is itself vague.

## Inputs

Resolve the request to a concrete list of issues before writing. GitHub example:

```
gh issue list --milestone "<title>" --state all --limit 200 --json number,title,labels,state
gh issue view <n> --json number,title,body,labels,milestone,state
```

GitLab: `glab issue list --milestone "<title>"` / `glab issue view <n>`. Azure DevOps: a WIQL query via
`az boards query`. Jira: JQL `fixVersion = "<name>"` or `sprint = <id>`. An export or issue list
already on disk (JSON, CSV, markdown) is a valid source: read it directly and name the file. No
tracker access and no file: ask the user to paste the issues or export them. Include closed issues
only when the user wants status; say which.

Pull the brief from each issue body: scope, dependencies, effort, security block, decision log, open
questions. The issue body is the source of the plan; do not invent scope, effort or dates from the
repo or from memory. **One allowed repo check:** when an issue names a file path, symbol or "X
already exists", a quick search may confirm it. A claim the repo contradicts is reported as a
stale-premise risk ("#42 cites `src/pdf/PdfRenderer.js`, which no longer exists"), not silently
corrected. Keep it to that; scoring and rewriting are the other modes.

## Order by build sequence, not issue number

Issue numbers are creation order and tell the reader nothing. Read each issue's dependencies, sort
them topologically, and group them into waves: what can start now, what unblocks after that, and so on.
Issues with no coupling to the rest go into a separate **parallel track** so they are not falsely
sequenced. If two issues block each other, or a dependency points at an issue outside the set, name it.

## Output

Two parts, in this order. Write in plain, full sentences even if the session is otherwise terse; an
executive summary is the one place clarity beats compression. Default to chat; write to a file only if
the user asks (then `docs/briefs/<milestone>.md` or a path they name).

### Part 1 - Issue by issue

Group under build-order headings that fit the milestone (for example "Foundation", "Core flow",
"Migration", "Closeout and parallel track"). One block per issue:

```
**#<n> <title>** (<effort, or "effort not stated">)
<What it builds, one sentence.> <Why it matters, one sentence.>
<Optional: the key decision locked or the sharp finding from grooming.>
Depends on #x, #y.
```

Two to four sentences each. Lead with the outcome. Name the decision or the sharp finding (a wrong
premise corrected, a security gap, a vendor not yet chosen) when there is one; that is what a reader
remembers. For an epic, give the child count and how it is sliced.

### Part 2 - Whole milestone

- **Goal.** One or two sentences: what the milestone delivers, the end state.
- **The arc.** The waves in order, one line each, naming the issues in each and what gates the next.
  Call out the parallel track.
- **Decisions locked.** Owner-level calls already made and where they are written, so they are not
  re-argued.
- **Where the risk concentrates.** Specific: which issues carry security or data risk, which single
  issue is heaviest, where one issue's correctness gates many others, which depend on an outside vendor.
- **Critical path.** The actual chain of blocking issues from start to close.
- **Open questions.** Each with its issue and default, or "none".
- **Bottom line.** One paragraph: readiness, and whether the milestone is buildable as written.

## Quality bar

- Every claim traces to an issue body, or to a repo check of a premise the issue itself states. If you
  state a risk or a dependency, cite where it comes from.
- Name problems, do not bury them. Contradicting issues, ungroomed issues and undeclared dependencies are named;
  that is exactly the signal a stakeholder needs.
- No new scope, no invented effort, no invented dates. Unlabelled effort is reported as such.
- Honest risk. "All green, no risk" for a data migration or an auth change is not credible.

## Common mistakes

| Mistake | Fix |
|---|---|
| Ordering by issue number | Topological order from the dependency sections. |
| Summarizing a messy issue as if it were solid | Flag it as ungroomed; recommend score mode. |
| Explaining implementation detail | Outcome and stake first; one clause of how at most. |
| Filling missing effort or dates | Say "not stated". |
| Editing issues while briefing | Read-only. Changes belong to apply mode. |
| Terse bullet fragments | Full sentences. The reader is not in the code. |
