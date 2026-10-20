# Pricing models: margin math and traps per model

Read when you reach Step 2. Identify the model the product uses (or should use), then apply its
checks on top of the general workflow.

## Seat-based SaaS

Price scales with the number of users.

- **Margin math:** revenue per seat minus variable cost per active seat (compute, storage, any
  per-seat third-party licence). Fixed cost is spread over all seats for break-even.
- **Traps:**
  - Seat price fits collaboration tools but punishes products where value comes from one power user;
    customers share logins.
  - Heavy users on a flat seat price can cost more than the seat if any per-use cost exists. Compute
    cost for the 95th-percentile user, not the average.
  - Minimum seat counts on a tier must match what checkout actually enforces.
  - Seat changes mid-cycle: is proration on or off in the billing config, and does the UI say so?

## Usage or credits

Price scales with consumption: API calls, minutes, tokens, credits, GB.

- **Margin math:** price per unit minus cost per unit. If one credit maps to several operations with
  different costs, compute margin per operation, not per credit. The cheapest-to-serve operation
  hides the most expensive one.
- **Traps:**
  - Credit-to-cost mapping drifts when a provider changes price; note where the mapping lives.
  - Included allowances: margin at 100% use, not at typical use.
  - Rollover vs reset: what the code does must match what the page promises.
  - Top-ups cheaper per unit than in-plan credits cannibalise upgrades.
  - No hard cap and no overage price means unbounded cost. Decide the behaviour at the limit.
  - Free trial credits are a cost; count them as acquisition spend.

## One-time licence

Customer pays once, optionally for a version or a period of updates.

- **Margin math:** price minus payment fees minus the lifetime cost of support and any hosted
  component. Anything hosted (sync, licence server, updates CDN) is a recurring cost against
  one-off revenue.
- **Traps:**
  - "Lifetime" deals with a hosted component lose money over time. Compute years-to-loss.
  - Update policy (major versions paid? 1 year of updates?) must be stated identically on the page,
    in the licence text and in the app's update check.
  - Volume and education discounts stack unexpectedly; check the coupon config.

## Open-core

Free core (often open source) plus paid features, support or hosted service.

- **Margin math:** paid tier revenue against the cost of the hosted offering plus the support load
  the free tier generates. The free tier is a marketing cost; size it honestly.
- **Traps:**
  - The paid/free boundary is the product decision. Features a single user needs belong in free;
    features a team or company needs (SSO, audit log, roles, SLA) are the usual paid line.
  - Licence text, README, docs and the pricing page must agree on what is free.
  - A self-host option undercuts a hosted tier priced only on convenience; price the hosted tier on
    operations saved, not on features.

## Hybrid

Seat base fee plus usage, or platform fee plus credits. Run the checks for every component, then
check the combination: a customer at the cheapest seat count with maximum usage is the worst case.
