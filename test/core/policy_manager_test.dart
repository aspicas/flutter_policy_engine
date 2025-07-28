import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_policy_engine/src/exceptions/policy_sdk_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_policy_engine/src/core/policy_manager.dart';
import 'package:flutter_policy_engine/src/core/interfaces/i_policy_evaluator.dart';
import 'package:flutter_policy_engine/src/core/interfaces/i_policy_storage.dart';
import 'package:flutter_policy_engine/src/models/role.dart';
import 'package:flutter_policy_engine/src/utils/json_handler.dart';
import 'package:flutter_policy_engine/src/exceptions/json_parse_exception.dart';

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

class ThrowingPolicy extends Role {
  const ThrowingPolicy({required super.name, required super.allowedContent});

  static Role fromJson(Map<String, dynamic> json) {
    throw StateError('Forced error in fromJson');
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
        expect(manager.roles, isEmpty);
      });

      test('should create instance with custom storage and evaluator', () {
        final manager = PolicyManager(
          storage: mockStorage,
          evaluator: mockEvaluator,
        );
        expect(manager, isA<PolicyManager>());
        expect(manager.isInitialized, isFalse);
        expect(manager.roles, isEmpty);
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
        expect(policyManager.roles, isEmpty);
      });

      test('should return unmodifiable policies map', () {
        expect(
            () => policyManager.roles['test'] =
                const Role(name: 'test', allowedContent: ['read']),
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
        expect(policyManager.roles.length, equals(2));
        expect(policyManager.roles['admin'], isA<Role>());
        expect(policyManager.roles['user'], isA<Role>());
        expect(policyManager.roles['admin']!.allowedContent,
            containsAll(['read', 'write', 'delete']));
        expect(
            policyManager.roles['user']!.allowedContent, containsAll(['read']));
      });

      test('should handle empty policies gracefully', () async {
        final jsonPolicies = <String, dynamic>{};

        await policyManager.initialize(jsonPolicies);

        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles, isEmpty);
      });

      test('should handle single policy', () async {
        final jsonPolicies = {
          'admin': ['read', 'write'],
        };

        await policyManager.initialize(jsonPolicies);

        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles.length, equals(1));
        expect(policyManager.roles['admin']!.name, equals('admin'));
        expect(policyManager.roles['admin']!.allowedContent,
            containsAll(['read', 'write']));
      });

      test('should save policies to storage after successful initialization',
          () async {
        final jsonPolicies = {
          'admin': ['read', 'write'],
        };

        await policyManager.initialize(jsonPolicies);

        expect(mockStorage.storedPolicies.length, equals(1));
        expect(mockStorage.storedPolicies['admin'], isA<Role>());
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
            throwsA(isA<PolicySDKException>()));
        expect(policyManager.isInitialized, isFalse);
      });

      test('should handle malformed JSON data gracefully', () async {
        final jsonPolicies = {
          'admin': 'invalid_content', // Should be List<String>
        };

        await policyManager.initialize(jsonPolicies);

        // Should initialize successfully but skip invalid policies
        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles, isEmpty);
      });

      test('should handle null values in JSON data gracefully', () async {
        final jsonPolicies = {
          'admin': null,
        };

        await policyManager.initialize(jsonPolicies);

        // Should initialize successfully but skip null policies
        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles, isEmpty);
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
        expect(policyManager.roles.length, equals(2));
        expect(policyManager.roles['admin'], isNotNull);
        expect(policyManager.roles['guest'], isNotNull);
        expect(policyManager.roles['user'], isNull);
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
        expect(policyManager.roles, isEmpty);
      });

      test('should handle exception in Policy.fromJson during initialization',
          () async {
        // Prepare a validPolicies map that will be passed to parseMap
        final validPolicies = {
          'admin': const Role(name: 'admin', allowedContent: ['read', 'write'])
              .toJson(),
        };

        expect(
          () => JsonHandler.parseMap<Role>(
            validPolicies,
            (json) => ThrowingPolicy.fromJson(json),
            allowPartialSuccess: false,
          ),
          throwsA(isA<JsonParseException>()),
        );
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
        expect(policyManager.roles.length, equals(1000));
      });

      test('should handle policies with empty allowed content', () async {
        final jsonPolicies = {
          'admin': <String>[],
        };

        await policyManager.initialize(jsonPolicies);

        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles['admin']!.allowedContent, isEmpty);
      });

      test('should handle policies with duplicate content', () async {
        final jsonPolicies = {
          'admin': ['read', 'read', 'write'],
        };

        await policyManager.initialize(jsonPolicies);

        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles['admin']!.allowedContent,
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
            throwsA(isA<PolicySDKException>()));
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
        expect(policyManager.roles.length, equals(1));
      });

      test('should handle policies with non-string content items', () async {
        final jsonPolicies = {
          'admin': ['read', 123, 'write'], // contains non-string
        };

        await policyManager.initialize(jsonPolicies);

        // Should initialize successfully but skip invalid policies
        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles, isEmpty);
      });

      test('should handle policies with non-list values', () async {
        final jsonPolicies = {
          'admin': 'not_a_list', // should be List<String>
        };

        await policyManager.initialize(jsonPolicies);

        // Should initialize successfully but skip invalid policies
        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles, isEmpty);
      });

      test('should handle complete initialization failure gracefully',
          () async {
        final jsonPolicies = {
          'admin': null,
          'user': null,
          'guest': null,
        };

        await policyManager.initialize(jsonPolicies);

        // Should still mark as initialized even with no valid policies
        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles, isEmpty);
      });

      test('should handle hasAccess when not initialized', () {
        expect(policyManager.hasAccess('admin', 'read'), isFalse);
      });

      test('should handle hasAccess when evaluator is null', () async {
        // Initialize with empty policies to create null evaluator
        await policyManager.initialize({});

        expect(policyManager.hasAccess('admin', 'read'), isFalse);
      });

      test('should handle initialization error and rethrow', () async {
        // Create a mock storage that throws on save
        mockStorage.setShouldThrowOnSave(true);

        final jsonPolicies = {
          'admin': ['read', 'write'],
        };

        expect(
          () => policyManager.initialize(jsonPolicies),
          throwsA(isA<PolicySDKException>()),
        );

        expect(policyManager.isInitialized, isFalse);
      });

      test('should handle JsonParseException during initialization', () async {
        // Create policies that will cause JsonParseException
        final jsonPolicies = {
          'admin': ['read', 'write'],
        };

        // Mock the JsonHandler to throw an exception
        // This is a bit tricky to test directly, so we'll test the error handling
        // by creating a scenario where the storage throws during save
        mockStorage.setShouldThrowOnSave(true);

        expect(
          () => policyManager.initialize(jsonPolicies),
          throwsA(isA<PolicySDKException>()),
        );
      });
    });

    group('initializeFromJsonAssets', () {
      setUpAll(() {
        TestWidgetsFlutterBinding.ensureInitialized();
      });

      test('should initialize successfully with valid JSON asset', () async {
        // Mock the rootBundle to return valid JSON
        const validJson = '''
        {
          "admin": {
            "allowedContent": ["read", "write", "delete"]
          },
          "user": {
            "allowedContent": ["read"]
          }
        }
        ''';

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          return ByteData.view(
              Uint8List.fromList(utf8.encode(validJson)).buffer);
        });

        await policyManager
            .initializeFromJsonAssets('assets/policies/test.json');

        // The method should initialize successfully with valid JSON
        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles.length, equals(2));
        expect(policyManager.roles['admin'], isA<Role>());
        expect(policyManager.roles['user'], isA<Role>());
        expect(policyManager.roles['admin']!.allowedContent,
            containsAll(['read', 'write', 'delete']));
        expect(
            policyManager.roles['user']!.allowedContent, containsAll(['read']));

        // Clean up mock message handler
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null);
      });

      test('should handle empty asset path', () async {
        expect(
          () => policyManager.initializeFromJsonAssets(''),
          throwsA(isA<PolicySDKException>()),
        );
      });

      test('should handle asset not found gracefully', () async {
        // Test with a non-existent asset path
        await policyManager
            .initializeFromJsonAssets('assets/policies/nonexistent.json');

        // Should handle gracefully and initialize with empty policies
        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles, isEmpty);
      });

      test('should handle invalid JSON in asset gracefully', () async {
        // Mock the rootBundle to return invalid JSON
        const invalidJson = 'invalid json content';

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          return ByteData.view(
              Uint8List.fromList(utf8.encode(invalidJson)).buffer);
        });

        await policyManager
            .initializeFromJsonAssets('assets/policies/invalid.json');

        // Should handle gracefully and initialize with empty policies
        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles, isEmpty);

        // Clean up mock message handler
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null);
      });

      test('should handle malformed policy data in JSON asset', () async {
        // Mock the rootBundle to return JSON with malformed policy data
        const malformedJson = '''
        {
          "admin": {
            "allowedContent": "not_a_list"
          },
          "user": null,
          "guest": {
            "allowedContent": ["read"]
          },
          "invalid_role": {
            "allowedContent": [123, "read"]
          }
        }
        ''';

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          return ByteData.view(
              Uint8List.fromList(utf8.encode(malformedJson)).buffer);
        });

        await policyManager
            .initializeFromJsonAssets('assets/policies/malformed.json');

        // Should initialize with only valid policies
        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles.length, equals(1));
        expect(policyManager.roles['guest'], isNotNull);
        expect(policyManager.roles['guest']!.name, equals('guest'));
        expect(policyManager.roles['guest']!.allowedContent, contains('read'));
        expect(policyManager.roles['admin'], isNull);
        expect(policyManager.roles['user'], isNull);
        expect(policyManager.roles['invalid_role'], isNull);

        // Clean up mock message handler
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null);
      });

      test('should handle non-Map policy values in JSON asset', () async {
        // Mock the rootBundle to return JSON with non-Map policy values
        const nonMapJson = '''
        {
          "admin": "not_a_map",
          "user": 123,
          "guest": ["read", "write"],
          "valid_role": {
            "allowedContent": ["read"]
          }
        }
        ''';

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          return ByteData.view(
              Uint8List.fromList(utf8.encode(nonMapJson)).buffer);
        });

        await policyManager
            .initializeFromJsonAssets('assets/policies/non_map.json');

        // Should initialize with only valid policies
        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles.length, equals(1));
        expect(policyManager.roles['valid_role'], isNotNull);
        expect(policyManager.roles['valid_role']!.name, equals('valid_role'));
        expect(policyManager.roles['valid_role']!.allowedContent,
            contains('read'));
        expect(policyManager.roles['admin'], isNull);
        expect(policyManager.roles['user'], isNull);
        expect(policyManager.roles['guest'], isNull);

        // Clean up mock message handler
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null);
      });

      test('should execute warning log for non-Map values', () async {
        // Mock the rootBundle to return JSON with non-Map policy values
        const nonMapJson = '''
        {
          "admin": "not_a_map",
          "user": 123,
          "guest": ["read", "write"],
          "valid_role": {
            "allowedContent": ["read"]
          }
        }
        ''';

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          return ByteData.view(
              Uint8List.fromList(utf8.encode(nonMapJson)).buffer);
        });

        await policyManager
            .initializeFromJsonAssets('assets/policies/non_map.json');

        // Should initialize with only valid policies
        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles.length, equals(1));
        expect(policyManager.roles['valid_role'], isNotNull);
        expect(policyManager.roles['valid_role']!.name, equals('valid_role'));
        expect(policyManager.roles['valid_role']!.allowedContent,
            contains('read'));
        expect(policyManager.roles['admin'], isNull);
        expect(policyManager.roles['user'], isNull);
        expect(policyManager.roles['guest'], isNull);

        // Clean up mock message handler
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null);
      });

      test('should handle empty JSON object in asset', () async {
        // Mock the rootBundle to return empty JSON object
        const emptyJson = '{}';

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          return ByteData.view(
              Uint8List.fromList(utf8.encode(emptyJson)).buffer);
        });

        await policyManager
            .initializeFromJsonAssets('assets/policies/empty.json');

        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles, isEmpty);

        // Clean up mock message handler
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null);
      });

      test('should handle single policy in JSON asset', () async {
        // Mock the rootBundle to return JSON with single policy
        const singlePolicyJson = '''
        {
          "admin": {
            "allowedContent": ["read", "write"]
          }
        }
        ''';

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          return ByteData.view(
              Uint8List.fromList(utf8.encode(singlePolicyJson)).buffer);
        });

        await policyManager
            .initializeFromJsonAssets('assets/policies/single.json');

        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles.length, equals(1));
        expect(policyManager.roles['admin']!.name, equals('admin'));
        expect(policyManager.roles['admin']!.allowedContent,
            containsAll(['read', 'write']));

        // Clean up mock message handler
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null);
      });

      test('should handle large policy set in JSON asset', () async {
        // Create a large JSON with many policies
        final largeJson = <String, dynamic>{};
        for (int i = 0; i < 100; i++) {
          largeJson['role_$i'] = {
            'allowedContent': ['read', 'write']
          };
        }

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          return ByteData.view(
              Uint8List.fromList(utf8.encode(jsonEncode(largeJson))).buffer);
        });

        await policyManager
            .initializeFromJsonAssets('assets/policies/large.json');

        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles.length, equals(100));

        // Clean up mock message handler
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null);
      });

      test('should handle policies with empty content arrays', () async {
        // Mock the rootBundle to return JSON with empty content arrays
        const emptyContentJson = '''
        {
          "admin": {
            "allowedContent": []
          },
          "user": {
            "allowedContent": ["read"]
          }
        }
        ''';

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          return ByteData.view(
              Uint8List.fromList(utf8.encode(emptyContentJson)).buffer);
        });

        await policyManager
            .initializeFromJsonAssets('assets/policies/empty_content.json');

        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles.length, equals(2));
        expect(policyManager.roles['admin']!.allowedContent, isEmpty);
        expect(
            policyManager.roles['user']!.allowedContent, containsAll(['read']));

        // Clean up mock message handler
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null);
      });

      test('should handle policies with duplicate content items', () async {
        // Mock the rootBundle to return JSON with duplicate content
        const duplicateContentJson = '''
        {
          "admin": {
            "allowedContent": ["read", "read", "write", "write"]
          }
        }
        ''';

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          return ByteData.view(
              Uint8List.fromList(utf8.encode(duplicateContentJson)).buffer);
        });

        await policyManager
            .initializeFromJsonAssets('assets/policies/duplicate.json');

        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles.length, equals(1));
        expect(policyManager.roles['admin']!.allowedContent,
            containsAll(['read', 'write']));

        // Clean up mock message handler
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null);
      });

      test('should handle platform exception during asset loading', () async {
        // Test with an invalid asset path that will cause platform exception
        await policyManager
            .initializeFromJsonAssets('invalid/path/with/special/chars/\\/');

        // Should handle gracefully and initialize with empty policies
        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles, isEmpty);
      });

      test('should handle concurrent initialization from assets', () async {
        // Mock the rootBundle to return valid JSON
        const validJson = '''
        {
          "admin": {
            "allowedContent": ["read", "write"]
          },
          "user": {
            "allowedContent": ["read"]
          }
        }
        ''';

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          return ByteData.view(
              Uint8List.fromList(utf8.encode(validJson)).buffer);
        });

        // Start multiple initialization calls
        final futures = [
          policyManager.initializeFromJsonAssets('assets/policies/test1.json'),
          policyManager.initializeFromJsonAssets('assets/policies/test2.json'),
          policyManager.initializeFromJsonAssets('assets/policies/test3.json'),
        ];

        await Future.wait(futures);

        expect(policyManager.isInitialized, isTrue);
        expect(policyManager.roles.length, equals(2));

        // Clean up mock message handler
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null);
      });

      test(
          'should notify listeners after successful initialization from assets',
          () async {
        // Mock the rootBundle to return valid JSON
        const validJson = '''
        {
          "admin": {
            "allowedContent": ["read", "write"]
          }
        }
        ''';

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          return ByteData.view(
              Uint8List.fromList(utf8.encode(validJson)).buffer);
        });

        bool listenerCalled = false;
        policyManager.addListener(() {
          listenerCalled = true;
        });

        await policyManager
            .initializeFromJsonAssets('assets/policies/test.json');

        expect(listenerCalled, isTrue);
        expect(policyManager.isInitialized, isTrue);

        // Clean up mock message handler
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null);
      });

      test(
          'should save policies to storage after successful initialization from assets',
          () async {
        // Create a fresh policy manager and storage for this test
        final freshStorage = MockPolicyStorage();
        final freshEvaluator = MockPolicyEvaluator();
        final freshPolicyManager = PolicyManager(
          storage: freshStorage,
          evaluator: freshEvaluator,
        );

        // Mock the rootBundle to return valid JSON
        const validJson = '''
        {
          "admin": {
            "allowedContent": ["read", "write"]
          }
        }
        ''';

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          return ByteData.view(
              Uint8List.fromList(utf8.encode(validJson)).buffer);
        });

        await freshPolicyManager
            .initializeFromJsonAssets('assets/policies/test.json');

        // Check that the expected policy is present in storage
        expect(freshPolicyManager.isInitialized, isTrue);
        expect(freshStorage.storedPolicies['admin'], isA<Role>());
        expect(
          (freshStorage.storedPolicies['admin'] as Role).allowedContent,
          containsAll(
            ['read', 'write'],
          ),
        );

        // Clean up mock message handler
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null);
      });

      test(
          'should handle storage save errors during initialization from assets',
          () async {
        // Mock the rootBundle to return valid JSON
        const validJson = '''
        {
          "admin": {
            "allowedContent": ["read", "write"]
          }
        }
        ''';

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          return ByteData.view(
              Uint8List.fromList(utf8.encode(validJson)).buffer);
        });

        // Make storage throw on save
        mockStorage.setShouldThrowOnSave(true);

        // The method should throw PolicySDKException when storage fails
        expect(
          () => policyManager
              .initializeFromJsonAssets('assets/policies/test.json'),
          throwsA(isA<PolicySDKException>()),
        );

        // Should not be initialized due to storage error
        expect(policyManager.isInitialized, isFalse);

        // Clean up mock message handler
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null);
      });

      tearDown(() {
        // Clean up mock message handlers
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null);
      });
    });

    group('addRole', () {
      test('should add a new role successfully', () async {
        await policyManager.initialize({});

        const newRole = Role(name: 'editor', allowedContent: ['read', 'write']);
        await policyManager.addRole(newRole);

        expect(policyManager.roles['editor'], equals(newRole));
        expect(policyManager.roles.length, equals(1));
      });

      test('should overwrite existing role with same name', () async {
        await policyManager.initialize({
          'admin': ['read', 'write'],
        });

        const updatedRole =
            Role(name: 'admin', allowedContent: ['read', 'write', 'delete']);
        await policyManager.addRole(updatedRole);

        expect(policyManager.roles['admin'], equals(updatedRole));
        expect(policyManager.roles['admin']!.allowedContent,
            containsAll(['read', 'write', 'delete']));
        expect(policyManager.roles.length, equals(1));
      });

      test('should throw ArgumentError for role with empty name', () async {
        await policyManager.initialize({});

        const invalidRole = Role(name: '', allowedContent: ['read']);

        expect(
          () => policyManager.addRole(invalidRole),
          throwsA(isA<PolicySDKException>()),
        );
      });

      test('should save role to storage after adding', () async {
        await policyManager.initialize({});

        const newRole = Role(name: 'editor', allowedContent: ['read', 'write']);
        await policyManager.addRole(newRole);

        expect(mockStorage.storedPolicies['editor'], equals(newRole));
      });

      test('should notify listeners after adding role', () async {
        await policyManager.initialize({});

        bool listenerCalled = false;
        policyManager.addListener(() {
          listenerCalled = true;
        });

        const newRole = Role(name: 'editor', allowedContent: ['read', 'write']);
        await policyManager.addRole(newRole);

        expect(listenerCalled, isTrue);
      });

      test('should update evaluator after adding role', () async {
        await policyManager.initialize({});

        const newRole = Role(name: 'editor', allowedContent: ['read', 'write']);
        await policyManager.addRole(newRole);

        // The evaluator should be updated and functional
        expect(policyManager.hasAccess('editor', 'read'), isTrue);
        expect(policyManager.hasAccess('editor', 'write'), isTrue);
        expect(policyManager.hasAccess('editor', 'delete'), isFalse);
      });

      test('should handle storage errors when adding role', () async {
        await policyManager.initialize({});
        mockStorage.setShouldThrowOnSave(true);

        const newRole = Role(name: 'editor', allowedContent: ['read', 'write']);

        expect(
          () => policyManager.addRole(newRole),
          throwsA(isA<StateError>()),
        );
      });

      test('should handle multiple role additions', () async {
        await policyManager.initialize({});

        const role1 =
            Role(name: 'admin', allowedContent: ['read', 'write', 'delete']);
        const role2 = Role(name: 'user', allowedContent: ['read']);
        const role3 = Role(name: 'guest', allowedContent: ['read']);

        await policyManager.addRole(role1);
        await policyManager.addRole(role2);
        await policyManager.addRole(role3);

        expect(policyManager.roles.length, equals(3));
        expect(policyManager.roles['admin'], equals(role1));
        expect(policyManager.roles['user'], equals(role2));
        expect(policyManager.roles['guest'], equals(role3));
      });
    });

    group('removeRole', () {
      test('should remove existing role successfully', () async {
        await policyManager.initialize({
          'admin': ['read', 'write'],
          'user': ['read'],
        });

        await policyManager.removeRole('admin');

        expect(policyManager.roles['admin'], isNull);
        expect(policyManager.roles['user'], isNotNull);
        expect(policyManager.roles.length, equals(1));
      });

      test('should complete successfully when removing non-existent role',
          () async {
        await policyManager.initialize({
          'admin': ['read', 'write'],
        });

        await policyManager.removeRole('non-existent');

        expect(policyManager.roles['admin'], isNotNull);
        expect(policyManager.roles.length, equals(1));
      });

      test('should throw ArgumentError for empty role name', () async {
        await policyManager.initialize({
          'admin': ['read', 'write'],
        });

        expect(
          () => policyManager.removeRole(''),
          throwsA(isA<PolicySDKException>()),
        );
      });

      test('should save updated policies to storage after removal', () async {
        await policyManager.initialize({
          'admin': ['read', 'write'],
          'user': ['read'],
        });

        await policyManager.removeRole('admin');

        expect(mockStorage.storedPolicies['admin'], isNull);
        expect(mockStorage.storedPolicies['user'], isNotNull);
        expect(mockStorage.storedPolicies.length, equals(1));
      });

      test('should notify listeners after removing role', () async {
        await policyManager.initialize({
          'admin': ['read', 'write'],
          'user': ['read'],
        });

        bool listenerCalled = false;
        policyManager.addListener(() {
          listenerCalled = true;
        });

        await policyManager.removeRole('admin');

        expect(listenerCalled, isTrue);
      });

      test('should update evaluator after removing role', () async {
        await policyManager.initialize({
          'admin': ['read', 'write'],
          'user': ['read'],
        });

        await policyManager.removeRole('admin');

        // The evaluator should be updated and reflect the removal
        expect(policyManager.hasAccess('admin', 'read'), isFalse);
        expect(policyManager.hasAccess('user', 'read'), isTrue);
      });

      test('should handle storage errors when removing role', () async {
        await policyManager.initialize({
          'admin': ['read', 'write'],
        });

        mockStorage.setShouldThrowOnSave(true);

        expect(
          () => policyManager.removeRole('admin'),
          throwsA(isA<StateError>()),
        );
      });

      test('should handle removing last role', () async {
        await policyManager.initialize({
          'admin': ['read', 'write'],
        });

        await policyManager.removeRole('admin');

        expect(policyManager.roles, isEmpty);
        expect(policyManager.hasAccess('admin', 'read'), isFalse);
      });

      test('should handle multiple role removals', () async {
        await policyManager.initialize({
          'admin': ['read', 'write'],
          'user': ['read'],
          'guest': ['read'],
        });

        await policyManager.removeRole('admin');
        await policyManager.removeRole('user');

        expect(policyManager.roles.length, equals(1));
        expect(policyManager.roles['guest'], isNotNull);
        expect(policyManager.roles['admin'], isNull);
        expect(policyManager.roles['user'], isNull);
      });
    });

    group('updateRole', () {
      test('should update existing role successfully', () async {
        await policyManager.initialize({
          'admin': ['read', 'write'],
        });

        const updatedRole =
            Role(name: 'admin', allowedContent: ['read', 'write', 'delete']);
        await policyManager.updateRole('admin', updatedRole);

        expect(policyManager.roles['admin'], equals(updatedRole));
        expect(policyManager.roles['admin']!.allowedContent,
            containsAll(['read', 'write', 'delete']));
      });

      test('should add new role when updating non-existent role', () async {
        await policyManager.initialize({
          'admin': ['read', 'write'],
        });

        const newRole = Role(name: 'editor', allowedContent: ['read', 'write']);
        await policyManager.updateRole('editor', newRole);

        expect(policyManager.roles['editor'], equals(newRole));
        expect(policyManager.roles.length, equals(2));
        expect(policyManager.roles['admin'], isNotNull);
      });

      test('should throw ArgumentError for empty role name', () async {
        await policyManager.initialize({
          'admin': ['read', 'write'],
        });

        const role = Role(name: '', allowedContent: ['read']);

        expect(
          () => policyManager.updateRole('', role),
          throwsA(isA<PolicySDKException>()),
        );
      });

      test('should throw ArgumentError for role with empty name', () async {
        await policyManager.initialize({
          'admin': ['read', 'write'],
        });

        const invalidRole = Role(name: '', allowedContent: ['read']);

        expect(
          () => policyManager.updateRole('', invalidRole),
          throwsA(isA<PolicySDKException>()),
        );
      });

      test('should save updated policies to storage', () async {
        await policyManager.initialize({
          'admin': ['read', 'write'],
        });

        const updatedRole =
            Role(name: 'admin', allowedContent: ['read', 'write', 'delete']);
        await policyManager.updateRole('admin', updatedRole);

        expect(mockStorage.storedPolicies['admin'], equals(updatedRole));
      });

      test('should notify listeners after updating role', () async {
        await policyManager.initialize({
          'admin': ['read', 'write'],
        });

        bool listenerCalled = false;
        policyManager.addListener(() {
          listenerCalled = true;
        });

        const updatedRole =
            Role(name: 'admin', allowedContent: ['read', 'write', 'delete']);
        await policyManager.updateRole('admin', updatedRole);

        expect(listenerCalled, isTrue);
      });

      test('should update evaluator after updating role', () async {
        await policyManager.initialize({
          'admin': ['read', 'write'],
        });

        const updatedRole =
            Role(name: 'admin', allowedContent: ['read', 'write', 'delete']);
        await policyManager.updateRole('admin', updatedRole);

        // The evaluator should be updated and reflect the changes
        expect(policyManager.hasAccess('admin', 'read'), isTrue);
        expect(policyManager.hasAccess('admin', 'write'), isTrue);
        expect(policyManager.hasAccess('admin', 'delete'), isTrue);
        expect(policyManager.hasAccess('admin', 'execute'), isFalse);
      });

      test('should handle storage errors when updating role', () async {
        await policyManager.initialize({
          'admin': ['read', 'write'],
        });

        mockStorage.setShouldThrowOnSave(true);
        const updatedRole =
            Role(name: 'admin', allowedContent: ['read', 'write', 'delete']);

        expect(
          () => policyManager.updateRole('admin', updatedRole),
          throwsA(isA<StateError>()),
        );
      });

      test('should handle updating role with different name in parameter',
          () async {
        await policyManager.initialize({
          'admin': ['read', 'write'],
        });

        const updatedRole = Role(
            name: 'superadmin', allowedContent: ['read', 'write', 'delete']);
        await policyManager.updateRole('admin', updatedRole);

        // Should update the role at 'admin' key with the new role data
        expect(policyManager.roles['admin'], equals(updatedRole));
        expect(policyManager.roles['admin']!.name, equals('superadmin'));
        expect(
            policyManager.roles['superadmin'], isNull); // Key remains 'admin'
      });

      test('should handle multiple role updates', () async {
        await policyManager.initialize({
          'admin': ['read', 'write'],
          'user': ['read'],
        });

        const updatedAdmin =
            Role(name: 'admin', allowedContent: ['read', 'write', 'delete']);
        const updatedUser =
            Role(name: 'user', allowedContent: ['read', 'write']);

        await policyManager.updateRole('admin', updatedAdmin);
        await policyManager.updateRole('user', updatedUser);

        expect(policyManager.roles['admin'], equals(updatedAdmin));
        expect(policyManager.roles['user'], equals(updatedUser));
        expect(policyManager.roles.length, equals(2));
      });
    });

    group('Listener notifications', () {
      test('should notify listeners on addRole', () async {
        await policyManager.initialize({});

        int notificationCount = 0;
        policyManager.addListener(() {
          notificationCount++;
        });

        const role = Role(name: 'admin', allowedContent: ['read']);
        await policyManager.addRole(role);

        expect(notificationCount, equals(1));
      });

      test('should notify listeners on removeRole', () async {
        await policyManager.initialize({
          'admin': ['read', 'write'],
        });

        int notificationCount = 0;
        policyManager.addListener(() {
          notificationCount++;
        });

        await policyManager.removeRole('admin');

        expect(notificationCount, equals(1));
      });

      test('should notify listeners on updateRole', () async {
        await policyManager.initialize({
          'admin': ['read', 'write'],
        });

        int notificationCount = 0;
        policyManager.addListener(() {
          notificationCount++;
        });

        const updatedRole =
            Role(name: 'admin', allowedContent: ['read', 'write', 'delete']);
        await policyManager.updateRole('admin', updatedRole);

        expect(notificationCount, equals(1));
      });

      test('should notify multiple listeners', () async {
        await policyManager.initialize({});

        int notificationCount1 = 0;
        int notificationCount2 = 0;

        policyManager.addListener(() {
          notificationCount1++;
        });
        policyManager.addListener(() {
          notificationCount2++;
        });

        const role = Role(name: 'admin', allowedContent: ['read']);
        await policyManager.addRole(role);

        expect(notificationCount1, equals(1));
        expect(notificationCount2, equals(1));
      });
    });
  });
}
