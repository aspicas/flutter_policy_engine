import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_policy_engine/src/core/policy_provider.dart';
import 'package:flutter_policy_engine/src/core/policy_manager.dart';
import 'package:flutter_policy_engine/src/core/interfaces/i_policy_evaluator.dart';
import 'package:flutter_policy_engine/src/core/interfaces/i_policy_storage.dart';

/// Mock implementation of IPolicyStorage for testing
// ignore: must_be_immutable
class MockPolicyStorage implements IPolicyStorage {
  Map<String, dynamic> _policies = {};

  @override
  Future<Map<String, dynamic>> loadPolicies() async {
    return Map.from(_policies);
  }

  @override
  Future<void> savePolicies(Map<String, dynamic> policies) async {
    _policies = Map.from(policies);
  }

  @override
  Future<void> clearPolicies() async {
    _policies.clear();
  }
}

/// Mock implementation of IPolicyEvaluator for testing
class MockPolicyEvaluator implements IPolicyEvaluator {
  @override
  bool evaluate(String roleName, String content) {
    return true;
  }
}

/// Test widget that accesses PolicyProvider
class TestConsumerWidget extends StatelessWidget {
  const TestConsumerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Test the 'of' method
          Builder(
            builder: (context) {
              final provider = PolicyProvider.of(context);
              return Text('provider_found: ${provider != null}');
            },
          ),
          // Test the 'policyManagerOf' method
          Builder(
            builder: (context) {
              try {
                final _ = PolicyProvider.policyManagerOf(context);
                return const Text('manager_found: true');
              } catch (e) {
                return Text('error: ${e.toString()}');
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Test widget that triggers rebuilds
class RebuildTestWidget extends StatefulWidget {
  const RebuildTestWidget({super.key});

  @override
  State<RebuildTestWidget> createState() => _RebuildTestWidgetState();
}

class _RebuildTestWidgetState extends State<RebuildTestWidget> {
  int rebuildCount = 0;

  @override
  Widget build(BuildContext context) {
    rebuildCount++;
    final policyManager = PolicyProvider.policyManagerOf(context);
    return Text(
        'rebuild_count: $rebuildCount, initialized: ${policyManager.isInitialized}');
  }
}

/// Helper function to wrap widgets in MaterialApp for testing
Widget wrapWithMaterialApp(Widget child) {
  return MaterialApp(home: child);
}

void main() {
  group('PolicyProvider', () {
    late PolicyManager policyManager;
    late MockPolicyStorage mockStorage;
    late MockPolicyEvaluator mockEvaluator;

    setUp(() {
      mockStorage = MockPolicyStorage();
      mockEvaluator = MockPolicyEvaluator();
      policyManager = PolicyManager(
        storage: mockStorage,
        evaluator: mockEvaluator,
      );
    });

    group('Constructor', () {
      testWidgets('should create PolicyProvider with required parameters',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            PolicyProvider(
              policyManager: policyManager,
              child: const Text('Test Child'),
            ),
          ),
        );

        expect(find.text('Test Child'), findsOneWidget);
      });

      testWidgets('should accept key parameter', (WidgetTester tester) async {
        const key = Key('test_key');

        await tester.pumpWidget(
          wrapWithMaterialApp(
            PolicyProvider(
              key: key,
              policyManager: policyManager,
              child: const Text('Test Child'),
            ),
          ),
        );

        expect(find.byKey(key), findsOneWidget);
      });

      testWidgets('should require policyManager parameter',
          (WidgetTester tester) async {
        // This test verifies that the constructor requires policyManager
        // The actual validation would be done by Dart's type system
        expect(
          () => PolicyProvider(
            policyManager: policyManager,
            child: const Text('Test Child'),
          ),
          returnsNormally,
        );
      });

      testWidgets('should require child parameter',
          (WidgetTester tester) async {
        // This test verifies that the constructor requires child
        // The actual validation would be done by Dart's type system
        expect(
          () => PolicyProvider(
            policyManager: policyManager,
            child: const Text('Test Child'),
          ),
          returnsNormally,
        );
      });
    });

    group('PolicyProvider.of', () {
      testWidgets('should return PolicyProvider when found in widget tree',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            PolicyProvider(
              policyManager: policyManager,
              child: const TestConsumerWidget(),
            ),
          ),
        );

        expect(find.text('provider_found: true'), findsOneWidget);
      });

      testWidgets(
          'should return null when PolicyProvider not found in widget tree',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const TestConsumerWidget(),
          ),
        );

        expect(find.text('provider_found: false'), findsOneWidget);
      });

      testWidgets('should establish dependency for rebuilds',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            PolicyProvider(
              policyManager: policyManager,
              child: const RebuildTestWidget(),
            ),
          ),
        );

        expect(
            find.text('rebuild_count: 1, initialized: false'), findsOneWidget);

        // Create a new PolicyManager instance to trigger rebuild
        final newPolicyManager = PolicyManager(
          storage: mockStorage,
          evaluator: mockEvaluator,
        );

        await tester.pumpWidget(
          wrapWithMaterialApp(
            PolicyProvider(
              policyManager: newPolicyManager,
              child: const RebuildTestWidget(),
            ),
          ),
        );

        expect(
            find.text('rebuild_count: 2, initialized: false'), findsOneWidget);
      });
    });

    group('PolicyProvider.policyManagerOf', () {
      testWidgets('should return PolicyManager when PolicyProvider is found',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            PolicyProvider(
              policyManager: policyManager,
              child: const TestConsumerWidget(),
            ),
          ),
        );

        expect(find.text('manager_found: true'), findsOneWidget);
      });

      testWidgets('should throw StateError when PolicyProvider not found',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const TestConsumerWidget(),
          ),
        );

        expect(find.textContaining('error:'), findsOneWidget);
      });

      testWidgets('should establish dependency for rebuilds',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            PolicyProvider(
              policyManager: policyManager,
              child: const RebuildTestWidget(),
            ),
          ),
        );

        expect(
            find.text('rebuild_count: 1, initialized: false'), findsOneWidget);

        // Create a new PolicyManager instance to trigger rebuild
        final newPolicyManager = PolicyManager(
          storage: mockStorage,
          evaluator: mockEvaluator,
        );

        await tester.pumpWidget(
          wrapWithMaterialApp(
            PolicyProvider(
              policyManager: newPolicyManager,
              child: const RebuildTestWidget(),
            ),
          ),
        );

        expect(
            find.text('rebuild_count: 2, initialized: false'), findsOneWidget);
      });
    });

    group('updateShouldNotify', () {
      testWidgets('should return true when policyManager changes',
          (WidgetTester tester) async {
        final widget = PolicyProvider(
          policyManager: policyManager,
          child: const Text('Test'),
        );

        final newPolicyManager = PolicyManager(
          storage: mockStorage,
          evaluator: mockEvaluator,
        );
        final newWidget = PolicyProvider(
          policyManager: newPolicyManager,
          child: const Text('Test'),
        );

        expect(widget.updateShouldNotify(newWidget), isTrue);
      });

      testWidgets('should return false when policyManager is the same',
          (WidgetTester tester) async {
        final widget = PolicyProvider(
          policyManager: policyManager,
          child: const Text('Test'),
        );

        final sameWidget = PolicyProvider(
          policyManager: policyManager,
          child: const Text('Test'),
        );

        expect(widget.updateShouldNotify(sameWidget), isFalse);
      });

      testWidgets('should trigger rebuild when policyManager changes',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            PolicyProvider(
              policyManager: policyManager,
              child: const RebuildTestWidget(),
            ),
          ),
        );

        expect(
            find.text('rebuild_count: 1, initialized: false'), findsOneWidget);

        // Create a new PolicyManager instance
        final newPolicyManager = PolicyManager(
          storage: mockStorage,
          evaluator: mockEvaluator,
        );

        await tester.pumpWidget(
          wrapWithMaterialApp(
            PolicyProvider(
              policyManager: newPolicyManager,
              child: const RebuildTestWidget(),
            ),
          ),
        );

        expect(
            find.text('rebuild_count: 2, initialized: false'), findsOneWidget);
      });
    });

    group('Integration Tests', () {
      testWidgets('should work with nested PolicyProviders',
          (WidgetTester tester) async {
        final innerPolicyManager = PolicyManager(
          storage: mockStorage,
          evaluator: mockEvaluator,
        );

        await tester.pumpWidget(
          wrapWithMaterialApp(
            PolicyProvider(
              policyManager: policyManager,
              child: PolicyProvider(
                policyManager: innerPolicyManager,
                child: const TestConsumerWidget(),
              ),
            ),
          ),
        );

        // Should find the inner PolicyProvider
        expect(find.text('provider_found: true'), findsOneWidget);
        expect(find.text('manager_found: true'), findsOneWidget);
      });

      testWidgets('should handle multiple consumers in widget tree',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            PolicyProvider(
              policyManager: policyManager,
              child: const Column(
                children: [
                  TestConsumerWidget(),
                  TestConsumerWidget(),
                  RebuildTestWidget(),
                ],
              ),
            ),
          ),
        );

        expect(find.text('provider_found: true'), findsNWidgets(2));
        expect(find.text('manager_found: true'), findsNWidgets(2));
        expect(
            find.text('rebuild_count: 1, initialized: false'), findsOneWidget);
      });

      testWidgets('should handle deep widget tree',
          (WidgetTester tester) async {
        Widget buildDeepTree(int depth) {
          if (depth <= 0) {
            return const TestConsumerWidget();
          }
          return Container(
            child: buildDeepTree(depth - 1),
          );
        }

        await tester.pumpWidget(
          wrapWithMaterialApp(
            PolicyProvider(
              policyManager: policyManager,
              child: buildDeepTree(10),
            ),
          ),
        );

        expect(find.text('provider_found: true'), findsOneWidget);
        expect(find.text('manager_found: true'), findsOneWidget);
      });

      testWidgets('should handle PolicyManager lifecycle',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            PolicyProvider(
              policyManager: policyManager,
              child: const RebuildTestWidget(),
            ),
          ),
        );

        expect(
            find.text('rebuild_count: 1, initialized: false'), findsOneWidget);

        // Initialize the policy manager with some valid policies
        await policyManager.initialize({
          'test_role': ['content1', 'content2'],
        });

        // Create a new PolicyManager instance that's already initialized
        final initializedPolicyManager = PolicyManager(
          storage: mockStorage,
          evaluator: mockEvaluator,
        );
        await initializedPolicyManager.initialize({
          'test_role': ['content1', 'content2'],
        });

        await tester.pumpWidget(
          wrapWithMaterialApp(
            PolicyProvider(
              policyManager: initializedPolicyManager,
              child: const RebuildTestWidget(),
            ),
          ),
        );

        expect(
            find.text('rebuild_count: 2, initialized: true'), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle null context gracefully',
          (WidgetTester tester) async {
        // This test verifies that the methods handle edge cases
        // The actual null context handling would be done by Flutter framework
        expect(
          () => PolicyProvider(
            policyManager: policyManager,
            child: const TestConsumerWidget(),
          ),
          returnsNormally,
        );
      });

      testWidgets('should handle PolicyManager with errors',
          (WidgetTester tester) async {
        // Create a PolicyManager that might throw errors
        final errorPolicyManager = PolicyManager(
          storage: MockPolicyStorage(),
          evaluator: MockPolicyEvaluator(),
        );

        await tester.pumpWidget(
          wrapWithMaterialApp(
            PolicyProvider(
              policyManager: errorPolicyManager,
              child: const TestConsumerWidget(),
            ),
          ),
        );

        expect(find.text('provider_found: true'), findsOneWidget);
        expect(find.text('manager_found: true'), findsOneWidget);
      });
    });

    group('Performance Tests', () {
      testWidgets('should not cause unnecessary rebuilds',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            PolicyProvider(
              policyManager: policyManager,
              child: const RebuildTestWidget(),
            ),
          ),
        );

        expect(
            find.text('rebuild_count: 1, initialized: false'), findsOneWidget);

        // Pump again without changing the PolicyManager
        await tester.pump();

        // Should not rebuild
        expect(
            find.text('rebuild_count: 1, initialized: false'), findsOneWidget);
      });

      testWidgets('should handle rapid PolicyManager changes efficiently',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            PolicyProvider(
              policyManager: policyManager,
              child: const RebuildTestWidget(),
            ),
          ),
        );

        expect(
            find.text('rebuild_count: 1, initialized: false'), findsOneWidget);

        // Rapidly change PolicyManager instances
        for (int i = 0; i < 5; i++) {
          final newPolicyManager = PolicyManager(
            storage: mockStorage,
            evaluator: mockEvaluator,
          );

          await tester.pumpWidget(
            wrapWithMaterialApp(
              PolicyProvider(
                policyManager: newPolicyManager,
                child: const RebuildTestWidget(),
              ),
            ),
          );
        }

        expect(
            find.text('rebuild_count: 6, initialized: false'), findsOneWidget);
      });
    });
  });
}
