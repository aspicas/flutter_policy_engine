import 'package:flutter_policy_engine/src/domain/entities/policy.dart';
import 'package:flutter_policy_engine/src/domain/entities/role_entity.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/value_objects/role_name.dart';
import 'package:flutter_policy_engine/src/infrastructure/storage/shared_preferences_policy_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Policy _buildPolicy() => Policy(
      roles: {
        'admin': RoleEntity(
          name: RoleName('admin'),
          allowedResources: const {'dashboard', 'users'},
        ),
      },
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SharedPreferencesPolicyRepository', () {
    test('load on fresh instance returns empty policy', () async {
      final repo = await SharedPreferencesPolicyRepository.create();
      final result = await repo.load();
      expect(result.isOk, isTrue);
      expect(result.getOrElse(const Policy(roles: {})).isEmpty, isTrue);
    });

    test('save then load returns equivalent policy', () async {
      final repo = await SharedPreferencesPolicyRepository.create();
      final policy = _buildPolicy();

      await repo.save(policy);
      final loaded = await repo.load();

      expect(loaded.isOk, isTrue);
      final loadedPolicy = loaded.getOrElse(const Policy(roles: {}));
      expect(loadedPolicy.roleFor('admin'), isNotNull);
      expect(
        loadedPolicy.roleFor('admin')!.allowedResources,
        containsAll(['dashboard', 'users']),
      );
    });

    test('clear then load returns empty policy', () async {
      final repo = await SharedPreferencesPolicyRepository.create();
      await repo.save(_buildPolicy());
      await repo.clear();

      final result = await repo.load();
      expect(result.getOrElse(const Policy(roles: {})).isEmpty, isTrue);
    });

    test('clear removes the SharedPreferences key', () async {
      final repo = await SharedPreferencesPolicyRepository.create();
      await repo.save(_buildPolicy());
      await repo.clear();

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(SharedPreferencesPolicyRepository.storageKey),
        isNull,
      );
    });

    test('multiple saves overwrite previous data', () async {
      final repo = await SharedPreferencesPolicyRepository.create();
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

      final loaded = (await repo.load()).getOrElse(const Policy(roles: {}));
      expect(loaded.roleFor('a'), isNull);
      expect(loaded.roleFor('b'), isNotNull);
    });

    test('corrupted JSON in storage returns Err', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesPolicyRepository.storageKey: 'not valid json {{{}',
      });
      final repo = await SharedPreferencesPolicyRepository.create();
      final result = await repo.load();
      expect(result.isErr, isTrue);
    });

    test('save returns Ok', () async {
      final repo = await SharedPreferencesPolicyRepository.create();
      final result = await repo.save(_buildPolicy());
      expect(result.isOk, isTrue);
    });

    test('clear returns Ok', () async {
      final repo = await SharedPreferencesPolicyRepository.create();
      final result = await repo.clear();
      expect(result.isOk, isTrue);
    });
  });
}
