# Smell to cut

Read when triaging finder output. For each smell: where to start looking, the cut, and the safe
mechanic (`refactor` has step-by-step mechanics for each name). Searches are starting
points, not proof; read the code and cite `file:line` before cutting.

## Dispensables (first: highest value, lowest risk)

| Smell | Starting point | Cut | Mechanic |
|-------|----------------|-----|----------|
| Unused export / function | compiler or linter unused warnings; search the symbol repo-wide | Delete it and its tests | Remove Dead Code |
| Unreachable branch | guards for states the type system or boundary validation already forbids | Delete the branch | Remove Dead Code |
| Speculative generality | interface, abstract class or generic with one implementation and no DI role | Inline to the concrete type | Collapse Hierarchy / Inline Class |
| Needless try/catch | handlers that only rethrow, where a global handler exists | Delete; let the global handler catch | Remove the wrapper |
| Restating comments | comment above a self-explaining line | Delete (or run `trim-comments`) | Rename instead of commenting |

## Bloaters

| Smell | Starting point | Cut | Mechanic |
|-------|----------------|-----|----------|
| Long function / component | over ~40 lines doing more than one thing | Extract cohesive steps, or collapse a loop to a pipeline | Extract Method / Replace Loop with Pipeline |
| Long parameter list | 4+ positional params | Typed parameter object or an existing DTO | Introduce Parameter Object |
| Primitive obsession | bare strings / numbers that carry rules | Use the type that already models it | Replace Primitive with Object |
| Data clumps | same fields passed together everywhere | One object | Introduce Parameter Object |

## Couplers and duplication

| Smell | Starting point | Cut | Mechanic |
|-------|----------------|-----|----------|
| Duplicate code, same file | repeated block | Extract a private function | Extract Method |
| Duplicate code, across modules | same body in sibling modules | One owning home that others call, or a shared utility if pure | Extract + Move Method / Pull Up Method |
| Feature envy | function using another object's data more than its own | Move it to the owner | Move Method |
| Message chains | `a.b().c().d()` | Hide the walk behind one call | Hide Delegate |
| Middle man | a class that only forwards calls | Call the real object | Remove Middle Man |

## Hand-rolled vs platform

| Hand-rolled | Usually replaced by |
|-------------|---------------------|
| Manual dedupe / group / index loops | Set, Map / dict, group-by helpers, comprehensions, reduce |
| Manual deep copy | the language's structured clone / copy facility |
| Manual null-walk | optional chaining, null-coalescing, `Option` / `Maybe` helpers |
| Filtering, paging or counting in memory after a broad fetch | the ORM or query: where / select / include / count / limit / offset |
| Re-validating already-validated input | trust the boundary validator; do not double-guard |
| Bespoke response or error shaping | the project's shared response or error helper |
| Custom retry / debounce / date math | the library the project already depends on |

## Efficiency (only when the result is provably identical)

| Smell | Starting point | Cut | Check |
|-------|----------------|-----|-------|
| N+1 | a query or remote call awaited inside a loop over rows | One batched query (`IN (...)`, include / join), then index in memory | Same rows, same order, same not-found behavior |
| Duplicate fetch | same lookup twice in one request path | Fetch once, pass it down | No write in between that changes the record |
| Serial awaits | independent awaits in sequence | Run concurrently (`Promise.all`, `asyncio.gather`, `Task.WhenAll`, errgroup) | Truly independent: no write ordering, same error behavior |
| Recompute in scope | value derived again that is already bound | Reuse the binding | Not a deliberate refresh |
| Repeated render work | expensive derivation on every UI render | Memoize or hoist | Same output, inputs listed correctly |

No covering test and no characterization test added in the same change: defer and flag.

## Wrong layer (fix by relocating, not deleting)

| Smell | Starting point | Cut |
|-------|----------------|-----|
| Transport or UI doing data work | query assembly in a controller, handler or component | Move to the service, repository, hook or store that owns it |
| Business logic touching transport | request / response / headers / status in a service | Keep transport at the edge; pass plain values in |
| Format validation in the wrong place | shape or format checks on route params inside a service | Move the format check to the route or form boundary; ownership and authorization stay in the service |
| Comment at the wrong altitude | a comment narrating how a line works | Delete, or lift to a why one level up |

Relocate only within the target slice and only where gates cover both sides; otherwise defer.

## When a cut needs an abstraction

Only when cross-module duplication is real and the abstraction is scored (for example with
`refactor`):

- Same skeleton, varying step -> template method or a function that takes the varying step.
- Interchangeable algorithm chosen at runtime -> strategy (often just a map of functions).
- Two incompatible interfaces that should be one -> adapter.
- The same cluster of calls into one subsystem everywhere -> facade.

A weak or rejected score means leave the duplication. A wrong abstraction couples modules that
should stay apart and costs more than the copy.
