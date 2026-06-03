# Spec-002: ABAC Evaluation

## Context
Attribute-Based Access Control makes access decisions based on attributes attached to the
requesting subject and the target resource, rather than role membership alone.

## Rules

1. A `Subject` carries an `AttributeSet` — an unordered map of `String → String`.
2. A `Resource` carries an `AttributeSet` as well.
3. An `AbacPolicy` defines a list of `AttributeRule`s. Each rule specifies:
   - `subjectAttribute`: key that must exist on the subject.
   - `expectedValue`: the value it must equal (exact match).
   - `resourceAttribute` (optional): key that must match on the resource.
4. `AbacEvaluator.evaluate(subject, resource, policy)` returns `AccessDecision.granted` when **all**
   rules in the policy are satisfied.
5. If any single rule is not satisfied, returns `AccessDecision.denied(MissingAttributeFailure)`.
6. A policy with zero rules grants access to everyone (open policy).
7. Attribute matching is case-sensitive.

## Examples

```dart
final subject = Subject(attributes: {'role': 'admin', 'region': 'eu'});
final resource = Resource(id: 'report-eu', attributes: {'region': 'eu'});
final policy = AbacPolicy(rules: [
  AttributeRule(subjectAttribute: 'region', resourceAttribute: 'region'),
]);

evaluate(subject, resource, policy); // granted — regions match

// Denied: subject has region=eu but resource is us
final resourceUs = Resource(id: 'report-us', attributes: {'region': 'us'});
evaluate(subject, resourceUs, policy); // denied
```

## Edge Cases
- Subject missing required attribute → `denied(MissingAttributeFailure)`.
- Resource missing required attribute → `denied(MissingAttributeFailure)`.
- Empty `AttributeSet` on either side → rules that reference those attributes deny.
- Policy with no rules → `granted` (explicit open-access design).

## Acceptance Criteria
- [ ] `AbacEvaluator` is pure Dart with no Flutter imports.
- [ ] All rules must pass for `granted`.
- [ ] Missing attribute produces `MissingAttributeFailure`.
- [ ] Covered by `test/domain/evaluators/abac_evaluator_test.dart`.
- [ ] Covered by `test/bdd/abac_access_feature_test.dart`.
