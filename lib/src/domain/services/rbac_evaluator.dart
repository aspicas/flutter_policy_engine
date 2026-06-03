import 'package:flutter_policy_engine/src/domain/entities/access_decision.dart';
import 'package:flutter_policy_engine/src/domain/entities/policy.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/services/policy_evaluator.dart';
import 'package:meta/meta.dart';

/// Evaluates access based on Role-Based Access Control rules.
///
/// A request is granted when `roleName` and `resourceId` are non-empty,
/// a role with that name exists in the policy, and `resourceId` is in
/// the role's `allowedResources` set.
///
/// All comparisons are exact and case-sensitive.
@immutable
final class RbacEvaluator implements PolicyEvaluator {
  /// Creates a [RbacEvaluator].
  const RbacEvaluator();

  @override
  AccessDecision evaluate(String roleName, String resourceId, Policy policy) {
    if (roleName.isEmpty || resourceId.isEmpty) {
      return const AccessDecision.denied(
        InvalidPolicyFailure('Role name and resource id must not be empty'),
      );
    }

    final role = policy.roleFor(roleName);
    if (role == null) {
      return AccessDecision.denied(
        PolicyNotFoundFailure('No policy found for role "$roleName"'),
      );
    }

    if (!role.isResourceAllowed(resourceId)) {
      return AccessDecision.denied(
        ResourceNotAllowedFailure(
          roleName: roleName,
          resourceId: resourceId,
        ),
      );
    }

    return const AccessDecision.granted();
  }
}
