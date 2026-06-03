// BDD feature tests for spec-006-presentation.md

import 'package:flutter/widgets.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/presentation/providers/policy_engine_scope.dart';
import 'package:flutter_policy_engine/src/presentation/state/policy_engine_controller.dart';
import 'package:flutter_policy_engine/src/presentation/widgets/policy_builder.dart';
import 'package:flutter_policy_engine/src/presentation/widgets/policy_gate.dart';
import 'package:flutter_test/flutter_test.dart';

const _adminPolicy = <String, dynamic>{
  'roles': <String, dynamic>{
    'admin': <String, dynamic>{
      'allowedResources': <String>['dashboard', 'settings'],
    },
    'guest': <String, dynamic>{
      'allowedResources': <String>['home'],
    },
  },
};

Widget _wrap(PolicyEngineController controller, Widget child) =>
    PolicyEngineScope(controller: controller, child: child);

void main() {
  group('Feature: Presentation (spec-006)', () {
    group('Scenario: PolicyGate grants access to authorised role', () {
      testWidgets(
          'Given admin policy loaded, '
          'When admin accesses dashboard, '
          'Then protected content is visible', (tester) async {
        final controller = PolicyEngineController.inMemory();
        addTearDown(controller.dispose);
        await controller.loadPolicies(_adminPolicy);

        await tester.pumpWidget(
          _wrap(
            controller,
            const PolicyGate(
              roleName: 'admin',
              resourceId: 'dashboard',
              fallback: Text(
                'Denied',
                textDirection: TextDirection.ltr,
              ),
              child: Text(
                'Dashboard',
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Denied'), findsNothing);
      });
    });

    group('Scenario: PolicyGate denies access to unauthorised role', () {
      testWidgets(
          'Given admin policy loaded, '
          'When guest accesses settings, '
          'Then fallback is shown', (tester) async {
        final controller = PolicyEngineController.inMemory();
        addTearDown(controller.dispose);
        await controller.loadPolicies(_adminPolicy);

        DomainFailure? deniedWith;

        await tester.pumpWidget(
          _wrap(
            controller,
            PolicyGate(
              roleName: 'guest',
              resourceId: 'settings',
              fallback: const Text(
                'Access Denied',
                textDirection: TextDirection.ltr,
              ),
              onDenied: (f) => deniedWith = f,
              child: const Text(
                'Settings',
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Settings'), findsNothing);
        expect(find.text('Access Denied'), findsOneWidget);
        expect(deniedWith, isNotNull);
      });
    });

    group('Scenario: PolicyBuilder exposes decision to subtree', () {
      testWidgets(
          'Given admin policy loaded, '
          'When builder renders for granted role, '
          'Then decision.isGranted is true', (tester) async {
        final controller = PolicyEngineController.inMemory();
        addTearDown(controller.dispose);
        await controller.loadPolicies(_adminPolicy);

        bool? grantedSeen;

        await tester.pumpWidget(
          _wrap(
            controller,
            PolicyBuilder(
              roleName: 'admin',
              resourceId: 'settings',
              builder: (context, decision) {
                grantedSeen = decision?.isGranted;
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        await tester.pump();

        expect(grantedSeen, isTrue);
      });
    });

    group('Scenario: Widget tree rebuilds after policy change', () {
      testWidgets(
          'Given PolicyEngineScope in tree, '
          'When loadPolicies is called again, '
          'Then subscribed builders rebuild', (tester) async {
        final controller = PolicyEngineController.inMemory();
        addTearDown(controller.dispose);
        await controller.loadPolicies(_adminPolicy);

        var buildCount = 0;

        await tester.pumpWidget(
          _wrap(
            controller,
            PolicyBuilder(
              roleName: 'admin',
              resourceId: 'dashboard',
              builder: (context, decision) {
                buildCount++;
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        await tester.pump();
        final before = buildCount;

        await controller.loadPolicies(_adminPolicy);
        await tester.pump();

        expect(buildCount, greaterThan(before));
      });
    });

    group('Scenario: Engine not initialised shows fallback via PolicyGate', () {
      testWidgets(
          'Given uninitialized controller, '
          'When PolicyGate renders, '
          'Then fallback shown with EngineNotInitializedFailure', (
        tester,
      ) async {
        final controller = PolicyEngineController.inMemory();
        addTearDown(controller.dispose);

        DomainFailure? failure;

        await tester.pumpWidget(
          _wrap(
            controller,
            PolicyGate(
              roleName: 'admin',
              resourceId: 'dashboard',
              fallback: const Text(
                'not ready',
                textDirection: TextDirection.ltr,
              ),
              onDenied: (f) => failure = f,
              child:
                  const Text('ok', textDirection: TextDirection.ltr),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('not ready'), findsOneWidget);
        expect(failure, isA<EngineNotInitializedFailure>());
      });
    });
  });
}
