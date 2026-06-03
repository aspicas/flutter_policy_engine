# ADR-0003: Error Model — Result + DomainFailure

## Status
Accepted

## Date
2026-06-03

## Context
v1 used a mix of patterns:
- `PolicySDKException` (thrown, caught) for most failures.
- `PolicyNotInitializedException` defined but never thrown.
- `hasAccess` returning `false` silently on uninitialized state.
- Internal exceptions (`JsonParseException`, `JsonSerializeException`) leaking through the boundary.

This made it impossible to distinguish an intentional "access denied" from an operational failure
without inspecting the boolean return combined with log output.

## Decision

### Domain layer — no exceptions, use `Result`
All domain operations return `Result<T, DomainFailure>` where:

```dart
sealed class Result<T, E> { ... }
final class Ok<T, E> extends Result<T, E> { final T value; }
final class Err<T, E> extends Result<T, E> { final E error; }
```

`DomainFailure` is a sealed class:

```dart
sealed class DomainFailure { ... }
final class PolicyNotFoundFailure extends DomainFailure { ... }
final class InvalidPolicyFailure extends DomainFailure { ... }
final class StorageFailure extends DomainFailure { ... }
final class ParseFailure extends DomainFailure { ... }
final class EngineNotInitializedFailure extends DomainFailure { ... }
final class MissingAttributeFailure extends DomainFailure { ... }
```

This makes failure cases explicit, exhaustive (via `switch`), and eliminates silent booleans.

### Application/Infrastructure boundary — `PolicyEngineException`
The `PolicyEngine` facade unwraps `Result` at the public boundary and throws
`PolicyEngineException` (a single exported exception type) on `Err` when the caller is not
expected to handle all failure cases inline. Use cases expose `Result` directly for callers that
prefer functional error handling.

### Widget layer
`PolicyGate` and `PolicyBuilder` receive an `AccessDecision` (which is a domain value object, not a
bool) that carries the reason for denial. They never throw.

## Consequences
- **Positive**: Callers can exhaustively match on failure types using Dart's `switch` on sealed
  classes.
- **Positive**: `EngineNotInitializedFailure` is now propagated explicitly instead of silently
  returning `false`.
- **Positive**: Widget layer never crashes on access check; it always receives a typed decision.
- **Negative**: Callers adopting functional style need to learn `Result`. Mitigated by the facade
  throwing `PolicyEngineException` for callers who prefer imperative style.
