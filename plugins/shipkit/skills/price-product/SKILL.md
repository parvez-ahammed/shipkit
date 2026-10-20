---
name: price-product
description: >-
  Sets or reviews a software product's pricing: tiers, margin per tier, cited competitor prices, and
  an audit of every price surface in the repo, as an HTML report. Use for "how should we price this",
  "are we charging enough", "is this tier profitable", "is the margin too thin", "our pricing page
  contradicts Stripe". Not for pricing-page SEO (use boost-seo) or copy (use write-plainly).
argument-hint: "[product or repo | 'audit surfaces only' | competitor list]"
license: MIT
---

# price-product - prices with a cost beside every number

Price is the highest-leverage number in a product and the one most often set by copying a
competitor. This skill stops that: it interviews first, measures the cost of delivering the product
from the code that runs, researches competitors with citations, and only then proposes prices, each
with a margin check next to it.

Nothing here assumes a stack, a currency, a market or a billing provider. Find them in the repo.

**Iron Law:** never propose a price without the cost of delivering it. A pricing report without unit
cost is a wish list. If unit cost cannot be established, say so at the top of the report and label
every recommendation PROVISIONAL.

**Second law:** never invent a competitor price. Every figure carries a URL and an access date, or it
is marked UNKNOWN with a note of what to look up.

## When to use / not use

- Use when: setting first prices, repricing, adding or removing a tier, checking whether a tier loses
  money at full use, comparing against competitors, or checking that every place the product states
  a price agrees.
- Short form: "audit surfaces only" runs Step 3 alone and returns the contradiction list.
- Not for: SEO or search ranking of the pricing page (use `boost-seo`); general UX of the checkout
  flow (use `find-ux-gaps`); wording of the pricing copy (use `write-plainly` after the numbers are
  settled).

## Before you start

- Read the project's `CLAUDE.md` and docs index. They may name the billing provider, the currency and
  where plans are defined. Project rules override this file.
- Nothing outward without a yes. Do not change prices in a billing provider, push a pricing page
  change, or email customers. This skill produces a report and, if asked, a local diff.
- Label every claim: Verified (`file:line` or URL + date) / Assumed (say why) / UNKNOWN.

## Workflow

1. Interview the owner (blocking).
2. Identify the pricing model.
3. Find and audit every price surface.
4. Measure unit cost from the code.
5. Research competitors and the non-software alternative.
6. Analyse: value metric, price per outcome, margin safety, utilisation, expansion, annual, risks.
7. Recommend, with numbers.
8. Write the report.

### 1. Interview the owner (do not skip)

Ask before any research, batching related questions. The answers change the shape of the whole
report, and guessing them wastes the research pass.

1. **Who is the customer?** Solo user, small business, agency, enterprise buyer, developer. This sets
   the willingness-to-pay anchor more than anything else.
2. **Positioning: premium, parity or penetration?** If premium, argue from value against the
   customer's alternative, not from competitor prices. Do not quietly undercut a competitor when the
   owner said premium.
3. **What would the customer buy instead?** A freelancer, an agency, an in-house hire, a cheaper
   tool, a spreadsheet, or nothing. This is the real anchor.
4. **Current state?** Live prices, a draft, or nothing. Live prices mean existing customers and a
   grandfathering plan.
5. **Currency, and are listed prices tax-inclusive or exclusive?** Ask explicitly. Tax is a
   double-digit share of revenue and is often stated inconsistently across surfaces, which can be a
   consumer-law problem.
6. **What must not change?** Signed contracts, a published price, a partner deal, a free tier
   promise.
7. **Is there a hard cost floor?** Pass-through costs that scale with usage, not revenue: model
   inference, per-minute media, per-message SMS, storage, per-seat third-party licences.

If the owner cannot answer question 3, record that as a finding: the product is probably positioned
against tools rather than against the job.

### 2. Identify the pricing model

Name which model the product uses or should use: seat-based SaaS, usage or credits, one-time
licence (with or without paid updates), open-core (free core plus paid features or hosting), or a
hybrid. Each has its own margin math and its own typical traps. Read
`${CLAUDE_SKILL_DIR}/references/pricing-models.md` when you reach this step.

### 3. Find and audit every price surface

