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

import '../../helpers/fakes.dart';

class _MockRepository extends Mock implements IPolicyRepository {}

void _registerFallbacks() {
  registerFallbackValues();
}

RoleEntity _admin() => RoleEntity(
      name: RoleName('admin'),
      allowedResources: const {'dashboard'},
    );

Policy _policyWithAdmin() => Policy(
      roles: {'admin': _admin()},
    );

void main() {
  setUpAll(_registerFallbacks);

  late _MockRepository repository;

  setUp(() {
    repository = _MockRepository();
    when(() => repository.load())
        .thenAnswer((_) async => Ok(_policyWithAdmin()));
    when(() => repository.save(any())).thenAnswer((_) async => const Ok(null));
  });

  group('AddRole', () {
    late AddRole useCase;
    setUp(() => useCase = AddRole(repository: repository));

    test('adds a new role to the repository', () async {
      final role = RoleEntity(
        name: RoleName('manager'),
        allowedResources: const {'reports'},
      );
      final result = await useCase.call(role);

      expect(result.isOk, isTrue);
      verify(() => repository.save(any())).called(1);
    });

    test('overwrites existing role with same name', () async {
      final result = await useCase.call(_admin());

      expect(result.isOk, isTrue);
      verify(() => repository.save(any())).called(1);
    });

    test('returns StorageFailure when save fails', () async {
      when(() => repository.save(any())).thenAnswer(
        (_) async => const Err(StorageFailure('write error')),
      );

      final result = await useCase.call(_admin());

      expect(result.isErr, isTrue);
    });
  });

  group('UpdateRole', () {
    late UpdateRole useCase;
    setUp(() => useCase = UpdateRole(repository: repository));

    test('replaces existing role', () async {
      final updated = RoleEntity(
        name: RoleName('admin'),
        allowedResources: const {'dashboard', 'reports'},
      );
      final result = await useCase.call('admin', updated);

      expect(result.isOk, isTrue);
      verify(() => repository.save(any())).called(1);
    });

    test('creates role when it does not exist', () async {
      final newRole = RoleEntity(
        name: RoleName('guest'),
        allowedResources: const {},
      );
      final result = await useCase.call('guest', newRole);

      expect(result.isOk, isTrue);
    });
  });

  group('RemoveRole', () {
    late RemoveRole useCase;
    setUp(() => useCase = RemoveRole(repository: repository));

    test('removes existing role', () async {
      final result = await useCase.call('admin');

      expect(result.isOk, isTrue);
      verify(() => repository.save(any())).called(1);
    });

    test('no-op when role does not exist', () async {
      final result = await useCase.call('ghost');

      expect(result.isOk, isTrue);
      verify(() => repository.save(any())).called(1);
    });

    test('returns InvalidPolicyFailure for empty name', () async {
      final result = await useCase.call('');

      expect(result.isErr, isTrue);
      expect((result as Err).error, isA<InvalidPolicyFailure>());
    });
  });

  group('ListRoles', () {
    late ListRoles useCase;
    setUp(() => useCase = ListRoles(repository: repository));

    test('returns all roles in the repository', () async {
      final result = await useCase.call();

      expect(result.isOk, isTrue);
      final roles = (result as Ok).value as List<RoleEntity>;
      expect(roles.length, equals(1));
      expect(roles.first.name.value, equals('admin'));
    });

    test('returns empty list when no roles loaded', () async {
      when(() => repository.load())
          .thenAnswer((_) async => const Ok(Policy(roles: {})));

      final result = await useCase.call();

      expect(result.isOk, isTrue);
      final roles = (result as Ok).value as List<RoleEntity>;
      expect(roles, isEmpty);
    });

    test('returns StorageFailure when repository fails', () async {
      when(() => repository.load()).thenAnswer(
        (_) async => const Err(StorageFailure('read error')),
      );

      final result = await useCase.call();

      expect(result.isErr, isTrue);
    });
  });
}
