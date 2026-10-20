# Margin math and the analysis checklist

Read when you reach Step 6. All examples use made-up numbers in a neutral currency unit (CU).

## Value metric

List candidate metrics (seats, usage units, projects, outcomes, spend managed). For each, answer:

1. Does it grow as the customer gets more value? (If not, customers resent paying more.)
2. Can the customer predict their bill? (Unpredictable bills slow buying.)
3. Does it track your cost? (If cost scales with usage but price scales with seats, heavy users
   erode margin.)
4. Is it hard to game? (Shared logins defeat seats; batching defeats per-call pricing.)

Show what each competitor uses, then argue for one.

## Price per outcome

`price per outcome = plan price / outcomes delivered per period`

Compare against every alternative, including the human one:
`human cost per outcome = hourly rate x hours per outcome` (cite the rate source or mark UNKNOWN).

## Gross margin per tier

```
variable cost at utilisation u = included units x u x cost per unit (+ per-seat variable costs)
gross margin at u = (price - payment fees - variable cost at u) / price
```

Compute at realistic u (measured if possible) and at u = 100%. Example: a tier at 50 CU with 1,000
included units costing 0.04 CU each and 3% fees: at 100% use, cost 40 + fees 1.5, margin 17%. At
40% use, cost 16, margin 65%. Flag any tier below the owner's target margin at 100%.

## Break-even utilisation

```
u_break_even = (price - payment fees) / (included units x cost per unit)
```

If u_break_even < 1, the tier loses money above that utilisation. Report it per tier.

## Expansion revenue

`in-plan unit rate = tier price / included units`. A top-up's unit rate should be at or above the
in-plan rate of the tier the buyer would otherwise upgrade to; otherwise top-ups cannibalise
upgrades.

## Annual discount

```
effective discount = 1 - (annual price / (monthly price x 12))
months free equivalent = 12 x effective discount
```

Check entitlement reset: an annual plan that grants 12 months of credits up front lets a customer
burn a year of cost in month one. Find what the code does.

## Grandfathering

If prices are live, state for existing customers: keep old price for how long, migrate on renewal,
or migrate with notice. Note any legal notice period the owner must confirm.

## Sensitivity

Vary the two inputs with the most uncertainty (usually utilisation and unit cost) by +/-50% and show
which tiers flip from safe to unsafe.
