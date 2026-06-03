import 'package:flutter_policy_engine/src/domain/entities/role_entity.dart';
import 'package:meta/meta.dart';

/// The aggregate containing all loaded [RoleEntity] objects.
///
/// Provides immutable operations that return new [Policy] instances.
@immutable
final class Policy {
  /// Creates a [Policy] from a map of role name strings to [RoleEntity].
  const Policy({required Map<String, RoleEntity> roles}) : _roles = roles;

  final Map<String, RoleEntity> _roles;

  /// An unmodifiable view of all roles keyed by role name.
  Map<String, RoleEntity> get roles => Map.unmodifiable(_roles);

  /// Returns the [RoleEntity] for [roleName], or `null` if not found.
  RoleEntity? roleFor(String roleName) => _roles[roleName];

  /// Returns `true` when no roles have been loaded.
  bool get isEmpty => _roles.isEmpty;

  /// Returns `true` when at least one role is present.
  bool get isNotEmpty => _roles.isNotEmpty;

  /// Returns a new [Policy] that merges [other] into this one.
  ///
  /// Roles in [other] overwrite roles with the same name in this policy.
  Policy merge(Policy other) => Policy(roles: {..._roles, ...other._roles});

  /// Returns a new [Policy] with [role] added or replaced.
  Policy withRole(RoleEntity role) =>
      Policy(roles: {..._roles, role.name.value: role});

  /// Returns a new [Policy] with the role named [roleName] removed.
  ///
  /// No-op if [roleName] does not exist.
  Policy withoutRole(String roleName) => Policy(
        roles: Map.fromEntries(
          _roles.entries.where((e) => e.key != roleName),
        ),
      );
}
