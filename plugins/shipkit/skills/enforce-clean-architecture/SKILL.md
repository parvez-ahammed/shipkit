---
name: enforce-clean-architecture
description: >-
  Lay out, check and enforce Clean / Hexagonal (ports and adapters) layering in any language, with a
  config-driven guard that fails CI on a forbidden import. Use for "set up clean architecture",
  "where does this code go", "is this the right layer", "did I break the dependency rule",
  "bootstrap a hexagonal project". Not for problems inside one layer such as long methods or pattern
  choice (use refactor).
license: MIT
compatibility: "Layering guard (scripts/check-layering.ps1) needs PowerShell 7+ (pwsh), which runs on Windows, macOS and Linux; Windows PowerShell 5.1 also works. Without PowerShell, apply the same config by hand with grep. The rulebook and bootstrap guidance need nothing installed."
---

# Clean Architecture: rulebook, bootstrap, and guard

Clean / Hexagonal / Ports-and-Adapters architectures all share one core idea - **the
Dependency Rule** - and most teams get the *folders* right but let the *dependencies*
rot. This skill gives you the rule, a way to bootstrap the layout in your stack, and a
guard that mechanically enforces the boundaries (because nothing else will).

## The one rule that matters: dependencies point inward

Layers from outside to inside: Presentation / API -> Infrastructure / Adapters -> Application /
Use Cases -> Domain / Entities. Source-code dependencies only ever point inward, and Domain depends
on nothing. An inner layer that needs a database defines a **port** (interface) and an outer
**adapter** implements it.

Read `${CLAUDE_SKILL_DIR}/references/dependency-rule.md` section "Layers" for the diagram and what
each layer may contain before placing code in a layer you are unsure about.

## "Where does this code go?" - quick decisions

- A business rule / invariant -> **Domain** (entity method or domain service).
- "Do X to fulfil a request, calling repos/services" -> **Application** use case.
- Talking to Postgres / Stripe / S3 / SMTP -> **Infrastructure** adapter behind a port.
- Parsing an HTTP request, status codes, serialization -> **Presentation**.
- A `using`/`import` of a framework in Domain -> **wrong**; move it out or invert it.
- A controller doing a DB query directly -> **wrong**; call a use case.

## Bootstrap a new project

Pick your stack in `${CLAUDE_SKILL_DIR}/references/bootstrap-by-stack.md` - it gives the concrete folder/
project layout and, crucially, **how to make the dependency direction enforceable** in
that ecosystem (project references in .NET, module boundaries / ESLint in TS, Gradle
modules in Java, internal packages in Go). Start with the inner layers and the ports;
wire concrete adapters at a single composition root.

## Enforce it (or it rots)

Folder discipline decays under deadline pressure, and these violations never fail a build
or a test - they're architectural. Add the guard:

1. Copy `${CLAUDE_SKILL_DIR}/assets/clean-arch.json` to your repo root and edit it: declare each layer's
   source paths and the imports/namespaces forbidden in that layer. The defaults name common
   folders (`src/domain`, `src/infra`, `src/adapters`, ...) and common I/O imports per stack
   (Node `fs`/`http` and DB drivers, EF Core, Spring, SQLAlchemy/requests, Go `database/sql`).
   List the repo's real layer folders first, then rename `roots` and the relative-path patterns
   (`../infra`, `../db`) to match. Roots that match nothing exit 2; patterns that name the wrong
   folder pass silently, which is why step 3 exists.
2. Run the guard:
   ```
   pwsh -File "${CLAUDE_SKILL_DIR}/scripts/check-layering.ps1" -Config clean-arch.json -Root .
   ```
   Needs PowerShell 7 (`pwsh`), which runs on Windows, macOS and Linux (Windows
   PowerShell 5.1 also works). If it is not installed and cannot be, apply the same config
   by hand with Grep (one search per layer root and forbidden pattern) and say the guard
   was not run.
   It scans each layer for forbidden imports (language-agnostic) and, for .NET, can
   verify the `.csproj` reference DAG. Exit 1 on a hard violation; exit 2 when no layer
   root matched any source file (a mistyped `roots` must not pass silently).
3. **Prove the guard bites.** Add one throwaway forbidden import to a domain file, run the
   guard, confirm exit 1 and the VIOLATION line, then revert. A guard never seen failing is not
   evidence. If the repo has no PowerShell and a zero-dependency checker in the repo's own
   language fits better (for example a small Node script run by `npm run lint`), write that
   instead; keep the same config shape and this same prove-it step.
4. Wire it into CI and/or a pre-commit hook so the boundary is checked every change, not
   remembered. CI does not have the skill folder: commit a copy of the script (e.g.
   `scripts/check-layering.ps1`) next to `clean-arch.json` and call that copy.

Also in `${CLAUDE_SKILL_DIR}/references/dependency-rule.md`: ports vs adapters, mapping at
boundaries, the common violations and how to fix each by inverting instead of bending the
rule.

## Don't over-build it

Clean Architecture is a means, not a trophy. For a tiny CRUD app it can be overkill - the
layers earn their keep when business rules are non-trivial and you want them independent
of frameworks and testable in isolation. Apply the dependency rule strictly where it
pays; don't add ceremony where it doesn't.

For problems inside one layer (a long method, a god class, "should this be a Strategy")
use `refactor` instead; this skill is about where code lives and
which way dependencies point.
