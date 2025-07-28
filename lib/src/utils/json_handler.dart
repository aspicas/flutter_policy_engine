import 'package:flutter_policy_engine/src/exceptions/json_parse_exception.dart';
import 'package:flutter_policy_engine/src/exceptions/json_serialize_exception.dart';
import 'package:flutter_policy_engine/src/utils/log_handler.dart';
import 'dart:convert';

/// Utility for type-safe JSON conversions with generic support.
///
/// Provides strongly-typed parsing and serialization to prevent runtime errors
/// when working with dynamic JSON data structures.
///
/// Includes comprehensive error handling and logging for debugging and monitoring.
class JsonHandler {
  /// Converts JSON map to strongly-typed map using provided constructor.
  ///
  /// Use this when you need to parse a collection of JSON objects into
  /// a specific type while maintaining type safety.
  ///
  /// Returns a map containing successfully parsed items. Failed items are logged
  /// and skipped, allowing partial success scenarios.
  ///
  /// Throws [JsonParseException] if no items could be parsed successfully.
  static Map<String, T> parseMap<T>(
    Map<String, dynamic> jsonMap,
    T Function(Map<String, dynamic>) fromJson, {
    String? context,
    bool allowPartialSuccess = true,
  }) {
    final result = <String, T>{};
    final errors = <String, String>{};

    LogHandler.debug(
      'Starting JSON map parsing',
      context: {
        'total_items': jsonMap.length,
        'context': context ?? 'unknown',
        'allow_partial_success': allowPartialSuccess,
      },
      operation: 'json_parse_map',
    );

    for (final entry in jsonMap.entries) {
      final key = entry.key;
      final value = entry.value;

      try {
        // Validate value is a map before casting
        if (value is! Map<String, dynamic>) {
          throw TypeError();
        }

        final parsed = fromJson(value);
        result[key] = parsed;

        LogHandler.debug(
          'Successfully parsed item',
          context: {'key': key, 'type': T.toString()},
          operation: 'json_parse_item',
        );
      } catch (e, stackTrace) {
        final errorMessage =
            'Failed to parse item with key "$key": ${e.toString()}';
        errors[key] = errorMessage;

        LogHandler.error(
          errorMessage,
          error: e,
          stackTrace: stackTrace,
          context: {
            'key': key,
            'value_type': value.runtimeType.toString(),
            'expected_type': 'Map<String, dynamic>',
            'context': context ?? 'unknown',
          },
          operation: 'json_parse_error',
        );

        if (!allowPartialSuccess) {
          throw JsonParseException(
            'Failed to parse item "$key": ${e.toString()}',
            key: key,
            originalError: e,
          );
        }
      }
    }

    // Log summary
    LogHandler.info(
      'JSON map parsing completed',
      context: {
        'total_items': jsonMap.length,
        'successful_items': result.length,
        'failed_items': errors.length,
        'context': context ?? 'unknown',
      },
      operation: 'json_parse_complete',
    );

    // If no items were parsed successfully and partial success is not allowed
    if (result.isEmpty && !allowPartialSuccess) {
      final errorSummary =
          errors.entries.take(3).map((e) => '${e.key}: ${e.value}').join(', ');

      throw JsonParseException(
        'Failed to parse any items. First few errors: $errorSummary',
        errors: errors,
      );
    }

    // Log errors summary if any
    if (errors.isNotEmpty) {
      LogHandler.warning(
        'Some items failed to parse',
        context: {
          'failed_count': errors.length,
          'failed_keys': errors.keys.take(5).toList(),
          'context': context ?? 'unknown',
        },
        operation: 'json_parse_partial_failure',
      );
    }

    return result;
  }

