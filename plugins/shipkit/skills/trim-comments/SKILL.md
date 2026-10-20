---
name: trim-comments
description: >-
  Delete or tighten the existing code comments in one file or folder that restate code, narrate
  history or log decisions, keeping only the non-obvious why, invariants and gotchas. Comment-only,
  verified by the repo's gates. Use for "clean up comments", "the comments are bloated", "remove
  commented-out code", "strip history comments". Not for writing new prose (use write-plainly) or
  code cleanup (use simplify-code).
argument-hint: "[file | folder | module]"
license: MIT
---

# trim-comments - keep the WHY, cut the noise

A comment either carries information the code cannot, or it is noise. A good comment tells a future reader something the code
cannot: WHY this odd choice, WHAT invariant must hold, WHICH gotcha bites if you touch it. A bad
comment restates the code, narrates how the code got here, or stamps a decision with a date and an
owner. Noise is worse than nothing: it bloats the file, rots as the code moves under it, and hides
the few comments that matter.

**Rule:** code and comments describe the CURRENT state only. A comment that only makes sense if you
know what the code used to be is dead weight; version control already holds the history.

**Iron Law:** comment-only. Not one token of code changes. The repo's gates must stay green.

Not for: the style of new prose you are writing (use `write-plainly`); renames, dead code, or
structural cleanups (use `simplify-code`); design-pattern decisions (use `refactor`).

## The one test

For every comment ask: **would a competent engineer reading this code cold be worse off without it?**

- Yes -> keep it, and tighten the wording if it rambles.
- No -> delete it.

Unsure? Ask the narrower question: *does this describe the code as it is now, or as it used to be /
how it got here / who decided it?* The second kind always goes.

## Kill these

- **History / migration trace.** Only explains a past state. Triggers: "used to", "previously",
  "formerly", "was renamed", "migrated from", "RETIRED", "DELETED", "no longer", "since the split",
  "after the rewrite".
  ```
  // The old OrdersWidget that previously rendered here was removed; orders now live at /orders.
  ```
- **Dated decision logs and authority stamps.** A comment is not a changelog or meeting record.
  Triggers: a bare `#123` ticket ref, an ISO date, "authority:", "decision:", "per <person>",
  "owner decision", a project codename. Rescue the one durable fact if there is one, drop the rest.
  Exception: a ticket ref that points at a **still-open** problem the reader must know about
  (`// Workaround for #301 (upstream rounding bug); remove when it closes`) is a current gotcha.
  Keep it. Check the ticket state if you can; if you cannot, keep the ref and say so in the report.
  ```
  // Decision (#47, 2025-06-12, per platform team): ReportsPage is the one canonical /reports page.
  ->  // ReportsPage is the canonical /reports page.
  ```
- **Restated code.** `// increment the counter` above `counter += 1`, or `// map user to DTO` above a
  function named `mapUserToDto`. If the code is not self-evident, the fix is a better name, which is
  a code change: note it, do not make it here.
- **Banners and step narration.** `// Types`, `// Helpers`, `# =====`, `// ----`, `// Step 1 / Step 2`
  over a linear function. The language's own structure is the map.
- **Commented-out code.** Delete it; version control has it.
- **Signature-echo doc blocks.** `@param userId the user id`, `:returns: the result`,
  `/// <param name="id">The id</param>`. Keep a doc block only when it adds a constraint, unit,
  caveat or non-obvious contract, or when it feeds published API docs (see traps).

## Keep these

- **Non-obvious WHY.** `// /bulk must be registered before /:id or the router shadows it.`
- **Gotchas and invariants.** `# Validate the slug before any I/O so a bad slug never creates a DB.`
- **Meaning of a confusing but current name.** A column really called `legacy_id` that scopes a
  tenant today: the comment explains the present, keep it. The word "legacy" alone is not bloat;
  judge whether the comment explains now or narrates then.
- **External-world caveats.** Third-party API quirks, rate limits, spec footguns, security reasoning
  (why this is escaped, why this check exists).
