import 'package:flutter_policy_engine/src/domain/entities/access_decision.dart';
import 'package:flutter_policy_engine/src/domain/entities/policy.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';

/// Contract for RBAC policy evaluation.
///
/// Implementations must be stateless and produce deterministic results.
abstract interface class PolicyEvaluator {
  /// Evaluates whether [roleName] is allowed to access [resourceId]
  /// according to [policy].
  ///
  /// Returns [AccessDecision.granted] or [AccessDecision.denied] with a
  /// typed [DomainFailure] reason.
  AccessDecision evaluate(String roleName, String resourceId, Policy policy);
}
