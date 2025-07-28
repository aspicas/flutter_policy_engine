import 'package:flutter_policy_engine/src/exceptions/i_policy_sdk_exceptions.dart';

/// Exception thrown when JSON parsing fails during policy evaluation.
///
/// This exception is raised when the policy engine encounters malformed
/// or invalid JSON data that cannot be parsed into the expected format.
/// It provides detailed context about the parsing failure including
/// the specific key that failed, the original error, and any additional
/// validation errors.
class JsonParseException implements IDetailPolicySDKException {
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
  final String message;

  /// The specific JSON key that caused the parsing failure, if applicable.
  @override
  final String? key;

  /// The original error object from the JSON parsing library.
  @override
  final Object? originalError;

  /// A map of field-specific validation errors encountered during parsing.
  @override
  final Map<String, String>? errors;

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
