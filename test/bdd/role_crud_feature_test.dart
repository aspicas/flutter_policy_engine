// BDD feature tests for spec-004-role-crud.md

import 'package:flutter_policy_engine/src/application/use_cases/add_role.dart';
import 'package:flutter_policy_engine/src/application/use_cases/list_roles.dart';
import 'package:flutter_policy_engine/src/application/use_cases/remove_role.dart';
import 'package:flutter_policy_engine/src/application/use_cases/update_role.dart';
import 'package:flutter_policy_engine/src/domain/entities/policy.dart';
import 'package:flutter_policy_engine/src/domain/entities/role_entity.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/repositories/i_policy_repository.dart';
import 'package:flutter_policy_engine/src/domain/value_objects/role_name.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/bdd.dart';
import '../helpers/fakes.dart';

class _MockRepository extends Mock implements IPolicyRepository {}

void main() {
  setUpAll(registerFallbackValues);

  late _MockRepository repository;

  setUp(() {
    repository = _MockRepository();
    when(() => repository.load())
        .thenAnswer((_) async => const Ok(Policy(roles: {})));
    when(() => repository.save(any())).thenAnswer((_) async => const Ok(null));
  });

  group('Feature: Role CRUD (spec-004)', () {
    group('Scenario: add a new role', () {
      test(
          'Given empty repository, '
          'When adding admin role, Then save is called', () async {
        final useCase = AddRole(repository: repository);
        final role = RoleEntity(
          name: RoleName('admin'),
          allowedResources: const {'dashboard'},
        );

        await given('empty repository')
            .whenAsync(
          'adding admin role',
          () => useCase.call(role),
        )
            .then('result is Ok and save was called', (result) {
          expect(result.isOk, isTrue);
          verify(() => repository.save(any())).called(1);
        });
      });
    });

    group('Scenario: empty role name is rejected', () {
      test(
          'Given a role name of empty string, '
          'When removing, Then InvalidPolicyFailure is returned', () async {
        final useCase = RemoveRole(repository: repository);

        await given('empty role name for removal')
            .whenAsync(
          'calling remove with empty string',
          () => useCase.call(''),
        )
            .then('InvalidPolicyFailure is returned', (result) {
          expect(result.isErr, isTrue);
          expect((result as Err).error, isA<InvalidPolicyFailure>());
        });
      });
    });

    group('Scenario: remove non-existent role is a no-op', () {
      test(
          'Given a role that does not exist, '
          'When removing it, Then Ok is returned', () async {
        final useCase = RemoveRole(repository: repository);

        await given('non-existent role ghost')
            .whenAsync(
          'removing ghost',
          () => useCase.call('ghost'),
        )
            .then('result is Ok (no-op)', (result) {
          expect(result.isOk, isTrue);
        });
      });
    });

    group('Scenario: list roles on empty repository', () {
      test(
          'Given empty repository, '
          'When listing roles, Then empty list is returned', () async {
        final useCase = ListRoles(repository: repository);

        await given('empty repository')
            .whenAsync(
          'listing roles',
          useCase.call,
        )
            .then('empty list is returned', (result) {
          expect(result.isOk, isTrue);
          final roles = (result as Ok).value as List<RoleEntity>;
          expect(roles, isEmpty);
        });
      });
    });

    group('Scenario: update existing role', () {
      test(
          'Given admin role exists, '
          'When updating with new resources, Then updated policy is saved',
          () async {
        when(() => repository.load()).thenAnswer(
          (_) async => Ok(
            Policy(
              roles: {
                'admin': RoleEntity(
                  name: RoleName('admin'),
                  allowedResources: const {'dashboard'},
                ),
              },
            ),
          ),
        );

        final useCase = UpdateRole(repository: repository);
        final updated = RoleEntity(
          name: RoleName('admin'),
          allowedResources: const {'dashboard', 'reports'},
        );

        await given('admin role with only dashboard')
            .whenAsync(
          'updating admin to add reports',
          () => useCase.call('admin', updated),
        )
            .then('result is Ok and save was called', (result) {
          expect(result.isOk, isTrue);
          verify(() => repository.save(any())).called(1);
        });
      });
    });
  });
}
