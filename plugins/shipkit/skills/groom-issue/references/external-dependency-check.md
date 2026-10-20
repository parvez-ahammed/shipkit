# External paid dependency check (web pass)

Read when an issue depends on a third-party paid API or service (AI models, media generation,
speech, maps, payments, messaging, data feeds) or sets a price the user pays. Scores rubric dim 11.

The rest of the rubric checks the issue against the repo. This pass checks it against the outside
world, which the repo cannot answer. An issue will happily say "generate it with Provider X" with no
idea that X is not wired up, costs more per unit than the feature charges, or is not offered where
the project's users are.

**Use the live web** (a web search or fetch tool) against the vendor's own pricing and docs pages. Do
not price from memory; prices and tiers move. Every number gets a URL and an access date. If you have
no web access, mark each item `unverified - no web access` and do not score dim 11 above 1.

## Questions

1. **Provider decision.** Is a real provider chosen and wired, or does the issue name one or several
   aspirationally? If undecided, that is a declared blocker the issue must carry. List the candidate
   providers with short pros and cons so the owner can pick. Naming a swappable interface is good;
   leaving the vendor blank is not.
2. **Current price.** The live per-unit cost (per request, per 1k tokens or characters, per second of
   media, per image, per seat), cited with URL and date. If the feature is priced to users, map the
   unit cost to the user-facing price or credit cost so the margin is visible.
3. **Availability and data rules.** Is the service offered in the regions and to the kind of business
   the project serves? Data-residency, privacy-law (for example GDPR) or content-licensing constraints?
   A great provider that is unavailable where the users are is a blocker.
4. **Comparable products.** Which competing products ship this feature, what they charge, and what the
   user gets at that price. Prevents scoping or pricing blind to the market.
5. **Prerequisites.** Account, API key, billing setup, quota or model access: ready today, or a human
   action the owner must take first? One line each with `ready` / `not ready`.
6. **Usable after ship.** Once merged, can a real user use the feature end to end, or does it dead-end
   on an unconfigured vendor, a missing key or an unpriced action?
7. **Premise check.** Does the issue assume a capability or price that the vendor's docs contradict
   (for example a search API that only returns a subset of the data the issue expects)? If reality
   contradicts the premise, say so plainly. That is the sharpest finding this pass produces.

## Recording

In apply mode, record the result as the `External dependency (YYYY-MM-DD)` block in the issue body.
In score mode, put a one-line summary on the `External dependency:` line of the output record.
Unresolved provider or price choices become `OPEN QUESTION` callouts with a default, never a guess.