  /// Converts typed map to JSON-serializable format using provided serializer.
  ///
  /// Use this when you need to serialize a collection of typed objects
  /// back to JSON format for storage or transmission.
  ///
  /// Returns a map containing successfully serialized items. Failed items are logged
  /// and skipped, allowing partial success scenarios.
  ///
  /// Throws [JsonSerializeException] if no items could be serialized successfully.
  static Map<String, dynamic> mapToJson<T>(
    Map<String, T> items,
    Map<String, dynamic> Function(T) toJson, {
    String? context,
    bool allowPartialSuccess = true,
  }) {
    final result = <String, dynamic>{};
    final errors = <String, String>{};

    LogHandler.debug(
      'Starting JSON map serialization',
      context: {
        'total_items': items.length,
        'context': context ?? 'unknown',
        'allow_partial_success': allowPartialSuccess,
      },
      operation: 'json_serialize_map',
    );

    for (final entry in items.entries) {
      final key = entry.key;
      final value = entry.value;

      try {
        final serialized = toJson(value);
        result[key] = serialized;

        LogHandler.debug(
          'Successfully serialized item',
          context: {'key': key, 'type': T.toString()},
          operation: 'json_serialize_item',
        );
      } catch (e, stackTrace) {
        final errorMessage =
            'Failed to serialize item with key "$key": ${e.toString()}';
        errors[key] = errorMessage;

        LogHandler.error(
          errorMessage,
          error: e,
          stackTrace: stackTrace,
          context: {
            'key': key,
            'value_type': value.runtimeType.toString(),
            'context': context ?? 'unknown',
          },
          operation: 'json_serialize_error',
        );

        if (!allowPartialSuccess) {
          throw JsonSerializeException(
            'Failed to serialize item "$key": ${e.toString()}',
            key: key,
            originalError: e,
          );
        }
      }
    }

    // Log summary
    LogHandler.info(
      'JSON map serialization completed',
      context: {
        'total_items': items.length,
        'successful_items': result.length,
        'failed_items': errors.length,
        'context': context ?? 'unknown',
      },
      operation: 'json_serialize_complete',
    );

    // If no items were serialized successfully and partial success is not allowed
    if (result.isEmpty && !allowPartialSuccess) {
      final errorSummary =
          errors.entries.take(3).map((e) => '${e.key}: ${e.value}').join(', ');

      throw JsonSerializeException(
        'Failed to serialize any items. First few errors: $errorSummary',
        errors: errors,
      );
    }

    // Log errors summary if any
    if (errors.isNotEmpty) {
      LogHandler.warning(
        'Some items failed to serialize',
        context: {
          'failed_count': errors.length,
          'failed_keys': errors.keys.take(5).toList(),
          'context': context ?? 'unknown',
        },
        operation: 'json_serialize_partial_failure',
      );
    }

    return result;
  }

  /// Validates if a value can be safely cast to Map&lt;String, dynamic&gt;
  static bool isValidJsonMap(dynamic value) {
    return value is Map<String, dynamic>;
  }

  /// Safely attempts to parse a single JSON object
  static T? tryParse<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson, {
    String? context,
  }) {
    try {
      final result = fromJson(json);
      LogHandler.debug(
        'Successfully parsed single item',
        context: {'type': T.toString(), 'context': context ?? 'unknown'},
        operation: 'json_parse_single',
      );
      return result;
    } catch (e, stackTrace) {
      LogHandler.error(
        'Failed to parse single item',
        error: e,
        stackTrace: stackTrace,
        context: {
          'type': T.toString(),
          'context': context ?? 'unknown',
        },
        operation: 'json_parse_single_error',
      );
      return null;
    }
  }

  /// Parses a JSON string into a Map&lt;String, dynamic&gt; with comprehensive error handling.
  ///
  /// This function safely converts a JSON string representation into a strongly-typed
  /// map structure. It includes validation to ensure the parsed result is actually
  /// a map and provides detailed error information for debugging.
  ///
  /// The function handles various error scenarios:
  /// - Invalid JSON syntax
  /// - JSON that doesn't represent an object (e.g., arrays, primitives)
  /// - Empty or null input strings
  ///
  /// Returns a [Map&lt;String, dynamic&gt;] containing the parsed JSON data.
  ///
  /// Throws [JsonParseException] if the JSON string cannot be parsed or doesn't
  /// represent a valid JSON object.
  ///
  /// Example usage:
  /// ```dart
  /// try {
  ///   final jsonString = '{"name": "John", "age": 30}';
  ///   final result = JsonHandler.parseJsonString(jsonString);
  ///   print(result['name']); // Output: John
  /// } catch (e) {
  ///   print('Failed to parse JSON: $e');
  /// }
  /// ```
  static Map<String, dynamic> parseJsonString(
    String jsonString, {
    String? context,
  }) {
    LogHandler.debug(
      'Starting JSON string parsing',
      context: {
        'input_length': jsonString.length,
        'context': context ?? 'unknown',
      },
      operation: 'json_parse_string',
    );

    try {
      // Validate input
      if (jsonString.isEmpty) {
        throw JsonParseException(
          'Cannot parse empty JSON string',
        );
      }

      // Parse JSON string
      final dynamic parsed = jsonDecode(jsonString);

      // Validate that the parsed result is a map
      if (parsed is! Map<String, dynamic>) {
        throw JsonParseException(
          'JSON string does not represent a valid object. '
          'Expected Map<String, dynamic>, got ${parsed.runtimeType}',
          originalError: TypeError(),
        );
      }

      LogHandler.debug(
        'Successfully parsed JSON string',
        context: {
          'parsed_keys_count': parsed.length,
          'context': context ?? 'unknown',
        },
        operation: 'json_parse_string_success',
      );

      return parsed;
    } catch (e, stackTrace) {
      final errorMessage = 'Failed to parse JSON string: ${e.toString()}';

      LogHandler.error(
        errorMessage,
        error: e,
        stackTrace: stackTrace,
        context: {
          'input_length': jsonString.length,
          'input_preview': jsonString.length > 100
              ? '${jsonString.substring(0, 100)}...'
              : jsonString,
          'context': context ?? 'unknown',
        },
        operation: 'json_parse_string_error',
      );

      // Re-throw as JsonParseException if it's not already
      if (e is JsonParseException) {
        rethrow;
      }

      throw JsonParseException(
        errorMessage,
        originalError: e,
      );
    }
  }
}
