import 'package:meta/meta.dart';

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
class Policy {
  /// Creates a new policy with the specified role name and allowed content.
  ///
  /// The [roleName] identifies the role this policy applies to.
  /// The [allowedContent] list contains the content types or actions that are
  /// permitted for this role. The [metadata] provides additional configuration
  /// options and defaults to an empty map if not specified.
  ///
  /// Throws an [ArgumentError] if [roleName] is empty or [allowedContent] is null.
  const Policy({
    required this.roleName,
    required this.allowedContent,
    this.metadata = const {},
  });

  /// The name of the role this policy applies to.
  ///
  /// This should be a unique identifier for the role within your application.
  final String roleName;

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
  /// Returns a new [Policy] instance with the same values as this one,
  /// except for the fields that are explicitly provided in the parameters.
  ///
  /// Example:
  /// ```dart
  /// final updatedPolicy = policy.copyWith(
  ///   allowedContent: ['read', 'write'],
  ///   metadata: {'priority': 'low'},
  /// );
  /// ```
  Policy copyWith({
    String? roleName,
    List<String>? allowedContent,
    Map<String, dynamic>? metadata,
  }) =>
      Policy(
        roleName: roleName ?? this.roleName,
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
  /// Two policies are considered equal if they have the same [roleName] and
  /// the same [allowedContent] (regardless of order). The [metadata] is not
  /// considered in the equality comparison.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Policy &&
          roleName == other.roleName &&
          allowedContent.length == other.allowedContent.length &&
          allowedContent
              .every((content) => other.allowedContent.contains(content));

  /// Returns the hash code for this policy.
  ///
  /// The hash code is based on the [roleName] and [allowedContent] fields.
  @override
  int get hashCode => roleName.hashCode ^ allowedContent.hashCode;

  /// Returns a string representation of this policy.
  ///
  /// The string includes the role name, allowed content, and metadata.
  @override
  String toString() =>
      'Policy(roleName: $roleName, allowedContent: $allowedContent, metadata: $metadata)';

  /// Creates a [Policy] instance from a JSON map.
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
  factory Policy.fromJson(Map<String, dynamic> json) => Policy(
        roleName: json['roleName'] as String,
        allowedContent: json['allowedContent'] as List<String>,
        metadata: json['metadata'] as Map<String, dynamic>,
      );

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
        'roleName': roleName,
        'allowedContent': allowedContent,
        'metadata': metadata,
      };
}
