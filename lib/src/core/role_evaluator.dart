import 'package:flutter_policy_engine/src/core/interfaces/i_policy_evaluator.dart';
import 'package:flutter_policy_engine/src/models/role.dart';
import 'package:meta/meta.dart';

/// A policy evaluator that determines access permissions based on role-based policies.
///
/// The [RoleEvaluator] implements the [IPolicyEvaluator] interface to provide
/// role-based access control functionality. It evaluates whether content is
/// allowed for a specific role by checking against predefined policies.
///
/// Each role is associated with a [Role] that defines the rules for content
/// evaluation. If no policy exists for a given role, access is denied by default.
///
/// Example usage:
/// ```dart
/// final policies = {
///   'admin': Policy(...),
///   'user': Policy(...),
/// };
/// final evaluator = RoleEvaluator(policies);
/// final hasAccess = evaluator.evaluate('admin', 'sensitive_content');
/// ```
@immutable
class RoleEvaluator implements IPolicyEvaluator {
  /// Creates a new [RoleEvaluator] with the specified policies.
  ///
  /// The [policies] parameter should contain a mapping of role names to their
  /// corresponding [Role] objects. Each policy defines the rules for content
  /// evaluation for that specific role.
  ///
  /// Throws an [ArgumentError] if [policies] is null.
  const RoleEvaluator(this._policies);

  /// The collection of policies mapped by role name.
  ///
  /// This map contains all available policies that can be evaluated by this
  /// evaluator. The key is the role name and the value is the corresponding
  /// [Role] object.
  final Map<String, Role> _policies;

  /// Evaluates whether the specified content is allowed for the given role.
  ///
  /// This method checks if a policy exists for the [roleName] and then
  /// evaluates whether the [content] is allowed according to that policy's rules.
  ///
  /// Returns `true` if:
  /// - A policy exists for the [roleName]
  /// - The policy's [Role.isContentAllowed] method returns `true` for the [content]
  ///
  /// Returns `false` if:
  /// - No policy exists for the [roleName]
  /// - The policy's [Role.isContentAllowed] method returns `false` for the [content]
  ///
  /// Parameters:
  /// - [roleName]: The name of the role to evaluate permissions for
  /// - [content]: The content to check against the role's policy
  ///
  /// Returns `true` if the content is allowed for the role, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// final hasAccess = evaluator.evaluate('admin', 'confidential_document');
  /// if (hasAccess) {
  ///   // Allow access to confidential document
  /// }
  /// ```
  @override
  bool evaluate(String roleName, String content) {
    final policy = _policies[roleName];
    if (policy == null) {
      return false;
    }
    return policy.isContentAllowed(content);
  }
}
