/// Utility for type-safe JSON conversions with generic support.
///
/// Provides strongly-typed parsing and serialization to prevent runtime errors
/// when working with dynamic JSON data structures.
class JsonHandler {
  /// Converts JSON map to strongly-typed map using provided constructor.
  ///
  /// Use this when you need to parse a collection of JSON objects into
  /// a specific type while maintaining type safety.
  static Map<String, T> parseMap<T>(
    Map<String, dynamic> jsonMap,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return jsonMap.map(
      (key, value) => MapEntry(key, fromJson(value as Map<String, dynamic>)),
    );
  }

  /// Converts typed map to JSON-serializable format using provided serializer.
  ///
  /// Use this when you need to serialize a collection of typed objects
  /// back to JSON format for storage or transmission.
  static Map<String, dynamic> mapToJson<T>(
    Map<String, T> items,
    Map<String, dynamic> Function(T) toJson,
  ) {
    return items.map(
      (key, value) => MapEntry(key, toJson(value)),
    );
  }
}
