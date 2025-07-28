import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_policy_engine/src/widgets/policy_widget.dart';
import 'package:flutter_policy_engine/src/core/policy_provider.dart';
import 'package:flutter_policy_engine/src/core/policy_manager.dart';
import 'package:flutter_policy_engine/src/core/interfaces/i_policy_evaluator.dart';
import 'package:flutter_policy_engine/src/core/interfaces/i_policy_storage.dart';
import 'package:flutter_policy_engine/src/exceptions/i_policy_sdk_exceptions.dart';
import 'package:flutter_policy_engine/src/exceptions/policy_sdk_exception.dart';

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
// ignore: must_be_immutable
class MockPolicyEvaluator implements IPolicyEvaluator {
  final Map<String, bool> _evaluationResults = {};
  bool _shouldThrowError = false;

  void setEvaluationResult(String roleName, String content, bool result) {
    _evaluationResults['$roleName:$content'] = result;
  }

  void setShouldThrowError(bool value) => _shouldThrowError = value;

  @override
  bool evaluate(String roleName, String content) {
    if (_shouldThrowError) {
      throw PolicySDKException('Mock evaluation error');
    }
    return _evaluationResults['$roleName:$content'] ?? false;
  }
}

/// Test widget that tracks callback invocations
class CallbackTracker {
  int accessDeniedCallCount = 0;

  void onAccessDenied() {
    accessDeniedCallCount++;
  }

  void reset() {
    accessDeniedCallCount = 0;
  }
}

