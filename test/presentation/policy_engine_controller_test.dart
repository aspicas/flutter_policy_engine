import 'package:flutter_policy_engine/src/domain/entities/access_decision.dart';
import 'package:flutter_policy_engine/src/domain/entities/role_entity.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/value_objects/role_name.dart';
import 'package:flutter_policy_engine/src/presentation/state/policy_engine_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PolicyEngineController', () {
    late PolicyEngineController controller;

    setUp(() {
      controller = PolicyEngineController.inMemory();
    });

    tearDown(() => controller.dispose());

    test('is not initialized before loadPolicies', () {
      expect(controller.isInitialized, isFalse);
    });

    test('is initialized after loadPolicies succeeds', () async {
      await controller.loadPolicies(<String, dynamic>{
        'roles': <String, dynamic>{
          'admin': <String, dynamic>{
            'allowedResources': <String>['dashboard'],
          },
        },
      });
      expect(controller.isInitialized, isTrue);
    });

    test('notifies listeners after loadPolicies', () async {
      var notified = false;
      controller.addListener(() => notified = true);
      await controller.loadPolicies(<String, dynamic>{
        'roles': <String, dynamic>{},
      });
      expect(notified, isTrue);
    });

    test('evaluateAccess returns EngineNotInitializedFailure before init',
        () async {
      final result = await controller.evaluateAccess('admin', 'dashboard');
      expect(result.isErr, isTrue);
      expect(
        (result as Err).error,
        isA<EngineNotInitializedFailure>(),
      );
    });

    test('evaluateAccess grants access for known role+resource', () async {
      await controller.loadPolicies(<String, dynamic>{
        'roles': <String, dynamic>{
          'admin': <String, dynamic>{
            'allowedResources': <String>['dashboard'],
          },
        },
      });
      final result = await controller.evaluateAccess('admin', 'dashboard');
      expect(result.isOk, isTrue);
      final decision =
          (result as Ok<AccessDecision, DomainFailure>).value;
      expect(decision.isGranted, isTrue);
    });

    test('evaluateAccess denies access for unknown resource', () async {
      await controller.loadPolicies(<String, dynamic>{
        'roles': <String, dynamic>{
          'viewer': <String, dynamic>{
            'allowedResources': <String>['reports'],
          },
        },
      });
      final result = await controller.evaluateAccess('viewer', 'admin_panel');
      expect(result.isOk, isTrue);
      expect(
        (result as Ok<AccessDecision, DomainFailure>).value.isGranted,
        isFalse,
      );
    });

    test('addRole notifies listeners', () async {
      await controller.loadPolicies(
        <String, dynamic>{'roles': <String, dynamic>{}},
      );
      var notified = false;
      controller.addListener(() => notified = true);
      await controller.addRole(
        RoleEntity(
          name: RoleName('editor'),
          allowedResources: const {'posts'},
        ),
      );
      expect(notified, isTrue);
    });

    test('removeRole notifies listeners', () async {
      await controller.loadPolicies(<String, dynamic>{
        'roles': <String, dynamic>{
          'temp': <String, dynamic>{
            'allowedResources': <String>[],
          },
        },
      });
      var notified = false;
      controller.addListener(() => notified = true);
      await controller.removeRole('temp');
      expect(notified, isTrue);
    });

    test('listRoles returns current roles', () async {
      await controller.loadPolicies(<String, dynamic>{
        'roles': <String, dynamic>{
          'admin': <String, dynamic>{
            'allowedResources': <String>['*'],
          },
        },
      });
      final result = await controller.listRoles();
      expect(result.isOk, isTrue);
      expect(
        (result as Ok<List<RoleEntity>, DomainFailure>).value,
        hasLength(1),
      );
    });
  });
}
