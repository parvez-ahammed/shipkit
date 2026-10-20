# Master linkage map

Symptom -> candidate refactoring(s) and/or candidate pattern(s) -> the reference file that
scores it. Use it to decide which file to open for a symptom. The pattern file always has
final say via its scored preconditions; this table only nominates candidates.

Covers all 22 smells in `smells.md` (plus Incomplete Library Class), and every refactoring
named here has an entry in `refactorings.md`. Keep the three in sync: if a smell or
refactoring is added to one, add its row here.

## Smell -> refactoring (fix the smell directly)

| Smell | Group | Candidate refactorings | File |
|-------|-------|------------------------|-------|
| Long Method | Bloater | Extract Method, Replace Temp with Query, Decompose Conditional | refactorings.md |
| Large Class | Bloater | Extract Class, Extract Subclass, Extract Interface | refactorings.md |
| Long Parameter List | Bloater | Introduce Parameter Object, Preserve Whole Object, Replace Parameter with Method Call | refactorings.md (+ patterns-behavioral.md if flag params select behavior: Strategy) |
| Primitive Obsession | Bloater | Replace Primitive with Object, Replace Type Code with Subclasses / State/Strategy | refactorings.md (+ patterns-behavioral.md when the type code drives behavior) |
| Data Clumps | Bloater | Extract Class, Introduce Parameter Object | refactorings.md |
| Switch Statements | OO-Abuser | Replace Conditional with Polymorphism, Replace Type Code with Subclasses | refactorings.md + patterns-creational.md / patterns-behavioral.md |
| Temporary Field | OO-Abuser | Extract Class, Introduce Null Object | refactorings.md |
| Refused Bequest | OO-Abuser | Replace Inheritance with Delegation, Push Down Method/Field | refactorings.md |
| Alternative Classes with Different Interfaces | OO-Abuser | Rename Method, Move Method, Extract Superclass | refactorings.md (+ patterns-structural.md: Adapter if a class cannot be changed) |
| Divergent Change | Change-Preventer | Extract Class (split responsibilities) | refactorings.md |
| Shotgun Surgery | Change-Preventer | Move Method/Field, Inline Class | refactorings.md |
| Parallel Inheritance Hierarchies | Change-Preventer | Move Method/Field to collapse hierarchies | refactorings.md |
| Comments (as deodorant) | Dispensable | Extract Method, Rename, Introduce Assertion | refactorings.md |
| Duplicate Code | Dispensable | Extract Method, Pull Up Method, Form Template Method | refactorings.md + patterns-behavioral.md |
| Dead Code | Dispensable | Delete; Inline | refactorings.md |
| Speculative Generality | Dispensable | Collapse Hierarchy, Inline Class, Remove Parameter | refactorings.md |
| Lazy Class | Dispensable | Inline Class, Collapse Hierarchy | refactorings.md |
| Data Class | Dispensable | Encapsulate Field/Collection, Remove Setting Method, Move Method | refactorings.md |
| Feature Envy | Coupler | Move Method, Extract Method | refactorings.md |
| Inappropriate Intimacy | Coupler | Move Method/Field, Change Bidirectional Association to Unidirectional, Replace Inheritance with Delegation | refactorings.md |
| Message Chains | Coupler | Hide Delegate, Extract Method | refactorings.md + patterns-structural.md (Facade) |
| Middle Man | Coupler | Remove Middle Man, Inline Method, Replace Delegation with Inheritance | refactorings.md (+ patterns-structural.md if the indirection is a deliberate Proxy/Decorator/Facade) |
| Incomplete Library Class | Other | Introduce Foreign Method / Local Extension | refactorings.md (+ patterns-structural.md: Adapter) |

## Symptom -> candidate design pattern (when refactoring alone is not enough)

### Creational (object construction)

| Symptom | Candidate pattern | File |
|---------|-------------------|-------|
| constructor arity high / telescoping ctors / many optional params | Builder | patterns-creational.md |
| `new ConcreteClass` scattered; subclass decides which type to make | Factory Method | patterns-creational.md |
| families of related objects must be created together and stay consistent | Abstract Factory | patterns-creational.md |
| object expensive to build, needs many similar copies | Prototype | patterns-creational.md |
| hand-rolled global single instance | Singleton (often anti; verify) | patterns-creational.md |

### Structural (object composition / interfaces)

| Symptom | Candidate pattern | File |
|---------|-------------------|-------|
| incompatible interface needs to fit an expected one | Adapter | patterns-structural.md |
| abstraction and implementation vary independently (combinatorial subclasses) | Bridge | patterns-structural.md |
| tree of part-whole objects treated uniformly | Composite | patterns-structural.md |
| add responsibilities to one object at runtime without subclass explosion | Decorator | patterns-structural.md |
| complex subsystem needs a simple entry point; Message Chains | Facade | patterns-structural.md |
| many similar objects blow memory; shared intrinsic state | Flyweight | patterns-structural.md |
| need to control / defer / guard access to an object | Proxy | patterns-structural.md |

### Behavioral (object interaction / responsibility)

| Symptom | Candidate pattern | File |
|---------|-------------------|-------|
| switch/if selecting interchangeable algorithms at runtime | Strategy | patterns-behavioral.md |
| object behavior changes with internal state; state-machine if/switch | State | patterns-behavioral.md |
| request needs to be queued, logged, undone, parameterized | Command | patterns-behavioral.md |
| one-to-many change notification / event subscription | Observer | patterns-behavioral.md |
| request handled by one of a chain of handlers | Chain of Responsibility | patterns-behavioral.md |
| algorithm skeleton fixed, steps vary by subclass; Duplicate Code in siblings | Template Method | patterns-behavioral.md |
| operation added across a class hierarchy without editing the classes | Visitor | patterns-behavioral.md |
| many objects communicate in a tangle (n-to-n) | Mediator | patterns-behavioral.md |
| traverse a collection without exposing its structure | Iterator | patterns-behavioral.md |
| capture and restore object state (undo) | Memento | patterns-behavioral.md |

## Disambiguation notes

- Strategy vs State: Strategy's variants are chosen by the client and rarely change each
  other; State's variants drive transitions between themselves. Distinguishing precondition:
  "do the variants decide the next variant?" yes -> State, no -> Strategy.
- Factory Method vs Abstract Factory: one product vs a family of related products.
- Decorator vs Proxy: Decorator adds behavior; Proxy controls access. Same shape, different
  intent.
- Adapter vs Facade: Adapter makes one interface fit a required one; Facade simplifies a
  whole subsystem.
- Template Method vs Strategy: inheritance with a fixed skeleton vs composition with injected
  variation; runtime choice or unwanted inheritance -> Strategy.
- Chain of Responsibility vs Decorator: may a link end the request? yes -> Chain.
- Observer vs Mediator: one-to-many notification vs centralized many-to-many coordination.
