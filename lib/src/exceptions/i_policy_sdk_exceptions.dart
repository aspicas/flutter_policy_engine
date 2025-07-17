/// Base exception interface for all policy SDK related errors.
///
/// This abstract interface provides a common contract for all exceptions
/// thrown by the policy engine, ensuring consistent error handling
/// and messaging across the SDK.
abstract class IPolicySDKException implements Exception {
  /// The error message describing the exception.
  String get message;

  @override
  String toString();
}

/// Abstract interface for detailed policy SDK errors with contextual information.
///
/// This interface extends [IPolicySDKException] to provide additional context for
/// errors that occur within the policy engine, such as the specific key involved,
/// the original error thrown, and a map of field-specific validation errors.
/// Implementations should use this to represent exceptions where more granular
/// diagnostic information is valuable for debugging or reporting.
abstract class IDetailPolicySDKException implements IPolicySDKException {
  @override
  String get message;

  /// The specific key or field that caused the error, if applicable.
  String? get key;

  /// The original error object that led to this exception, if available.
  Object? get originalError;

  /// A map of field-specific validation errors encountered during processing, if any.
  Map<String, String>? get errors;
}
