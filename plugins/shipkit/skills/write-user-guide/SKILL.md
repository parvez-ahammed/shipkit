---
name: write-user-guide
description: >-
  Write a print-ready, user-facing HTML feature guide for a ticket, issue or PR, have a fresh agent
  check every claim against the code, print it to PDF, and (only when asked) attach it to the tracker item. Use for
  "write a user guide for this ticket", "feature guide", "end-user docs for this PR", or to update,
  re-verify or re-attach a guide after the code changed. Not for API docs or changelogs.
argument-hint: "[ticket-id or PR number]"
license: MIT
compatibility: "PDF step needs Python 3.11+, PyMuPDF (pip install pymupdf) and Chrome, Chromium or Edge (set CHROME_PATH if not found). Attaching needs the tracker's CLI or API access: gh, az (Azure DevOps) or curl with a Jira token."
---

# User guide maker

One self-contained HTML guide per ticket, written for end users, in one fixed format. Every label,
role, message and limit comes from the code, and a separate agent checks each claim before anyone
sees it. The guide is printed to PDF and attached to the ticket. The value is the format (no design
work per guide) and the claim check (a guide written from notes or memory is wrong in many small
places, and users trust it).

## When to use / not use

- Use when: a feature is built (or nearly built) on a branch and end users need to learn it.
- Don't use when: you need developer docs, API reference or a changelog entry. Don't use for
  screenshot-heavy Markdown help pages either; this format has no screenshots on purpose, so it
  does not go stale every time the UI moves a pixel. For a clickable preview of a planned flow use
  `make-demo`; for a promo video use `make-video`.

## The format is fixed

Copy `${CLAUDE_SKILL_DIR}/assets/example-guide.html` (fictional product "Acme Tasks"). Keep its CSS, header chips,
"In one line" box, section order, flow diagrams, term list, field/column table, message rows,
limitations, known behaviours, footer and the `@media print` block. Replace only the content.
Do not design a new look and do not ask the user which format to use. Delete a section that does
not apply; do not invent content to fill it. To match a brand, change only the `:root` colour
variables.

Section order: header (product, feature, one-line lede, chips) - "In one line" - when it happens /
when it does not - what it does / requires / does not do - how it works (flow) - terms - how to
open it - who sees what - fields or columns - messages - limitations - known behaviours.

## Workflow

1. **Learn the feature from the code, not from notes.** Work on the ticket's branch (find it with
   `git branch -a --list "*<ticket>*"`; ask before switching). Read `git diff <main>...HEAD`, the
   ticket text and comments, and the PR threads. Copy every label, menu path, role, column, message
   text and limit from the source file. Notes, specs and chat history are hints, never proof.
2. **Write** the guide inside the repo, in a folder the team uses for working files (for example
   `docs/guides/` or a git-ignored working folder such as `.work/<ticket>/`), as `<ticket>-<Feature>-User-Guide.html`. The
   file name becomes the attachment name on the ticket, so never a generic name like `guide.html`.
   - Plain words, short active sentences, ASCII only (unless the product's UI language needs other
     characters; then skip the ASCII check in step 4). If the `write-plainly` skill is installed,
     load it first.
   - Audience is end users: no file names, code, commit or PR history, review findings.
   - Describe *when* something happens in the user's terms first ("when you mark the task Done"),
     then the other triggers, then what does NOT trigger it. Users think in their own actions, not
     in the system events the code is built around.
   - For every state (empty, error, never, hidden, no permission), say what the user sees, with the
     exact text from the code.
3. **Verify with a fresh agent** (the strongest model you have). Brief: treat the guide as a list
   of claims and the code as the truth; give a verdict per claim - CONFIRMED (file:line), WRONG
   (with replacement text) or UNVERIFIABLE - plus behaviour the guide is MISSING and places where
   the guide contradicts itself. The agent that wrote the guide never verifies it.
4. **Apply every fix.** Then grep the guide for each old wrong phrase (a bulk rewrite often leaves
   one copy behind), and check for non-ASCII: `grep -cP '[^\x00-\x7F]' <guide>.html` must print 0
   (GNU grep; on macOS or without `-P` use
   `python -c "import sys; print(sum(ord(c) > 127 for c in open(sys.argv[1], encoding='utf-8').read()))" <guide>.html`).
5. **PDF:** `python "${CLAUDE_SKILL_DIR}/scripts/make_pdf.py" <guide>.html <guide>.pdf` (same base name). Read two or
   three of the preview PNGs it writes. A page flagged `<-- check` usually has a heading left
   alone at the bottom or a card pushed to the next page: adjust `break-inside` / `break-after`
   in the print block and run again. Delete the previews afterwards.
6. **Open** the HTML in a browser for the user to read.
7. **Attach only when asked.** Read `${CLAUDE_SKILL_DIR}/references/attaching.md` first (Azure DevOps, Jira, GitHub commands).
   Before you upload or post anything, show the user the tracker item, the files and the comment
   text, and wait for a yes. Replace an attachment with the same name instead of adding a second
   copy. An older guide under a different name stays: list it and ask before removing it.

## After code changes

Every change to a label, limit or behaviour on the branch makes the guide stale. Before you
attach again: grep the guide for the old text (old labels, removed messages, removed limits), fix
it, re-run the claim check on the changed parts, print again, attach again. Tell the user that the
copy on the ticket does not update itself.

## Gotchas

| Mistake | Fix |
|---|---|
| `pdftoppm` / `pdftocairo` not installed | `make_pdf.py` uses PyMuPDF (`pip install pymupdf`) |
| Chrome not on the default path | Set `CHROME_PATH` (Edge works too) |
| Chrome drops backgrounds or splits cards | Keep the `@media print` block from the example |
| Half-empty page before a two-column block | Chrome does not split a tall grid row, so the print block stacks `.grid-2`. Never put `break-inside: avoid` on a tall container |

## Reference map

Paths are relative to this skill's folder (`${CLAUDE_SKILL_DIR}`). Use `python3` instead of
`python` where that is the interpreter's name (macOS, most Linux).

- `assets/example-guide.html` - the format to copy (fictional example).
- `scripts/make_pdf.py` - HTML to PDF with headless Chrome or Edge, page-fill report, PNG previews.
- `scripts/attach_azure_devops.py` - attach to an Azure DevOps work item, replacing by name.
- `references/attaching.md` - read only when the user asks to attach.
