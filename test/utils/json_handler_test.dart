import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_policy_engine/utils/json_handler.dart';

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
              return entry.value.length == otherValue.length &&
                  (entry.value as List)
                      .every((item) => otherValue.contains(item));
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
    group('fromJson', () {
      test('should convert valid JSON string to object', () {
        const jsonString = '''
        {
          "name": "John Doe",
          "age": 30,
          "hobbies": ["reading", "swimming"],
          "metadata": {"city": "New York"}
        }
        ''';

        final result = JsonHandler.fromJson<TestUser>(
          jsonString,
          (json) => TestUser.fromJson(json),
        );

        expect(result, isNotNull);
        expect(result!.name, 'John Doe');
        expect(result.age, 30);
        expect(result.hobbies, ['reading', 'swimming']);
        expect(result.metadata, {'city': 'New York'});
      });

      test('should return null for invalid JSON format', () {
        const invalidJson = '{"name": "John", "age": 30,}'; // Trailing comma

        final result = JsonHandler.fromJson<TestUser>(
          invalidJson,
          (json) => TestUser.fromJson(json),
        );

        expect(result, isNull);
      });

      test('should return null for malformed JSON', () {
        const malformedJson =
            '{"name": "John", "age": "invalid"}'; // age should be int

        final result = JsonHandler.fromJson<TestUser>(
          malformedJson,
          (json) => TestUser.fromJson(json),
        );

        expect(result, isNull);
      });

      test('should return null for empty string', () {
        const emptyString = '';

        final result = JsonHandler.fromJson<TestUser>(
          emptyString,
          (json) => TestUser.fromJson(json),
        );

        expect(result, isNull);
      });

      // Note: null string tests removed as JsonHandler doesn't handle null strings
      // The method signature requires a non-null String parameter

      test('should handle JSON with missing optional fields', () {
        const jsonString = '{"name": "Jane", "age": 25}';

        final result = JsonHandler.fromJson<TestUser>(
          jsonString,
          (json) => TestUser.fromJson(json),
        );

        expect(result, isNotNull);
        expect(result!.name, 'Jane');
        expect(result.age, 25);
        expect(result.hobbies, isEmpty);
        expect(result.metadata, isEmpty);
      });
    });

    group('fromJsonList', () {
      test('should convert valid JSON array to list of objects', () {
        const jsonString = '''
        [
          {
            "name": "John Doe",
            "age": 30,
            "hobbies": ["reading"],
            "metadata": {"city": "NYC"}
          },
          {
            "name": "Jane Smith",
            "age": 25,
            "hobbies": ["swimming", "coding"],
            "metadata": {"city": "LA"}
          }
        ]
        ''';

        final result = JsonHandler.fromJsonList<TestUser>(
          jsonString,
          (json) => TestUser.fromJson(json),
        );

        expect(result, hasLength(2));
        expect(result[0].name, 'John Doe');
        expect(result[0].age, 30);
        expect(result[1].name, 'Jane Smith');
        expect(result[1].age, 25);
      });

      test('should return empty list for invalid JSON format', () {
        const invalidJson = '[{"name": "John", "age": 30,}]'; // Trailing comma

        final result = JsonHandler.fromJsonList<TestUser>(
          invalidJson,
          (json) => TestUser.fromJson(json),
        );

        expect(result, isEmpty);
      });

      test('should return empty list for malformed JSON', () {
        const malformedJson = '[{"name": "John", "age": "invalid"}]';

        final result = JsonHandler.fromJsonList<TestUser>(
          malformedJson,
          (json) => TestUser.fromJson(json),
        );

        expect(result, isEmpty);
      });

      test('should return empty list for empty string', () {
        const emptyString = '';

        final result = JsonHandler.fromJsonList<TestUser>(
          emptyString,
          (json) => TestUser.fromJson(json),
        );

        expect(result, isEmpty);
      });

      // Note: null string tests removed as JsonHandler doesn't handle null strings
      // The method signature requires a non-null String parameter

      test('should handle empty JSON array', () {
        const emptyArray = '[]';

        final result = JsonHandler.fromJsonList<TestUser>(
          emptyArray,
          (json) => TestUser.fromJson(json),
        );

        expect(result, isEmpty);
      });

      test('should handle JSON array with missing optional fields', () {
        const jsonString = '''
        [
          {"name": "John", "age": 30},
          {"name": "Jane", "age": 25}
        ]
        ''';

        final result = JsonHandler.fromJsonList<TestUser>(
          jsonString,
          (json) => TestUser.fromJson(json),
        );

        expect(result, hasLength(2));
        expect(result[0].hobbies, isEmpty);
        expect(result[0].metadata, isEmpty);
        expect(result[1].hobbies, isEmpty);
        expect(result[1].metadata, isEmpty);
      });
    });

    group('toJson', () {
      test('should convert object to valid JSON string', () {
        const user = TestUser(
          name: 'John Doe',
          age: 30,
          hobbies: ['reading', 'swimming'],
          metadata: {'city': 'New York'},
        );

        final result = JsonHandler.toJson<TestUser>(
          user,
          (user) => user.toJson(),
        );

        expect(result, isNotNull);
        expect(result, contains('"name":"John Doe"'));
        expect(result, contains('"age":30'));
        expect(result, contains('"hobbies":["reading","swimming"]'));
        expect(result, contains('"metadata":{"city":"New York"}'));
      });

      test('should handle object with empty collections', () {
        const user = TestUser(
          name: 'Jane Smith',
          age: 25,
          hobbies: [],
          metadata: {},
        );

        final result = JsonHandler.toJson<TestUser>(
          user,
          (user) => user.toJson(),
        );

        expect(result, isNotNull);
        expect(result, contains('"hobbies":[]'));
        expect(result, contains('"metadata":{}'));
      });

      // Note: null object tests removed as JsonHandler doesn't handle null objects
      // The method signature requires a non-null object parameter

      test('should handle complex nested objects', () {
        const policy = TestPolicy(
          roleName: 'admin',
          allowedContent: ['read', 'write', 'delete'],
          metadata: {
            'permissions': ['user_management', 'system_config'],
            'level': 5,
            'active': true,
          },
        );

        final result = JsonHandler.toJson<TestPolicy>(
          policy,
          (policy) => policy.toJson(),
        );

        expect(result, isNotNull);
        expect(result, contains('"roleName":"admin"'));
        expect(result, contains('"allowedContent":["read","write","delete"]'));
        expect(result,
            contains('"permissions":["user_management","system_config"]'));
        expect(result, contains('"level":5'));
        expect(result, contains('"active":true'));
      });
    });

    group('toJsonList', () {
      test('should convert list of objects to valid JSON string', () {
        const users = [
          TestUser(
            name: 'John Doe',
            age: 30,
            hobbies: ['reading'],
            metadata: {'city': 'NYC'},
          ),
          TestUser(
            name: 'Jane Smith',
            age: 25,
            hobbies: ['swimming', 'coding'],
            metadata: {'city': 'LA'},
          ),
        ];

        final result = JsonHandler.toJsonList<TestUser>(
          users,
          (user) => user.toJson(),
        );

        expect(result, isNotNull);
        expect(result, startsWith('['));
        expect(result, endsWith(']'));
        expect(result, contains('"name":"John Doe"'));
        expect(result, contains('"name":"Jane Smith"'));
      });

      test('should handle empty list', () {
        const users = <TestUser>[];

        final result = JsonHandler.toJsonList<TestUser>(
          users,
          (user) => user.toJson(),
        );

        expect(result, isNotNull);
        expect(result, '[]');
      });

      // Note: null list tests removed as JsonHandler doesn't handle null lists
      // The method signature requires a non-null List parameter

      test('should handle list with objects containing empty collections', () {
        const users = [
          TestUser(name: 'John', age: 30, hobbies: [], metadata: {}),
          TestUser(name: 'Jane', age: 25, hobbies: [], metadata: {}),
        ];

        final result = JsonHandler.toJsonList<TestUser>(
          users,
          (user) => user.toJson(),
        );

        expect(result, isNotNull);
        expect(result, contains('"hobbies":[]'));
        expect(result, contains('"metadata":{}'));
      });
    });

    group('parseJson', () {
      test('should parse valid JSON string to Map', () {
        const jsonString = '''
        {
          "name": "John Doe",
          "age": 30,
          "hobbies": ["reading", "swimming"],
          "metadata": {"city": "New York"}
        }
        ''';

        final result = JsonHandler.parseJson(jsonString);

        expect(result, isNotNull);
        expect(result!['name'], 'John Doe');
        expect(result['age'], 30);
        expect(result['hobbies'], ['reading', 'swimming']);
        expect(result['metadata'], {'city': 'New York'});
      });

      test('should return null for invalid JSON format', () {
        const invalidJson = '{"name": "John", "age": 30,}'; // Trailing comma

        final result = JsonHandler.parseJson(invalidJson);

        expect(result, isNull);
      });

      test('should return null for malformed JSON', () {
        const malformedJson = '{"name": "John", "age": 30,}'; // Trailing comma

        final result = JsonHandler.parseJson(malformedJson);

        expect(result, isNull);
      });

      test('should return null for empty string', () {
        const emptyString = '';

        final result = JsonHandler.parseJson(emptyString);

        expect(result, isNull);
      });

      // Note: null string tests removed as JsonHandler doesn't handle null strings
      // The method signature requires a non-null String parameter

      test('should handle JSON with nested objects', () {
        const jsonString = '''
        {
          "user": {
            "name": "John",
            "profile": {
              "age": 30,
              "preferences": {
                "theme": "dark",
                "notifications": true
              }
            }
          }
        }
        ''';

        final result = JsonHandler.parseJson(jsonString);

        expect(result, isNotNull);
        expect(result!['user']['name'], 'John');
        expect(result['user']['profile']['age'], 30);
        expect(result['user']['profile']['preferences']['theme'], 'dark');
        expect(result['user']['profile']['preferences']['notifications'], true);
      });
    });

    group('isValidJson', () {
      test('should return true for valid JSON object', () {
        const validJson = '{"name": "John", "age": 30}';

        final result = JsonHandler.isValidJson(validJson);

        expect(result, isTrue);
      });

      test('should return true for valid JSON array', () {
        const validJson = '[{"name": "John"}, {"name": "Jane"}]';

        final result = JsonHandler.isValidJson(validJson);

        expect(result, isTrue);
      });

      test('should return true for valid JSON with nested structures', () {
        const validJson = '''
        {
          "users": [
            {"name": "John", "metadata": {"city": "NYC"}},
            {"name": "Jane", "metadata": {"city": "LA"}}
          ]
        }
        ''';

        final result = JsonHandler.isValidJson(validJson);

        expect(result, isTrue);
      });

      test('should return false for invalid JSON format', () {
        const invalidJson = '{"name": "John", "age": 30,}'; // Trailing comma

        final result = JsonHandler.isValidJson(invalidJson);

        expect(result, isFalse);
      });

      test('should return false for malformed JSON', () {
        const malformedJson = '{"name": "John", "age": 30,}'; // Trailing comma

        final result = JsonHandler.isValidJson(malformedJson);

        expect(result, isFalse);
      });

      test('should return false for empty string', () {
        const emptyString = '';

        final result = JsonHandler.isValidJson(emptyString);

        expect(result, isFalse);
      });

      // Note: null string tests removed as JsonHandler doesn't handle null strings
      // The method signature requires a non-null String parameter

      test('should return false for plain text', () {
        const plainText = 'This is not JSON';

        final result = JsonHandler.isValidJson(plainText);

        expect(result, isFalse);
      });

      test('should return false for incomplete JSON', () {
        const incompleteJson = '{"name": "John"';

        final result = JsonHandler.isValidJson(incompleteJson);

        expect(result, isFalse);
      });
    });

    group('Integration tests', () {
      test('should handle round-trip conversion for single object', () {
        const originalUser = TestUser(
          name: 'John Doe',
          age: 30,
          hobbies: ['reading', 'swimming'],
          metadata: {'city': 'New York', 'country': 'USA'},
        );

        // Convert to JSON
        final jsonString = JsonHandler.toJson<TestUser>(
          originalUser,
          (user) => user.toJson(),
        );

        expect(jsonString, isNotNull);

        // Convert back from JSON
        final convertedUser = JsonHandler.fromJson<TestUser>(
          jsonString!,
          (json) => TestUser.fromJson(json),
        );

        expect(convertedUser, isNotNull);
        expect(convertedUser, equals(originalUser));
      });

      test('should handle round-trip conversion for list of objects', () {
        const originalUsers = [
          TestUser(
            name: 'John Doe',
            age: 30,
            hobbies: ['reading'],
            metadata: {'city': 'NYC'},
          ),
          TestUser(
            name: 'Jane Smith',
            age: 25,
            hobbies: ['swimming', 'coding'],
            metadata: {'city': 'LA'},
          ),
        ];

        // Convert to JSON
        final jsonString = JsonHandler.toJsonList<TestUser>(
          originalUsers,
          (user) => user.toJson(),
        );

        expect(jsonString, isNotNull);

        // Convert back from JSON
        final convertedUsers = JsonHandler.fromJsonList<TestUser>(
          jsonString!,
          (json) => TestUser.fromJson(json),
        );

        expect(convertedUsers, hasLength(2));
        expect(convertedUsers[0], equals(originalUsers[0]));
        expect(convertedUsers[1], equals(originalUsers[1]));
      });

      test('should handle complex nested structures', () {
        const originalPolicies = [
          TestPolicy(
            roleName: 'admin',
            allowedContent: ['read', 'write', 'delete'],
            metadata: {
              'permissions': ['user_management'],
              'level': 5,
              'active': true,
            },
          ),
          TestPolicy(
            roleName: 'user',
            allowedContent: ['read'],
            metadata: {
              'permissions': ['basic_access'],
              'level': 1,
              'active': true,
            },
          ),
        ];

        // Convert to JSON
        final jsonString = JsonHandler.toJsonList<TestPolicy>(
          originalPolicies,
          (policy) => policy.toJson(),
        );

        expect(jsonString, isNotNull);

        // Convert back from JSON
        final convertedPolicies = JsonHandler.fromJsonList<TestPolicy>(
          jsonString!,
          (json) => TestPolicy.fromJson(json),
        );

        expect(convertedPolicies, hasLength(2));
        expect(convertedPolicies[0], equals(originalPolicies[0]));
        expect(convertedPolicies[1], equals(originalPolicies[1]));
      });
    });
  });
}
