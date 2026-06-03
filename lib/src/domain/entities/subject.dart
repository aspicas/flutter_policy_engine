import 'package:meta/meta.dart';

/// The entity requesting access, carrying a set of key-value attributes.
///
/// Used by ABAC evaluation to match against attribute rules.
@immutable
final class Subject {
  /// Creates a [Subject] with the given [attributes].
  const Subject({required Map<String, String> attributes})
      : _attributes = attributes;

  final Map<String, String> _attributes;

  /// An unmodifiable view of this subject's attributes.
  Map<String, String> get attributes => Map.unmodifiable(_attributes);

  /// Returns the value of [key], or `null` if not present.
  String? getAttribute(String key) => _attributes[key];

  /// Returns `true` when [key] is present in the attributes.
  bool hasAttribute(String key) => _attributes.containsKey(key);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subject && _mapEquals(_attributes, other._attributes);

  @override
  int get hashCode => Object.hashAll(
        _attributes.entries.map((e) => Object.hash(e.key, e.value)),
      );

  @override
  String toString() => 'Subject(attributes: $_attributes)';

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
