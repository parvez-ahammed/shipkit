---
name: write-user-guide
description: >-
  Write a user-facing feature guide for a ticket, issue or PR as HTML, PDF or Markdown, with or
  without screenshots of the running app, have a fresh agent check every claim against the code, and
  (only when asked) attach it to the tracker item. Use for "write a user guide for this ticket",
  "feature guide", "end-user docs for this PR", "help page in Markdown", "guide with screenshots", or
  to update, re-verify or re-attach a guide after the code changed. Not for API docs or changelogs.
argument-hint: "[ticket-id or PR number] [html|pdf|md] [screenshots]"
license: MIT
compatibility: "PDF step needs Python 3.11+, PyMuPDF (pip install pymupdf) and Chrome, Chromium or Edge (set CHROME_PATH if not found). Screenshots need the app running and a browser tool that can drive it (Playwright MCP or similar). Attaching needs the tracker's CLI or API access: gh, az (Azure DevOps) or curl with a Jira token."
---

# User guide maker

One guide per ticket, written for end users, in one fixed format: HTML and a PDF printed from it by
default, or Markdown for a repo or wiki. Every label, role, message and limit comes from the code,
and a separate agent checks each claim before anyone sees it. The value is the format (no design
work per guide) and the claim check (a guide written from notes or memory is wrong in many small
places, and users trust it).

## When to use / not use

- Use when: a feature is built (or nearly built) on a branch and end users need to learn it.
- Don't use when: you need developer docs, API reference or a changelog entry. For a clickable
  preview of a planned flow use `make-demo`; for a promo video use `make-video`.

## Pick the output

Take the format and screenshots from the request. When the user names neither, write HTML, print it
to PDF, use no screenshots, and say in the hand-over that Markdown and screenshots are available.

| The user asks for | Write |
|---|---|
| nothing specific, "a guide", "a PDF" | HTML from `assets/example-guide.html`, printed to PDF |
| "HTML only" | HTML, no PDF |
| Markdown, "for the repo", "for the wiki", a `docs/` page | Markdown from `assets/example-guide.md` |
| screenshots, "with pictures", "show the screens" | either format, plus 2-4 screenshots of the running app |

Screenshots are off by default because a guide without them does not go stale when the UI moves.
For Markdown, screenshots or "PDF only", read `${CLAUDE_SKILL_DIR}/references/formats-and-screenshots.md`
before step 2: it covers the Markdown rules, which screens to capture, test data, and how to embed images.

## The format is fixed

Copy `${CLAUDE_SKILL_DIR}/assets/example-guide.html` (fictional product "Acme Tasks"), or
`assets/example-guide.md` for Markdown. Keep its CSS, its parts and the `@media print` block. Replace only the content. Do not design a new look and do
not ask the user which format to use. To match a brand, change only the `:root` colour variables,
and keep every text colour at 4.5:1 contrast or more against its background. Change the product
name in the two `@page` footer lines too: they print on every page.

A reader opens a guide with a task in mind, then checks details later. The sections follow that
order. Delete a section that does not apply; never invent content to fill one.

1. **Header:** product, feature name, a lede of 2-3 sentences (what it does for the user, and the
   one rule that surprises people), and the Where / Who / Shown in facts.
2. **Do the main task:** numbered steps, one action each, exact labels in bold. A requirement
   ("needs a due date") goes in the step where the user meets it, not in a list before the steps.
3. **What happens:** the behaviour, shown as a worked example with realistic names, dates or
   numbers ("You do this" / "Acme Tasks does this"). One example with 3-4 rows explains more than
   a paragraph of rules, and it covers the surprising cases (late, empty, overdue) in context.
4. **When it does not happen:** the triggers that look as if they should work but do not.
5. **Change, undo or stop it.**
6. **Who can do what:** a table, one row per role, including the roles that cannot.
7. **Fields or columns**, then **messages**: the exact text, what it means, and what to do next.
8. **Good to know:** limits and odd cases not already covered above.

For a process that passes between people or systems, add a flow (`.flow`) inside section 3. Define
a new term in the sentence where it first appears; add a term list (`dl.terms`, markup
`<dl class="terms"><div><dt>Term</dt><dd>Meaning</dd></div></dl>`) only for 5 or more new terms.

The brand colour stays in the frame (top rule, product line, step numbers, example header); the
reading column stays black and grey. These are the marks of a generated document, and the example
avoids each one on purpose:
- a small uppercase label above every heading
- a box inside a box, or a row of same-size boxes that could be a list or a table
- a thick coloured stripe down the side of a box or row
- emoji or Unicode symbols as icons (use the SVG symbols at the top of the example)
- the meaning carried by colour alone (every coloured state also has a word: "Warning", "Error")

## Workflow

