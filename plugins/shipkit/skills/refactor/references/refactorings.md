# Refactoring Methods

Contents:
- Catalog
- References
- Output
- Evals

The safe mechanics to apply a refactoring once a smell is known. Do not edit the working
tree; produce the ordered steps and the safety check between them. Refactoring changes
structure without changing behavior, so every sequence rests on one rule:

SAFETY RULE: run the tests (or the tightest available check) after each small step. If a
step has no test covering it, add one before refactoring. Never batch multiple structural
changes between test runs.

## Catalog

Each entry: smell it fixes -> one-line mechanic. Deep entries (preconditions, ordered
mechanics, risk) are bundled only for the two groups marked with a reference file below. For
every other entry, expand the one-line mechanic into small steps yourself, each followed by
a test run per the SAFETY RULE, and state the preconditions you checked. Preconditions
decide whether the refactoring is the right move; mechanics decide how. (This is the same
scored-precondition idea the pattern files use, applied lightly; the full schema is in
`${CLAUDE_SKILL_DIR}/references/verdict-format.md`.)

### Composing methods (most common; see ${CLAUDE_SKILL_DIR}/references/refactorings-composing-methods.md)

| Refactoring | Fixes | One-line mechanic |
|-------------|-------|-------------------|
| Extract Method | Long Method, Duplicate Code, Comments | name a coherent block, move it to its own method, pass needed locals |
| Inline Method | Middle Man, indirection with no value | replace calls with the body, delete the method |
| Extract Variable | complex expression | name a subexpression with an explaining local |
| Inline Temp | temp that just holds one expression | replace the temp with the expression |
| Replace Temp with Query | Long Method blocked by locals | turn a temp into a method so it can be reused and extracted |
| Split Temporary Variable | a temp reused for two purposes | one temp per responsibility |
| Replace Method with Method Object | locals too tangled to extract | move the method into its own class where locals become fields |

### Moving features between objects

| Refactoring | Fixes | One-line mechanic |
|-------------|-------|-------------------|
| Move Method | Feature Envy, Inappropriate Intimacy | move the method to the class whose data it uses most |
| Move Field | Inappropriate Intimacy | move the field to the class that uses it most |
| Extract Class | Large Class, Divergent Change, Data Clumps | pull a cohesive subset of fields+methods into a new class |
| Inline Class | Lazy Class, Speculative Generality | fold a too-small class back into its only user |
| Hide Delegate | Message Chains | expose a method on the server that hides the delegate chain |
| Remove Middle Man | Middle Man | let the client talk to the delegate directly |
| Introduce Foreign Method / Local Extension | Incomplete Library Class | add the missing behavior in a client-side helper or wrapper/extension |
| Extract Function + Move Function (cross-module) | Duplicate Code in two unrelated modules | pin both copies with characterization tests, extract one copy into a shared module, point each caller at it one at a time, delete the other copy last |

### Organizing data

| Refactoring | Fixes | One-line mechanic |
|-------------|-------|-------------------|
| Replace Primitive with Object | Primitive Obsession | give the concept a small type that owns its validation/behavior |
| Replace Type Code with Subclasses | Switch Statements on a type code | one subclass per type-code value |
| Replace Type Code with State/Strategy | type code that drives behavior + changes | score with patterns-behavioral.md State/Strategy |
| Introduce Parameter Object | Long Parameter List, Data Clumps | group co-traveling params into one object |
| Preserve Whole Object | Long Parameter List | pass the source object instead of values pulled from it |
| Encapsulate Field / Encapsulate Collection | Data Class | make fields private behind accessors; return read-only views of collections |
| Change Bidirectional Association to Unidirectional | Inappropriate Intimacy | drop the back-reference the other side does not need |

### Simplifying conditionals (see ${CLAUDE_SKILL_DIR}/references/refactorings-simplifying-conditionals.md)

