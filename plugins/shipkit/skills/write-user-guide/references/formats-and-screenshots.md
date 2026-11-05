# Output formats and screenshots

Read this when the user asks for Markdown, for only one of HTML or PDF, or for screenshots.

## Formats

| Format | Use it for | Source to copy | Ships as |
|---|---|---|---|
| HTML | the default; opens in any browser; attach to a ticket | `assets/example-guide.html` | one `.html` file (with screenshots: a copy with the images embedded) |
| PDF | print, email, ticket attachments for people who will not open HTML | printed from the HTML by `make_pdf.py` | one `.pdf` file |
| Markdown | a repo `docs/` folder, a GitHub or GitLab wiki, a README section | `assets/example-guide.md` | `.md` file plus an `images/` folder when it has screenshots |

- With no format named, write HTML and print it to PDF (both files, same base name).
- PDF always comes from the HTML. For "PDF only", write the HTML in the working folder, print it, and
  hand over the PDF; keep the HTML so the guide can be printed again after a code change.
- Markdown keeps the same section order and the same writing rules. It has no colours or icons, so:
  notes are blockquotes that start with a bold title; messages are a table with Type, Message and What
  to do; the worked example is a table under a bold "Example:" line. Use only GitHub-style Markdown
  (tables, lists, blockquotes, images); a wiki that does not render a feature shows raw symbols.
- Markdown and HTML for the same ticket: write the HTML first, have it checked (step 3 in SKILL.md),
  then write the Markdown from the checked HTML, so both say the same thing. Diff the two by eye for any
  fact present in one and missing in the other.

## Screenshots

Off by default: a guide without pictures does not go stale when the UI moves a pixel. Add them when the
user asks, or when they confirm after you mention it, and only when the app runs (locally or on a test
environment) and a browser tool can drive it (Playwright MCP, Claude in Chrome, or similar).

**Which screens.** One picture where the reader has to find something: the field in step 2, the menu in
step 1, the result after the last step, and a message the user is likely to hit. Not one per step, not
one per section. A guide of 3 steps usually needs 2-3 pictures.

**How to take them.**
1. Sign in as the role the guide is for (a Member guide shows a Member's screen, not an admin's).
2. Use test data with believable names ("Send the weekly report"), never real customer names, emails,
   tokens or IDs. If only real data exists, blur or replace it before saving, and tell the user.
3. Same browser window size for every picture (1280x800 is a good default), same zoom, same theme.
4. Capture the element or region the step is about, not the whole screen: the dialog, the panel, the
   row. Leave a little surrounding context so the reader can find it on their own screen.
5. Mark the target when it is not obvious: before the screenshot, draw an outline on it from the page,
   for example `el.style.outline = "3px solid #d93025"; el.style.outlineOffset = "3px"`. One mark per picture.
6. Save as PNG under `<guide-base-name>-images/` next to the guide, named by section and step:
   `repeat-step-2-field.png`, `messages-warning.png`.

**Placing them.** Directly under the step or sentence it shows. Every picture has alt text that says
what it shows ("Task details with the Repeat field outlined"), and a caption only when the picture needs
a word of explanation. HTML:

```html
<figure class="shot">
  <img src="Recurring-Tasks-images/repeat-step-2-field.png" alt="Task details with the Repeat field outlined">
  <figcaption>The Repeat field is under the due date.</figcaption>
</figure>
```

Markdown: `![Task details with the Repeat field outlined](Recurring-Tasks-images/repeat-step-2-field.png)`.

Under the header facts, add one line that dates the pictures, so a reader knows when they may be out of
date: `<p class="shots-note">Screens from version 4.2 (test environment), 6 November 2026.</p>`.

**Before printing.**
- Keep editing the source guide with its relative image paths. To share, write a copy with the pictures
  embedded, so it still shows them after it is attached to a ticket:
  `python "${CLAUDE_SKILL_DIR}/scripts/embed_images.py" <guide>.html share/<guide>.html`, and print the PDF to
  `share/<guide>.pdf`. Attach the files in `share/`. Never embed into the source: base64 images make it
  megabytes long and hard to edit. The script stops with a list of missing files.
- The fresh checker (step 3 in SKILL.md) also gets the pictures: every label in a picture must match the
  label in the text, and the picture must show the role and state the text describes.
- After a code change that moves or renames anything shown, take the affected pictures again.
