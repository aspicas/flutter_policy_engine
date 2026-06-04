// BDD feature tests for spec-005-persistence.md

import 'package:flutter_policy_engine/src/domain/entities/policy.dart';
import 'package:flutter_policy_engine/src/domain/entities/role_entity.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/value_objects/role_name.dart';
import 'package:flutter_policy_engine/src/infrastructure/storage/in_memory_policy_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bdd.dart';

Policy _buildPolicy() => Policy(
      roles: {
        'admin': RoleEntity(
          name: RoleName('admin'),
          allowedResources: const {'dashboard'},
        ),
      },
    );

void main() {
  group('Feature: Persistence (spec-005)', () {
    group('Scenario: InMemoryPolicyRepository save and load', () {
      test(
          'Given a policy, '
          'When saved and loaded, Then same roles are available', () async {
        final repo = InMemoryPolicyRepository();

        await given('admin policy').whenAsync(
          'saving and loading',
          () async {
            await repo.save(_buildPolicy());
            return repo.load();
          },
        ).then('admin role is available after load', (result) {
          expect(result.isOk, isTrue);
          final policy = result.getOrElse(const Policy(roles: {}));
          expect(policy.roleFor('admin'), isNotNull);
        });
      });
    });

    group('Scenario: clear resets the repository', () {
      test(
          'Given a saved policy, '
          'When cleared, Then load returns empty policy', () async {
        final repo = InMemoryPolicyRepository();
        await repo.save(_buildPolicy());

        await given('repository with admin policy').whenAsync(
          'clearing and loading',
          () async {
            await repo.clear();
            return repo.load();
          },
        ).then('empty policy is returned', (result) {
          expect(result.getOrElse(const Policy(roles: {})).isEmpty, isTrue);
        });
      });
    });

    group('Scenario: loaded policy is a deep copy', () {
      test(
          'Given a stored policy, '
          'When loaded roles are attempted to be mutated, '
          'Then UnsupportedError is thrown', () async {
        final repo = InMemoryPolicyRepository();
        await repo.save(_buildPolicy());
        final loaded = (await repo.load()).getOrElse(const Policy(roles: {}));

        given('unmodifiable loaded roles')
            .when(
          'attempting to mutate',
          () => loaded.roles.keys.toList(),
        )
            .then('roles are accessible but not mutable', (keys) {
          expect(keys, contains('admin'));
          expect(
            () => loaded.roles['x'] = RoleEntity(
              name: RoleName('x'),
              allowedResources: const {},
            ),
            throwsUnsupportedError,
          );
        });
      });
    });

    group('Scenario: empty repository returns empty policy', () {
      test(
          'Given fresh repository, '
          'When loading, Then empty policy is returned', () async {
        final repo = InMemoryPolicyRepository();

        await given('fresh empty repository')
            .whenAsync(
          'loading',
          repo.load,
        )
            .then('empty policy', (result) {
          expect(result.isOk, isTrue);
          expect(result.getOrElse(const Policy(roles: {})).isEmpty, isTrue);
        });
      });
    });

    group('Scenario: multiple saves overwrite data', () {
      test(
          'Given two saves, '
          'When loading after second save, Then only second data is present',
          () async {
        final repo = InMemoryPolicyRepository();
        await repo.save(
          Policy(
            roles: {
              'a': RoleEntity(
                name: RoleName('a'),
                allowedResources: const {},
              ),
            },
          ),
        );
        await repo.save(
          Policy(
            roles: {
              'b': RoleEntity(
                name: RoleName('b'),
                allowedResources: const {},
              ),
            },
          ),
        );

        await given('second save with different policy')
            .whenAsync(
          'loading',
          repo.load,
        )
            .then('only second save data is present', (result) {
          final policy = result.getOrElse(const Policy(roles: {}));
          expect(policy.roleFor('a'), isNull);
          expect(policy.roleFor('b'), isNotNull);
        });
      });
    });
  });
}
