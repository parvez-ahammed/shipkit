# Milestone mode

Read before delivering more than one issue: a milestone, a label, or a list.

## Set up (confirm with the user once, at the start)

Ask, recommendation first, and record the answers in the run notes:

1. **Branch layout.** One integration branch for the batch (for example `milestone/<slug>`, created
   off the base branch if missing), with each issue as its own commit(s); or one branch and PR per
   issue. Default: per-issue branches, unless the project's docs say otherwise.
2. **Order.** Run `groom-issue` in brief mode (or its dependency sort) and show the waves. Default build order
   when dependencies do not decide it: data model -> data access and services -> API -> UI wiring ->
   background jobs -> dependent features -> polish -> clean-up last. An epic is delivered through its
   children and closed when all of them land.
3. **Attended or unattended.** Attended: plan approval per issue (phase 2). Unattended: plans are
   recorded, not approved one by one; the user approves the batch order up front.
4. **Pre-authorized outward actions.** Ask explicitly which, if any, may happen without a per-action
   yes: push the batch branch after each issue, comment on issues, open the batch PR, merge. Default:
   none; everything outward waits for a yes at the end. Never assume merge is authorized.

## Per issue

Run phases 1-4 of the main skill. Then:

- Commit with the project's message convention, referencing the issue.
- Push only if pre-authorized; otherwise keep commits local and queue the push for the end.
- **Parking rule (unattended):** an issue with a surviving outcome-changing unknown is skipped, not
  guessed. Record the question with its default. Queue the `needs-decision` label and question comment
  as proposed actions for the end (or post them if pre-authorized). Continue with the next unblocked
  issue; issues that depend on a skipped one are also skipped.
- **Gate failure you cannot fix within the issue's scope:** revert that issue's commits (or turn its
  feature flag off), record BLOCKED with the failing output, and move on. The branch must stay green
  after every issue, so the batch is mergeable at any point.
- If the project has a feature-flag layer, new user-facing surfaces land off by default.

## End of batch

1. Run `review-branch` on the whole batch diff (`advanced` if any issue touched auth, payments, data
   migration, jobs or destructive paths). Fix and re-gate.
2. Offer `test-branch` across the batch; one run per batch, not per issue.
3. Present the queued outward actions as one list (push, PR, issue comments, labels, closes) and wait
   for a yes. Accept partial approval.
4. Write the handoff report. In chat by default; as a file only if the user wants one (ask for the
   path, or use the project's notes folder):

```
Milestone: <name>   Branch(es): <...>   Base: <...>
| Issue | Title | Status | Commit(s) | Note |
|---|---|---|---|---|
| #12 | ... | DONE | abc123 | |
| #14 | ... | SKIPPED | - | needs decision: <question> (default: <...>) |
| #15 | ... | BLOCKED | reverted | <gate> failed: <one line> |
Outward actions taken: <list, with who approved>
Outward actions pending: <list>
Follow-ups: <proposed issues>
```
