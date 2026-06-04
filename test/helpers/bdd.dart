// ignore_for_file: public_member_api_docs

/// BDD-style test DSL.
///
/// Provides a lightweight `given/when/then` fluent interface for writing
/// behaviour-driven tests without introducing an external Gherkin dependency.
///
/// Usage:
/// ```dart
/// import '../helpers/bdd.dart';
///
/// void main() {
///   test('admin accesses dashboard', () async {
///     await given('an admin role')
///         .whenAsync(
///           'evaluating dashboard access',
///           () async => engine.evaluateAccess('admin', 'dashboard'),
///         )
///         .then('access is granted', (decision) {
///           expect(decision.isGranted, isTrue);
///         });
///   });
/// }
/// ```
library bdd;

/// Starts a BDD scenario with a human-readable description.
BddScenario given(String description) => BddScenario._();

/// Represents a BDD scenario chain.
final class BddScenario {
  BddScenario._();

  /// Records the "when" action returning its result for the "then" assertion.
  BddWhen<T> when<T>(String description, T Function() action) =>
      BddWhen._(action);

  /// Async variant of [when].
  BddWhenAsync<T> whenAsync<T>(
    String description,
    Future<T> Function() action,
  ) =>
      BddWhenAsync._(action);
}

/// Intermediate step that carries the pending action.
final class BddWhen<T> {
  BddWhen._(this._action);

  final T Function() _action;

  /// Executes the action and passes its result to [verify].
  void then(String description, void Function(T result) verify) {
    final result = _action();
    verify(result);
  }
}

/// Async intermediate step that carries the pending async action.
final class BddWhenAsync<T> {
  BddWhenAsync._(this._action);

  final Future<T> Function() _action;

  /// Executes the async action and passes its result to [verify].
  Future<void> then(
    String description,
    void Function(T result) verify,
  ) async {
    final result = await _action();
    verify(result);
  }
}