| Refactoring | Fixes | One-line mechanic |
|-------------|-------|-------------------|
| Decompose Conditional | complex if/else | extract condition, then-branch, else-branch into named methods |
| Consolidate Conditional Expression | several checks, same result | combine into one named check |
| Replace Nested Conditional with Guard Clauses | deep nesting | return early on edge cases, leave the main path flat |
| Replace Conditional with Polymorphism | Switch Statements on type | one subclass per branch, override the varying method |
| Introduce Null Object | repeated null checks | a do-nothing object replaces null |
| Introduce Assertion | Comments stating an assumption | turn the assumption into an assert that fails loudly |

### Simplifying method calls

| Refactoring | Fixes | One-line mechanic |
|-------------|-------|-------------------|
| Rename Method | unclear name; Comments | name says what, not how |
| Add/Remove Parameter | wrong method interface | adjust signature, update callers |
| Separate Query from Modifier | a method that returns and mutates | split into a pure query and a command |
| Replace Parameter with Method Call | Long Parameter List | let the callee derive the value itself |
| Parameterize Method | near-duplicate methods differing by a value | one method taking that value |
| Remove Setting Method | Data Class, field that should not change after creation | set it in the constructor only, delete the setter |

### Dealing with generalization

| Refactoring | Fixes | One-line mechanic |
|-------------|-------|-------------------|
| Pull Up Method / Pull Up Field | Duplicate Code in sibling subclasses | move the identical member into the superclass |
| Push Down Method / Field | Refused Bequest (member used by one subclass) | move it into the subclass that uses it |
| Extract Superclass | Duplicate Code, Alternative Classes with Different Interfaces | create a shared parent, pull common members up |
| Extract Subclass | Large Class with features used only in some cases | move the conditional features into a subclass |
| Extract Interface | Large Class, several clients using the same subset | declare the subset as an interface |
| Collapse Hierarchy | Lazy Class, Speculative Generality | merge a subclass that adds nothing into its parent |
| Form Template Method | Duplicate Code with the same step order | pull the skeleton up, leave varying steps as overrides; score with patterns-behavioral.md Template Method vs Strategy |
| Replace Inheritance with Delegation | Refused Bequest, Inappropriate Intimacy with a parent | hold the former parent as a field and forward only what is used |
| Replace Delegation with Inheritance | Middle Man forwarding everything to one delegate | inherit instead, when the subclass truly is-a delegate |

Dead Code has no mechanic beyond "delete it": confirm no callers (search, reflection,
config, public API), delete, run tests.

## References

- `${CLAUDE_SKILL_DIR}/references/refactorings-composing-methods.md` - read when giving mechanics for Extract Method,
  Replace Temp with Query, or Replace Method with Method Object.
- `${CLAUDE_SKILL_DIR}/references/refactorings-simplifying-conditionals.md` - read when giving mechanics for Decompose
  Conditional, Guard Clauses, Replace Conditional with Polymorphism, or Introduce Null Object.

## Output

For one refactoring, emit the block below. For a plan that chains several (for example Extract
Method, then Move Method, then delete the dead copy), emit one block per refactoring in the order
they run, numbered `STEP 1 of N`, and start with a `CHARACTERIZATION TESTS` list: the tests to
write first that pin current behavior, including any bug you are deliberately preserving.

```
REFACTORING: <name>
WHY HERE: <the smell + cited file:line>
PRECONDITIONS MET: <which, with evidence> | BLOCKED BY: <missing precondition, if any>
MECHANICS:
  1. <step>            (run check)
  2. <step>            (run check)
  ...
RISK: <what can silently break> + the mitigating check
```

If preconditions are not met, say so and recommend the prerequisite refactoring first (e.g.
Extract Method before Move Method when only part of a method envies another class).

This skill does not edit the user's working tree. If the user wants proof that the plan holds,
dry-run it in a throwaway copy (a scratch folder or a separate git worktree), run the tests after
each step, report the results, and delete the copy.

## Evals

- Input: Long Method with a self-contained 12-line block.
  Expected: Extract Method, mechanics list, "run tests after extraction".
- Input: a 3-level nested conditional guarding edge cases.
  Expected: Replace Nested Conditional with Guard Clauses.
- Input: a method that both saves and returns a value, used in a query context.
  Expected: Separate Query from Modifier (proves it catches command/query mixing).
