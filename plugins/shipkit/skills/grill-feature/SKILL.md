---
name: grill-feature
description: >-
  Pressure-tests whether shipped features keep their user-facing PROMISE by reading (and where
  possible running) the real code, with a BULLETPROOF / CRACKED / FAKE verdict and file:line evidence.
  Use for "grill this feature", "is X actually ready", "can users really do Y", "audit promise vs
  reality". Not for a branch diff (use review-branch) or pricing and margin (use price-product).
argument-hint: "[feature name | release or phase]"
license: MIT
---

# Grill room

Interrogate features at the level that actually matters to a paying user: not "does the button
exist" but "does the promise behind the button hold". The answer comes from reading the real code,
never from the UI or from memory. Hidden or UI-gated features still count: judge the code.

Two roles run in the room:

1. **Feature interrogator** (one per feature). Asks 3-6 fundamental promise-level questions, then
   answers each from the code with `file:line` evidence, adversarially hunting for the gap between
   the claim and the implementation. Ends with a verdict.
2. **CEO cost evaluator** (one, cross-cutting; only for products with metered or paid actions).
   Reads the cost charged per paid action, any COGS/usage ledger, the external/provider calls
   invoked, and plan prices/entitlements, then computes per-action and per-plan margin and says
   plainly whether the cost is too much. Skip this role for a product with no per-action cost.

## The interrogation protocol

For one feature:

1. State the **promise**: the one-sentence thing the feature claims to do for a user.
2. Read the real code that backs it: follow the full call chain (entry point / route -> handler /
   controller -> service / business logic -> data layer), plus the relevant UI feature folder.
   Do not stop at the route.
3. Ask 3-6 questions at the right **altitude**. Good questions probe the promise, not the syntax:
   - Does the action actually reach the external system (publish actually hits the platform; the
     file is actually uploaded), or does it stop at our DB?
   - Is money/credit exact under retry and double-click (idempotent), and is a failure refunded?
   - Is tenant/owner isolation real (can account A read/mutate account B's rows)? Any IDOR?
   - What happens to an existing user with an expired token / a reconnect-required integration?
   - Is the persisted state real, or a no-op / stub / mock / fabricated number?
   - For configurable / AI features: is the config/override (model, settings, feature flags)
     actually USED at run time, or stored and ignored?
   - For multi-step pipelines: does the CONTENT survive each hand-off between steps, or only the
     format (the file exists, but is it the right data)?
4. **Answer each question from the code**, citing `file:line`. No vibes.
5. **Reproduce what you can.** If the app or its tests can run locally, confirm every CRACKED or
   FAKE gap with a real request, a script or a failing test, and quote the result (`GET
   /orders/7 as customer 2 -> 200 with customer 1's order`). A gap you could not run is labelled
   `code-reading inference`. A ship-blocker should be reproduced whenever the app can run. Run only against a local or test environment, never production.
6. Assign a verdict and list concrete gaps.

### Verdicts

- **BULLETPROOF** - the promise fully holds in the code, with evidence.
- **CRACKED** - it works but has a real gap or risk (un-refunded failure, weak isolation, an
  override that is stored but not applied, a seam that only holds at the format level).
- **FAKE** - the promise is not actually delivered: a stub, a mock, a no-op, or fabricated data.

Set `shipBlocker: true` when a gap would hurt a paying customer or lose money/data.

## Two ways to run

### One feature, inline (fast)

Run the protocol above yourself in the main context for the one feature, and report its verdict.
One feature does not need a subagent; dispatch a read-only interrogator (the `Explore` agent type
fits) only when you want to keep a large codebase read out of your context.

### A whole release/phase, as a sweep (the room)

**Prerequisite:** the sweep runs on Claude Code's Workflow tool. Use it only when that tool is available
in the session and the user has opted in to running a workflow (say what it will fan out and ask first if
they have not). Otherwise use the fallback below.

Run the bundled workflow, which fans out one interrogator per feature plus the CEO cost pass and
synthesizes one report. The script ships beside this skill at
`${CLAUDE_SKILL_DIR}/room-workflow.js`. Pass your feature list as `args` instead of editing it:

```
Workflow({
  scriptPath: "${CLAUDE_SKILL_DIR}/room-workflow.js",
  args: {
    features: [{ id, area, name, promise, hints }, ...],
    costPass: false,          // default false; true only for products with metered or paid actions
    date: "YYYY-MM-DD"        // optional; stamped into the report heading
  }
})
```

Without `args.features` the script runs its built-in worked EXAMPLE list (generic auth, payments
and publish features), which is only useful as a demo. The workflow runs in the background and
returns `{ counts, interrogations, cost, report }`. **Write the `report` to a dated file** (e.g.
`docs/reviews/grill-<scope>-<date>.md`) so stakeholders have the artifact. Pass the date in
through `args.date`: a workflow script cannot read the clock.

**Fallback (no Workflow tool, or no opt-in).** Dispatch one interrogator per feature with the Agent tool, in
parallel batches of at most four, plus the cost evaluator if wanted. No Agent tool either: run
the protocol yourself, feature by feature. Then write the synthesis report yourself in this
order:

1. One-paragraph executive summary: counts of BULLETPROOF / CRACKED / FAKE, number of
   ship-blockers, the single biggest risk.
2. Verdict table: Feature | Area | Verdict | Ship-blocker | one-line headline gap.
3. Ship-blockers: every `shipBlocker: true` item with gaps and evidence, worst first.
4. Cracks: CRACKED and FAKE items grouped by area, with gaps and evidence.
5. CEO cost read (only when the cost pass ran): per-action economics, per-plan margin, verdict,
   concerns.
6. Top 10 fixes, ranked by customer or money impact times how cheap the fix is.

Keep `file:line` evidence inline and mark each gap reproduced or `code-reading inference`.

The workflow is the deterministic engine; this skill is the protocol and the verdict bar. Keep the
interrogators read-only and code-grounded, keep the CEO pass (when used) tied to real `file:line`
cost evidence, and never soften a verdict to be polite: a CRACKED called BULLETPROOF is the one
outcome that makes the room worthless.
