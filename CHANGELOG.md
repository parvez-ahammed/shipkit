# Changelog

All notable changes to ShipKit are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- `make-video`: a new step picks the look before any scene is built and writes it to `direction.md`.
  New `references/design.md` gives measured rules for type size, layout, motion, sound and the end
  card. The fresh reviewer now answers ship, fix or rebuild, with at most two review rounds.
- `make-video` engine: scenes cut hard instead of fading. Arrivals use a softer curve with blur.
  New `drift()`, `blur()`, `ease.soft` and `ease.exit`, and a `.vm-ground` brand-colour scene.
  Headline, point, pill and caption sizes are larger. The template shows the new look.
- `write-user-guide`: the example guide is rewritten in the order a reader needs it: the steps
  first, then a worked example with dates, then reference tables. Each fact is stated once. It prints
  on white with page numbers, uses SVG icons, and every text colour passes 4.5:1 contrast.
- `write-user-guide`: the page-fill check in `make_pdf.py` ignores the page-number footer, and the
  script creates the output folder.

### Added

- `write-user-guide`: Markdown output (`assets/example-guide.md`) and optional screenshots of the
  running app, with rules for which screens to take, test data and placement
  (`references/formats-and-screenshots.md`). `scripts/embed_images.py` writes a one-file copy of an
  HTML guide with its pictures embedded, for attaching to a ticket. Default output is still HTML +
  PDF without screenshots.

## [1.0.0] - 2026-10-20

First public release: a Claude Code plugin with 24 skills and 2 git hooks.

### Added

- **Review and fix:** `review-branch`, `fix-bug`, `build-story`, `test-branch`,
  `grill-feature`.
- **Plan and deliver:** `groom-issue` (with a milestone brief mode), `deliver-issue`,
  `price-product`.
- **QA and UX:** `audit-app`, `find-ux-gaps`.
- **Refactor and architecture:** `refactor` (code smells, refactoring mechanics and
  design-pattern scoring), `enforce-clean-architecture`, `find-shared-code`, `simplify-code`,
  `trim-comments`.
- **Ship and operate:** `deploy-to-vps` (with honest health checks), `add-mcp-server`,
  `boost-seo`.
- **Create and document:** `make-video`, `make-demo`, `write-user-guide`, `write-plainly`.
- **Insight:** `show-usage`, `fill-timesheet`.
- `deliver-issue`, `show-usage` and `fill-timesheet` run only as slash commands, so their
  descriptions add nothing to a session until you call them.
- **Git hooks:** `secret-hygiene` and `safe-commit`, with bash and PowerShell installers.
- Plugin marketplace manifest, project website with `llms.txt`, issue and PR templates.
- CI checks every skill's frontmatter, both manifests, the syntax of every script, that the
  skill count and list in the docs match the skill folders, and that no personal email
  address is in the tree.

[Unreleased]: https://github.com/parvez-ahammed/shipkit/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/parvez-ahammed/shipkit/releases/tag/v1.0.0
