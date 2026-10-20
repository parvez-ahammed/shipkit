## What and why

<!-- What does this PR change, and why? Link the issue: Closes #123 -->

## Type

- [ ] New skill
- [ ] Fix or improvement to an existing skill
- [ ] Hook (`hooks/`)
- [ ] Docs, CI or repo housekeeping
- [ ] Breaking change (renames a skill, removes behaviour, changes a manifest)

## Checklist

- [ ] `claude plugin validate . && claude plugin validate plugins/shipkit` passes
- [ ] Skill `name` is verb-object kebab-case and matches its folder
- [ ] `description` <= 1024 chars, `description` + `when_to_use` <= 1536 chars
- [ ] `license: MIT` set; `compatibility` set if the skill needs installed tools
- [ ] `SKILL.md` under 500 lines; bundled files referenced via `${CLAUDE_SKILL_DIR}`
- [ ] Scripts are run through their interpreter (`node`, `python`, `bash`) and work on Windows, macOS and Linux
- [ ] Tested locally (`bash sync-skills.sh`, `pwsh -File sync-skills.ps1`, or `/plugin marketplace add .`)
- [ ] `README.md`, `INDEX.md` and `CHANGELOG.md` updated if user-facing
- [ ] Conventional commit messages
- [ ] No secrets, tokens, email addresses, internal URLs or private data

## How I tested it

<!-- The prompt or command you ran, and what came back. -->
