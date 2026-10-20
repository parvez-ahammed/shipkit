# Changelog

All notable changes to ShipKit are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