Every place that states a price, a limit, a discount, a trial length or a tax stance is a surface,
and surfaces that restate the same fact drift apart. Find all of them, not just the pricing page:
marketing pages, plan config, the billing provider's products and prices, checkout and upgrade UI,
in-app limit messages, transactional emails, docs, README, meta descriptions and structured data,
app store listings, terms of service. Read `${CLAUDE_SKILL_DIR}/references/price-surfaces.md` for
where to look and the search commands.

Build one table: fact (e.g. "Pro monthly price"), value, surface, `file:line` or provider id. Every
row where the same fact has two values is a contradiction. Also check:

- **Discount arithmetic.** "20% off annual" and "2 months free" are different claims: 20% of 12
  months is 2.4 months. Compute the real figure from the price data.
- **Limits match enforcement.** A plan that says "5 projects" must be enforced as 5 in the code that
  checks it, not 3 and not unlimited.
- **The provider is the source of truth for what is charged.** If the page says 29 and the provider
  price object says 39, the customer pays 39.

### 4. Measure unit cost from the code

Do not trust config comments, a changelog or a spreadsheet. Read what executes.

- **Find every paid external call** in the request path (APIs, inference, media, email, SMS,
  storage, egress). Note the endpoint or model and whether the path that runs matches the one the
  pricing config assumes.
- **Priced but never built.** Cost constants for a provider that throws, is stubbed or was never
  wired up make the ledger record cost that was never incurred, so every margin figure built on it
  is wrong, sometimes inverted. Cross-check each cost constant against the factory or registry that
  instantiates providers.
- **Paid options must change behaviour.** If a higher tier or a "quality" flag charges more, trace it
  to the call site and confirm it reaches the provider. Charging more for the same operation is a
  margin illusion and a refund risk.
- **Fixed vs variable.** Separate per-unit cost (scales with usage) from fixed cost (hosting floor,
  support). Margin per tier uses variable cost; break-even uses both.

If any cost cannot be measured, mark it UNKNOWN, give the range you would need, and carry the gap
into the report.

### 5. Research competitors with citations

For each competitor: tier names, price, what the price includes (seats, credits, usage, limits),
annual discount, and the implied cost per unit of what the customer actually wants.

- Cite every figure with a URL and an access date (YYYY-MM-DD).
- **If web search or fetch is unavailable, or a page is blocked (JS wall, 403, "contact sales"),
  mark the figure UNKNOWN.** Do not estimate, recall from memory or round a guess into a number.
  Instead list exactly what the owner should look up: competitor, page URL if known, which tier,
  which field.
- Include the non-software alternative (freelancer, agency, in-house hire, manual process). For
  premium positioning this is the anchor that matters.
- Prices change. Note that every figure is as of its access date.

### 6. Analyse what a naive report leaves out

Read `${CLAUDE_SKILL_DIR}/references/margin-math.md` for the formulas and worked shapes. Cover each:
value metric (argue for one; a wrong metric caps the business more than a wrong number), price per
outcome against every alternative including the human one, gross margin per tier at realistic and at
full utilisation (name every tier that loses money at full use), break-even utilisation (say if
utilisation is assumed, not measured), expansion revenue, annual discount, grandfathering if prices
are live, and risks (provider price rises, a competitor bundling the feature free, churn at renewal).

### 7. Recommend, with numbers

Commit to a structure: named tiers, prices, what each includes, and the margin check beside each. A
report that lists considerations without choosing is not finished. Say which recommendations are
firm and which depend on an UNKNOWN, and what would change them.

### 8. Write the report

A standalone HTML file the owner can open from disk, unless they ask for something else. Save it
where the project keeps notes (ask if there is no such place). Read
`${CLAUDE_SKILL_DIR}/references/html-output.md` for the required sections and chart rules.

## Output shape

1. The HTML report (path stated).
2. A chat summary of at most 10 lines: the recommended tiers and prices, unsafe tiers, the number of
   surface contradictions, and the UNKNOWNs the owner must resolve.
3. If asked to fix surface contradictions: a local diff only, shown before any commit. Never change
   prices in a billing provider dashboard or API.

## Common mistakes

| If you wrote | Reconsider |
|---|---|
| A price with no unit cost beside it | You are guessing. Measure it or label it PROVISIONAL. |
| "Competitive pricing" as the rationale | That is copying. What is the value anchor? |
| A tier with unlimited anything | Compute its cost at full use. Usually negative. |
| Usage tier priced without a hard cap or overage | Decide what happens at the limit. |
