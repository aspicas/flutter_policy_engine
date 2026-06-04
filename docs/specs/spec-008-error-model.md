# Spec-008: Error Model

## Context
See ADR-0003. This spec defines the exact failure types, their constructors, and the mapping rules
to `PolicyEngineException` at the public boundary.

## DomainFailure Hierarchy

```
DomainFailure (sealed)
├── PolicyNotFoundFailure      — no role/policy found for the given name
├── ResourceNotAllowedFailure  — role exists but resource not in allowed list
├── InvalidPolicyFailure       — malformed input (empty name, bad structure)
├── ParseFailure               — JSON/asset parsing error
├── StorageFailure             — I/O or serialization error in repository
├── EngineNotInitializedFailure — engine used before any policies are loaded
└── MissingAttributeFailure    — required ABAC attribute absent from subject/resource
```

Each failure carries:
- `message`: human-readable explanation.
- `cause` (optional): underlying exception if applicable.

## Result Type

```dart
sealed class Result<T, E> {
  const Result();
}
final class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);
  final T value;
}
final class Err<T, E> extends Result<T, E> {
  const Err(this.error);
  final E error;
}
```

Helper extensions:
- `result.isOk` / `result.isErr`
- `result.getOrElse(T fallback)` — returns value or fallback.
- `result.mapOk<R>(R Function(T) fn)` — transforms the ok value.

## PolicyEngineException (Public Boundary)

```dart
class PolicyEngineException implements Exception {
  final String message;
  final DomainFailure failure;
  final Object? cause;
}
```

`PolicyEngine` facade methods that do not return `Result` throw `PolicyEngineException`. Use cases
that return `Result<T, DomainFailure>` never throw.

## Mapping Rules
| DomainFailure | PolicyEngineException.message prefix |
|---------------|-------------------------------------|
| `PolicyNotFoundFailure` | `"Policy not found: ..."` |
| `ResourceNotAllowedFailure` | `"Access denied: ..."` |
| `InvalidPolicyFailure` | `"Invalid policy: ..."` |
| `ParseFailure` | `"Failed to parse policies: ..."` |
| `StorageFailure` | `"Storage error: ..."` |
| `EngineNotInitializedFailure` | `"Engine not initialized"` |
| `MissingAttributeFailure` | `"Missing attribute: ..."` |

## Acceptance Criteria
- [ ] `Result<T, E>` is defined in `domain/` with no dependencies.
- [ ] All seven `DomainFailure` subtypes exist and are sealed.
- [ ] `PolicyEngineException` is exported in the public barrel.
- [ ] Mapping from every `DomainFailure` to exception is tested.
- [ ] Covered by `test/domain/failures/domain_failure_test.dart`.
- [ ] Covered by `test/bdd/error_model_feature_test.dart`.
