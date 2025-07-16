import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_policy_engine/src/core/memory_policy_storage.dart';

void main() {
  group('MemoryPolicyStorage', () {
    late MemoryPolicyStorage storage;

    setUp(() {
      storage = MemoryPolicyStorage();
    });

    group('Constructor', () {
      test('should create instance successfully', () {
        expect(storage, isA<MemoryPolicyStorage>());
      });
    });

    group('loadPolicies', () {
      test('should return empty map when no policies are stored', () async {
        final policies = await storage.loadPolicies();
        expect(policies, isEmpty);
        expect(policies, isA<Map<String, dynamic>>());
      });

      test('should return copy of stored policies', () async {
        final testPolicies = {
          'admin': {
            'role': 'admin',
            'permissions': ['read', 'write']
          },
          'user': {
            'role': 'user',
            'permissions': ['read']
          },
        };

        await storage.savePolicies(testPolicies);
        final loadedPolicies = await storage.loadPolicies();

        expect(loadedPolicies, equals(testPolicies));
        expect(loadedPolicies, isNot(same(testPolicies))); // Should be a copy
      });

      test('should return deep copy of policies', () async {
        final testPolicies = {
          'admin': {
            'role': 'admin',
            'permissions': ['read', 'write']
          },
        };

        await storage.savePolicies(testPolicies);
        final loadedPolicies = await storage.loadPolicies();

        // Modify the loaded policies
        (loadedPolicies['admin']!['permissions'] as List<dynamic>)
            .add('delete');

        // Reload to verify original wasn't modified
        final reloadedPolicies = await storage.loadPolicies();
        expect(reloadedPolicies['admin']!['permissions'],
            equals(['read', 'write']));
      });

      test('should handle complex nested structures', () async {
        final testPolicies = {
          'admin': {
            'role': 'admin',
            'permissions': ['read', 'write', 'delete'],
            'metadata': {
              'level': 1,
              'departments': ['IT', 'HR'],
              'nested': {
                'key': 'value',
                'array': [1, 2, 3],
              },
            },
          },
        };

        await storage.savePolicies(testPolicies);
        final loadedPolicies = await storage.loadPolicies();

        expect(loadedPolicies, equals(testPolicies));
        expect(loadedPolicies['admin']!['metadata']!['nested']!['array'],
            equals([1, 2, 3]));
      });
    });

    group('savePolicies', () {
      test('should save policies successfully', () async {
        final testPolicies = {
          'admin': {
            'role': 'admin',
            'permissions': ['read', 'write']
          },
          'user': {
            'role': 'user',
            'permissions': ['read']
          },
        };

        await storage.savePolicies(testPolicies);
        final loadedPolicies = await storage.loadPolicies();

        expect(loadedPolicies, equals(testPolicies));
      });

      test('should overwrite existing policies', () async {
        final initialPolicies = {
          'admin': {
            'role': 'admin',
            'permissions': ['read']
          },
        };

        final newPolicies = {
          'user': {
            'role': 'user',
            'permissions': ['read', 'write']
          },
        };

        await storage.savePolicies(initialPolicies);
        await storage.savePolicies(newPolicies);

        final loadedPolicies = await storage.loadPolicies();
        expect(loadedPolicies, equals(newPolicies));
        expect(loadedPolicies, isNot(equals(initialPolicies)));
      });

      test('should create deep copy of input policies', () async {
        final testPolicies = {
          'admin': {
            'role': 'admin',
            'permissions': ['read', 'write']
          },
        };

        await storage.savePolicies(testPolicies);

        // Modify the original policies
        final permissions =
            testPolicies['admin']!['permissions'] as List<dynamic>;
        permissions.add('delete');

        // Reload to verify stored policies weren't modified
        final loadedPolicies = await storage.loadPolicies();
        expect(
            loadedPolicies['admin']!['permissions'], equals(['read', 'write']));
      });

      test('should handle empty policies map', () async {
        final emptyPolicies = <String, dynamic>{};

        await storage.savePolicies(emptyPolicies);
        final loadedPolicies = await storage.loadPolicies();

        expect(loadedPolicies, isEmpty);
      });

      test('should handle null values in policies', () async {
        final testPolicies = {
          'admin': {
            'role': 'admin',
            'permissions': ['read']
          },
          'user': null,
          'guest': {'role': 'guest', 'permissions': []},
        };

        await storage.savePolicies(testPolicies);
        final loadedPolicies = await storage.loadPolicies();

        expect(loadedPolicies, equals(testPolicies));
        expect(loadedPolicies['user'], isNull);
      });

      test('should handle large policy sets', () async {
        final largePolicies = <String, dynamic>{};
        for (int i = 0; i < 1000; i++) {
          largePolicies['policy_$i'] = {
            'id': i,
            'permissions': ['read', 'write'],
            'metadata': {'created': DateTime.now().toIso8601String()},
          };
        }

        await storage.savePolicies(largePolicies);
        final loadedPolicies = await storage.loadPolicies();

        expect(loadedPolicies.length, equals(1000));
        expect(loadedPolicies['policy_500']!['id'], equals(500));
      });
    });

    group('clearPolicies', () {
      test('should clear all stored policies', () async {
        final testPolicies = {
          'admin': {
            'role': 'admin',
            'permissions': ['read', 'write']
          },
          'user': {
            'role': 'user',
            'permissions': ['read']
          },
        };

        await storage.savePolicies(testPolicies);
        await storage.clearPolicies();

        final loadedPolicies = await storage.loadPolicies();
        expect(loadedPolicies, isEmpty);
      });

      test('should handle clearing empty storage', () async {
        await storage.clearPolicies();
        final loadedPolicies = await storage.loadPolicies();

        expect(loadedPolicies, isEmpty);
      });

      test('should clear policies immediately', () async {
        final testPolicies = {
          'admin': {
            'role': 'admin',
            'permissions': ['read']
          },
        };

        await storage.savePolicies(testPolicies);
        await storage.clearPolicies();

        // Verify policies are immediately cleared
        final loadedPolicies = await storage.loadPolicies();
        expect(loadedPolicies, isEmpty);
      });
    });

    group('Integration tests', () {
      test('should handle complete lifecycle: save, load, clear, load',
          () async {
        final testPolicies = {
          'admin': {
            'role': 'admin',
            'permissions': ['read', 'write', 'delete']
          },
          'user': {
            'role': 'user',
            'permissions': ['read']
          },
        };

        // Save policies
        await storage.savePolicies(testPolicies);
        var loadedPolicies = await storage.loadPolicies();
        expect(loadedPolicies, equals(testPolicies));

        // Clear policies
        await storage.clearPolicies();
        loadedPolicies = await storage.loadPolicies();
        expect(loadedPolicies, isEmpty);

        // Save new policies
        final newPolicies = {
          'guest': {
            'role': 'guest',
            'permissions': ['read']
          },
        };
        await storage.savePolicies(newPolicies);
        loadedPolicies = await storage.loadPolicies();
        expect(loadedPolicies, equals(newPolicies));
      });

      test('should maintain data integrity across multiple operations',
          () async {
        final initialPolicies = {
          'admin': {
            'role': 'admin',
            'permissions': ['read']
          },
        };

        await storage.savePolicies(initialPolicies);
        var loadedPolicies = await storage.loadPolicies();
        expect(loadedPolicies, equals(initialPolicies));

        // Update policies
        final updatedPolicies = {
          'admin': {
            'role': 'admin',
            'permissions': ['read', 'write']
          },
          'user': {
            'role': 'user',
            'permissions': ['read']
          },
        };

        await storage.savePolicies(updatedPolicies);
        loadedPolicies = await storage.loadPolicies();
        expect(loadedPolicies, equals(updatedPolicies));

        // Clear and verify
        await storage.clearPolicies();
        loadedPolicies = await storage.loadPolicies();
        expect(loadedPolicies, isEmpty);
      });
    });

    group('Edge cases', () {
      test('should handle policies with empty string keys', () async {
        final testPolicies = {
          '': {
            'role': 'empty',
            'permissions': ['read']
          },
          'admin': {
            'role': 'admin',
            'permissions': ['read', 'write']
          },
        };

        await storage.savePolicies(testPolicies);
        final loadedPolicies = await storage.loadPolicies();

        expect(loadedPolicies, equals(testPolicies));
        expect(loadedPolicies[''], isNotNull);
      });

      test('should handle policies with special characters in keys', () async {
        final testPolicies = {
          'admin@domain.com': {
            'role': 'admin',
            'permissions': ['read']
          },
          'user-name_123': {
            'role': 'user',
            'permissions': ['read', 'write']
          },
          'role with spaces': {
            'role': 'spaced',
            'permissions': ['read']
          },
        };

        await storage.savePolicies(testPolicies);
        final loadedPolicies = await storage.loadPolicies();

        expect(loadedPolicies, equals(testPolicies));
        expect(loadedPolicies['admin@domain.com'], isNotNull);
        expect(loadedPolicies['user-name_123'], isNotNull);
        expect(loadedPolicies['role with spaces'], isNotNull);
      });

      test('should handle deeply nested structures', () async {
        final testPolicies = {
          'admin': {
            'level1': {
              'level2': {
                'level3': {
                  'level4': {
                    'level5': {
                      'value': 'deep_value',
                      'array': [1, 2, 3, 4, 5],
                    },
                  },
                },
              },
            },
          },
        };

        await storage.savePolicies(testPolicies);
        final loadedPolicies = await storage.loadPolicies();

        expect(
            loadedPolicies['admin']!['level1']!['level2']!['level3']![
                'level4']!['level5']!['value'],
            equals('deep_value'));
        expect(
            loadedPolicies['admin']!['level1']!['level2']!['level3']![
                'level4']!['level5']!['array'],
            equals([1, 2, 3, 4, 5]));
      });

      test('should handle policies with various data types', () async {
        final testPolicies = {
          'admin': {
            'string': 'value',
            'int': 42,
            'double': 3.14,
            'bool': true,
            'list': [1, 2, 3],
            'map': {'key': 'value'},
            'null': null,
          },
        };

        await storage.savePolicies(testPolicies);
        final loadedPolicies = await storage.loadPolicies();

        expect(loadedPolicies['admin']!['string'], equals('value'));
        expect(loadedPolicies['admin']!['int'], equals(42));
        expect(loadedPolicies['admin']!['double'], equals(3.14));
        expect(loadedPolicies['admin']!['bool'], equals(true));
        expect(loadedPolicies['admin']!['list'], equals([1, 2, 3]));
        expect(loadedPolicies['admin']!['map'], equals({'key': 'value'}));
        expect(loadedPolicies['admin']!['null'], isNull);
      });
    });

    group('Performance considerations', () {
      test('should handle rapid save operations', () async {
        for (int i = 0; i < 100; i++) {
          final policies = {
            'policy_$i': {
              'id': i,
              'permissions': ['read']
            },
          };
          await storage.savePolicies(policies);
        }

        final loadedPolicies = await storage.loadPolicies();
        expect(
            loadedPolicies.length, equals(1)); // Only last save should remain
        expect(loadedPolicies['policy_99']!['id'], equals(99));
      });

      test('should handle rapid load operations', () async {
        final testPolicies = {
          'admin': {
            'role': 'admin',
            'permissions': ['read', 'write']
          },
        };

        await storage.savePolicies(testPolicies);

        // Perform multiple load operations
        final futures = List.generate(100, (_) => storage.loadPolicies());
        final results = await Future.wait(futures);

        for (final result in results) {
          expect(result, equals(testPolicies));
        }
      });
    });
  });
}
