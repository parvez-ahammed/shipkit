# Grep helpers for trim-comments (candidates, not verdicts)

Adjust the comment marker to the language (`//`, `#`, `--`). Add `|| true` so a no-match exit does
not abort a batch of commands.

```bash
# history / migration narration
grep -rnE "(//|#).*(used to|previously|formerly|renamed|migrated from|no longer|RETIRED|DELETED)" <target> || true
# dated or ticket-stamped decision logs
grep -rnE "(//|#).*(authority:|decision:|owner decision|#[0-9]{2,}|20[0-9]{2}-[0-9]{2}-[0-9]{2})" <target> || true
# banners and step narration
grep -rnE "^\s*(//|#)\s*(Types|Constants|Helpers?|Section|={4,}|-{4,}|Step [0-9])" <target> || true
# commented-out code (rough)
grep -rnE "^\s*(//|#)\s*(const|let|var|return|if|for|await|import|export|def|func|public|private)\b" <target> || true
```

The same keyword is noise in one file and a needed warning in the next.
