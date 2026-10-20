# Readiness rubric

Read when scoring an issue (Process step 5) or deciding how a type of issue is judged.

Score each applicable dimension 0-2: **0** missing or wrong, **1** present but thin, **2** solid.
Dimensions 1-9 always apply (max 18). Dimensions 10 and 11 are conditional: they count only when
their surface is present, and then raise the applicable max by 2 each.

If the project has a gold-standard template, map each of its sections onto these dimensions. A
template section with no matching dimension is scored as an extra required field (0 = missing,
2 = filled) and raises the applicable max by 2; a dimension with no template section is still
scored. One template section that covers two dimensions (for example "Testing" holding both
acceptance criteria and the test plan) is scored once per dimension it covers. Print the mapping
in one line (`Template "Testing" -> dims 3, 4`) so the score can be checked.

| # | Dimension | What a 2 looks like |
|---|---|---|
| 1 | **Context / problem** | Why the work exists; the current state of the code named with real, checked file paths; a link to the design or architecture doc where one applies. |
| 2 | **Scope** | Concrete deliverables: models, endpoints, screens, files, behaviours. No vague verbs ("improve", "handle", "support"). |
| 3 | **Acceptance criteria** | Numbered, binary pass/fail, each bound 1:1 to the named test that proves it (`AC3 -> orders.service.test > "refuses negative stock"`). Given-When-Then or "WHEN x, the system SHALL y" phrasing preferred. Prose with no named test caps this at 1. |
| 4 | **Test plan + Verification** | A runnable checklist (happy path plus the failure modes in 5), and a `## Verification` block with the literal gate commands CI runs plus the new test paths. Code work with no Verification block caps this at 1. |
| 5 | **Failure modes / edge cases** | Named failure modes, each with "handled how". Empty, null, max, concurrent, duplicate, partial failure, retry, permission denied. |
| 6 | **Technical approach** | New vs edited files named; reuse-first (points at the existing code to extend, not a parallel rebuild). |
| 7 | **Dependencies** | Blocked-by and blocks listed by issue reference; order consistent with the milestone. |
| 8 | **Out of scope** | Explicit, so the builder does not gold-plate. |
| 9 | **Effort + decisions** | Size (S/M/L/XL). Open decisions have a recommendation or a named owner, and every `OPEN QUESTION` carries `Default if unanswered: <decision>`. A blocking question with no default is a 0. |
| 10 | **Security** (conditional) | Counts when the surface is HIGH. Surface is HIGH when the issue touches auth or sessions, money or credits, personal data, secrets or API keys, webhooks, outbound fetches to user-supplied URLs, job or queue payloads, file upload, or multi-tenant data. A 2 has a security block: threats, required mitigations, and security acceptance criteria with tests. LOW-surface issues state `Surface: LOW` in one line and are not scored here. |
| 11 | **External paid dependency** (conditional) | Counts when the issue depends on a third-party paid API or service, or sets a price the user pays. A 2: the provider is actually chosen (not a wish list); its current price is cited from the vendor's live page with URL and access date; availability in the regions the project serves and any data-residency constraint is confirmed; the unit cost is mapped to what the user is charged (when the feature is priced); comparable products at that price are named; prerequisites (account, key, billing, quota) are listed with ready / not ready. Pure-internal issues state `External dependency: NONE`. See `external-dependency-check.md`. |

## Readiness gate

Let **M** be the applicable max: 18, plus 2 for each conditional dimension that applies and each
extra template field. For epics and spikes, M is 2 times the number of dimensions that apply.

Apply the rules in this order and stop at the first match:

1. **NOT READY** - dim 2 (scope) or dim 3 (acceptance criteria) is 0, or total < M - 8.
2. **NEEDS WORK** - any dimension is 0, or total < M - 2, or an undeclared blocker exists.
3. **READY** - everything else (total >= M - 2, no 0, all blockers and open questions declared).

A **declared** blocker ("Blocked by #12, cannot start until it merges") does not lower readiness; the
issue is ready to queue. An **undeclared** blocker, one the builder would hit mid-build, is the main
thing this skill exists to catch. List it even when the score is high.

## Two extra checks that cost points when missed

- **Reuse claims.** When the issue says a feature is "already built", "exists" or reuses earlier
  code, that code is a behavioural floor, not proof of correctness. The issue must still carry review
  and test acceptance criteria for the reused part. "The page already exists" with no criteria
  inflates dims 1 and 6; score them down.
- **Project rules.** If the project has a rules file (`CLAUDE.md`, `CONTRIBUTING`, an architecture or
  conventions doc), the issue should name it as required reading. A proposed approach that breaks a
  stated project rule (for example a storage engine, layer or library the project has retired) is a
  dim 6 defect; cite the rule.

## Issue types

| Type | How to judge |
|---|---|
| Feature / implementation | Full rubric. |
| Epic | Must link its child issues and state the slicing. Dims 1, 2, 7, 8 apply; 3, 4, 5 may defer to children (say so). Score out of the dims that apply. |
| Bug | Dim 1 becomes "repro steps, expected vs actual, environment"; dim 3 needs a regression test that fails before the fix. |
| Spike / test-debt | Judge only whether the question and the exit criteria are crisp, plus dims 7 and 8. |
| Meta / tracking / grooming | Rubric does not apply. Mark `N/A - meta`. Do not edit. |

## Executable by an agent unattended

An issue that an agent will build without a human present must also let it:

1. **Prove each criterion mechanically** - dim 3 binding to named tests.
2. **Self-certify "done"** - dim 4 Verification block with the exact CI commands.
3. **Never stall on a decision** - dim 9 defaults on every open question.
4. **Build in small steps** - for L/XL issues, a `## Build sequence`: ordered steps (for example
   schema -> data access -> service -> endpoint -> UI wiring), each writing its failing test first and
   each landing green on its own. A single numbered deliverable list is not a build sequence.

Missing any of these on an issue marked for unattended work caps the related dimension at 1.
