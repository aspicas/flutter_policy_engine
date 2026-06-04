import 'package:meta/meta.dart';

/// A value object representing a validated, non-empty role identifier.
///
/// Trims surrounding whitespace on construction.
/// Throws [ArgumentError] when the trimmed value is empty.
@immutable
final class RoleName {
  /// Creates a [RoleName] from [value].
  ///
  /// Throws [ArgumentError] if [value] is empty or whitespace-only.
  RoleName(String value) : value = value.trim() {
    if (this.value.isEmpty) {
      throw ArgumentError.value(
        value,
        'value',
        'RoleName cannot be empty or whitespace',
      );
    }
  }

  /// The validated, trimmed role name string.
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RoleName && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
