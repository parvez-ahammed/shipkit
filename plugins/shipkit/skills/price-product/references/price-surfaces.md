# Finding price surfaces in a repo

Read when you reach Step 3. A surface is any place that states a price, a limit, a discount, a trial
length, a currency or a tax stance. Do not assume a folder layout; search the whole repo.

## Where surfaces usually live

| Surface | What to look for |
|---|---|
| Pricing / plans page | Routes or pages named pricing, plans, upgrade, billing; marketing site folders |
| Plan config | Files or constants named plans, tiers, entitlements, limits, features, pricing; JSON/YAML config; DB seed or migration data that inserts plans |
| Billing provider config | Stripe product and price ids (`prod_`, `price_`), Paddle, Lemon Squeezy, Chargebee, RevenueCat, app store product ids; webhook handlers that map provider ids to plans; IaC or scripts that create products |
| Checkout and upgrade UI | Plan cards, upgrade modals, paywalls, trial banners, "you have N left" messages |
| Limit enforcement | Code that checks quotas, seat counts, feature flags per plan |
| Emails | Templates for welcome, trial ending, receipt, renewal, upgrade, dunning |
| Docs and README | Docs site, FAQ, README, CHANGELOG entries announcing prices |
| SEO metadata | `<meta name="description">`, Open Graph text, JSON-LD `Offer` / `price` fields |
| Store listings | App store / marketplace listing text kept in the repo (fastlane, store metadata) |
| Legal | Terms of service, refund policy, licence files (especially for open-core) |
| Localisation | Translation files that hard-code prices or currency symbols |

## Search commands

Exploratory greps return non-zero when nothing matches; guard them with `|| true` so a batch of
commands does not abort. Exclude build output and dependencies.

Git Bash or any POSIX shell:

```bash
EXC='--exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build --exclude-dir=.next --exclude-dir=vendor --exclude-dir=bin --exclude-dir=obj'

# Currency amounts and price words
grep -rnE $EXC '[$€£¥][[:space:]]?[0-9]+([.,][0-9]{2})?|[0-9]+([.,][0-9]{2})?[[:space:]]?(USD|EUR|GBP|usd|eur|gbp)\b' . || true
grep -rniE $EXC '\b(per (month|year|seat|user)|/mo\b|/month|/yr|annual(ly)?|billed|free trial|money.back|refund)\b' . || true

# Discounts and tax stance
grep -rniE $EXC '([0-9]+ ?% ?off|months? free|discount|coupon|promo|(incl|excl)(uding|\.)? ?(vat|tax|gst)|plus (vat|tax))' . || true

# Plan and limit config
grep -rniE $EXC '\b(plans?|tiers?|entitlements?|quota|limits?|max_?(seats|users|projects|credits))\b' --include='*.json' --include='*.y*ml' --include='*.ts' --include='*.js' --include='*.py' --include='*.cs' --include='*.go' --include='*.rb' . || true

# Billing provider ids and SDKs
grep -rnE $EXC '\b(prod|price|plan)_[A-Za-z0-9]{8,}\b|stripe|paddle|lemonsqueezy|chargebee|revenuecat' . || true
```

PowerShell equivalent for a single pattern:

```powershell
Get-ChildItem -Recurse -File -Exclude *.min.js | Where-Object { $_.FullName -notmatch '\\(node_modules|\.git|dist|build|bin|obj)\\' } | Select-String -Pattern '(per month|/mo\b|billed|% off|months free)' -ErrorAction SilentlyContinue
```

## The billing provider

The provider decides what is actually charged, so read it, never write to it.

- If the provider config is in the repo (seed scripts, IaC, fixtures), read it there.
- If a CLI is installed and authenticated, list prices read-only (for Stripe: `stripe prices list
  --limit 100` and `stripe products list`). Ask before running it; it reads live account data.
- If neither is available, mark provider prices UNKNOWN and list the price ids found in code so the
  owner can check them in the dashboard.

## Building the surface table

One row per fact per surface:

| Fact | Value | Surface | Location |
|---|---|---|---|
| Pro monthly price | 29 USD | pricing page | `path/to/pricing-page:42` |
| Pro monthly price | 39 USD | billing provider | `price_...` (provider) |

Group by fact. Any fact with more than one distinct value is a contradiction; report it with every
location. Facts stated on only one surface are not errors but note them if a customer would expect
to see them elsewhere (e.g. tax stance missing at checkout).
