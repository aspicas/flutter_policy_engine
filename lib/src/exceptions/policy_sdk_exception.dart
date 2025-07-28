import 'package:flutter_policy_engine/src/exceptions/i_policy_sdk_exceptions.dart';

/// A concrete implementation of [IPolicySDKException] that represents
/// errors occurring within the Flutter Policy Engine SDK.
///
/// This exception class provides detailed error information including
/// a descriptive message and an optional underlying exception that
/// caused the error. It's used throughout the SDK to provide consistent
/// error handling and reporting.
///
/// Example usage:
/// ```dart
/// try {
///   // SDK operation that might fail
/// } catch (e) {
///   throw PolicySDKException(
///     'Failed to load policy configuration',
///     exception: e,
///   );
/// }
/// ```
class PolicySDKException implements IPolicySDKException {
  /// Creates a new [PolicySDKException] with the specified error message
  /// and optional underlying exception.
  ///
  /// The [message] should provide a clear, human-readable description
  /// of what went wrong. The [exception] parameter can be used to
  /// preserve the original exception that caused this error, which
  /// is useful for debugging and error tracing.
  ///
  /// Parameters:
  /// - [message]: A descriptive error message explaining what went wrong
  /// - [exception]: An optional underlying exception that caused this error
  PolicySDKException(
    this.message, {
    required this.exception,
  });

  /// A descriptive message explaining the error that occurred.
  ///
  /// This message should be clear enough for developers to understand
  /// what went wrong and potentially how to fix it.
  @override
  final String message;

  /// The underlying exception that caused this SDK error, if any.
  ///
  /// This field preserves the original exception for debugging purposes.
  /// It can be null if the error was generated directly by the SDK
  /// without an underlying exception.
  final Exception? exception;

  /// Returns a string representation of this exception.
  ///
  /// The returned string includes the SDK exception message and,
  /// if available, the underlying exception information for debugging.
  ///
  /// Returns:
  /// A formatted string containing the error message and optional
  /// underlying exception details.
  @override
  String toString() {
    final buffer = StringBuffer('SDKException: $message');
    if (exception != null) {
      buffer.write('\nExtra info: ${exception?.toString()}');
    }
    return buffer.toString();
  }
}
