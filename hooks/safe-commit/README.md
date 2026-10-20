# safe-commit (hook)

Validate the commit message before it lands. A **hook**, not a skill - message hygiene
should be enforced every commit, deterministically, not left to memory.

## Checks

**Default (on):**
- **No stray `@`-prefixed line** - catches the bash `@'...'@` slip that leaks a literal
  `@` into the subject. (Real bug; happened twice in a real repo.)
- **Conventional subject** - `type(scope): description` (`feat|fix|chore|docs|refactor|
  test|perf|build|ci|style|revert`). Disable with `SAFE_COMMIT_NO_CONVENTIONAL=1`.
- **Subject length** - warns over 72 chars (warning only).

git-generated subjects (`Merge ...`, `Revert "..."`, `fixup!`, `squash!`, `amend!`) are
skipped, so merges, reverts and autosquash keep working.

**Optional (opt in via env var):**
- `SAFE_COMMIT_NO_EMDASH=1` - reject em dashes (U+2014); use `-` or `:`.
- `SAFE_COMMIT_NO_AI_COAUTHOR=1` - reject `Co-Authored-By: <Claude/GPT/Copilot/Gemini>`
  trailers.

Bypass once (sparingly): `git commit --no-verify`.

## Install

```bash
bash install.sh /path/to/your/repo                     # macOS / Linux / Git Bash
```

```powershell
pwsh -File install.ps1 -Repo C:\path\to\your\repo   # Windows (PowerShell 5.1 or 7)
```

Both installers ask git for the hooks directory, so they work in worktrees and respect
`core.hooksPath`, and back up an existing `commit-msg` hook to `commit-msg.bak`. Manual
install: copy `commit-msg` into the directory printed by `git rev-parse --git-path hooks`
and `chmod +x` it.

To turn on the optional checks, export the env vars where your commits run (shell
profile, direnv `.envrc`, or before committing):

```bash
export SAFE_COMMIT_NO_EMDASH=1
export SAFE_COMMIT_NO_AI_COAUTHOR=1
```

## Note

`commit-msg` only sees the message, not the diff - pair it with the **secret-hygiene**
`pre-commit` hook to also block secrets in the content.
