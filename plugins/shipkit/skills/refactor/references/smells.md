# Code Smell Detector

Contents:
- How to scan
- Triage table (22 smells)
- Report shape
- References
- Evals

Scan the code the user points at and report smells with cited evidence. Do not edit code.
Each finding names the candidate fix (a refactoring, sometimes a design pattern); scoring a
pattern is a separate step with the `patterns-*.md` files.

## How to scan

1. Read only the files/dirs the user points at. No whole-repo review unless asked. Exception:
   to call something Dead Code, Lazy Class or Shotgun Surgery you must search the whole repo for
   its callers (`grep`/`rg` for the symbol). That search is evidence gathering, not a wider review;
   report only findings inside the target.
2. Walk the triage table below. For each smell, look for its signature.
3. A smell counts only with a concrete `file:line` you can cite. No citation, no finding.
4. Emit each finding in the unified report shape. Rank by severity (how much it blocks
   change), not by how many you can list.
5. If you find nothing, say the code is clean here. Never manufacture a smell.
6. **A bug is not a smell.** If you see code that gives a wrong result (an off-by-one, a dropped
   item, a missing auth check), report it first under a separate `BUGS` heading with `file:line`
   and how to reproduce it, and point to `fix-bug`. Do not file it as Long Method or Duplicate Code.

## Triage table (22 smells)

### Bloaters (code grown too large)

| Smell | Signature | Maps to |
|-------|-----------|---------|
| Long Method | function body long; many locals; nested blocks; needs comments to navigate | Extract Method, Replace Temp with Query (refactorings.md). See ${CLAUDE_SKILL_DIR}/references/smells-bloaters.md |
| Large Class | class with many fields/methods, multiple responsibilities | Extract Class / Subclass / Interface |
| Long Parameter List | 4+ params, or params that travel together | Introduce Parameter Object, Preserve Whole Object |
| Primitive Obsession | primitives standing in for concepts (string for money, int for status) | Replace Primitive with Object |
| Data Clumps | same group of fields/params recurring across the code | Extract Class, Introduce Parameter Object |

### Object-Orientation Abusers (OO used wrong)

| Smell | Signature | Maps to |
|-------|-----------|---------|
| Switch Statements | switch/if-else on a type code, repeated in several places | Replace Conditional with Polymorphism; State/Strategy (behavioral) |
| Temporary Field | field set only in some circumstances, null otherwise | Extract Class, Introduce Null Object |
| Refused Bequest | subclass uses little of its parent; overrides to no-op | Replace Inheritance with Delegation |
| Alternative Classes with Different Interfaces | two classes do the same job with different method names | Rename Method, Move Method, Extract Superclass |

### Change Preventers (one change forces many)

| Smell | Signature | Maps to |
|-------|-----------|---------|
| Divergent Change | one class changes for many unrelated reasons | Extract Class (split by reason to change) |
| Shotgun Surgery | one change forces edits scattered across many classes | Move Method/Field, Inline Class |
| Parallel Inheritance Hierarchies | making a subclass here forces a subclass there | Move Method/Field to collapse the duplication |

### Dispensables (things that add no value)

| Smell | Signature | Maps to |
|-------|-----------|---------|
| Comments (as deodorant) | comments explaining what bad code does | Extract Method, Rename, Introduce Assertion |
| Duplicate Code | same/near-same code in 2+ places | Extract Method, Pull Up Method, Form Template Method |
| Dead Code | unreachable or never-called code | Delete it |
| Speculative Generality | abstractions/hooks "for the future" with one user | Collapse Hierarchy, Inline Class, Remove Parameter |
| Lazy Class | class that does too little to justify itself | Inline Class, Collapse Hierarchy |
| Data Class | class with only fields + getters/setters; other classes hold its behavior | Encapsulate Field/Collection, Move Method (bring the behavior in) |

### Couplers (excessive coupling)

| Smell | Signature | Maps to |
|-------|-----------|---------|
| Feature Envy | method uses another object's data more than its own | Move Method (refactorings.md). See ${CLAUDE_SKILL_DIR}/references/smells-couplers.md |
| Inappropriate Intimacy | two classes reach into each other's internals | Move Method/Field, Replace Inheritance with Delegation |
| Message Chains | `a.getB().getC().getD()` | Hide Delegate; Facade (structural) |
| Middle Man | class that only delegates to another | Remove Middle Man, Inline |

Also check the one "other" smell refactoring.guru lists outside the five groups:
Incomplete Library Class (a library lacks a method you need, so call sites work around it)
-> Introduce Foreign Method / Introduce Local Extension (a wrapper or extension function).

## Report shape

```
TARGET: path/to/File.ext:Symbol
FINDING: <smell name> (<group>)
EVIDENCE: file:line - <what was seen>
VERDICT: APPLY | CONSIDER | REJECT   (severity of acting, not pattern-scoring; see below)
RECOMMENDATION: <candidate refactoring/pattern> - <one line>
NEXT: <next step, e.g. "score with patterns-creational.md" or "mechanics: Extract Method">
```

Verdict rubric for a smell (this is not the pattern score):

- **APPLY** - the smell blocks a change that is planned or likely (the code is edited often, a
  ticket touches it, a bug hides in it), and the fix is local and covered by tests or easy to cover.
- **CONSIDER** - the smell is real but the code is stable, or the fix crosses a public surface,
  or it needs tests that do not exist yet.
- **REJECT** - the signature matches but acting costs more than it saves: generated code, a
  framework-mandated shape, a one-off script, or code that is about to be deleted. Say why.

For Comments (as deodorant), set NEXT to `trim-comments` when the problem is the comments
themselves, and to `mechanics: Extract Method` or `Rename` when the comments hide bad code.

For smells whose fix is a design pattern, set NEXT to `score <pattern> with patterns-<family>.md`.
If you stop before scoring it, mark the pattern `unscored` in RECOMMENDATION, so the user knows
a fit was not tested.

## References

Only two groups have deep reference files; the other three (OO Abusers, Change Preventers,
Dispensables) are covered by the triage table above, which is enough to detect and route
them. The fix mechanics for every group are in `refactorings.md`.

- `${CLAUDE_SKILL_DIR}/references/smells-bloaters.md` - read when a Bloater is found and you need signs/fix detail
  (Long Method, Large Class, Long Parameter List, Primitive Obsession, Data Clumps).
- `${CLAUDE_SKILL_DIR}/references/smells-couplers.md` - read when a Coupler is found (Feature Envy, Inappropriate
  Intimacy, Message Chains, Middle Man); the costliest group in layered apps.

## Evals

- Input: a 120-line function with 8 locals and nested conditionals.
  Expected: Long Method finding, NEXT = mechanics: Extract Method.
- Input: `order.getCustomer().getAddress().getCountry().getCode()`.
  Expected: Message Chains finding, NEXT = score Facade with patterns-structural.md, or mechanics: Hide Delegate.
- Input: a 15-line single-purpose function, no duplication.
  Expected: no findings, "clean here". (Proves the detector does not manufacture smells.)
