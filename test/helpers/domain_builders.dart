// ignore_for_file: public_member_api_docs

import 'package:flutter_policy_engine/src/domain/entities/abac_policy.dart';
import 'package:flutter_policy_engine/src/domain/entities/policy.dart';
import 'package:flutter_policy_engine/src/domain/entities/resource.dart';
import 'package:flutter_policy_engine/src/domain/entities/role_entity.dart';
import 'package:flutter_policy_engine/src/domain/entities/subject.dart';
import 'package:flutter_policy_engine/src/domain/value_objects/role_name.dart';

/// Returns a [RoleEntity] with given [name] and [allowedResources].
RoleEntity aRoleEntity({
  String name = 'test_role',
  Set<String> allowedResources = const {},
}) =>
    RoleEntity(
      name: RoleName(name),
      allowedResources: allowedResources,
    );

/// Returns an admin [RoleEntity] with common permissions.
RoleEntity anAdminRoleEntity() => aRoleEntity(
      name: 'admin',
      allowedResources: const {'dashboard', 'users', 'settings', 'reports'},
    );

/// Returns a user [RoleEntity] with limited permissions.
RoleEntity aUserRoleEntity() => aRoleEntity(
      name: 'user',
      allowedResources: const {'dashboard'},
    );

/// Returns a [Policy] with admin, manager, user, and guest roles.
Policy aBasicPolicy() => Policy(
      roles: {
        'admin': anAdminRoleEntity(),
        'manager': aRoleEntity(
          name: 'manager',
          allowedResources: const {'dashboard', 'users', 'reports'},
        ),
        'user': aUserRoleEntity(),
        'guest': aRoleEntity(name: 'guest'),
      },
    );

/// Returns an empty [Policy].
const Policy anEmptyPolicy = Policy(roles: {});

/// Returns a [Subject] with the given [attributes].
Subject aSubject({Map<String, String> attributes = const {}}) =>
    Subject(attributes: attributes);

/// Returns a [Resource] with the given [id] and [attributes].
Resource aResource({
  String id = 'test-resource',
  Map<String, String> attributes = const {},
}) =>
    Resource(id: id, attributes: attributes);

/// Returns an [AbacPolicy] with region-matching rule.
AbacPolicy aRegionAbacPolicy() => const AbacPolicy(
      rules: [
        AttributeRule(subjectAttribute: 'region', resourceAttribute: 'region'),
      ],
    );
