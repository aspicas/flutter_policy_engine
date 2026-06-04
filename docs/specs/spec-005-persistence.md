# Spec-005: Persistence

## Context
The engine needs at least two storage backends: a fast in-memory store for testing and ephemeral
use, and a `SharedPreferences`-backed persistent store for production.

## InMemoryPolicyRepository

1. Stores roles in a `Map<String, Policy>` within the object's lifetime.
2. `save`, `load`, and `clear` are all synchronous in behavior (return completed futures).
3. `load` returns a deep copy — external mutations do not affect stored data.
4. Data is lost when the object is garbage collected.
5. Safe for use in unit tests.

## SharedPreferencesPolicyRepository

1. Persists policies as a JSON-encoded string under the key `flutter_policy_engine_policies`.
2. `save(policies)` serializes with `PolicyJsonCodec.encode` and writes to SharedPreferences.
3. `load()` reads from SharedPreferences, deserializes with `PolicyJsonCodec.decode`.
4. `clear()` removes the key from SharedPreferences.
5. Returns `StorageFailure` on read/write errors.
6. If the stored value cannot be parsed (corrupted data), `load()` returns `StorageFailure` and
   does not crash.

## Contract (applies to all implementations)
- `save` followed by `load` returns equivalent data.
- `clear` followed by `load` returns an empty map.
- Concurrent `save` calls are not explicitly ordered; last-write wins.

## Acceptance Criteria
- [ ] Both implementations pass `test/contract/policy_repository_contract.dart`.
- [ ] `InMemoryPolicyRepository` has no Flutter imports.
- [ ] `SharedPreferencesPolicyRepository` uses `shared_preferences` package.
- [ ] Covered by `test/infrastructure/storage/*_test.dart`.
- [ ] Covered by `test/bdd/persistence_feature_test.dart`.
