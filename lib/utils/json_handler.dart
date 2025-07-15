import 'dart:convert';

import 'package:flutter_policy_engine/utils/log_handler.dart';

/// A utility class for handling JSON conversions with generic type support.
///
/// This class provides methods to convert JSON strings to strongly-typed objects
/// and vice versa, with proper error handling and type safety.
class JsonHandler {
  /// Converts a JSON string to an object of type T.
  ///
  /// [jsonString] - The JSON string to parse
  /// [fromJson] - A factory function that creates an instance of T from a Map
  ///
  /// Returns an instance of T if successful, null otherwise.
  ///
  /// Example:
  /// ```dart
  /// final policy = JsonHandler.fromJson<Policy>(
  ///   jsonString,
  ///   (json) => Policy.fromJson(json),
  /// );
  /// ```
  static T? fromJson<T>(
    String jsonString,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return fromJson(jsonMap);
    } on FormatException catch (e) {
      LogHandler.error('JSON format error: $e');
      return null;
    } on TypeError catch (e) {
      LogHandler.error('Type conversion error: $e');
      return null;
    } catch (e) {
      LogHandler.error('Stack trace: ${e.toString()}');
      return null;
    }
  }

  /// Converts a JSON string to a list of objects of type T.
  ///
  /// [jsonString] - The JSON string to parse (should be a JSON array)
  /// [fromJson] - A factory function that creates an instance of T from a Map
  ///
  /// Returns a List<T> if successful, empty list otherwise.
  ///
  /// Example:
  /// ```dart
  /// final policies = JsonHandler.fromJsonList<Policy>(
  ///   jsonString,
  ///   (json) => Policy.fromJson(json),
  /// );
  /// ```
  static List<T> fromJsonList<T>(
    String jsonString,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    } on FormatException catch (e) {
      LogHandler.error('JSON format error: $e');
      return [];
    } on TypeError catch (e) {
      LogHandler.error('Type conversion error: $e');
      return [];
    } catch (e) {
      LogHandler.error('Stack trace: ${e.toString()}');
      return [];
    }
  }

  /// Converts an object to a JSON string.
  ///
  /// [object] - The object to convert
  /// [toJson] - A function that converts the object to a Map
  ///
  /// Returns a JSON string if successful, null otherwise.
  ///
  /// Example:
  /// ```dart
  /// final jsonString = JsonHandler.toJson<Policy>(
  ///   policy,
  ///   (policy) => policy.toJson(),
  /// );
  /// ```
  static String? toJson<T>(
    T object,
    Map<String, dynamic> Function(T object) toJson,
  ) {
    try {
      final Map<String, dynamic> jsonMap = toJson(object);
      return jsonEncode(jsonMap);
    } on TypeError catch (e) {
      LogHandler.error('Type conversion error: $e');
      return null;
    } catch (e) {
      LogHandler.error('Stack trace: ${e.toString()}');
      return null;
    }
  }

  /// Converts a list of objects to a JSON string.
  ///
  /// [objects] - The list of objects to convert
  /// [toJson] - A function that converts an object to a Map
  ///
  /// Returns a JSON string if successful, null otherwise.
  ///
  /// Example:
  /// ```dart
  /// final jsonString = JsonHandler.toJsonList<Policy>(
  ///   policies,
  ///   (policy) => policy.toJson(),
  /// );
  /// ```
  static String? toJsonList<T>(
    List<T> objects,
    Map<String, dynamic> Function(T object) toJson,
  ) {
    try {
      final List<Map<String, dynamic>> jsonList =
          objects.map((object) => toJson(object)).toList();
      return jsonEncode(jsonList);
    } on TypeError catch (e) {
      LogHandler.error('Type conversion error: $e');
      return null;
    } catch (e) {
      LogHandler.error('Stack trace: ${e.toString()}');
      return null;
    }
  }

  /// Safely parses a JSON string and returns the raw Map.
  ///
  /// [jsonString] - The JSON string to parse
  ///
  /// Returns a Map<String, dynamic> if successful, null otherwise.
  static Map<String, dynamic>? parseJson(String jsonString) {
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } on FormatException catch (e) {
      LogHandler.error('JSON format error: $e');
      return null;
    } catch (e) {
      LogHandler.error('Stack trace: ${e.toString()}');
      return null;
    }
  }

  /// Validates if a string is valid JSON.
  ///
  /// [jsonString] - The string to validate
  ///
  /// Returns true if the string is valid JSON, false otherwise.
  static bool isValidJson(String jsonString) {
    try {
      jsonDecode(jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }
}
