# audit-app

Audits a **running** web app and writes two cross-linked, screenshot-backed HTML reports:
`qa-report.html` (release recommendation) and `ux-report.html` (Product Experience score and ranked
problems). Say "just QA" or "only UX" to get one.

Invoke `audit-app`, or ask for a "QA / release report" or "UX review" of a running app. It needs a
browser-automation tool that can screenshot and resize the viewport (Playwright MCP, Claude in
Chrome or similar); `ffprobe` is optional. Use a dev or staging environment.

How it works, rules and output paths: see `SKILL.md`.

Ships in this plugin. To use standalone, copy this folder to `~/.claude/skills/audit-app/` or
`<repo>/.claude/skills/audit-app/`.
