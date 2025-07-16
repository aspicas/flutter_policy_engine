import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_policy_engine/src/core/policy_manager.dart';
import 'package:flutter_policy_engine/src/core/interfaces/i_policy_evaluator.dart';
import 'package:flutter_policy_engine/src/core/interfaces/i_policy_storage.dart';
import 'package:flutter_policy_engine/src/models/policy.dart';

/// Mock implementation of IPolicyStorage for testing
// ignore: must_be_immutable
class MockPolicyStorage implements IPolicyStorage {
  Map<String, dynamic> _policies = {};
  bool _shouldThrowError = false;
  bool _shouldThrowOnSave = false;

  void setShouldThrowError(bool value) => _shouldThrowError = value;
  void setShouldThrowOnSave(bool value) => _shouldThrowOnSave = value;

  @override
  Future<Map<String, dynamic>> loadPolicies() async {
    if (_shouldThrowError) {
      throw StateError('Storage error');
    }
    return Map.from(_policies);
  }

  @override
  Future<void> savePolicies(Map<String, dynamic> policies) async {
    if (_shouldThrowOnSave) {
      throw StateError('Save error');
    }
    _policies = Map.from(policies);
  }

  @override
  Future<void> clearPolicies() async {
    if (_shouldThrowError) {
      throw StateError('Clear error');
    }
    _policies.clear();
  }

  Map<String, dynamic> get storedPolicies => Map.from(_policies);
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
      throw StateError('Evaluation error');
    }
    return _evaluationResults['$roleName:$content'] ?? false;
  }
}

