# Security Policy

## Supported versions

Only the latest release of ShipKit gets security fixes. Update with
`/plugin marketplace update shipkit`.

| Version | Supported |
| ------- | --------- |
| 1.x     | Yes       |
| < 1.0   | No        |

## Reporting a vulnerability

**Do not open a public issue for security problems.**

Report privately through GitHub:

1. Go to the [Security tab](https://github.com/parvez-ahammed/shipkit/security) of
   this repository.
2. Click **Report a vulnerability**.
3. Describe the problem, the affected skill, script or hook, and steps to reproduce.

Only the maintainers can see the report. You should get a first reply within 7 days. We
will keep you updated, agree a disclosure date with you, and credit you in the advisory
unless you ask us not to.

## What counts

ShipKit skills run inside Claude Code with your permissions, and some ship scripts and
git hooks. Relevant reports include:

- a skill, script or hook that can run unintended commands, or write or delete files
  outside the expected scope;
- a skill that leaks secrets, tokens or credentials (for example into logs, reports,
  commits or tickets);
- a bypass of the `secret-hygiene` pre-commit hook for a common secret format;
- unsafe defaults in generated deployment config (for example from `deploy-to-vps`);
- secrets or personal data committed to this repository.

Bugs in Claude Code itself should go to Anthropic, not here.
