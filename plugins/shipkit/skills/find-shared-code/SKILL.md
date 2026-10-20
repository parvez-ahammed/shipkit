---
name: find-shared-code
description: >-
  Plans what to build once and share across a milestone or backlog of feature issues (engines,
  helpers, UI), with build-now / build-narrow / keep-per-feature verdicts, over-abstractions to
  resist, and a build order. Use for "what can be shared across these issues", "are we
  reimplementing this across planned issues or a backlog", "design the platform layer for this
  milestone". Not for existing duplicate code (use simplify-code).
argument-hint: "[milestone | phase | label | issue list]"
license: MIT
---

# find-shared-code - what to build once across a backlog

Feature issues read one at a time hide that many want the same machinery (a pipeline, a provider API
client, an upload, a filtered grid, an async job). Built blind, each feature copies it. This skill
reads the whole set and proposes a small **shared platform** the features consume, plus a thin layer
per feature. Shared is earned, not assumed: say which abstractions are worth it and which add
complexity for little gain. If the set has little to share, say so; do not invent a platform. This
audits structure and adds no product scope.

## Inputs

A milestone title or number, a phase, a label, or an explicit issue list. Resolve it to a concrete set
(for example `gh issue list --milestone "<title>" --json number,title`, or the Jira, Azure DevOps,
GitLab or Linear equivalent) and read the bodies. Ungroomed issues give vague candidates: groom them
first with `groom-issue`.

## Process

Run these as parallel read-only sweeps (dispatch agents when the set is large), then synthesize.

### 1. Find the candidate commons
Look for the same capability described in 2 or more places under different names:
- **Engines:** processing pipeline, provider gateway (payments, email, AI models, maps), template or
  rendering assembler, job queue and streaming layer, asset storage service, registry.
- **Primitives:** hardened outbound fetch (SSRF), upload validator, cache wrapper, cost or pricing
  table, tenant scoping helper, signer, idempotency guard.
- **UI kit:** filter/search/grid, async-job status hook, feature-flag or entitlement gate, cost or
  quota estimate display, KPI strip, loading/empty/error/retry wrapper.

### 2. Cross-phase ownership check (the step people skip)
For each candidate, before proposing to build it, decide:
- **Already built** in the codebase (cite the file)? A sibling domain often has the primitive
  (`grep` for it). Promote or reuse it; do not start from scratch.
- **Owned by an issue in another milestone or phase?** Re-sequenced milestones cause this drift. If an
  earlier phase owns it (billing ledger, tenancy, auth), this milestone depends on it and does not
  rebuild it.
- **Unowned** new work this milestone must create?
Output: built-in-code / owned-by-#n-in-phase-X / unowned, with evidence.

### 3. Verdict per candidate
Score each against:
- **Rule of three:** 3 or more real consumers earns extraction now; 2 can wait.
- **Real duplication or just tidiness?** Is the abstraction sized to today's need or to an imagined
  future (a registry for one provider, a framework for one use)? Name the **simpler form** when it is
  over-built.
- **Coupling:** would sharing force unrelated features to deploy together, leak a wrong key or tenant,
  or trust the client for something the server must own? Then it is a bad seam; say what to do instead.

Verdict: **build-now** / **build-but-narrow** (with the narrowed scope) / **keep-per-feature**.

### 4. Build order
Order the platform pieces so the shared layer exists before the features that use it: pure utilities
first, then the foundation issue (data model, billing, queue), then engines that need it, then the UI
kit, then features.

## Output format

Produce, in this order:

1. **Cross-phase table** - candidate | status (built-in-code <file> / owned-by-#n <phase> / unowned) |
   evidence. Lead with this: it prevents duplicate issues. Every "share it" and "already owned" claim
   cites a real issue body or file, not memory.
2. **Verdict table** - candidate | verdict | rule-of-three and duplication note | coupling risk |
   simpler form if over-built | one-line rationale tied to a specific issue or file.
3. **What to resist** - the over-abstractions that would create a problem (god-engine, registry of
   one, one model for everything, a framework where a function would do) and the simpler thing to do.
   Mandatory: an audit with no "resist" list did not do the work.
4. **Missed commons** - anything shared across 3 or more issues your list did not name.
5. **Build order** - the dependency-ordered sequence, naming which issues each piece unblocks.
6. (only when the user authorizes it) **The platform spec and issues** - write one platform doc (ask
   where it lives, for example `docs/platform.md`), then create the build-first platform issues with
   `blocks` / `blocked-by` links (or your tracker's equivalent) so feature issues depend on them. Fold
   foundation pieces (cost table, scoping, multi-step transactions) into the existing foundation
   issue instead of creating micro-issues.
