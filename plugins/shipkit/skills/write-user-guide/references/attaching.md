# Attaching the guide to a tracker item

Pick the tracker the project uses. All of them: attach both the HTML and the PDF, and post one
short comment that says what the guide covers. Before you upload or post anything, tell the user the
tracker item, the files and the comment text, and wait for a yes.

- **Azure DevOps work item:** `python "${CLAUDE_SKILL_DIR}/scripts/attach_azure_devops.py" <id> "<comment>" <html> <pdf>`
  with `ADO_ORG_URL` and `ADO_PROJECT` set; uses `az login`. It replaces same-named attachments and
  refuses a file whose name does not start with `<id>-`.
- **Jira issue:** `curl -u "$JIRA_USER:$JIRA_TOKEN" -H "X-Atlassian-Token: no-check"
  -F "file=@<guide>.pdf" "$JIRA_URL/rest/api/3/issue/<KEY>/attachments"` (once per file). Jira
  keeps same-named files side by side, so delete the old attachment first
  (`DELETE /rest/api/3/attachment/<attachmentId>`, ids from `GET /rest/api/3/issue/<KEY>?fields=attachment`).
- **GitHub issue or PR:** `gh` cannot upload files to a comment. Commit the HTML and PDF to the
  branch (for example `docs/guides/`) and post a link with
  `gh pr comment <n> --body "..."` or `gh issue comment <n> --body "..."`. Ask before committing.
- **Other trackers:** attach by hand or through their API; keep the same file names.
