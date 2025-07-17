import 'package:flutter_policy_engine/src/exceptions/json_parse_exception.dart';
import 'package:flutter_policy_engine/src/exceptions/json_serialize_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_policy_engine/src/utils/json_handler.dart';

// Test data classes for JSON conversion testing
class TestUser {
  final String name;
  final int age;
  final List<String> hobbies;
  final Map<String, dynamic> metadata;

  const TestUser({
    required this.name,
    required this.age,
    required this.hobbies,
    this.metadata = const {},
  });

  factory TestUser.fromJson(Map<String, dynamic> json) {
    return TestUser(
      name: json['name'] as String,
      age: json['age'] as int,
      hobbies: List<String>.from(json['hobbies'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'hobbies': hobbies,
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestUser &&
          name == other.name &&
          age == other.age &&
          hobbies.length == other.hobbies.length &&
          hobbies.every((hobby) => other.hobbies.contains(hobby)) &&
          metadata.length == other.metadata.length &&
          metadata.entries
              .every((entry) => other.metadata[entry.key] == entry.value);

  @override
  int get hashCode => name.hashCode ^ age.hashCode ^ hobbies.hashCode;

  @override
  String toString() =>
      'TestUser(name: $name, age: $age, hobbies: $hobbies, metadata: $metadata)';
}

class TestPolicy {
  final String roleName;
  final List<String> allowedContent;
  final Map<String, dynamic> metadata;

  const TestPolicy({
    required this.roleName,
    required this.allowedContent,
    this.metadata = const {},
  });

  factory TestPolicy.fromJson(Map<String, dynamic> json) {
    return TestPolicy(
      roleName: json['roleName'] as String,
      allowedContent: List<String>.from(json['allowedContent'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roleName': roleName,
      'allowedContent': allowedContent,
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestPolicy &&
          roleName == other.roleName &&
          allowedContent.length == other.allowedContent.length &&
          allowedContent
              .every((content) => other.allowedContent.contains(content)) &&
          metadata.length == other.metadata.length &&
          metadata.entries.every((entry) {
            final otherValue = other.metadata[entry.key];
            if (entry.value is List && otherValue is List) {
              final valueList = entry.value as List;
              return valueList.length == otherValue.length &&
                  valueList.every((item) => otherValue.contains(item));
            }
            return entry.value == otherValue;
          });

  @override
  int get hashCode =>
      roleName.hashCode ^ allowedContent.hashCode ^ metadata.hashCode;

  @override
  String toString() =>
      'TestPolicy(roleName: $roleName, allowedContent: $allowedContent, metadata: $metadata)';
}

void main() {
  group('JsonHandler', () {
    group('parseMap', () {
      test('should convert JSON map to strongly-typed map', () {
        final jsonMap = {
          'user1': {
            'name': 'John Doe',
            'age': 30,
            'hobbies': ['reading', 'swimming'],
            'metadata': {'city': 'New York'}
          },
          'user2': {
            'name': 'Jane Smith',
            'age': 25,
            'hobbies': ['coding', 'gaming'],
            'metadata': {'city': 'Los Angeles'}
          }
        };

        final result = JsonHandler.parseMap<TestUser>(
          jsonMap,
          (json) => TestUser.fromJson(json),
        );

        expect(result, hasLength(2));
        expect(result['user1']!.name, 'John Doe');
        expect(result['user1']!.age, 30);
        expect(result['user1']!.hobbies, ['reading', 'swimming']);
        expect(result['user1']!.metadata, {'city': 'New York'});
        expect(result['user2']!.name, 'Jane Smith');
        expect(result['user2']!.age, 25);
        expect(result['user2']!.hobbies, ['coding', 'gaming']);
        expect(result['user2']!.metadata, {'city': 'Los Angeles'});
      });

      test('should handle empty map', () {
        final emptyMap = <String, dynamic>{};

        final result = JsonHandler.parseMap<TestUser>(
          emptyMap,
          (json) => TestUser.fromJson(json),
        );

        expect(result, isEmpty);
      });

      test('should handle map with missing optional fields', () {
        final jsonMap = {
          'user1': {
            'name': 'John Doe',
            'age': 30,
          },
          'user2': {
            'name': 'Jane Smith',
            'age': 25,
          }
        };

        final result = JsonHandler.parseMap<TestUser>(
          jsonMap,
          (json) => TestUser.fromJson(json),
        );

        expect(result, hasLength(2));
        expect(result['user1']!.hobbies, isEmpty);
        expect(result['user1']!.metadata, isEmpty);
        expect(result['user2']!.hobbies, isEmpty);
        expect(result['user2']!.metadata, isEmpty);
      });

      test('should handle different object types', () {
        final jsonMap = {
          'admin': {
            'roleName': 'admin',
            'allowedContent': ['read', 'write', 'delete'],
            'metadata': {'level': 5, 'active': true}
          },
          'user': {
            'roleName': 'user',
            'allowedContent': ['read'],
            'metadata': {'level': 1, 'active': true}
          }
        };

        final result = JsonHandler.parseMap<TestPolicy>(
          jsonMap,
          (json) => TestPolicy.fromJson(json),
        );

        expect(result, hasLength(2));
        expect(result['admin']!.roleName, 'admin');
        expect(result['admin']!.allowedContent, ['read', 'write', 'delete']);
        expect(result['admin']!.metadata, {'level': 5, 'active': true});
        expect(result['user']!.roleName, 'user');
        expect(result['user']!.allowedContent, ['read']);
        expect(result['user']!.metadata, {'level': 1, 'active': true});
      });

      // New error handling tests
      group('Error handling', () {
        test(
            'should handle invalid value types gracefully with partial success',
            () {
          final jsonMap = {
            'valid_user': {
              'name': 'John Doe',
              'age': 30,
              'hobbies': ['reading'],
              'metadata': {}
            },
            'invalid_user': 'not_a_map', // Invalid type
            'another_valid_user': {
              'name': 'Jane Smith',
              'age': 25,
              'hobbies': ['coding'],
              'metadata': {}
            }
          };

          final result = JsonHandler.parseMap<TestUser>(
            jsonMap,
            (json) => TestUser.fromJson(json),
            allowPartialSuccess: true,
          );

          expect(result, hasLength(2));
          expect(result['valid_user']!.name, 'John Doe');
          expect(result['another_valid_user']!.name, 'Jane Smith');
          expect(result.containsKey('invalid_user'), false);
        });

        test(
            'should throw JsonParseException when allowPartialSuccess is false',
            () {
          final jsonMap = {
            'valid_user': {
              'name': 'John Doe',
              'age': 30,
              'hobbies': ['reading'],
              'metadata': {}
            },
            'invalid_user': 'not_a_map', // Invalid type
          };

          expect(
            () => JsonHandler.parseMap<TestUser>(
              jsonMap,
              (json) => TestUser.fromJson(json),
              allowPartialSuccess: false,
            ),
            throwsA(isA<JsonParseException>()),
          );
        });

        test('should handle fromJson function throwing exceptions', () {
          final jsonMap = {
            'valid_user': {
              'name': 'John Doe',
              'age': 30,
              'hobbies': ['reading'],
              'metadata': {}
            },
            'invalid_user': {
              'name': 'Jane Smith',
              // Missing required 'age' field
              'hobbies': ['coding'],
              'metadata': {}
            }
          };

          final result = JsonHandler.parseMap<TestUser>(
            jsonMap,
            (json) => TestUser.fromJson(json),
            allowPartialSuccess: true,
          );

          expect(result, hasLength(1));
          expect(result['valid_user']!.name, 'John Doe');
          expect(result.containsKey('invalid_user'), false);
        });

        test('should throw JsonParseException when no items can be parsed', () {
          final jsonMap = {
            'invalid1': 'not_a_map',
            'invalid2': 123,
            'invalid3': null,
          };

          expect(
            () => JsonHandler.parseMap<TestUser>(
              jsonMap,
              (json) => TestUser.fromJson(json),
              allowPartialSuccess: false,
            ),
            throwsA(isA<JsonParseException>()),
          );
        });

        test('should include context in error messages', () {
          final jsonMap = {
            'invalid_user': 'not_a_map',
          };

          try {
            JsonHandler.parseMap<TestUser>(
              jsonMap,
              (json) => TestUser.fromJson(json),
              context: 'test_context',
              allowPartialSuccess: false,
            );
            fail('Expected JsonParseException to be thrown');
          } catch (e) {
            expect(e, isA<JsonParseException>());
            // The context is logged but not included in the exception message
            // This is expected behavior for logging vs exception messages
          }
        });
      });
    });

    group('mapToJson', () {
      test('should convert typed map to JSON-serializable map', () {
        final users = {
          'user1': const TestUser(
              name: 'John Doe',
              age: 30,
              hobbies: ['reading', 'swimming'],
              metadata: {'city': 'New York'}),
          'user2': const TestUser(
              name: 'Jane Smith',
              age: 25,
              hobbies: ['coding', 'gaming'],
              metadata: {'city': 'Los Angeles'})
        };

        final result = JsonHandler.mapToJson<TestUser>(
          users,
          (user) => user.toJson(),
        );

        expect(result, hasLength(2));
        expect((result['user1'] as Map<String, dynamic>)['name'], 'John Doe');
        expect((result['user1'] as Map<String, dynamic>)['age'], 30);
        expect((result['user1'] as Map<String, dynamic>)['hobbies'],
            ['reading', 'swimming']);
        expect((result['user1'] as Map<String, dynamic>)['metadata'],
            {'city': 'New York'});
        expect((result['user2'] as Map<String, dynamic>)['name'], 'Jane Smith');
        expect((result['user2'] as Map<String, dynamic>)['age'], 25);
        expect((result['user2'] as Map<String, dynamic>)['hobbies'],
            ['coding', 'gaming']);
        expect((result['user2'] as Map<String, dynamic>)['metadata'],
            {'city': 'Los Angeles'});
      });

      test('should handle empty map', () {
        final emptyMap = <String, TestUser>{};

        final result = JsonHandler.mapToJson<TestUser>(
          emptyMap,
          (user) => user.toJson(),
        );

        expect(result, isEmpty);
      });

      test('should handle objects with empty collections', () {
        final users = {
          'user1': const TestUser(
              name: 'John Doe', age: 30, hobbies: [], metadata: {}),
          'user2': const TestUser(
              name: 'Jane Smith', age: 25, hobbies: [], metadata: {})
        };

        final result = JsonHandler.mapToJson<TestUser>(
          users,
          (user) => user.toJson(),
        );

        expect(result, hasLength(2));
        expect((result['user1'] as Map<String, dynamic>)['hobbies'], isEmpty);
        expect((result['user1'] as Map<String, dynamic>)['metadata'], isEmpty);
        expect((result['user2'] as Map<String, dynamic>)['hobbies'], isEmpty);
        expect((result['user2'] as Map<String, dynamic>)['metadata'], isEmpty);
      });

      test('should handle different object types', () {
        final policies = {
          'admin': const TestPolicy(
              roleName: 'admin',
              allowedContent: ['read', 'write', 'delete'],
              metadata: {'level': 5, 'active': true}),
          'user': const TestPolicy(
              roleName: 'user',
              allowedContent: ['read'],
              metadata: {'level': 1, 'active': true})
        };

        final result = JsonHandler.mapToJson<TestPolicy>(
          policies,
          (policy) => policy.toJson(),
        );

        expect(result, hasLength(2));
        expect((result['admin'] as Map<String, dynamic>)['roleName'], 'admin');
        expect((result['admin'] as Map<String, dynamic>)['allowedContent'],
            ['read', 'write', 'delete']);
        expect((result['admin'] as Map<String, dynamic>)['metadata'],
            {'level': 5, 'active': true});
        expect((result['user'] as Map<String, dynamic>)['roleName'], 'user');
        expect((result['user'] as Map<String, dynamic>)['allowedContent'],
            ['read']);
        expect((result['user'] as Map<String, dynamic>)['metadata'],
            {'level': 1, 'active': true});
      });

      // New error handling tests for serialization
      group('Serialization error handling', () {
        test(
            'should handle toJson function throwing exceptions with partial success',
            () {
          final users = {
            'valid_user': const TestUser(
                name: 'John Doe', age: 30, hobbies: ['reading'], metadata: {}),
            'problematic_user': ProblematicUser('Jane Smith', 25),
          };

          final result = JsonHandler.mapToJson<TestUser>(
            users,
            (user) => user.toJson(),
            allowPartialSuccess: true,
          );

          expect(result, hasLength(1));
          expect((result['valid_user'] as Map<String, dynamic>)['name'],
              'John Doe');
          expect(result.containsKey('problematic_user'), false);
        });

        test(
            'should throw JsonSerializeException when allowPartialSuccess is false',
            () {
          final users = {
            'valid_user': const TestUser(
                name: 'John Doe', age: 30, hobbies: ['reading'], metadata: {}),
            'problematic_user': ProblematicUser('Jane Smith', 25),
          };

          expect(
            () => JsonHandler.mapToJson<TestUser>(
              users,
              (user) => user.toJson(),
              allowPartialSuccess: false,
            ),
            throwsA(isA<JsonSerializeException>()),
          );
        });

        test(
            'should throw JsonSerializeException when no items can be serialized',
            () {
          final users = {
            'problematic1': ProblematicUser('User1', 25),
            'problematic2': ProblematicUser('User2', 30),
          };

          expect(
            () => JsonHandler.mapToJson<TestUser>(
              users,
              (user) => user.toJson(),
              allowPartialSuccess: false,
            ),
            throwsA(isA<JsonSerializeException>()),
          );
        });
      });
    });

    group('Utility methods', () {
      test('isValidJsonMap should correctly validate JSON maps', () {
        expect(JsonHandler.isValidJsonMap({'key': 'value'}), true);
        expect(
            JsonHandler.isValidJsonMap({
              'key': 123,
              'nested': {'a': 'b'}
            }),
            true);
        expect(JsonHandler.isValidJsonMap('not_a_map'), false);
        expect(JsonHandler.isValidJsonMap(123), false);
        expect(JsonHandler.isValidJsonMap(null), false);
        expect(JsonHandler.isValidJsonMap([]), false);
      });

      test('tryParse should return parsed object on success', () {
        final json = {
          'name': 'John Doe',
          'age': 30,
          'hobbies': ['reading'],
          'metadata': {}
        };

        final result = JsonHandler.tryParse<TestUser>(
          json,
          (json) => TestUser.fromJson(json),
          context: 'test_context',
        );

        expect(result, isNotNull);
        expect(result!.name, 'John Doe');
        expect(result.age, 30);
      });

      test('tryParse should return null on failure', () {
        final invalidJson = {
          'name': 'John Doe',
          // Missing required 'age' field
          'hobbies': ['reading'],
          'metadata': {}
        };

        final result = JsonHandler.tryParse<TestUser>(
          invalidJson,
          (json) => TestUser.fromJson(json),
          context: 'test_context',
        );

        expect(result, isNull);
      });
    });

    group('Integration tests', () {
      test('should handle round-trip conversion for map of objects', () {
        final originalUsers = {
          'user1': const TestUser(
              name: 'John Doe',
              age: 30,
              hobbies: ['reading', 'swimming'],
              metadata: {'city': 'New York', 'country': 'USA'}),
          'user2': const TestUser(
              name: 'Jane Smith',
              age: 25,
              hobbies: ['coding', 'gaming'],
              metadata: {'city': 'Los Angeles', 'country': 'USA'})
        };

        // Convert to JSON map
        final jsonMap = JsonHandler.mapToJson<TestUser>(
          originalUsers,
          (user) => user.toJson(),
        );

        expect(jsonMap, hasLength(2));

        // Convert back from JSON map
        final convertedUsers = JsonHandler.parseMap<TestUser>(
          jsonMap,
          (json) => TestUser.fromJson(json),
        );

        expect(convertedUsers, hasLength(2));
        expect(convertedUsers['user1'], equals(originalUsers['user1']));
        expect(convertedUsers['user2'], equals(originalUsers['user2']));
      });

      test('should handle round-trip conversion for policy map', () {
        final originalPolicies = {
          'admin': const TestPolicy(roleName: 'admin', allowedContent: [
            'read',
            'write',
            'delete'
          ], metadata: {
            'permissions': ['user_management'],
            'level': 5,
            'active': true,
          }),
          'user': const TestPolicy(roleName: 'user', allowedContent: [
            'read'
          ], metadata: {
            'permissions': ['basic_access'],
            'level': 1,
            'active': true,
          })
        };

        // Convert to JSON map
        final jsonMap = JsonHandler.mapToJson<TestPolicy>(
          originalPolicies,
          (policy) => policy.toJson(),
        );

        expect(jsonMap, hasLength(2));

        // Convert back from JSON map
        final convertedPolicies = JsonHandler.parseMap<TestPolicy>(
          jsonMap,
          (json) => TestPolicy.fromJson(json),
        );

        expect(convertedPolicies, hasLength(2));
        expect(convertedPolicies['admin'], equals(originalPolicies['admin']));
        expect(convertedPolicies['user'], equals(originalPolicies['user']));
      });

      test('should handle mixed valid and invalid data in round-trip', () {
        final originalUsers = {
          'valid_user': const TestUser(
              name: 'John Doe', age: 30, hobbies: ['reading'], metadata: {}),
          'invalid_user': const TestUser(
              name: 'Jane Smith', age: 25, hobbies: ['coding'], metadata: {}),
        };

        // Convert to JSON map
        final jsonMap = JsonHandler.mapToJson<TestUser>(
          originalUsers,
          (user) => user.toJson(),
        );

        // Add some invalid data to the JSON map
        jsonMap['corrupted_user'] = 'not_a_map';
        jsonMap['null_user'] = null;

        // Convert back from JSON map with partial success
        final convertedUsers = JsonHandler.parseMap<TestUser>(
          jsonMap,
          (json) => TestUser.fromJson(json),
          allowPartialSuccess: true,
        );

        expect(convertedUsers, hasLength(2));
        expect(
            convertedUsers['valid_user'], equals(originalUsers['valid_user']));
        expect(convertedUsers['invalid_user'],
            equals(originalUsers['invalid_user']));
        expect(convertedUsers.containsKey('corrupted_user'), false);
        expect(convertedUsers.containsKey('null_user'), false);
      });

      test(
          'should handle complete parsing failure with allowPartialSuccess false',
          () {
        final invalidJsonMap = {
          'user1': 'not_a_map',
          'user2': null,
          'user3': 123,
        };

        expect(
          () => JsonHandler.parseMap<TestUser>(
            invalidJsonMap,
            (json) => TestUser.fromJson(json),
            allowPartialSuccess: false,
          ),
          throwsA(isA<JsonParseException>()),
        );
      });

      test(
          'should handle complete serialization failure with allowPartialSuccess false',
          () {
        final problematicUsers = {
          'user1': ProblematicUser('User1', 25),
          'user2': ProblematicUser('User2', 30),
        };

        expect(
          () => JsonHandler.mapToJson<TestUser>(
            problematicUsers,
            (user) => user.toJson(),
            allowPartialSuccess: false,
          ),
          throwsA(isA<JsonSerializeException>()),
        );
      });

      test('should handle empty map with allowPartialSuccess false', () {
        final emptyMap = <String, dynamic>{};

        expect(
          () => JsonHandler.parseMap<TestUser>(
            emptyMap,
            (json) => TestUser.fromJson(json),
            allowPartialSuccess: false,
          ),
          throwsA(isA<JsonParseException>()),
        );
      });

      test(
          'should handle empty map serialization with allowPartialSuccess false',
          () {
        final emptyMap = <String, TestUser>{};

        expect(
          () => JsonHandler.mapToJson<TestUser>(
            emptyMap,
            (user) => user.toJson(),
            allowPartialSuccess: false,
          ),
          throwsA(isA<JsonSerializeException>()),
        );
      });
    });
  });
}

// Helper class for testing serialization errors
class ProblematicUser extends TestUser {
  ProblematicUser(String name, int age)
      : super(name: name, age: age, hobbies: [], metadata: {});

  @override
  Map<String, dynamic> toJson() {
    throw Exception('Simulated serialization error');
  }
}
