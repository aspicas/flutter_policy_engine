import 'package:flutter/widgets.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/presentation/providers/policy_engine_scope.dart';
import 'package:flutter_policy_engine/src/presentation/state/policy_engine_controller.dart';
import 'package:flutter_policy_engine/src/presentation/widgets/policy_gate.dart';
import 'package:flutter_test/flutter_test.dart';

const _policy = <String, dynamic>{
  'roles': <String, dynamic>{
    'admin': <String, dynamic>{
      'allowedResources': <String>['dashboard'],
    },
    'viewer': <String, dynamic>{
      'allowedResources': <String>['reports'],
    },
  },
};

Widget _wrap({
  required PolicyEngineController controller,
  required Widget child,
}) {
  return PolicyEngineScope(
    controller: controller,
    child: child,
  );
}

void main() {
  group('PolicyGate', () {
    late PolicyEngineController controller;

    setUp(() async {
      controller = PolicyEngineController.inMemory();
      await controller.loadPolicies(_policy);
    });

    tearDown(() => controller.dispose());

    testWidgets('shows child when access is granted', (tester) async {
      await tester.pumpWidget(
        _wrap(
          controller: controller,
          child: const PolicyGate(
            roleName: 'admin',
            resourceId: 'dashboard',
            child: Text('Protected Content', textDirection: TextDirection.ltr),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Protected Content'), findsOneWidget);
    });

    testWidgets('shows fallback when access is denied', (tester) async {
      await tester.pumpWidget(
        _wrap(
          controller: controller,
          child: const PolicyGate(
            roleName: 'viewer',
            resourceId: 'dashboard',
            fallback: Text(
              'Access Denied',
              textDirection: TextDirection.ltr,
            ),
            child: Text('Secret', textDirection: TextDirection.ltr),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Secret'), findsNothing);
      expect(find.text('Access Denied'), findsOneWidget);
    });

    testWidgets('shows SizedBox.shrink as default fallback', (tester) async {
      await tester.pumpWidget(
        _wrap(
          controller: controller,
          child: const PolicyGate(
            roleName: 'viewer',
            resourceId: 'dashboard',
            child: Text('Secret', textDirection: TextDirection.ltr),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Secret'), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('calls onDenied when access is denied', (tester) async {
      DomainFailure? capturedFailure;

      await tester.pumpWidget(
        _wrap(
          controller: controller,
          child: PolicyGate(
            roleName: 'viewer',
            resourceId: 'dashboard',
            child: const SizedBox.shrink(),
            onDenied: (f) => capturedFailure = f,
          ),
        ),
      );
      await tester.pump();
      expect(capturedFailure, isNotNull);
    });

    testWidgets('shows loading widget while evaluating', (tester) async {
      await tester.pumpWidget(
        _wrap(
          controller: controller,
          child: const PolicyGate(
            roleName: 'admin',
            resourceId: 'dashboard',
            loading: Text('Loading…', textDirection: TextDirection.ltr),
            child: Text('Ready', textDirection: TextDirection.ltr),
          ),
        ),
      );
      // Before pump — FutureBuilder hasn't resolved yet.
      expect(find.text('Loading…'), findsOneWidget);
      await tester.pump();
      expect(find.text('Ready'), findsOneWidget);
    });

    testWidgets('shows fallback for uninitialized engine', (tester) async {
      final uninit = PolicyEngineController.inMemory();
      addTearDown(uninit.dispose);

      DomainFailure? failure;

      await tester.pumpWidget(
        _wrap(
          controller: uninit,
          child: PolicyGate(
            roleName: 'admin',
            resourceId: 'dashboard',
            fallback: const Text('denied', textDirection: TextDirection.ltr),
            onDenied: (f) => failure = f,
            child: const Text('ok', textDirection: TextDirection.ltr),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('denied'), findsOneWidget);
      expect(failure, isA<EngineNotInitializedFailure>());
    });
  });
}
