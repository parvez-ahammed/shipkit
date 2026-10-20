# Review lenses for grooming

Read during phase 1, before running `groom-issue`, to pressure-test the issue from the angles a full
team would bring. Run only the lenses that apply. Skip any lens a previous groom already folded into
the issue (an existing security block or implementation-notes block counts). Each lens is a short set
of questions you answer yourself from the issue, the code and the docs; findings go back into the
issue through `groom-issue`, with a yes before anything is written.

| Lens | Applies when | Questions |
|---|---|---|
| **Product** | User-facing or business impact, or non-trivial scope | Is this worth building now? What is the smallest version that delivers the value? Who uses it, and what do they do the moment it ships? What is explicitly out? |
| **Engineering** | Always | Is the approach sound and reuse-first (extending existing code, not rebuilding)? Is it sized right, or should it split? Where will it break: concurrency, data volume, migrations, partial failure? Does it follow the project's layering and rules? |
| **UX** | It touches UI or a user flow | Does the flow make sense end to end? Are loading, empty, error, permission-denied and slow-network states covered? Does new text use the words the UI already uses? |
| **Developer experience** | It adds or changes an API, CLI, config, tooling or dev workflow | Is it obvious to the next engineer? Defaults safe? Errors actionable? Any footgun? Is it documented where people look? |
| **Security** | Auth, sessions, payments or credits, personal data, secrets, webhooks, outbound fetches, queue payloads, file upload, multi-tenant data, user-authored code or config | What is the attack surface? Can one user reach another's data (missing ownership check)? Can a user-supplied URL make the server fetch internal addresses? Can a queued payload be forged? Injection? Secret leakage in logs or responses? Which mitigations must become acceptance criteria with tests? |
| **Test** | There is behaviour to verify | What are the real failure modes? Which test proves each acceptance criterion? What existing behaviour could regress, and what guards it? |

## Rules

- **The lenses inform the plan; they do not invent scope.** A lens that wants something the user did
  not ask for raises it as an `OPEN QUESTION` with a default, not as new scope.
- **When lenses disagree,** prefer keeping existing proven behaviour and note the tension. Security
  wins on security; engineering wins on structure; product wins on what ships. A true conflict
  between them becomes an open question for the user.
- **Stop when nothing outcome-changing remains.** The lenses are a checklist to clear, not a ritual
  to repeat.
