# Contributing to ShipKit

Thanks for helping. ShipKit is a Claude Code plugin: 24 skills under
`plugins/shipkit/skills/`, plus two git hooks under `hooks/`. Most contributions are a new
skill or a fix to an existing one.

Before you start on anything large, open an issue (or a
[discussion](https://github.com/parvez-ahammed/shipkit/discussions)) so we can agree
on the shape first.

## Repository layout

```
.claude-plugin/marketplace.json     marketplace manifest (name: shipkit)
plugins/shipkit/.claude-plugin/     plugin manifest (name: shipkit)
plugins/shipkit/skills/<skill>/     one folder per skill: SKILL.md + references/ scripts/ assets/
hooks/safe-commit/                  commit-msg hook (conventional commits)
hooks/secret-hygiene/               pre-commit hook (blocks secrets)
_template/SKILL.md                  starting point for a new skill
sync-skills.sh / sync-skills.ps1    copy skills into ~/.claude/skills for local testing
```

## Adding or changing a skill

1. **Start from the template.** Copy `_template/SKILL.md` into
   `plugins/shipkit/skills/<skill-name>/SKILL.md`.
2. **Name it verb-object, in kebab-case.** Examples: `fix-bug`, `review-branch`,
   `add-mcp-server`. The `name:` in the frontmatter must match the folder name exactly.
   Users invoke it as `/shipkit:<skill-name>`.
3. **Write the frontmatter.**
   - `description`: what the skill does and when it should trigger. 1,024 characters
     at most.
   - `when_to_use` (optional): extra trigger phrases. `description` + `when_to_use`
     must be 1,536 characters or fewer.
   - `license: MIT` is required.
   - `compatibility` is required when the skill needs a tool to be installed (Node,
     Python, ffmpeg, Playwright, `gh`...). 500 characters at most.
4. **Keep `SKILL.md` under 500 lines.** Move detail into `references/` (one level deep)
   and say in `SKILL.md` when to read each file.
5. **Reference bundled files through `${CLAUDE_SKILL_DIR}`**, for example
   `${CLAUDE_SKILL_DIR}/references/checklist.md`. That path works whether the skill is
   installed as a plugin or copied into `~/.claude/skills`.
6. **Run scripts through their interpreter**: `node ${CLAUDE_SKILL_DIR}/scripts/x.mjs`,
   `python ${CLAUDE_SKILL_DIR}/scripts/x.py`, `bash ${CLAUDE_SKILL_DIR}/scripts/x.sh`.
   Don't rely on the executable bit or a shebang; it fails on Windows and after some
   installs.
7. **Stay stack-neutral and cross-platform.** Skills should work on Windows, macOS and
   Linux, and should not assume one company's tooling, repo names or paths.
8. **Update every place that lists the skills.** Adding or removing a skill changes the
   count and the list in all of these:
   - `README.md` (headline, badge, skill table) and `INDEX.md`;
   - `docs/index.html` (meta tags, JSON-LD, skill cards) and `docs/llms.txt`;
   - the `description` in both manifests;
   - the banner: edit `.github/og-source.html`, then render it to `docs/og.png` and
     `.github/social-preview.png` (see "Banner" below), and upload the new
     `social-preview.png` in the repository settings on GitHub;
   - the repository description on GitHub;
   - an entry under `Unreleased` in `CHANGELOG.md`.

   CI fails when the count or the list in these files does not match the skill folders.

Renaming a skill is a breaking change for users. Call it out in the PR and in
`CHANGELOG.md`.

## Testing locally

Pick one:

- **Copy the skills into your personal skills folder** (no plugin needed):

  ```bash
  bash sync-skills.sh               # macOS / Linux / Git Bash
  bash sync-skills.sh --dry-run     # preview
  ```

  ```powershell
  pwsh -File sync-skills.ps1        # Windows
  ```

  Restart Claude Code, then invoke the skill by its plain name.

- **Install this checkout as a marketplace**, from the repo root inside Claude Code:

  ```
  /plugin marketplace add .
  /plugin install shipkit@shipkit
  ```

  Then invoke `/shipkit:<skill-name>`.

Try the skill on a real task, and check that it triggers from the phrases in its
description, not only from the slash command.

## Banner

`docs/og.png` and `.github/social-preview.png` are screenshots of `.github/og-source.html`
at 1280 x 640. Render with any Chromium browser:

```bash
chrome --headless=new --hide-scrollbars --force-device-scale-factor=1 \
  --window-size=1280,640 --screenshot=docs/og.png "file://$PWD/.github/og-source.html"
cp docs/og.png .github/social-preview.png
```

## Checks before opening a PR

```bash
claude plugin validate . && claude plugin validate plugins/shipkit
```

CI (`.github/workflows/validate.yml`) also runs on every push and PR. It checks:

- every `SKILL.md` frontmatter: `name` matches the folder, description and
  `when_to_use` lengths, `license` present, `compatibility` length, body under 500 lines;
- both manifests parse as JSON;
- `node --check` on every `.js` / `.mjs`, `py_compile` on every `.py`, `bash -n` on every
  `.sh`;
- the skill count and skill list in the README, INDEX, website, `llms.txt`, manifests and
  banner source match the skill folders;
- no personal email addresses anywhere in the tree.

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/):
`type(scope): description`, where type is one of `feat`, `fix`, `chore`, `docs`,
`refactor`, `test`, `perf`, `build`, `ci`, `style`, `revert`. Example:
`fix(boost-seo): handle redirects in audit-url`.

The `hooks/safe-commit` hook enforces this locally. The `hooks/secret-hygiene` hook
blocks secrets before they are committed. Install both:

```bash
bash hooks/safe-commit/install.sh .
bash hooks/secret-hygiene/install.sh .
```

```powershell
pwsh -File hooks/safe-commit/install.ps1 -Repo .
pwsh -File hooks/secret-hygiene/install.ps1 -Repo .
```

## No secrets, no private data

Never commit API keys, tokens, passwords, `.env` files, email addresses, customer names,
internal URLs or real data from your own projects. Use placeholders like `example.com`,
`<your-token>` and `acme-app` in examples. If you find leaked data in the repo, report it
privately (see [SECURITY.md](SECURITY.md)) instead of opening a public issue.

## Code of conduct

By taking part you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## License

Contributions are released under the [MIT License](LICENSE).