1. **Learn the feature from the code, not from notes.** Work on the ticket's branch (find it with
   `git branch -a --list "*<ticket>*"`; ask before switching). Read `git diff <main>...HEAD`, the
   ticket text and comments, and the PR threads. Copy every label, menu path, role, column, message
   text and limit from the source file. Notes, specs and chat history are hints, never proof.
2. **Write** the guide inside the repo, in a folder the team uses for working files (for example
   `docs/guides/` or a git-ignored working folder such as `.work/<ticket>/`), as `<ticket>-<Feature>-User-Guide.html`
   (or `.md`). The file name becomes the attachment name on the ticket, so never a generic name like `guide.html`.
   With screenshots, capture them now, from the branch's build, as the guide's role (see the reference).
   - Plain words, short active sentences, ASCII only (unless the product's UI language needs other
     characters; then skip the ASCII check in step 4). If the `write-plainly` skill is installed,
     load it first.
   - Audience is end users: no file names, code, commit or PR history, review findings.
   - Write to the reader as "you". Headings name the reader's task or question ("Make a task
     repeat", "When no copy is made"), not a category ("Overview", "Behaviour", "Limitations").
   - Describe *when* something happens in the user's terms first ("when you mark the task Done"),
     then the other triggers, then what does NOT trigger it. Users think in their own actions, not
     in the system events the code is built around.
   - Say each fact once, in the section where the reader needs it. Before printing, list the facts
     in the guide and check none appears twice: the old version of the example said three times
     that comments are not copied.
   - For every state (empty, error, never, hidden, no permission), say what the user sees, with the
     exact text from the code. Every error message gets a next step the user can take.
3. **Verify with a fresh agent** (the strongest model you have). Brief: treat the guide as a list
   of claims and the code as the truth; give a verdict per claim - CONFIRMED (file:line), WRONG
   (with replacement text) or UNVERIFIABLE - plus behaviour the guide is MISSING and places where
   the guide contradicts itself. With screenshots, give it the pictures too: a label in a picture
   that differs from the text, or a picture showing the wrong role or state, is WRONG. The agent
   that wrote the guide never verifies it.
4. **Apply every fix.** Then grep the guide for each old wrong phrase (a bulk rewrite often leaves
   one copy behind), and check for non-ASCII: `grep -cP '[^\x00-\x7F]' <guide>.html` must print 0
   (GNU grep; on macOS or without `-P` use
   `python -c "import sys; print(sum(ord(c) > 127 for c in open(sys.argv[1], encoding='utf-8').read()))" <guide>.html`).
5. **PDF** (skip for Markdown and "HTML only"): `python "${CLAUDE_SKILL_DIR}/scripts/make_pdf.py" <guide>.html <guide>.pdf` (same base name). Read every
   preview PNG it writes (up to 12), and fix what you find in one pass, then print once more:
   - a heading alone at the bottom of a page, or a box pushed to the next page (page flagged
     `<-- check`): adjust `break-inside` / `break-after` in the print block
   - a table, flow or row cut off at the right edge, or a word broken mid-line
   - the product name in the page footer still "Acme Tasks"
   - one of the marks listed under "The format is fixed" that crept in with new content
   - cover the product name: if the page could belong to any product, the content is too generic
     (labels and messages not copied from the code)
   - a screenshot cut across two pages, blurry, or showing real customer data

   Delete the previews afterwards. A guide with screenshots also gets its one-file copy for sharing
   (`scripts/embed_images.py`, see the reference).
6. **Open** the HTML in a browser for the user to read (Markdown: show the file in the repo's
   preview, or on the platform it is meant for).
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
| Half-empty page before a two-column block | Chrome does not split a tall grid row. Never put `break-inside: avoid` on a tall container |
| A heading stranded at the bottom of a page before a grid | Chrome ignores `break-after: avoid` when the next element is a grid. Use block rows (as in the term list) |
| No page numbers in the PDF | Chrome before version 131 ignores the `@page` footer boxes. Update Chrome; the guide still prints without them |
| Pictures missing after the HTML is attached to a ticket | The ticket stores only the HTML, not the images folder. Attach the copy written by `embed_images.py` |
| Markdown shows raw `>` or `|` symbols on the wiki | The wiki does not support that Markdown. Use only the parts in `example-guide.md` |

## Reference map

Paths are relative to this skill's folder (`${CLAUDE_SKILL_DIR}`). Use `python3` instead of
`python` where that is the interpreter's name (macOS, most Linux).

- `assets/example-guide.html` - the format to copy (fictional example).
- `assets/example-guide.md` - the same guide in Markdown.
- `references/formats-and-screenshots.md` - read for Markdown, screenshots or "PDF only".
- `scripts/embed_images.py` - a one-file copy of an HTML guide with its screenshots embedded.
- `scripts/make_pdf.py` - HTML to PDF with headless Chrome or Edge, page-fill report, PNG previews.
- `scripts/attach_azure_devops.py` - attach to an Azure DevOps work item, replacing by name.
- `references/attaching.md` - read only when the user asks to attach.
