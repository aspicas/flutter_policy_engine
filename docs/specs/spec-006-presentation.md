# Spec-006: Presentation Layer

## Context
The presentation layer provides Flutter widgets that gate UI rendering on policy decisions, without
requiring consumers to write imperative `if` checks.

## PolicyEngineScope
1. An `InheritedNotifier<PolicyEngineController>` that exposes the controller to descendants.
2. `PolicyEngineScope.of(context)` returns the nearest controller; throws `StateError` if absent.
3. Rebuilds dependents whenever `PolicyEngineController.notifyListeners()` is called.
4. Must be an ancestor of any `PolicyGate` or `PolicyBuilder`.

## PolicyEngineController
1. A `ChangeNotifier` that wraps `PolicyEngine`.
2. Exposes:
   - `Future<void> loadPolicies(Map<String, dynamic> json)`
   - `Future<void> loadPoliciesFromAsset(String assetPath)`
   - `Future<void> addRole(Role role)`
   - `Future<void> updateRole(String name, Role role)`
   - `Future<void> removeRole(String name)`
   - `List<Role> get roles`
   - `bool get isInitialized`
3. Calls `notifyListeners()` after every mutation.
4. Throws `PolicyEngineException` (not `DomainFailure`) on unrecoverable errors.

## PolicyGate
1. A `StatelessWidget` that reads the controller via `PolicyEngineScope.of(context)`.
2. Constructor: `PolicyGate({required String role, required String resource, required Widget child, Widget? fallback, VoidCallback? onDenied})`.
3. Shows `child` when `AccessDecision.granted`, `fallback ?? SizedBox.shrink()` otherwise.
4. Calls `onDenied` (if provided) when access is denied; called at most once per build.
5. Never throws; on unexpected engine errors it silently falls back to `fallback`.

## PolicyBuilder
1. A `StatelessWidget` similar to `PolicyGate` but exposes the `AccessDecision` to a builder.
2. Constructor: `PolicyBuilder({required String role, required String resource, required Widget Function(BuildContext, AccessDecision) builder})`.
3. Passes `AccessDecision` to `builder`; consumer decides how to render.

## Rebuilds
- When `PolicyEngineController.notifyListeners()` fires, all `PolicyGate` and `PolicyBuilder`
  instances in the tree are rebuilt automatically via `InheritedNotifier`.

## Acceptance Criteria
- [ ] `PolicyEngineScope.of` throws `StateError` when no scope is found.
- [ ] `PolicyGate` shows `child` on granted, `fallback` on denied.
- [ ] `PolicyGate` calls `onDenied` on deny.
- [ ] `PolicyBuilder` receives correct `AccessDecision` in builder.
- [ ] Rebuild on role change propagates to gates/builders.
- [ ] Covered by `test/presentation/*_test.dart`.
- [ ] Covered by `test/bdd/presentation_feature_test.dart`.
