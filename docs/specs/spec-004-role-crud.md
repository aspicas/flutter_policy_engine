# Spec-004: Role CRUD

## Context
Roles must be manageable at runtime without reinitializing the entire engine. Operations must
maintain repository consistency and propagate state changes to listeners.

## Rules

### AddRole
1. Adds a new `Role` to the repository.
2. If a role with the same name already exists it is **overwritten**.
3. Returns `Ok<void>` on success.
4. Returns `Err(InvalidPolicyFailure)` if role name is empty.

### UpdateRole
1. Replaces the role identified by `roleName` with new data.
2. Equivalent to `addRole` if `roleName` does not already exist.
3. Returns `Err(InvalidPolicyFailure)` if `roleName` is empty.

### RemoveRole
1. Removes the role named `roleName` from the repository.
2. No-op (returns `Ok<void>`) if the role does not exist.
3. Returns `Err(InvalidPolicyFailure)` if `roleName` is empty.

### ListRoles
1. Returns `Ok<List<Role>>` with all currently stored roles.
2. Returns an empty list when no roles are loaded.
3. The returned list is unmodifiable.

## Invariants
- Role names are unique keys; no two roles with the same name can coexist.
- All mutations are persisted to the repository immediately.
- After any mutation, `PolicyEngineController.notifyListeners()` is called.

## Edge Cases
- Adding a role while the engine is not initialized is permitted; initialization status refers only
  to whether the initial policy load has been performed.
- Unicode role names are valid.

## Acceptance Criteria
- [ ] `AddRole`, `UpdateRole`, `RemoveRole`, `ListRoles` are separate use case classes.
- [ ] Each returns `Result<T, DomainFailure>`.
- [ ] Empty name returns `InvalidPolicyFailure`.
- [ ] After mutation, repository reflects the change.
- [ ] Covered by `test/application/use_cases/*_role_test.dart`.
- [ ] Covered by `test/bdd/role_crud_feature_test.dart`.
