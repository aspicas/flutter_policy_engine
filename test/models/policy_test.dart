import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_policy_engine/src/models/policy.dart';

void main() {
  group('Policy', () {
    group('Constructor', () {
      test('should create instance with required parameters', () {
        const policy = Policy(
          roleName: 'admin',
          allowedContent: ['read', 'write'],
        );

        expect(policy.roleName, equals('admin'));
        expect(policy.allowedContent, equals(['read', 'write']));
        expect(policy.metadata, equals({}));
      });

      test('should create instance with all parameters', () {
        final metadata = {'level': 'high', 'department': 'IT'};
        final policy = Policy(
          roleName: 'admin',
          allowedContent: const ['read', 'write', 'delete'],
          metadata: metadata,
        );

        expect(policy.roleName, equals('admin'));
        expect(policy.allowedContent, equals(['read', 'write', 'delete']));
        expect(policy.metadata, equals(metadata));
      });

      test('should create immutable instance', () {
        const policy = Policy(
          roleName: 'admin',
          allowedContent: ['read'],
        );

        expect(policy, isA<Policy>());
        // Verify it's const-constructible
        const policyConst = Policy(
          roleName: 'admin',
          allowedContent: ['read'],
        );
        expect(policyConst, isA<Policy>());
      });

      test('should handle empty allowed content', () {
        const policy = Policy(
          roleName: 'guest',
          allowedContent: [],
        );

        expect(policy.roleName, equals('guest'));
        expect(policy.allowedContent, isEmpty);
      });

      test('should handle empty role name', () {
        const policy = Policy(
          roleName: '',
          allowedContent: ['read'],
        );

        expect(policy.roleName, equals(''));
        expect(policy.allowedContent, equals(['read']));
      });
    });

    group('isContentAllowed', () {
      late Policy policy;

      setUp(() {
        policy = const Policy(
          roleName: 'admin',
          allowedContent: ['read', 'write', 'delete'],
        );
      });

      test('should return true for allowed content', () {
        expect(policy.isContentAllowed('read'), isTrue);
        expect(policy.isContentAllowed('write'), isTrue);
        expect(policy.isContentAllowed('delete'), isTrue);
      });

      test('should return false for disallowed content', () {
        expect(policy.isContentAllowed('execute'), isFalse);
        expect(policy.isContentAllowed('manage'), isFalse);
        expect(policy.isContentAllowed('admin'), isFalse);
      });

      test('should handle case-sensitive matching', () {
        expect(policy.isContentAllowed('READ'), isFalse);
        expect(policy.isContentAllowed('Read'), isFalse);
        expect(policy.isContentAllowed('read'), isTrue);
      });

      test('should handle empty content string', () {
        expect(policy.isContentAllowed(''), isFalse);
      });

      test('should handle policy with empty allowed content', () {
        const emptyPolicy = Policy(
          roleName: 'guest',
          allowedContent: [],
        );

        expect(emptyPolicy.isContentAllowed('read'), isFalse);
        expect(emptyPolicy.isContentAllowed(''), isFalse);
        expect(emptyPolicy.isContentAllowed('any_content'), isFalse);
      });

      test('should handle duplicate content in allowed list', () {
        const duplicatePolicy = Policy(
          roleName: 'duplicate_role',
          allowedContent: ['read', 'read', 'write'],
        );

        expect(duplicatePolicy.isContentAllowed('read'), isTrue);
        expect(duplicatePolicy.isContentAllowed('write'), isTrue);
        expect(duplicatePolicy.isContentAllowed('delete'), isFalse);
      });

      test('should handle special characters in content', () {
        const specialPolicy = Policy(
          roleName: 'special_role',
          allowedContent: ['read@domain', 'write-file', 'delete_user'],
        );

        expect(specialPolicy.isContentAllowed('read@domain'), isTrue);
        expect(specialPolicy.isContentAllowed('write-file'), isTrue);
        expect(specialPolicy.isContentAllowed('delete_user'), isTrue);
        expect(specialPolicy.isContentAllowed('read'), isFalse);
      });

      test('should handle whitespace in content', () {
        const whitespacePolicy = Policy(
          roleName: 'whitespace_role',
          allowedContent: ['read file', 'write document', 'delete record'],
        );

        expect(whitespacePolicy.isContentAllowed('read file'), isTrue);
        expect(whitespacePolicy.isContentAllowed('write document'), isTrue);
        expect(whitespacePolicy.isContentAllowed('delete record'), isTrue);
        expect(whitespacePolicy.isContentAllowed('readfile'), isFalse);
      });
    });

    group('copyWith', () {
      late Policy originalPolicy;

      setUp(() {
        originalPolicy = const Policy(
          roleName: 'admin',
          allowedContent: ['read', 'write'],
          metadata: {'level': 'high'},
        );
      });

      test('should create copy with same values when no parameters provided',
          () {
        final copy = originalPolicy.copyWith();

        expect(copy.roleName, equals(originalPolicy.roleName));
        expect(copy.allowedContent, equals(originalPolicy.allowedContent));
        expect(copy.metadata, equals(originalPolicy.metadata));
        expect(copy, isNot(same(originalPolicy)));
      });

      test('should create copy with updated role name', () {
        final copy = originalPolicy.copyWith(roleName: 'super_admin');

        expect(copy.roleName, equals('super_admin'));
        expect(copy.allowedContent, equals(originalPolicy.allowedContent));
        expect(copy.metadata, equals(originalPolicy.metadata));
      });

      test('should create copy with updated allowed content', () {
        final newContent = ['read', 'write', 'delete'];
        final copy = originalPolicy.copyWith(allowedContent: newContent);

        expect(copy.roleName, equals(originalPolicy.roleName));
        expect(copy.allowedContent, equals(newContent));
        expect(copy.metadata, equals(originalPolicy.metadata));
      });

      test('should create copy with updated metadata', () {
        final newMetadata = {'level': 'low', 'department': 'IT'};
        final copy = originalPolicy.copyWith(metadata: newMetadata);

        expect(copy.roleName, equals(originalPolicy.roleName));
        expect(copy.allowedContent, equals(originalPolicy.allowedContent));
        expect(copy.metadata, equals(newMetadata));
      });

      test('should create copy with multiple updated fields', () {
        final copy = originalPolicy.copyWith(
          roleName: 'user',
          allowedContent: ['read'],
          metadata: {'level': 'normal'},
        );

        expect(copy.roleName, equals('user'));
        expect(copy.allowedContent, equals(['read']));
        expect(copy.metadata, equals({'level': 'normal'}));
      });

      test('should handle empty values in copyWith', () {
        final copy = originalPolicy.copyWith(
          roleName: '',
          allowedContent: [],
          metadata: {},
        );

        expect(copy.roleName, equals(''));
        expect(copy.allowedContent, isEmpty);
        expect(copy.metadata, isEmpty);
      });
    });

    group('Equality', () {
      test('should be equal to itself', () {
        const policy = Policy(
          roleName: 'admin',
          allowedContent: ['read', 'write'],
        );

        expect(policy, equals(policy));
        expect(policy.hashCode, equals(policy.hashCode));
      });

      test('should be equal to policy with same values', () {
        const policy1 = Policy(
          roleName: 'admin',
          allowedContent: ['read', 'write'],
          metadata: {'level': 'high'},
        );
        const policy2 = Policy(
          roleName: 'admin',
          allowedContent: ['read', 'write'],
          metadata: {'level': 'high'},
        );

        expect(policy1, equals(policy2));
        expect(policy1.hashCode, equals(policy2.hashCode));
      });

      test('should not be equal to policy with different role name', () {
        const policy1 = Policy(
          roleName: 'admin',
          allowedContent: ['read', 'write'],
        );
        const policy2 = Policy(
          roleName: 'user',
          allowedContent: ['read', 'write'],
        );

        expect(policy1, isNot(equals(policy2)));
        expect(policy1.hashCode, isNot(equals(policy2.hashCode)));
      });

      test('should not be equal to policy with different allowed content', () {
        const policy1 = Policy(
          roleName: 'admin',
          allowedContent: ['read', 'write'],
        );
        const policy2 = Policy(
          roleName: 'admin',
          allowedContent: ['read', 'delete'],
        );

        expect(policy1, isNot(equals(policy2)));
        expect(policy1.hashCode, isNot(equals(policy2.hashCode)));
      });

      test('should be equal regardless of content order', () {
        const policy1 = Policy(
          roleName: 'admin',
          allowedContent: ['read', 'write'],
        );
        const policy2 = Policy(
          roleName: 'admin',
          allowedContent: ['write', 'read'],
        );

        expect(policy1, equals(policy2));
        expect(policy1.hashCode, equals(policy2.hashCode));
      });

      test('should not be equal to different object types', () {
        const policy = Policy(
          roleName: 'admin',
          allowedContent: ['read'],
        );

        expect(policy, isNot(equals('admin')));
        expect(policy, isNot(equals(42)));
        expect(policy, isNot(equals(null)));
      });

      test('should not consider metadata in equality', () {
        const policy1 = Policy(
          roleName: 'admin',
          allowedContent: ['read', 'write'],
          metadata: {'level': 'high'},
        );
        const policy2 = Policy(
          roleName: 'admin',
          allowedContent: ['read', 'write'],
          metadata: {'level': 'low'},
        );

        expect(policy1, equals(policy2));
        expect(policy1.hashCode, equals(policy2.hashCode));
      });
    });

    group('toString', () {
      test('should return meaningful string representation', () {
        const policy = Policy(
          roleName: 'admin',
          allowedContent: ['read', 'write'],
          metadata: {'level': 'high'},
        );

        final string = policy.toString();
        expect(string, contains('Policy'));
        expect(string, contains('roleName: admin'));
        expect(string, contains('allowedContent: [read, write]'));
        expect(string, contains('metadata: {level: high}'));
      });

      test('should handle empty values in string representation', () {
        const policy = Policy(
          roleName: '',
          allowedContent: [],
          metadata: {},
        );

        final string = policy.toString();
        expect(string, contains('roleName: '));
        expect(string, contains('allowedContent: []'));
        expect(string, contains('metadata: {}'));
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        const policy = Policy(
          roleName: 'admin',
          allowedContent: ['read', 'write', 'delete'],
          metadata: {'level': 'high', 'department': 'IT'},
        );

        final json = policy.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['roleName'], equals('admin'));
        expect(json['allowedContent'], equals(['read', 'write', 'delete']));
        expect(json['metadata'], equals({'level': 'high', 'department': 'IT'}));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'roleName': 'user',
          'allowedContent': ['read'],
          'metadata': {'level': 'normal'},
        };

        final policy = Policy.fromJson(json);

        expect(policy.roleName, equals('user'));
        expect(policy.allowedContent, equals(['read']));
        expect(policy.metadata, equals({'level': 'normal'}));
      });

      test('should handle JSON with empty values', () {
        final json = {
          'roleName': '',
          'allowedContent': [],
          'metadata': {},
        };

        final policy = Policy.fromJson(json);

        expect(policy.roleName, equals(''));
        expect(policy.allowedContent, isEmpty);
        expect(policy.metadata, isEmpty);
      });

      test('should handle JSON without metadata', () {
        final json = {
          'roleName': 'admin',
          'allowedContent': ['read', 'write'],
        };

        final policy = Policy.fromJson(json);

        expect(policy.roleName, equals('admin'));
        expect(policy.allowedContent, equals(['read', 'write']));
        expect(policy.metadata, equals({}));
      });

      test('should round-trip through JSON correctly', () {
        const originalPolicy = Policy(
          roleName: 'admin',
          allowedContent: ['read', 'write', 'delete'],
          metadata: {'level': 'high', 'department': 'IT'},
        );

        final json = originalPolicy.toJson();
        final deserializedPolicy = Policy.fromJson(json);

        expect(deserializedPolicy, equals(originalPolicy));
      });

      test('should handle complex metadata in JSON', () {
        final complexMetadata = {
          'level': 'high',
          'departments': ['IT', 'HR'],
          'nested': {
            'key': 'value',
            'array': [1, 2, 3],
            'boolean': true,
            'number': 42.5,
          },
        };

        final json = {
          'roleName': 'admin',
          'allowedContent': ['read', 'write'],
          'metadata': complexMetadata,
        };

        final policy = Policy.fromJson(json);

        expect(policy.metadata, equals(complexMetadata));
        expect(
          (policy.metadata['nested'] as Map<String, dynamic>)['array'],
          equals([1, 2, 3]),
        );
      });
    });

    group('Edge cases', () {
      test('should handle very long role names', () {
        final longRoleName = 'a' * 1000;
        final policy = Policy(
          roleName: longRoleName,
          allowedContent: const ['read'],
        );

        expect(policy.roleName, equals(longRoleName));
        expect(policy.isContentAllowed('read'), isTrue);
      });

      test('should handle very long content items', () {
        final longContent = 'a' * 10000;
        final policy = Policy(
          roleName: 'admin',
          allowedContent: [longContent],
        );

        expect(policy.isContentAllowed(longContent), isTrue);
        expect(policy.isContentAllowed('different'), isFalse);
      });

      test('should handle large number of allowed content items', () {
        final largeContentList = List.generate(1000, (i) => 'content_$i');
        final policy = Policy(
          roleName: 'admin',
          allowedContent: largeContentList,
        );

        expect(policy.allowedContent.length, equals(1000));
        expect(policy.isContentAllowed('content_500'), isTrue);
        expect(policy.isContentAllowed('content_999'), isTrue);
        expect(policy.isContentAllowed('nonexistent'), isFalse);
      });

      test('should handle unicode characters', () {
        const policy = Policy(
          roleName: 'admin',
          allowedContent: ['café', 'naïve', 'résumé'],
        );

        expect(policy.isContentAllowed('café'), isTrue);
        expect(policy.isContentAllowed('naïve'), isTrue);
        expect(policy.isContentAllowed('résumé'), isTrue);
        expect(policy.isContentAllowed('cafe'), isFalse);
      });

      test('should handle numbers as content', () {
        const policy = Policy(
          roleName: 'admin',
          allowedContent: ['123', '456', '789'],
        );

        expect(policy.isContentAllowed('123'), isTrue);
        expect(policy.isContentAllowed('456'), isTrue);
        expect(policy.isContentAllowed('789'), isTrue);
        expect(policy.isContentAllowed('999'), isFalse);
      });
    });

    group('Error handling', () {
      test('should handle null values in JSON gracefully', () {
        final json = {
          'roleName': null,
          'allowedContent': null,
          'metadata': null,
        };

        expect(() => Policy.fromJson(json), throwsA(isA<ArgumentError>()));
      });

      test('should handle missing required fields in JSON', () {
        final json = {
          'roleName': 'admin',
          // missing allowedContent
        };

        expect(() => Policy.fromJson(json), throwsA(isA<ArgumentError>()));
      });

      test('should handle wrong types in JSON', () {
        final json = {
          'roleName': 123, // should be string
          'allowedContent': ['read'],
        };

        expect(() => Policy.fromJson(json), throwsA(isA<ArgumentError>()));
      });

      test('should handle non-string items in allowedContent', () {
        final json = {
          'roleName': 'admin',
          'allowedContent': ['read', 123, 'write'], // contains non-string
        };

        expect(() => Policy.fromJson(json), throwsA(isA<ArgumentError>()));
      });
    });

    group('hashCode', () {
      test('should generate consistent hash codes for equal policies', () {
        const policy1 = Policy(
          roleName: 'admin',
          allowedContent: ['read', 'write'],
        );
        const policy2 = Policy(
          roleName: 'admin',
          allowedContent: ['write', 'read'], // different order
        );

        expect(policy1.hashCode, equals(policy2.hashCode));
      });

      test('should generate different hash codes for different policies', () {
        const policy1 = Policy(
          roleName: 'admin',
          allowedContent: ['read', 'write'],
        );
        const policy2 = Policy(
          roleName: 'user',
          allowedContent: ['read', 'write'],
        );

        expect(policy1.hashCode, isNot(equals(policy2.hashCode)));
      });

      test('should handle empty allowedContent in hashCode', () {
        const policy = Policy(
          roleName: 'admin',
          allowedContent: [],
        );

        expect(policy.hashCode, isA<int>());
        expect(policy.hashCode, isNot(equals(0)));
      });

      test('should handle large allowedContent lists in hashCode', () {
        final largeContentList = List.generate(100, (i) => 'content_$i');
        final policy = Policy(
          roleName: 'admin',
          allowedContent: largeContentList,
        );

        expect(policy.hashCode, isA<int>());
        expect(policy.hashCode, isNot(equals(0)));
      });
    });
  });
}
