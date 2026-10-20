# Scored-precondition format (shared schema)

Every pattern entry (and every refactoring entry) in the `patterns-*.md` files uses this fixed
shape. It is the mechanism that turns "should I apply this pattern" from taste into a
checkable decision.

```markdown
### <Pattern or Refactoring name>
intent: <one line: what it accomplishes>

opportunity signatures (what to grep for in code):
  - <structural signal the smell sweep can find>
  - <another signal>

preconditions (scored, weight in []):
  [3] <strong signal that this is a genuine fit>
  [2] <supporting signal>
  [1] <weak / corroborating signal>
threshold: >= N   (anchor: the default is at least one [3] or two [2]; an entry may set a stricter anchor)

anti-indicators (any present -> hard veto, REJECT):
  - <condition under which the pattern is wrong here>

cost: <complexity the pattern adds: indirection, classes, ceremony>
language notes: <cases where a language idiom makes it redundant -> downgrade>
evidence required: cite file:line for each matched precondition.
verdict: APPLY | CONSIDER | REJECT  + one-line why
```

## Scoring rules

1. Match each precondition against the code. A precondition counts only if you can cite a
   concrete `file:line` as evidence. Unsupported preconditions score 0.
2. Sum the weights of the matched preconditions.
3. Check anti-indicators first. If any anti-indicator is present, the verdict is REJECT,
   regardless of score. The veto is absolute.
4. Otherwise:
   - score >= threshold AND the anchor rule is met -> APPLY. The anchor is the one written on the
     entry's `threshold:` line (for example "the [3] is mandatory"). Only when an entry states no
     anchor does the default apply: at least one [3], or two [2].
   - score close to threshold but missing the anchor, OR cost outweighs the problem on
     small/stable code -> CONSIDER (with a YAGNI note).
   - score below that -> REJECT.
5. Apply language notes last: if the target language makes the pattern redundant (e.g. a
   module-level singleton, a built-in iterator protocol, plain functions passed as values standing in
   for a one-method Strategy), downgrade one verdict step and say why. "One step" means
   APPLY -> CONSIDER and CONSIDER -> REJECT; a REJECT stays REJECT. The verdict is always about
   the **class-based pattern**; the idiom goes in RECOMMENDATION. Example: a type switch picking
   one of three pricing functions scores Strategy 7/5, the language note fires, so the verdict is
   `CONSIDER (7/5, downgraded: functions as values)` and RECOMMENDATION is "a lookup table of
   functions keyed by type". Never print APPLY next to a recommendation that is not the pattern.

The VERDICT line always shows the arithmetic: `(score N / threshold M)`, plus `vetoed: <anti-indicator>`
or `downgraded: <language note>` when either fired.

## Why each rule exists

- Evidence requirement kills hallucinated fit: you cannot claim a precondition you cannot
  point at.
- Hard veto stops pattern-for-pattern's-sake: a tempting score never overrides a structural
  reason the pattern is wrong.
- Three verdicts (not two) preserve the honest middle: "plausible but not yet worth it".
- Language notes keep the advice idiomatic instead of dogmatically OO.
