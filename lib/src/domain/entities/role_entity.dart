import 'package:flutter_policy_engine/src/domain/value_objects/role_name.dart';
import 'package:meta/meta.dart';

/// A domain entity that maps a named role to a set of allowed resources.
///
/// Equality is defined by [name] only, so two roles with the same name but
/// different [allowedResources] are considered the same entity in a repository.
@immutable
final class RoleEntity {
  /// Creates a [RoleEntity].
  const RoleEntity({
    required this.name,
    required this.allowedResources,
  });

  /// The unique identifier for this role.
  final RoleName name;

  /// The set of resource identifiers this role is permitted to access.
  ///
  /// An empty set means the role has no permissions.
  final Set<String> allowedResources;

  /// Returns `true` when [resourceId] is present in [allowedResources].
  ///
  /// Matching is exact and case-sensitive.
  bool isResourceAllowed(String resourceId) =>
      allowedResources.contains(resourceId);

  /// Returns a copy of this entity with the given fields replaced.
  RoleEntity copyWith({
    RoleName? name,
    Set<String>? allowedResources,
  }) =>
      RoleEntity(
        name: name ?? this.name,
        allowedResources: allowedResources ?? this.allowedResources,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RoleEntity && name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() =>
      'RoleEntity(name: ${name.value}, resources: $allowedResources)';
}