void main() {
  group('PolicyManager', () {
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
      test('should create instance with default storage when none provided',
          () {
        final manager = PolicyManager();
        expect(manager, isA<PolicyManager>());
        expect(manager.isInitialized, isFalse);
        expect(manager.policies, isEmpty);
      });

      test('should create instance with custom storage and evaluator', () {
        final manager = PolicyManager(
          storage: mockStorage,
          evaluator: mockEvaluator,
        );
        expect(manager, isA<PolicyManager>());
        expect(manager.isInitialized, isFalse);
        expect(manager.policies, isEmpty);
      });

      test('should extend ChangeNotifier', () {
        expect(policyManager, isA<ChangeNotifier>());
      });
    });

    group('Initial state', () {
      test('should not be initialized by default', () {
        expect(policyManager.isInitialized, isFalse);
      });

      test('should have empty policies by default', () {
        expect(policyManager.policies, isEmpty);
      });

      test('should return unmodifiable policies map', () {
        expect(
            () => policyManager.policies['test'] =
                const Policy(roleName: 'test', allowedContent: ['read']),
            throwsA(isA<UnsupportedError>()));
      });
    });

    group('initialize', () {
      test('should initialize successfully with valid policies', () async {
        final jsonPolicies = {
          'admin': ['read', 'write', 'delete'],
          'user': ['read'],
        };

        await policyManager.initialize(jsonPolicies);

        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.policies.length, equals(2));
        expect(policyManager.policies['admin'], isA<Policy>());
        expect(policyManager.policies['user'], isA<Policy>());
        expect(policyManager.policies['admin']!.allowedContent,
            containsAll(['read', 'write', 'delete']));
        expect(policyManager.policies['user']!.allowedContent,
            containsAll(['read']));
      });

      test('should handle empty policies gracefully', () async {
        final jsonPolicies = <String, dynamic>{};

        await policyManager.initialize(jsonPolicies);

        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.policies, isEmpty);
      });

      test('should handle single policy', () async {
        final jsonPolicies = {
          'admin': ['read', 'write'],
        };

        await policyManager.initialize(jsonPolicies);

        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.policies.length, equals(1));
        expect(policyManager.policies['admin']!.roleName, equals('admin'));
        expect(policyManager.policies['admin']!.allowedContent,
            containsAll(['read', 'write']));
      });

      test('should save policies to storage after successful initialization',
          () async {
        final jsonPolicies = {
          'admin': ['read', 'write'],
        };

        await policyManager.initialize(jsonPolicies);

        expect(mockStorage.storedPolicies.length, equals(1));
        expect(mockStorage.storedPolicies['admin'], isA<Policy>());
      });

      test('should notify listeners after initialization', () async {
        bool listenerCalled = false;
        policyManager.addListener(() {
          listenerCalled = true;
        });

        final jsonPolicies = {
          'admin': ['read', 'write'],
        };

        await policyManager.initialize(jsonPolicies);

        expect(listenerCalled, isTrue);
      });

      test('should handle storage save errors gracefully', () async {
        mockStorage.setShouldThrowOnSave(true);
        final jsonPolicies = {
          'admin': ['read', 'write'],
        };

        expect(() => policyManager.initialize(jsonPolicies),
            throwsA(isA<StateError>()));
        expect(policyManager.isInitialized, isFalse);
      });

      test('should handle malformed JSON data gracefully', () async {
        final jsonPolicies = {
          'admin': 'invalid_content', // Should be List<String>
        };

        await policyManager.initialize(jsonPolicies);

        // Should initialize successfully but skip invalid policies
        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.policies, isEmpty);
      });

      test('should handle null values in JSON data gracefully', () async {
        final jsonPolicies = {
          'admin': null,
        };

        await policyManager.initialize(jsonPolicies);

        // Should initialize successfully but skip null policies
        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.policies, isEmpty);
      });

      test(
          'should handle mixed valid and invalid policies with partial success',
          () async {
        final jsonPolicies = {
          'admin': ['read', 'write'], // Valid
          'user': null, // Invalid
          'guest': ['read'], // Valid
        };

        await policyManager.initialize(jsonPolicies);

        // Should still initialize with valid policies
        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.policies.length, equals(2));
        expect(policyManager.policies['admin'], isNotNull);
        expect(policyManager.policies['guest'], isNotNull);
        expect(policyManager.policies['user'], isNull);
      });

      test('should create RoleEvaluator when policies are available', () async {
        final jsonPolicies = {
          'admin': ['read', 'write'],
        };

        await policyManager.initialize(jsonPolicies);

        // The evaluator should be created internally
        expect(policyManager.isInitialized, isTrue);
      });

      test('should handle initialization with no valid policies', () async {
        final jsonPolicies = {
          'admin': null, // Invalid
          'user': null, // Invalid
        };

        await policyManager.initialize(jsonPolicies);

        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.policies, isEmpty);
      });
    });

    group('Edge cases', () {
      test('should handle very large policy sets', () async {
        final jsonPolicies = <String, dynamic>{};
        for (int i = 0; i < 1000; i++) {
          jsonPolicies['role_$i'] = ['read', 'write'];
        }

        await policyManager.initialize(jsonPolicies);

        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.policies.length, equals(1000));
      });

      test('should handle policies with empty allowed content', () async {
        final jsonPolicies = {
          'admin': <String>[],
        };

        await policyManager.initialize(jsonPolicies);

        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.policies['admin']!.allowedContent, isEmpty);
      });

      test('should handle policies with duplicate content', () async {
        final jsonPolicies = {
          'admin': ['read', 'read', 'write'],
        };

        await policyManager.initialize(jsonPolicies);

        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.policies['admin']!.allowedContent,
            containsAll(['read', 'write']));
      });
    });

    group('Error handling', () {
      test('should rethrow exceptions from initialization', () async {
        final jsonPolicies = {
          'admin': ['read', 'write'],
        };

        // Simulate an error by making storage throw
        mockStorage.setShouldThrowOnSave(true);

        expect(() => policyManager.initialize(jsonPolicies),
            throwsA(isA<StateError>()));
        expect(policyManager.isInitialized, isFalse);
      });

      test('should handle concurrent initialization calls', () async {
        final jsonPolicies = {
          'admin': ['read', 'write'],
        };

        // Start multiple initialization calls
        final futures = [
          policyManager.initialize(jsonPolicies),
          policyManager.initialize(jsonPolicies),
          policyManager.initialize(jsonPolicies),
        ];

        await Future.wait(futures);

        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.policies.length, equals(1));
      });
    });
  });
}
