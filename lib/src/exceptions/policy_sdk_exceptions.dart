/// Base exception class for all policy SDK related errors.
///
/// This abstract class provides a common interface for all exceptions
/// thrown by the policy engine, ensuring consistent error handling
/// and messaging across the SDK.
abstract class PolicySDKException implements Exception {
  /// Creates a new PolicySDKException with the given error message.
  ///
  /// [message] should provide a clear description of what went wrong.
  const PolicySDKException(this.message);

  /// The error message describing the exception.
  final String message;

  @override
  String toString() => 'PolicySDKException: $message';
}

/// Exception thrown when JSON parsing fails during policy evaluation.
///
/// This exception is raised when the policy engine encounters malformed
/// or invalid JSON data that cannot be parsed into the expected format.
/// It provides detailed context about the parsing failure including
/// the specific key that failed, the original error, and any additional
/// validation errors.
class JsonParseException implements PolicySDKException {
  @override
  final String message;

  /// The specific JSON key that caused the parsing failure, if applicable.
  final String? key;

  /// The original error object from the JSON parsing library.
  final Object? originalError;

  /// A map of field-specific validation errors encountered during parsing.
  final Map<String, String>? errors;

  /// Creates a new JsonParseException.
  ///
  /// [message] should describe the parsing failure.
  /// [key] optionally specifies which JSON key caused the failure.
  /// [originalError] optionally provides the original parsing error.
  /// [errors] optionally provides a map of field-specific validation errors.
  JsonParseException(
    this.message, {
    this.key,
    this.originalError,
    this.errors,
  });

  @override
  String toString() {
    final buffer = StringBuffer('JsonParseException: $message');
    if (key != null) {
      buffer.write(' (key: $key)');
    }
    if (originalError != null) {
      buffer.write(' (original: $originalError)');
    }
    if (errors != null && errors!.isNotEmpty) {
      buffer.write(' (${errors!.length} total errors)');
    }
    return buffer.toString();
  }
}

/// Exception thrown when JSON serialization fails during policy operations.
///
/// This exception is raised when the policy engine cannot serialize
/// policy objects or data structures to JSON format. This typically
/// occurs when policy objects contain non-serializable data types
/// or circular references.
class JsonSerializeException implements PolicySDKException {
  @override
  final String message;

  /// The specific object key that caused the serialization failure, if applicable.
  final String? key;

  /// The original error object from the JSON serialization library.
  final Object? originalError;

  /// A map of field-specific serialization errors encountered.
  final Map<String, String>? errors;

  /// Creates a new JsonSerializeException.
  ///
  /// [message] should describe the serialization failure.
  /// [key] optionally specifies which object key caused the failure.
  /// [originalError] optionally provides the original serialization error.
  /// [errors] optionally provides a map of field-specific serialization errors.
  JsonSerializeException(
    this.message, {
    this.key,
    this.originalError,
    this.errors,
  });

  @override
  String toString() {
    final buffer = StringBuffer('JsonSerializeException: $message');
    if (key != null) {
      buffer.write(' (key: $key)');
    }
    if (originalError != null) {
      buffer.write(' (original: $originalError)');
    }
    if (errors != null && errors!.isNotEmpty) {
      buffer.write(' (${errors!.length} total errors)');
    }
    return buffer.toString();
  }
}
