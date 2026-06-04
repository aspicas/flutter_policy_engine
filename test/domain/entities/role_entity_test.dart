import 'package:flutter_policy_engine/src/domain/entities/role_entity.dart';
import 'package:flutter_policy_engine/src/domain/value_objects/role_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoleEntity', () {
    late RoleEntity adminRole;

    setUp(() {
      adminRole = RoleEntity(
        name: RoleName('admin'),
        allowedResources: const {'dashboard', 'users', 'settings'},
      );
    });

    test('isResourceAllowed returns true for allowed resource', () {
      expect(adminRole.isResourceAllowed('dashboard'), isTrue);
    });

    test('isResourceAllowed returns false for unknown resource', () {
      expect(adminRole.isResourceAllowed('unknown'), isFalse);
    });

    test('isResourceAllowed is case-sensitive', () {
      expect(adminRole.isResourceAllowed('Dashboard'), isFalse);
    });

    test('empty allowedResources denies everything', () {
      final role = RoleEntity(
        name: RoleName('empty'),
        allowedResources: const {},
      );
      expect(role.isResourceAllowed('anything'), isFalse);
    });

    test('equality by name', () {
      final a = RoleEntity(
        name: RoleName('admin'),
        allowedResources: const {'x'},
      );
      final b = RoleEntity(
        name: RoleName('admin'),
        allowedResources: const {'y'},
      );
      expect(a, equals(b));
    });

    test('hashCode consistent with equality', () {
      final a = RoleEntity(
        name: RoleName('admin'),
        allowedResources: const {},
      );
      final b = RoleEntity(
        name: RoleName('admin'),
        allowedResources: const {},
      );
      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith changes specified fields', () {
      final updated = adminRole.copyWith(
        allowedResources: const {'reports'},
      );
      expect(updated.name, equals(adminRole.name));
      expect(updated.allowedResources, contains('reports'));
      expect(updated.allowedResources, isNot(contains('dashboard')));
    });

    test('toString is human-readable', () {
      expect(adminRole.toString(), contains('admin'));
    });
  });
}
