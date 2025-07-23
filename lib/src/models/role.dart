import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';

/// Represents a policy that defines content access permissions for a specific role.
///
/// A policy consists of a role name, a list of allowed content types or actions,
/// and optional metadata for additional configuration. Policies are used by the
/// policy engine to determine whether a user with a specific role can access
/// certain content or perform specific actions.
///
/// Example:
/// ```dart
/// final policy = Policy(
///   roleName: 'admin',
///   allowedContent: ['read', 'write', 'delete'],
///   metadata: {'priority': 'high', 'expiresAt': '2024-12-31'},
/// );
/// ```
@immutable
class Role {
  /// Creates a new policy with the specified role name and allowed content.
  ///
  /// The [name] identifies the role this policy applies to.
  /// The [allowedContent] list contains the content types or actions that are
  /// permitted for this role. The [metadata] provides additional configuration
  /// options and defaults to an empty map if not specified.
  ///
  /// Throws an [ArgumentError] if [name] is empty or [allowedContent] is null.
  const Role({
    required this.name,
    required this.allowedContent,
    this.metadata = const {},
  });

  /// The name of the role this policy applies to.
  ///
  /// This should be a unique identifier for the role within your application.
  final String name;

  /// List of content types or actions that are allowed for this role.
  ///
  /// Each string in this list represents a permission or content type that
  /// users with this role can access or perform.
  final List<String> allowedContent;

  /// Additional configuration data for this policy.
  ///
  /// This map can contain any additional information needed to configure
  /// the policy behavior, such as expiration dates, priority levels, or
  /// other metadata.
  final Map<String, dynamic> metadata;

  /// Creates a copy of this policy with the given fields replaced by new values.
  ///
  /// Returns a new [Role] instance with the same values as this one,
  /// except for the fields that are explicitly provided in the parameters.
  ///
  /// Example:
  /// ```dart
  /// final updatedPolicy = policy.copyWith(
  ///   allowedContent: ['read', 'write'],
  ///   metadata: {'priority': 'low'},
  /// );
  /// ```
  Role copyWith({
    String? name,
    List<String>? allowedContent,
    Map<String, dynamic>? metadata,
  }) =>
      Role(
        name: name ?? this.name,
        allowedContent: allowedContent ?? this.allowedContent,
        metadata: metadata ?? this.metadata,
      );

  /// Checks if the specified content is allowed for this policy.
  ///
  /// Returns `true` if [content] is present in the [allowedContent] list,
  /// `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// if (policy.isContentAllowed('read')) {
  ///   // User can read content
  /// }
  /// ```
  bool isContentAllowed(String content) => allowedContent.contains(content);

  /// Compares this policy with another object for equality.
  ///
  /// Two policies are considered equal if they have the same [name] and
  /// the same [allowedContent] (regardless of order). The [metadata] is not
  /// considered in the equality comparison.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Role) return false;

    if (name != other.name) return false;
    if (allowedContent.length != other.allowedContent.length) return false;

    // Sort both lists to ensure order-independent comparison (same as hashCode)
    final sortedThis = List<String>.from(allowedContent)..sort();
    final sortedOther = List<String>.from(other.allowedContent)..sort();

    return listEquals(sortedThis, sortedOther);
  }

  /// Returns the hash code for this policy.
  ///
  /// The hash code is based on the [name] and [allowedContent] fields.
  /// The allowedContent is sorted to ensure consistent hash codes regardless of order.
  @override
  int get hashCode {
    final sortedContent = List<String>.from(allowedContent)..sort();
    return Object.hash(name, const ListEquality().hash(sortedContent));
  }

  /// Returns a string representation of this policy.
  ///
  /// The string includes the role name, allowed content, and metadata.
  @override
  String toString() =>
      'Policy(roleName: $name, allowedContent: $allowedContent, metadata: $metadata)';

  /// Creates a [Role] instance from a JSON map.
  ///
  /// The JSON map should contain:
  /// - `roleName`: A string representing the role name
  /// - `allowedContent`: A list of strings representing allowed content
  /// - `metadata`: A map of string keys to dynamic values (optional)
  ///
  /// Throws a [FormatException] if the JSON structure is invalid.
  ///
  /// Example:
  /// ```dart
  /// final json = {
  ///   'roleName': 'user',
  ///   'allowedContent': ['read'],
  ///   'metadata': {'priority': 'normal'},
  /// };
  /// final policy = Policy.fromJson(json);
  /// ```
  factory Role.fromJson(Map<String, dynamic> json) {
    final name = json['roleName'];
    final allowedContent = json['allowedContent'];
    final metadata = json['metadata'];

    if (name == null || name is! String) {
      throw ArgumentError('roleName must be a non-null string');
    }
    if (allowedContent == null || allowedContent is! List) {
      throw ArgumentError('allowedContent must be a non-null list');
    }
    if (allowedContent.any((item) => item is! String)) {
      throw ArgumentError('All allowedContent items must be strings');
    }

    return Role(
      name: name,
      allowedContent: allowedContent.cast<String>(),
      metadata:
          metadata is Map<String, dynamic> ? metadata : <String, dynamic>{},
    );
  }

  /// Converts this policy to a JSON map.
  ///
  /// Returns a map containing the role name, allowed content, and metadata
  /// that can be serialized to JSON.
  ///
  /// Example:
  /// ```dart
  /// final json = policy.toJson();
  /// // json = {
  /// //   'roleName': 'admin',
  /// //   'allowedContent': ['read', 'write'],
  /// //   'metadata': {'priority': 'high'},
  /// // }
  /// ```
  Map<String, dynamic> toJson() => {
        'roleName': name,
        'allowedContent': allowedContent,
        'metadata': metadata,
      };
}
