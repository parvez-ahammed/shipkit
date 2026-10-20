# HTML output: file rules, sections, charts

Read when you reach Step 8.

## File rules

- One complete HTML document: doctype, `html`, `head` with charset and viewport, `body`. It must
  render from `file://` with no server.
- Self-contained: no external JavaScript. A web font via `<link>` is fine. Draw charts as inline
  SVG you generate; do not pull in a chart library for a handful of charts.
- Light and dark: define the full palette as tokens on bare `:root`, redefine them under
  `@media (prefers-color-scheme: dark)` guarded as `:root:not([data-theme="light"])`, and again under
  `:root[data-theme="dark"]`. Give `body` an explicit background.
- Works down to about 400px wide. Put each table in its own `overflow-x: auto` container.

## Sections, in order

1. **Summary.** Recommended tiers and prices, firm vs PROVISIONAL, the top 3 risks. If unit cost was
   not established, say so here first.
2. **Owner inputs.** The interview answers, verbatim where possible.
3. **Pricing model.** Which model and why.
4. **Price surface audit.** The surface table and every contradiction with its locations.
5. **Unit cost.** Each paid call, its cost, where it was verified, and any priced-but-unbuilt or
   paid-option-does-nothing findings.
6. **Competitors.** One table: competitor, tier, price, includes, annual discount, cost per unit,
   source URL, access date. UNKNOWN cells stay UNKNOWN. Then a "to look up" list for every UNKNOWN.
7. **Analysis.** Value metric, price per outcome, margin per tier at realistic and full use,
   break-even utilisation, expansion, annual discount, grandfathering, risks.
8. **Recommendation.** Tiers, prices, inclusions, margin beside each.
9. **Assumptions.** Numbered, each justified, each saying what would change the conclusion if wrong.
10. **Sources.** Every URL with its access date.

## Charts

Charts must carry an argument, not decorate. Usual set:

- Competitor price positioning (only competitors with verified prices; note omitted UNKNOWNs).
- Price per outcome, including the human alternative.
- Tier value ladder (price vs what is included).
- Proposed price against unit cost per tier, at realistic and full utilisation.

Label every axis with real units. Keep marks and labels inside the viewBox. Never plot an UNKNOWN
as a number.
