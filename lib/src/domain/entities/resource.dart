import 'package:meta/meta.dart';

/// Represents the target resource being accessed.
///
/// Carries a required non-empty [id] and an optional set of key-value
/// [attributes] used by ABAC evaluation.
@immutable
final class Resource {
  /// Creates a [Resource] with a non-empty [id] and optional [attributes].
  ///
  /// Throws [ArgumentError] if [id] is empty or whitespace-only.
  Resource({
    required String id,
    Map<String, String> attributes = const {},
  }) : _attributes = attributes {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Resource id cannot be empty');
    }
    _id = id;
  }

  late final String _id;
  final Map<String, String> _attributes;

  /// The unique identifier for this resource.
  String get id => _id;

  /// An unmodifiable view of this resource's attributes.
  Map<String, String> get attributes => Map.unmodifiable(_attributes);

  /// Returns the value of [key], or `null` if not present.
  String? getAttribute(String key) => _attributes[key];

  /// Returns `true` when [key] is present in the attributes.
  bool hasAttribute(String key) => _attributes.containsKey(key);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Resource &&
          _id == other._id &&
          _mapEquals(_attributes, other._attributes);

  @override
  int get hashCode => Object.hash(
        _id,
        Object.hashAll(
          _attributes.entries.map((e) => Object.hash(e.key, e.value)),
        ),
      );

  @override
  String toString() => 'Resource(id: $_id, attributes: $_attributes)';

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
