import 'package:meta/meta.dart';

/// Abstract interface for evaluating policies based on role and content.
///
/// This interface defines the contract for policy evaluation implementations
/// that determine whether a given role has permission to access specific content.
/// Implementations should provide the logic for checking role-based access control
/// according to defined policy rules.
///
/// Example usage:
/// ```dart
/// class SimplePolicyEvaluator implements IPolicyEvaluator {
///   @override
///   bool evaluate(String roleName, String content) {
///     // Implementation logic here
///     return true;
///   }
/// }
/// ```
@immutable
abstract class IPolicyEvaluator {
  /// Evaluates whether a role has permission to access specific content.
  ///
  /// This method performs the core policy evaluation logic by checking
  /// if the specified role has the necessary permissions to access the
  /// given content according to the defined policy rules.
  ///
  /// [roleName] The name of the role to evaluate permissions for.
  ///           Must not be null or empty.
  ///
  /// [content] The content identifier or path to check access for.
  ///           Must not be null or empty.
  ///
  /// Returns `true` if the role has permission to access the content,
  /// `false` otherwise.
  ///
  /// Throws:
  /// - [ArgumentError] if [roleName] or [content] is null or empty
  /// - [StateError] if the policy evaluator is not properly initialized
  bool evaluate(String roleName, String content);
}
