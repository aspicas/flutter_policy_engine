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
    });
  });
}