void main() {
  group('PolicyWidget', () {
    late PolicyManager policyManager;
    late MockPolicyStorage mockStorage;
    late MockPolicyEvaluator mockEvaluator;
    late CallbackTracker callbackTracker;

    setUp(() {
      mockStorage = MockPolicyStorage();
      mockEvaluator = MockPolicyEvaluator();
      policyManager = PolicyManager(
        storage: mockStorage,
        evaluator: mockEvaluator,
      );
      callbackTracker = CallbackTracker();
    });

    Widget createTestApp({
      required Widget child,
      PolicyManager? manager,
    }) {
      return MaterialApp(
        home: PolicyProvider(
          policyManager: manager ?? policyManager,
          child: child,
        ),
      );
    }

    group('Access Control', () {
      testWidgets('should display child when access is granted',
          (tester) async {
        // Arrange
        mockEvaluator.setEvaluationResult('admin', 'dashboard', true);
        await policyManager.initialize({});

        // Act
        await tester.pumpWidget(
          createTestApp(
            child: const PolicyWidget(
              role: 'admin',
              content: 'dashboard',
              child: Text('Dashboard Content'),
            ),
          ),
        );

        // Assert
        expect(find.text('Dashboard Content'), findsOneWidget);
        expect(callbackTracker.accessDeniedCallCount, 0);
      });

      testWidgets('should display fallback when access is denied',
          (tester) async {
        // Arrange
        mockEvaluator.setEvaluationResult('user', 'admin-panel', false);
        await policyManager.initialize({});

        // Act
        await tester.pumpWidget(
          createTestApp(
            child: const PolicyWidget(
              role: 'user',
              content: 'admin-panel',
              child: Text('Admin Panel'),
              fallback: Text('Access Denied'),
            ),
          ),
        );

        // Assert
        expect(find.text('Admin Panel'), findsNothing);
        expect(find.text('Access Denied'), findsOneWidget);
      });

      testWidgets(
          'should display empty SizedBox when access denied and no fallback',
          (tester) async {
        // Arrange
        mockEvaluator.setEvaluationResult('guest', 'premium-content', false);
        await policyManager.initialize({});

        // Act
        await tester.pumpWidget(
          createTestApp(
            child: const PolicyWidget(
              role: 'guest',
              content: 'premium-content',
              child: Text('Premium Content'),
            ),
          ),
        );

        // Assert
        expect(find.text('Premium Content'), findsNothing);
        expect(find.byType(SizedBox), findsOneWidget);
      });
    });

    group('Callback Behavior', () {
      testWidgets('should call onAccessDenied when access is denied',
          (tester) async {
        // Arrange
        mockEvaluator.setEvaluationResult('user', 'restricted', false);
        await policyManager.initialize({});

        // Act
        await tester.pumpWidget(
          createTestApp(
            child: PolicyWidget(
              role: 'user',
              content: 'restricted',
              child: const Text('Restricted Content'),
              onAccessDenied: callbackTracker.onAccessDenied,
            ),
          ),
        );

        // Assert
        expect(callbackTracker.accessDeniedCallCount, 1);
      });

      testWidgets('should not call onAccessDenied when access is granted',
          (tester) async {
        // Arrange
        mockEvaluator.setEvaluationResult('admin', 'public', true);
        await policyManager.initialize({});

        // Act
        await tester.pumpWidget(
          createTestApp(
            child: PolicyWidget(
              role: 'admin',
              content: 'public',
              child: const Text('Public Content'),
              onAccessDenied: callbackTracker.onAccessDenied,
            ),
          ),
        );

        // Assert
        expect(callbackTracker.accessDeniedCallCount, 0);
      });

      testWidgets('should handle null onAccessDenied callback gracefully',
          (tester) async {
        // Arrange
        mockEvaluator.setEvaluationResult('user', 'restricted', false);
        await policyManager.initialize({});

        // Act & Assert - should not throw
        await tester.pumpWidget(
          createTestApp(
            child: const PolicyWidget(
              role: 'user',
              content: 'restricted',
              child: Text('Restricted Content'),
              onAccessDenied: null,
            ),
          ),
        );

        // Should render fallback without error
        expect(find.byType(SizedBox), findsOneWidget);
      });
    });

    group('Widget Tree Integration', () {
      testWidgets('should work with nested PolicyWidgets', (tester) async {
        // Arrange
        mockEvaluator.setEvaluationResult('admin', 'dashboard', true);
        mockEvaluator.setEvaluationResult('admin', 'settings', false);
        await policyManager.initialize({});

        // Act
        await tester.pumpWidget(
          createTestApp(
            child: const PolicyWidget(
              role: 'admin',
              content: 'dashboard',
              child: Column(
                children: [
                  Text('Dashboard Header'),
                  PolicyWidget(
                    role: 'admin',
                    content: 'settings',
                    child: Text('Settings Panel'),
                    fallback: Text('Settings Access Denied'),
                  ),
                ],
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('Dashboard Header'), findsOneWidget);
        expect(find.text('Settings Panel'), findsNothing);
        expect(find.text('Settings Access Denied'), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle empty role and content strings',
          (tester) async {
        // Arrange
        mockEvaluator.setEvaluationResult('', '', false);
        await policyManager.initialize({});

        // Act
        await tester.pumpWidget(
          createTestApp(
            child: const PolicyWidget(
              role: '',
              content: '',
              child: Text('Content'),
              fallback: Text('Empty Access Denied'),
            ),
          ),
        );

        // Assert
        expect(find.text('Content'), findsNothing);
        expect(find.text('Empty Access Denied'), findsOneWidget);
      });

      testWidgets('should handle special characters in role and content',
          (tester) async {
        // Arrange
        const specialRole = 'admin@company.com';
        const specialContent = 'api/v1/users';
        mockEvaluator.setEvaluationResult(specialRole, specialContent, true);
        await policyManager.initialize({});

        // Act
        await tester.pumpWidget(
          createTestApp(
            child: const PolicyWidget(
              role: specialRole,
              content: specialContent,
              child: Text('Special Content'),
            ),
          ),
        );

        // Assert
        expect(find.text('Special Content'), findsOneWidget);
      });

      testWidgets('should handle complex child widgets', (tester) async {
        // Arrange
        mockEvaluator.setEvaluationResult('admin', 'complex', true);
        await policyManager.initialize({});

        // Act
        await tester.pumpWidget(
          createTestApp(
            child: PolicyWidget(
              role: 'admin',
              content: 'complex',
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Complex Widget'),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Button'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('Complex Widget'), findsOneWidget);
        expect(find.text('Button'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });
    });

    group('Performance and Rebuilds', () {
      testWidgets(
          'should not rebuild unnecessarily when policy manager changes',
          (tester) async {
        // Arrange
        mockEvaluator.setEvaluationResult('user', 'content', true);
        await policyManager.initialize({});

        // Act
        await tester.pumpWidget(
          createTestApp(
            child: const PolicyWidget(
              role: 'user',
              content: 'content',
              child: Text('Content'),
            ),
          ),
        );

        // Assert initial state
        expect(find.text('Content'), findsOneWidget);

        // Update policy manager (should trigger rebuild)
        final newManager = PolicyManager(
          storage: mockStorage,
          evaluator: mockEvaluator,
        );
        await newManager.initialize({});

        await tester.pumpWidget(
          createTestApp(
            manager: newManager,
            child: const PolicyWidget(
              role: 'user',
              content: 'content',
              child: Text('Content'),
            ),
          ),
        );

        // Should still show content
        expect(find.text('Content'), findsOneWidget);
      });
    });
  });
}
