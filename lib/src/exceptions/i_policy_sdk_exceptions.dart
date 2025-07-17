/// Base exception class for all policy SDK related errors.
///
/// This abstract class provides a common interface for all exceptions
/// thrown by the policy engine, ensuring consistent error handling
/// and messaging across the SDK.
abstract class IPolicySDKException implements Exception {
  /// Creates a new PolicySDKException with the given error message.
  ///
  /// [message] should provide a clear description of what went wrong.
  const IPolicySDKException(this.message);

  /// The error message describing the exception.
  final String message;

  @override
  String toString() => 'PolicySDKException: $message';
}

/// Abstract exception for detailed policy SDK errors with contextual information.
///
/// This class extends [IPolicySDKException] to provide additional context for
/// errors that occur within the policy engine, such as the specific key involved,
/// the original error thrown, and a map of field-specific validation errors.
/// Subclasses should use this to represent exceptions where more granular
/// diagnostic information is valuable for debugging or reporting.
abstract class IDetailPolicySDKException implements IPolicySDKException {
  /// Creates a new [IDetailPolicySDKException] with an error [message] and optional details.
  ///
  /// [message] provides a human-readable description of the error.
  /// [key] optionally identifies the specific key or field related to the error.
  /// [originalError] optionally contains the original error object that triggered this exception.
  /// [errors] optionally provides a map of field-specific validation errors.
  const IDetailPolicySDKException(
    this.message, {
    this.key,
    this.originalError,
    this.errors,
  });

  @override
  final String message;

  /// The specific key or field that caused the error, if applicable.
  final String? key;

  /// The original error object that led to this exception, if available.
  final Object? originalError;

  /// A map of field-specific validation errors encountered during processing, if any.
  final Map<String, String>? errors;
}
