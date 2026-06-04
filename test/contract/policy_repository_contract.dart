// ignore_for_file: public_member_api_docs

/// Contract tests for [IPolicyRepository].
///
/// Any implementation of [IPolicyRepository] must pass these tests.
/// Register an implementation by calling [runPolicyRepositoryContractTests]
/// with a factory that creates a fresh instance per test.
///
/// Usage:
/// ```dart
/// void main() {
///   runPolicyRepositoryContractTests(
///     factory: () => InMemoryPolicyRepository(),
///   );
/// }
/// ```
library policy_repository_contract;

import 'package:flutter_policy_engine/src/domain/entities/policy.dart';
import 'package:flutter_policy_engine/src/domain/entities/role_entity.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/repositories/i_policy_repository.dart';
import 'package:flutter_policy_engine/src/domain/value_objects/role_name.dart';
import 'package:flutter_test/flutter_test.dart';

Policy _buildPolicy() => Policy(
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

/// Runs the full [IPolicyRepository] contract test suite.
///
/// [factory] must return a new, empty repository for each test.
void runPolicyRepositoryContractTests({
  required IPolicyRepository Function() factory,
}) {
  late IPolicyRepository repo;

  setUp(() {
    repo = factory();
  });

  group('IPolicyRepository contract', () {
    test('load on empty repository returns empty policy', () async {
      final result = await repo.load();
      expect(result.isOk, isTrue);
      expect(result.getOrElse(const Policy(roles: {})).isEmpty, isTrue);
    });

    test('save then load returns equivalent policy', () async {
      final policy = _buildPolicy();
      await repo.save(policy);
      final loaded = await repo.load();

      expect(loaded.isOk, isTrue);
      final loadedPolicy = loaded.getOrElse(const Policy(roles: {}));
      expect(loadedPolicy.roles.length, equals(policy.roles.length));
      for (final entry in policy.roles.entries) {
        expect(loadedPolicy.roleFor(entry.key), isNotNull);
      }
    });

    test('clear then load returns empty policy', () async {
      await repo.save(_buildPolicy());
      await repo.clear();
      final result = await repo.load();

      expect(result.getOrElse(const Policy(roles: {})).isEmpty, isTrue);
    });

    test('multiple saves overwrite previous data', () async {
      final first = Policy(
        roles: {
          'a': RoleEntity(name: RoleName('a'), allowedResources: const {}),
        },
      );
      final second = Policy(
        roles: {
          'b': RoleEntity(name: RoleName('b'), allowedResources: const {}),
        },
      );

      await repo.save(first);
      await repo.save(second);
      final loaded = await repo.load();

      final policy = loaded.getOrElse(const Policy(roles: {}));
      expect(policy.roleFor('a'), isNull);
      expect(policy.roleFor('b'), isNotNull);
    });

    test('loaded policy roles are independent of original', () async {
      final policy = _buildPolicy();
      await repo.save(policy);
      final loaded = (await repo.load()).getOrElse(const Policy(roles: {}));

      expect(
        () => loaded.roles['newRole'] = RoleEntity(
          name: RoleName('newRole'),
          allowedResources: const {},
        ),
        throwsUnsupportedError,
      );
    });
  });
}
