import 'package:flutter/widgets.dart';
import 'package:flutter_policy_engine/src/domain/entities/access_decision.dart';
import 'package:flutter_policy_engine/src/presentation/providers/policy_engine_scope.dart';
import 'package:flutter_policy_engine/src/presentation/state/policy_engine_controller.dart';
import 'package:flutter_policy_engine/src/presentation/widgets/policy_builder.dart';
import 'package:flutter_test/flutter_test.dart';

const _policy = <String, dynamic>{
  'roles': <String, dynamic>{
    'editor': <String, dynamic>{
      'allowedResources': <String>['posts'],
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
  group('PolicyBuilder', () {
    late PolicyEngineController controller;

    setUp(() async {
      controller = PolicyEngineController.inMemory();
      await controller.loadPolicies(_policy);
    });

    tearDown(() => controller.dispose());

    testWidgets('builder receives null decision before evaluation', (
      tester,
    ) async {
      AccessDecision? captured;
      var buildCount = 0;

      await tester.pumpWidget(
        _wrap(
          controller: controller,
          child: PolicyBuilder(
            roleName: 'editor',
            resourceId: 'posts',
            builder: (context, decision) {
              captured = decision;
              buildCount++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // First build — FutureBuilder hasn't resolved yet.
      expect(captured, isNull);
      expect(buildCount, greaterThanOrEqualTo(1));
    });

    testWidgets('builder receives granted decision after evaluation',
        (tester) async {
      AccessDecision? lastDecision;

      await tester.pumpWidget(
        _wrap(
          controller: controller,
          child: PolicyBuilder(
            roleName: 'editor',
            resourceId: 'posts',
            builder: (context, decision) {
              lastDecision = decision;
              return Text(
                decision?.isGranted ?? false ? 'granted' : 'loading',
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );
      await tester.pump();

      expect(lastDecision?.isGranted, isTrue);
      expect(find.text('granted'), findsOneWidget);
    });

    testWidgets('builder receives denied decision for unknown resource',
        (tester) async {
      AccessDecision? lastDecision;

      await tester.pumpWidget(
        _wrap(
          controller: controller,
          child: PolicyBuilder(
            roleName: 'editor',
            resourceId: 'admin',
            builder: (context, decision) {
              lastDecision = decision;
              return Text(
                decision?.isGranted ?? false ? 'granted' : 'denied',
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );
      await tester.pump();

      expect(lastDecision?.isGranted, isFalse);
      expect(find.text('denied'), findsOneWidget);
    });

    testWidgets('rebuilds when controller notifies', (tester) async {
      var buildCount = 0;

      await tester.pumpWidget(
        _wrap(
          controller: controller,
          child: PolicyBuilder(
            roleName: 'editor',
            resourceId: 'posts',
            builder: (context, decision) {
              buildCount++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();
      final countAfterFirst = buildCount;

      await controller.loadPolicies(_policy);
      await tester.pump();

      expect(buildCount, greaterThan(countAfterFirst));
    });
  });
}
