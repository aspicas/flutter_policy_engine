import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_policy_engine/src/core/policy_manager.dart';
import 'package:flutter_policy_engine/src/core/memory_policy_storage.dart';
import 'package:flutter_policy_engine/src/core/role_evaluator.dart';

void main() {
  group('Core Integration Tests', () {
    late PolicyManager policyManager;
    late MemoryPolicyStorage storage;

    setUp(() {
      storage = MemoryPolicyStorage();
      policyManager = PolicyManager(storage: storage);
    });

    group('PolicyManager with RoleEvaluator Integration', () {
      test('should initialize and evaluate policies correctly', () async {
        final jsonPolicies = {
          'admin': ['read', 'write', 'delete'],
          'user': ['read'],
          'guest': [],
        };

        await policyManager.initialize(jsonPolicies);

        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles.length, equals(3));

        // Verify policies were created correctly
        expect(policyManager.roles['admin']!.name, equals('admin'));
        expect(policyManager.roles['admin']!.allowedContent,
            containsAll(['read', 'write', 'delete']));
        expect(
            policyManager.roles['user']!.allowedContent, containsAll(['read']));
        expect(policyManager.roles['guest']!.allowedContent, isEmpty);
      });

      test('should persist policies to storage during initialization',
          () async {
        final jsonPolicies = {
          'admin': ['read', 'write'],
          'user': ['read'],
        };

        await policyManager.initialize(jsonPolicies);

        // Verify policies were saved to storage
        final storedPolicies = await storage.loadPolicies();
        expect(storedPolicies.length, equals(2));
        expect(storedPolicies['admin'], isNotNull);
        expect(storedPolicies['user'], isNotNull);
      });

      test('should handle policy updates through re-initialization', () async {
        // Initial policies
        final initialPolicies = {
          'admin': ['read', 'write'],
          'user': ['read'],
        };

        await policyManager.initialize(initialPolicies);
        expect(policyManager.roles.length, equals(2));

        // Updated policies
        final updatedPolicies = {
          'admin': ['read', 'write', 'delete'],
          'moderator': ['read', 'write'],
        };

        await policyManager.initialize(updatedPolicies);
        expect(policyManager.roles.length, equals(2));
        expect(policyManager.roles['admin']!.allowedContent,
            containsAll(['read', 'write', 'delete']));
        expect(policyManager.roles['moderator']!.allowedContent,
            containsAll(['read', 'write']));
        expect(policyManager.roles['user'], isNull); // Should be removed
      });
    });

    group('RoleEvaluator Integration', () {
      test('should evaluate policies correctly after initialization', () async {
        final jsonPolicies = {
          'admin': ['read', 'write', 'delete'],
          'user': ['read'],
          'guest': [],
        };

        await policyManager.initialize(jsonPolicies);

        // Create evaluator with the loaded policies
        final evaluator = RoleEvaluator(policyManager.roles);

        // Test admin permissions
        expect(evaluator.evaluate('admin', 'read'), isTrue);
        expect(evaluator.evaluate('admin', 'write'), isTrue);
        expect(evaluator.evaluate('admin', 'delete'), isTrue);
        expect(evaluator.evaluate('admin', 'execute'), isFalse);

        // Test user permissions
        expect(evaluator.evaluate('user', 'read'), isTrue);
        expect(evaluator.evaluate('user', 'write'), isFalse);
        expect(evaluator.evaluate('user', 'delete'), isFalse);

        // Test guest permissions
        expect(evaluator.evaluate('guest', 'read'), isFalse);
        expect(evaluator.evaluate('guest', 'write'), isFalse);

        // Test non-existent role
        expect(evaluator.evaluate('nonexistent', 'read'), isFalse);
      });

      test('should handle case-sensitive evaluation', () async {
        final jsonPolicies = {
          'admin': ['read', 'write'],
        };

        await policyManager.initialize(jsonPolicies);
        final evaluator = RoleEvaluator(policyManager.roles);

        expect(evaluator.evaluate('admin', 'read'), isTrue);
        expect(evaluator.evaluate('admin', 'READ'), isFalse);
        expect(evaluator.evaluate('admin', 'Read'), isFalse);
      });

      test('should handle special characters in content', () async {
        final jsonPolicies = {
          'admin': ['read@domain', 'write-file', 'delete_user'],
        };

        await policyManager.initialize(jsonPolicies);
        final evaluator = RoleEvaluator(policyManager.roles);

        expect(evaluator.evaluate('admin', 'read@domain'), isTrue);
        expect(evaluator.evaluate('admin', 'write-file'), isTrue);
        expect(evaluator.evaluate('admin', 'delete_user'), isTrue);
        expect(evaluator.evaluate('admin', 'read'), isFalse);
      });
    });

    group('Storage Integration', () {
      test('should maintain data consistency between manager and storage',
          () async {
        final jsonPolicies = {
          'admin': ['read', 'write'],
          'user': ['read'],
        };

        await policyManager.initialize(jsonPolicies);

        // Verify storage has the same data
        final storedPolicies = await storage.loadPolicies();
        expect(storedPolicies.length, equals(policyManager.roles.length));

        // Clear storage and verify manager is unaffected
        await storage.clearPolicies();
        expect(await storage.loadPolicies(), isEmpty);
        expect(policyManager.roles.length,
            equals(2)); // Manager still has policies
      });

      test('should handle storage errors gracefully', () async {
        // Create a storage that throws errors
        final failingStorage = _FailingPolicyStorage();
        final failingManager = PolicyManager(storage: failingStorage);

        final jsonPolicies = {
          'admin': ['read', 'write'],
        };

        // Should throw when storage fails
        expect(() => failingManager.initialize(jsonPolicies),
            throwsA(isA<StateError>()));
        expect(failingManager.isInitialized, isFalse);
      });

      test('should handle concurrent storage operations', () async {
        final jsonPolicies = {
          'admin': ['read', 'write'],
          'user': ['read'],
        };

        await policyManager.initialize(jsonPolicies);

        // Perform concurrent storage operations
        final futures = [
          storage.loadPolicies(),
          storage.loadPolicies(),
          storage.loadPolicies(),
        ];

        final results = await Future.wait(futures);
        for (final result in results) {
          expect(result.length, equals(2));
          expect(result['admin'], isNotNull);
          expect(result['user'], isNotNull);
        }
      });
    });

    group('ChangeNotifier Integration', () {
      test('should notify listeners on initialization', () async {
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

      test('should notify listeners on policy updates', () async {
        int notificationCount = 0;
        policyManager.addListener(() {
          notificationCount++;
        });

        // Initial initialization
        await policyManager.initialize({
          'admin': ['read'],
        });
        expect(notificationCount, equals(1));

        // Policy update
        await policyManager.initialize({
          'admin': ['read', 'write'],
        });
        expect(notificationCount, equals(2));
      });

      test('should handle multiple listeners', () async {
        int listener1Count = 0;
        int listener2Count = 0;

        policyManager.addListener(() {
          listener1Count++;
        });
        policyManager.addListener(() {
          listener2Count++;
        });

        final jsonPolicies = {
          'admin': ['read', 'write'],
        };

        await policyManager.initialize(jsonPolicies);

        expect(listener1Count, equals(1));
        expect(listener2Count, equals(1));
      });
    });

    group('Error Handling Integration', () {
      test('should handle malformed JSON during initialization gracefully',
          () async {
        final malformedPolicies = {
          'admin': 'invalid_content', // Should be List<String>
        };

        await policyManager.initialize(malformedPolicies);

        // Should initialize successfully but skip invalid policies
        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles, isEmpty);
      });

      test('should handle partial failures gracefully', () async {
        final mixedPolicies = {
          'admin': ['read', 'write'], // Valid
          'user': null, // Invalid
          'guest': ['read'], // Valid
        };

        await policyManager.initialize(mixedPolicies);

        // Should still initialize with valid policies
        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles.length, equals(2));
        expect(policyManager.roles['admin'], isNotNull);
        expect(policyManager.roles['guest'], isNotNull);
        expect(policyManager.roles['user'], isNull);
      });

      test('should handle empty policy set', () async {
        final emptyPolicies = <String, dynamic>{};

        await policyManager.initialize(emptyPolicies);

        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles, isEmpty);
      });
    });

    group('Performance Integration', () {
      test('should handle large policy sets efficiently', () async {
        final largePolicies = <String, dynamic>{};
        for (int i = 0; i < 1000; i++) {
          largePolicies['role_$i'] = ['read', 'write'];
        }

        final stopwatch = Stopwatch()..start();
        await policyManager.initialize(largePolicies);
        stopwatch.stop();

        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles.length, equals(1000));
        expect(stopwatch.elapsedMilliseconds,
            lessThan(5000)); // Should complete within 5 seconds
      });

      test('should handle rapid policy evaluations', () async {
        final jsonPolicies = {
          'admin': ['read', 'write'],
          'user': ['read'],
        };

        await policyManager.initialize(jsonPolicies);
        final evaluator = RoleEvaluator(policyManager.roles);

        const iterations = 10000;
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < iterations; i++) {
          evaluator.evaluate('admin', 'read');
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds,
            lessThan(1000)); // Should complete within 1 second
      });
    });

    group('Real-world Scenarios', () {
      test('should handle typical web application RBAC', () async {
        final webAppPolicies = {
          'super_admin': [
            'read',
            'write',
            'delete',
            'manage_users',
            'manage_roles'
          ],
          'admin': ['read', 'write', 'delete', 'manage_users'],
          'moderator': ['read', 'write', 'moderate'],
          'user': ['read', 'write'],
          'guest': ['read'],
        };

        await policyManager.initialize(webAppPolicies);
        final evaluator = RoleEvaluator(policyManager.roles);

        // Test role hierarchy
        expect(evaluator.evaluate('super_admin', 'manage_roles'), isTrue);
        expect(evaluator.evaluate('admin', 'manage_roles'), isFalse);
        expect(evaluator.evaluate('moderator', 'delete'), isFalse);
        expect(evaluator.evaluate('user', 'moderate'), isFalse);
        expect(evaluator.evaluate('guest', 'write'), isFalse);
      });

      test('should handle file system permissions', () async {
        final fileSystemPolicies = {
          'root': ['read', 'write', 'delete', 'execute', 'chmod', 'chown'],
          'owner': ['read', 'write', 'delete', 'chmod'],
          'group': ['read', 'write'],
          'other': ['read'],
        };

        await policyManager.initialize(fileSystemPolicies);
        final evaluator = RoleEvaluator(policyManager.roles);

        // Test Unix-like permissions
        expect(evaluator.evaluate('root', 'chown'), isTrue);
        expect(evaluator.evaluate('owner', 'chown'), isFalse);
        expect(evaluator.evaluate('group', 'delete'), isFalse);
        expect(evaluator.evaluate('other', 'write'), isFalse);
      });

      test('should handle API endpoint permissions', () async {
        final apiPolicies = {
          'admin': ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
          'user': ['GET', 'POST'],
          'readonly': ['GET'],
        };

        await policyManager.initialize(apiPolicies);
        final evaluator = RoleEvaluator(policyManager.roles);

        // Test REST API permissions
        expect(evaluator.evaluate('admin', 'DELETE'), isTrue);
        expect(evaluator.evaluate('user', 'PUT'), isFalse);
        expect(evaluator.evaluate('readonly', 'POST'), isFalse);
        expect(evaluator.evaluate('readonly', 'GET'), isTrue);
      });
    });
  });
}

/// Mock storage that throws errors for testing error handling
class _FailingPolicyStorage implements MemoryPolicyStorage {
  @override
  Future<Map<String, dynamic>> loadPolicies() async {
    throw StateError('Storage load failed');
  }

  @override
  Future<void> savePolicies(Map<String, dynamic> policies) async {
    throw StateError('Storage save failed');
  }

  @override
  Future<void> clearPolicies() async {
    throw StateError('Storage clear failed');
  }
}
