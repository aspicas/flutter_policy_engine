# Spec-001: RBAC Evaluation

## Context
Role-Based Access Control assigns a set of allowed resources to each named role. An access check
succeeds when the subject's role exists in the policy store and the requested resource is in that
role's allowed list.

## Rules

1. A `Role` has a non-empty `name` and a list of `allowedResources`.
2. `RbacEvaluator.evaluate(roleName, resourceId)` returns `AccessDecision.granted` when:
   - A `Policy` containing a `Role` named `roleName` exists in the repository.
   - `resourceId` is present in `role.allowedResources`.
3. Returns `AccessDecision.denied(PolicyNotFoundFailure)` when no role with `roleName` exists.
4. Returns `AccessDecision.denied(ResourceNotAllowedFailure)` when the role exists but
   `resourceId` is not in `allowedResources`.
5. Resource matching is **case-sensitive** and **exact** (no glob/wildcard in v2.0).
6. An empty `allowedResources` list means the role has no permissions.
7. Evaluation is synchronous and has no side effects.

## Examples

```dart
// Granted
evaluate('admin', 'dashboard') // Role admin has 'dashboard' → granted

// Denied — wrong resource
evaluate('user', 'settings')   // Role user lacks 'settings' → denied

// Denied — unknown role
evaluate('ghost', 'anything')  // No such role → denied (PolicyNotFoundFailure)
```

## Edge Cases
- `roleName` empty string → `AccessDecision.denied(InvalidPolicyFailure)`.
- `resourceId` empty string → `AccessDecision.denied(InvalidPolicyFailure)`.
- Role with `allowedResources: []` → denied for every resource.
- Multiple roles with the same name → only the last written wins (repository semantics, spec-004).

## Acceptance Criteria
- [ ] `RbacEvaluator` is a pure Dart class with no Flutter imports.
- [ ] Returns `AccessDecision.granted` only for the exact conditions above.
- [ ] All edge cases return the correct `DomainFailure` subtype.
- [ ] Covered by `test/domain/evaluators/rbac_evaluator_test.dart`.
- [ ] Covered by `test/bdd/rbac_access_feature_test.dart`.
