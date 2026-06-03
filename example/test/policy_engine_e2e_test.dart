// E2E integration tests for the flutter_policy_engine example.
//
// These tests run against the real package (no mocks), covering:
//   1. Basic RBAC evaluation
//   2. Role CRUD at runtime
//   3. Policy loading from a bundled JSON asset
//   4. ABAC attribute-based evaluation
//
// Run with: flutter test integration_test/ (from the example directory)

import 'package:flutter/widgets.dart';
import 'package:flutter_policy_engine/flutter_policy_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const _inlinePolicy = <String, dynamic>{
  'roles': <String, dynamic>{
    'admin': <String, dynamic>{
      'allowedResources': <String>['dashboard', 'settings', 'users'],
    },
    'viewer': <String, dynamic>{
      'allowedResources': <String>['dashboard'],
    },
    'guest': <String, dynamic>{
      'allowedResources': <String>[],
    },
  },
};

void main() {

  group('E2E — Basic RBAC evaluation', () {
    testWidgets('admin can access settings', (tester) async {
      final controller = PolicyEngineController.inMemory();
      addTearDown(controller.dispose);
      await controller.loadPolicies(_inlinePolicy);

      final result = await controller.evaluateAccess('admin', 'settings');
      expect(result.isOk, isTrue);
      expect((result as Ok<AccessDecision, DomainFailure>).value.isGranted, isTrue);
    });

    testWidgets('viewer is denied settings access', (tester) async {
      final controller = PolicyEngineController.inMemory();
      addTearDown(controller.dispose);
      await controller.loadPolicies(_inlinePolicy);

      final result = await controller.evaluateAccess('viewer', 'settings');
      expect(result.isOk, isTrue);
      expect((result as Ok<AccessDecision, DomainFailure>).value.isGranted, isFalse);
    });

    testWidgets('unknown role is denied', (tester) async {
      final controller = PolicyEngineController.inMemory();
      addTearDown(controller.dispose);
      await controller.loadPolicies(_inlinePolicy);

      final result = await controller.evaluateAccess('hacker', 'settings');
      expect(result.isOk, isTrue);
      expect((result as Ok<AccessDecision, DomainFailure>).value.isGranted, isFalse);
    });

    testWidgets(
        'evaluateAccess returns EngineNotInitializedFailure before init',
        (tester) async {
      final controller = PolicyEngineController.inMemory();
      addTearDown(controller.dispose);

      final result = await controller.evaluateAccess('admin', 'settings');
      expect(result.isErr, isTrue);
      expect(
        (result as Err<AccessDecision, DomainFailure>).error,
        isA<EngineNotInitializedFailure>(),
      );
    });
  });

  group('E2E — Role CRUD at runtime', () {
    testWidgets('add then evaluate new role', (tester) async {
      final controller = PolicyEngineController.inMemory();
      addTearDown(controller.dispose);
      await controller.loadPolicies(_inlinePolicy);

      await controller.addRole(
        RoleEntity(
          name: RoleName('analyst'),
          allowedResources: const {'reports', 'analytics'},
        ),
      );

      final result = await controller.evaluateAccess('analyst', 'reports');
      expect(
        (result as Ok<AccessDecision, DomainFailure>).value.isGranted,
        isTrue,
      );
    });

    testWidgets('remove role then deny access', (tester) async {
      final controller = PolicyEngineController.inMemory();
      addTearDown(controller.dispose);
      await controller.loadPolicies(_inlinePolicy);
      await controller.removeRole('admin');

      final result = await controller.evaluateAccess('admin', 'dashboard');
      expect(
        (result as Ok<AccessDecision, DomainFailure>).value.isGranted,
        isFalse,
      );
    });

    testWidgets('update role grants new resource', (tester) async {
      final controller = PolicyEngineController.inMemory();
      addTearDown(controller.dispose);
      await controller.loadPolicies(_inlinePolicy);

      // Before update: viewer cannot access reports
      var r = await controller.evaluateAccess('viewer', 'reports');
      expect((r as Ok<AccessDecision, DomainFailure>).value.isGranted, isFalse);

      await controller.updateRole(
        'viewer',
        RoleEntity(
          name: RoleName('viewer'),
          allowedResources: const {'dashboard', 'reports'},
        ),
      );

      // After update: viewer can access reports
      r = await controller.evaluateAccess('viewer', 'reports');
      expect((r as Ok<AccessDecision, DomainFailure>).value.isGranted, isTrue);
    });

    testWidgets('listRoles reflects mutations', (tester) async {
      final controller = PolicyEngineController.inMemory();
      addTearDown(controller.dispose);
      await controller.loadPolicies(_inlinePolicy);

      var listResult = await controller.listRoles();
      final before =
          (listResult as Ok<List<RoleEntity>, DomainFailure>).value.length;

      await controller.addRole(
        RoleEntity(name: RoleName('extra'), allowedResources: const {}),
      );

      listResult = await controller.listRoles();
      final after =
          (listResult as Ok<List<RoleEntity>, DomainFailure>).value.length;
      expect(after, before + 1);
    });
  });

  group('E2E — JSON asset loading', () {
    testWidgets('loads policies from bundled JSON asset', (tester) async {
      final controller = PolicyEngineController.withRepository(
        repository: InMemoryPolicyRepository(),
        assetLoader: const FlutterAssetLoader(),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: (_, __) => const SizedBox.shrink(),
        ),
      );

      final result = await controller
          .loadPoliciesFromAsset('assets/policies/user_roles.json');
      expect(result.isOk, isTrue);

      final adminResult =
          await controller.evaluateAccess('admin', 'dashboard');
      expect(
        (adminResult as Ok<AccessDecision, DomainFailure>).value.isGranted,
        isTrue,
      );
    });

    testWidgets('missing asset returns StorageFailure', (tester) async {
      final controller = PolicyEngineController.withRepository(
        repository: InMemoryPolicyRepository(),
        assetLoader: const FlutterAssetLoader(),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: (_, __) => const SizedBox.shrink(),
        ),
      );

      final result =
          await controller.loadPoliciesFromAsset('assets/missing.json');
      expect(result.isErr, isTrue);
    });
  });

  group('E2E — ABAC attribute-based evaluation', () {
    // The AbacEvaluator is a standalone service; combine its decision with
    // the RbacEvaluator to form a composite access decision.
    AccessDecision evaluate({
      required Policy policy,
      required String roleName,
      required Resource resource,
      required Subject subject,
      required AbacPolicy abacPolicy,
    }) {
      final rbac = const RbacEvaluator()
          .evaluate(roleName, resource.id, policy);
      if (rbac.isDenied) return rbac;
      return const AbacEvaluator()
          .evaluate(subject, resource, abacPolicy);
    }

    testWidgets('subject with matching region attribute is granted',
        (tester) async {
      const abacPolicy = AbacPolicy(
        rules: [
          AttributeRule(
            subjectAttribute: 'region',
            expectedValue: 'eu',
          ),
        ],
      );

      final repo = InMemoryPolicyRepository();
      await repo.save(
        Policy(
          roles: {
            'analyst': RoleEntity(
              name: RoleName('analyst'),
              allowedResources: const {'gdpr_data'},
            ),
          },
        ),
      );

      final policy =
          (await repo.load()).getOrElse(const Policy(roles: {}));
      const euSubject = Subject(
        attributes: {'region': 'eu'},
      );
      final resource = Resource(id: 'gdpr_data');

      final decision = evaluate(
        policy: policy,
        roleName: 'analyst',
        resource: resource,
        subject: euSubject,
        abacPolicy: abacPolicy,
      );

      expect(decision.isGranted, isTrue);
    });

    testWidgets('subject with non-matching region attribute is denied',
        (tester) async {
      const abacPolicy = AbacPolicy(
        rules: [
          AttributeRule(
            subjectAttribute: 'region',
            expectedValue: 'eu',
          ),
        ],
      );

      final repo = InMemoryPolicyRepository();
      await repo.save(
        Policy(
          roles: {
            'analyst': RoleEntity(
              name: RoleName('analyst'),
              allowedResources: const {'gdpr_data'},
            ),
          },
        ),
      );

      final policy =
          (await repo.load()).getOrElse(const Policy(roles: {}));
      const usSubject = Subject(
        attributes: {'region': 'us'},
      );
      final resource = Resource(id: 'gdpr_data');

      final decision = evaluate(
        policy: policy,
        roleName: 'analyst',
        resource: resource,
        subject: usSubject,
        abacPolicy: abacPolicy,
      );

      expect(decision.isGranted, isFalse);
    });
  });
}
