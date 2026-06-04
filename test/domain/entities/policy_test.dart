import 'package:flutter_policy_engine/src/domain/entities/policy.dart';
import 'package:flutter_policy_engine/src/domain/entities/role_entity.dart';
import 'package:flutter_policy_engine/src/domain/value_objects/role_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Policy', () {
    late Policy policy;

    setUp(() {
      policy = Policy(
        roles: {
          'admin': RoleEntity(
            name: RoleName('admin'),
            allowedResources: const {'dashboard', 'users'},
          ),
          'user': RoleEntity(
            name: RoleName('user'),
            allowedResources: const {'dashboard'},
          ),
        },
      );
    });

    test('roleFor returns role when present', () {
      final role = policy.roleFor('admin');
      expect(role, isNotNull);
      expect(role!.name.value, equals('admin'));
    });

    test('roleFor returns null for unknown role', () {
      expect(policy.roleFor('ghost'), isNull);
    });

    test('roles returns unmodifiable view', () {
      expect(
        () => policy.roles['newRole'] = RoleEntity(
          name: RoleName('newRole'),
          allowedResources: const {},
        ),
        throwsUnsupportedError,
      );
    });

    test('isEmpty is true with no roles', () {
      expect(const Policy(roles: {}).isEmpty, isTrue);
    });

    test('isNotEmpty is true with roles', () {
      expect(policy.isNotEmpty, isTrue);
    });

    test('merge adds new roles', () {
      final extra = Policy(
        roles: {
          'manager': RoleEntity(
            name: RoleName('manager'),
            allowedResources: const {'reports'},
          ),
        },
      );
      final merged = policy.merge(extra);
      expect(merged.roles.length, equals(3));
      expect(merged.roleFor('manager'), isNotNull);
    });

    test('merge overwrites existing role', () {
      final override = Policy(
        roles: {
          'admin': RoleEntity(
            name: RoleName('admin'),
            allowedResources: const {'reports'},
          ),
        },
      );
      final merged = policy.merge(override);
      final admin = merged.roleFor('admin');
      expect(admin!.allowedResources, contains('reports'));
      expect(admin.allowedResources, isNot(contains('dashboard')));
    });

    test('withRole adds or replaces a single role', () {
      final newRole = RoleEntity(
        name: RoleName('guest'),
        allowedResources: const {'login'},
      );
      final updated = policy.withRole(newRole);
      expect(updated.roleFor('guest'), isNotNull);
      expect(updated.roles.length, equals(3));
    });

    test('withoutRole removes a role', () {
      final updated = policy.withoutRole('user');
      expect(updated.roleFor('user'), isNull);
      expect(updated.roles.length, equals(1));
    });

    test('withoutRole on non-existent role is a no-op', () {
      final updated = policy.withoutRole('ghost');
      expect(updated.roles.length, equals(policy.roles.length));
    });
  });
}