- **Legal headers** (license, SPDX, copyright) and the one durable fact rescued from a decision log.

Precise beats present: when you keep a rambling comment, rewrite it to one or two tight lines.

## Workflow

1. **Read project rules.** The repo's `CLAUDE.md` / `AGENTS.md` / `CONTRIBUTING.md` may set comment
   rules, a formatter ban, or a commit style. They override this file.
2. **Scope one target** and state it: a file, a small module, or one feature folder. A whole-repo pass
   is an unreviewable diff that touches code nobody read. If you are already editing a file
   for another task, the target is the code your diff touches, and the trim goes in that task's
   commit.
3. **Detect the language and comment syntax** of every file in scope (`//`, `/* */`, `#`, `--`,
   `<!-- -->`, `;`, `%`, docstrings). Read `${CLAUDE_SKILL_DIR}/references/directives.md` before
   cutting anything: it lists the comment forms that are really code.
4. **Survey.** Read the target. One file or a few hundred lines: just read it top to bottom; grep
   helpers add nothing at that size. For a bigger folder (grep patterns: `${CLAUDE_SKILL_DIR}/references/grep-helpers.md`), if the Agent tool is available, fan the reading
   out to read-only subagents (one per file group) that return every comment as
   `file:line | keep/kill | one-line reason`; you make the final call. Without subagents, read the
   files yourself in sequence. Grep only finds candidates, never verdicts.
5. **Cut.** Delete kill-list comments, tighten keep-list ones. Touch comments and the blank lines they
   leave behind only. Wanting to rename or reorder "while here"? Stop, note it, leave it.
6. **Verify with the repo's gates** (next section). Read every exit code. Never claim green without
   running the gate: quote the exit code or say "unverified".
7. **Report and commit.** Output the summary below. If the user wants a commit, make one focused local
   commit in the repo's style, for example `docs: trim history and restated-code comments in <target>`.
   Never push without an explicit yes.

## Verify with the repo's own gates

Find the gates; do not assume them. Look at, in order: the project `CLAUDE.md`, CI config
(`.github/workflows/*`, `.gitlab-ci.yml`, `azure-pipelines.yml`), then the manifest (`package.json`
scripts, `Makefile`, `pyproject.toml` / `tox.ini`, `*.csproj` / `*.sln`, `go.mod`, `Cargo.toml`,
`pom.xml` / `build.gradle`). Run the cheapest that cover the change: typecheck / build, lint, tests.
Typical: `npm run typecheck && npm run lint && npm test`, `dotnet build && dotnet test`,
`go vet ./... && go test ./...`, `cargo check && cargo test`, `ruff check . && pytest`.

- Run each gate on its own and read its exit code. Piping through `tail` or `head` masks a failure.
- **Prove the diff is comment-only.** `git diff -U0 <target>` must show only comment lines and blank
  lines. For a stronger check, strip comments from the old and new file with the language's own
  tool (for example `npx esbuild --minify-whitespace`, `python -m tokenize`, or `gcc -fpreprocessed
  -E`) and diff the results; they must be identical.
- Do not run a formatter over the whole file unless the project already formats on commit; it buries
  the real diff.
- A gate that turns red after a comment-only change means you removed a directive. Restore it.
- If the project says not to run the build or the suite locally, say exactly what the user must run
  and mark the result unverified.

## Output

Never bulk-delete on a grep match: read the line, apply the one test, then cut.

```
TRIM-COMMENTS REPORT
Target:     <file | folder>
Removed:    <n> comments (<n> history, <n> decision-log, <n> restated, <n> banner, <n> dead code, <n> doc-echo)
Tightened:  <n> comments
Kept:       <n> needed (directives and legal headers not counted; list kept ticket refs)
Noted, not done: <renames or code smells seen (suggest simplify-code); directives for tools the repo lacks>
Gates:      <command> -> exit <code>, one line each, or "unverified: <why>"
Status:     DONE | DONE_WITH_CONCERNS | BLOCKED
```
