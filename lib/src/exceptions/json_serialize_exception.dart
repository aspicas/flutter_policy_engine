import 'package:flutter_policy_engine/src/exceptions/i_policy_sdk_exceptions.dart';

/// Exception thrown when JSON serialization fails during policy operations.
///
/// This exception is raised when the policy engine cannot serialize
/// policy objects or data structures to JSON format. This typically
/// occurs when policy objects contain non-serializable data types
/// or circular references.
class JsonSerializeException implements IDetailPolicySDKException {
  @override
  final String message;

  /// The specific object key that caused the serialization failure, if applicable.
  @override
  final String? key;

  /// The original error object from the JSON serialization library.
  @override
  final Object? originalError;

  /// A map of field-specific serialization errors encountered.
  @override
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
