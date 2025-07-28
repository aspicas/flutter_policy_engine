import 'package:flutter_policy_engine/src/exceptions/i_policy_sdk_exceptions.dart';

/// Exception thrown when a policy engine operation is attempted before initialization.
///
/// This exception indicates that a policy-related operation was invoked
/// before the policy engine or evaluator was properly initialized. This
/// typically occurs if you attempt to evaluate policies, check permissions,
/// or perform other policy operations before calling the required
/// initialization or setup methods.
///
/// Example:
/// ```dart
/// if (!_isInitialized) {
///   throw PolicyNotInitializedException('Policy engine must be initialized before use.');
/// }
/// ```
class PolicyNotInitializedException implements IPolicySDKException {
  /// Creates a new [PolicyNotInitializedException] with the given [message].
  const PolicyNotInitializedException(
    this.message,
  );

  /// A message describing the initialization error.
  @override
  final String message;

  @override
  String toString() {
    final buffer = StringBuffer('PolicyNotInitializedException: $message');
    return buffer.toString();
  }
}
