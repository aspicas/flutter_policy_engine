import 'dart:convert';

import 'package:flutter_policy_engine/src/domain/entities/policy.dart';
import 'package:flutter_policy_engine/src/domain/entities/role_entity.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/value_objects/role_name.dart';

/// Encodes and decodes [Policy] using the canonical v2 JSON schema.
///
/// Schema:
/// ```json
/// {
///   "roles": {
///     "<roleName>": {
///       "allowedResources": ["resource-a", "resource-b"],
///       "metadata": {}
///     }
///   }
/// }
/// ```
final class PolicyJsonCodec {
  /// Creates a [PolicyJsonCodec].
  const PolicyJsonCodec();

  /// Decodes a [Policy] from a v2 JSON [source] string.
  ///
  /// Returns [Err<ParseFailure>] when:
  /// - [source] is not valid JSON.
  /// - The top-level `roles` key is missing.
  ///
  /// Individual role entries with invalid structure are **skipped** with a
  /// logged warning; valid entries are loaded (partial success).
  Result<Policy, DomainFailure> decode(
    String source, {
    void Function(String message)? onWarning,
  }) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(source) as Map<String, dynamic>;
    } catch (e) {
      return Err(ParseFailure('Invalid JSON: $e', cause: e));
    }

    if (!json.containsKey('roles')) {
      return const Err(
        ParseFailure('Missing required "roles" key in policy JSON'),
      );
    }

    final rolesRaw = json['roles'];
    if (rolesRaw is! Map<String, dynamic>) {
      return const Err(ParseFailure('"roles" must be an object'));
    }

    return _decodeRoles(rolesRaw, onWarning: onWarning);
  }

  /// Decodes a [Policy] from a pre-parsed [map] conforming to the v2 schema.
  ///
  /// Equivalent to [decode] but skips the JSON parsing step.
  Result<Policy, DomainFailure> decodeFromMap(
    Map<String, dynamic> map, {
    void Function(String message)? onWarning,
  }) {
    final rolesRaw = map['roles'];
    if (rolesRaw is! Map<String, dynamic>) {
      return const Err(
        ParseFailure('Missing or invalid "roles" key in policy map'),
      );
    }
    return _decodeRoles(rolesRaw, onWarning: onWarning);
  }

  Result<Policy, DomainFailure> _decodeRoles(
    Map<String, dynamic> rolesRaw, {
    void Function(String message)? onWarning,
  }) {
    final roles = <String, RoleEntity>{};
    for (final entry in rolesRaw.entries) {
      final roleName = entry.key.trim();
      if (roleName.isEmpty) {
        onWarning?.call('Skipping role entry with empty name');
        continue;
      }

      final roleData = entry.value;
      if (roleData is! Map<String, dynamic>) {
        onWarning?.call('Skipping role "$roleName": expected an object');
        continue;
      }

      final resourcesRaw = roleData['allowedResources'];
      if (resourcesRaw is! List) {
        onWarning?.call(
          'Skipping role "$roleName": allowedResources must be a list',
        );
        continue;
      }

      final allowed = <String>{};
      for (final r in resourcesRaw) {
        if (r is String) allowed.add(r);
      }

      try {
        roles[roleName] = RoleEntity(
          name: RoleName(roleName),
          allowedResources: allowed,
        );
      } catch (_) {
        onWarning?.call('Skipping role "$roleName": invalid name');
      }
    }
    return Ok(Policy(roles: roles));
  }

  /// Encodes a [Policy] to a v2 JSON string.
  String encode(Policy policy) {
    final rolesMap = <String, dynamic>{};
    for (final entry in policy.roles.entries) {
      rolesMap[entry.key] = {
        'allowedResources': entry.value.allowedResources.toList()..sort(),
      };
    }
    return jsonEncode({'roles': rolesMap});
  }
}
