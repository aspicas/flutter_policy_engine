import 'package:flutter_policy_engine/src/domain/entities/access_decision.dart';
import 'package:flutter_policy_engine/src/domain/entities/policy.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/services/policy_evaluator.dart';

/// The decision strategy used when multiple evaluators disagree.
enum CompositeStrategy {
  /// All evaluators must grant for access to be allowed.
  ///
  /// A single denial overrides all grants (deny takes precedence).
  denyOverrides,

  /// Any evaluator granting is sufficient for access.
  ///
  /// A single grant overrides all denials (allow takes precedence).
  allowOverrides,
}

/// Combines multiple `PolicyEvaluator` instances with a configurable
/// [strategy].
///
/// - `denyOverrides`: all evaluators must grant.
/// - `allowOverrides`: any evaluator granting is sufficient.
///
/// An empty evaluator list always denies (safe default).
final class CompositeEvaluator implements PolicyEvaluator {
  /// Creates a [CompositeEvaluator].
  CompositeEvaluator({
    required List<PolicyEvaluator> evaluators,
    required this.strategy,
  }) : _evaluators = List.unmodifiable(evaluators);

  final List<PolicyEvaluator> _evaluators;

  /// The strategy applied when evaluators produce conflicting decisions.
  final CompositeStrategy strategy;

  @override
  AccessDecision evaluate(String roleName, String resourceId, Policy policy) {
    if (_evaluators.isEmpty) {
      return const AccessDecision.denied(
        PolicyNotFoundFailure('No evaluators configured'),
      );
    }

    return switch (strategy) {
      CompositeStrategy.denyOverrides =>
        _evaluateDenyOverrides(roleName, resourceId, policy),
      CompositeStrategy.allowOverrides =>
        _evaluateAllowOverrides(roleName, resourceId, policy),
    };
  }

  AccessDecision _evaluateDenyOverrides(
    String roleName,
    String resourceId,
    Policy policy,
  ) {
    AccessDecision? lastDecision;
    for (final evaluator in _evaluators) {
      final decision = evaluator.evaluate(roleName, resourceId, policy);
      if (decision.isDenied) return decision;
      lastDecision = decision;
    }
    return lastDecision ?? const AccessDecision.granted();
  }

  AccessDecision _evaluateAllowOverrides(
    String roleName,
    String resourceId,
    Policy policy,
  ) {
    AccessDecision? lastDenial;
    for (final evaluator in _evaluators) {
      final decision = evaluator.evaluate(roleName, resourceId, policy);
      if (decision.isGranted) return decision;
      lastDenial = decision;
    }
    return lastDenial ??
        const AccessDecision.denied(
          PolicyNotFoundFailure('All evaluators denied'),
        );
  }
}
