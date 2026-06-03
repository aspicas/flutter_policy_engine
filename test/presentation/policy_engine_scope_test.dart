import 'package:flutter/widgets.dart';
import 'package:flutter_policy_engine/src/presentation/providers/policy_engine_scope.dart';
import 'package:flutter_policy_engine/src/presentation/state/policy_engine_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PolicyEngineScope', () {
    testWidgets('of() returns controller from context', (tester) async {
      final controller = PolicyEngineController.inMemory();
      addTearDown(controller.dispose);

      PolicyEngineController? found;

      await tester.pumpWidget(
        PolicyEngineScope(
          controller: controller,
          child: Builder(
            builder: (context) {
              found = PolicyEngineScope.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(found, same(controller));
    });

    testWidgets('of() throws FlutterError when not in tree', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            expect(
              () => PolicyEngineScope.of(context),
              throwsA(isA<FlutterError>()),
            );
            return const SizedBox.shrink();
          },
        ),
      );
    });

    testWidgets('maybeOf() returns null when not in tree', (tester) async {
      PolicyEngineController? found;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            found = PolicyEngineScope.maybeOf(context);
            return const SizedBox.shrink();
          },
        ),
      );

      expect(found, isNull);
    });

    testWidgets('rebuilds dependants when controller notifies', (tester) async {
      final controller = PolicyEngineController.inMemory();
      addTearDown(controller.dispose);

      var buildCount = 0;

      await tester.pumpWidget(
        PolicyEngineScope(
          controller: controller,
          child: Builder(
            builder: (context) {
              PolicyEngineScope.of(context); // subscribe
              buildCount++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(buildCount, 1);

      await controller.loadPolicies(
        <String, dynamic>{'roles': <String, dynamic>{}},
      );
      await tester.pump();

      expect(buildCount, 2);
    });
  });
}
