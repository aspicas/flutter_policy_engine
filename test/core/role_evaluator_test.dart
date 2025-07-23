import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_policy_engine/src/core/role_evaluator.dart';
import 'package:flutter_policy_engine/src/models/role.dart';

void main() {
  group('RoleEvaluator', () {
    late Map<String, Role> policies;
    late RoleEvaluator evaluator;

    setUp(() {
      policies = {
        'admin': const Role(
          name: 'admin',
          allowedContent: ['read', 'write', 'delete'],
          metadata: {'level': 'high'},
        ),
        'user': const Role(
          name: 'user',
          allowedContent: ['read'],
          metadata: {'level': 'normal'},
        ),
        'guest': const Role(
          name: 'guest',
          allowedContent: [],
          metadata: {'level': 'low'},
        ),
      };
      evaluator = RoleEvaluator(policies);
    });

    group('Constructor', () {
      test('should create instance with policies', () {
        expect(evaluator, isA<RoleEvaluator>());
      });

      test('should accept empty policies map', () {
        const emptyEvaluator = RoleEvaluator({});
        expect(emptyEvaluator, isA<RoleEvaluator>());
      });

      test('should be immutable', () {
        expect(evaluator, isA<RoleEvaluator>());
        // Verify it's const-constructible
        const evaluatorConst = RoleEvaluator({});
        expect(evaluatorConst, isA<RoleEvaluator>());
      });
    });

    group('evaluate', () {
      test('should return true for allowed content', () {
        expect(evaluator.evaluate('admin', 'read'), isTrue);
        expect(evaluator.evaluate('admin', 'write'), isTrue);
        expect(evaluator.evaluate('admin', 'delete'), isTrue);
        expect(evaluator.evaluate('user', 'read'), isTrue);
      });

      test('should return false for disallowed content', () {
        expect(evaluator.evaluate('admin', 'execute'), isFalse);
        expect(evaluator.evaluate('user', 'write'), isFalse);
        expect(evaluator.evaluate('user', 'delete'), isFalse);
        expect(evaluator.evaluate('guest', 'read'), isFalse);
      });

      test('should return false for non-existent role', () {
        expect(evaluator.evaluate('nonexistent', 'read'), isFalse);
        expect(evaluator.evaluate('', 'read'), isFalse);
      });

      test('should handle case-sensitive content matching', () {
        expect(evaluator.evaluate('admin', 'READ'), isFalse);
        expect(evaluator.evaluate('admin', 'Read'), isFalse);
        expect(evaluator.evaluate('admin', 'read'), isTrue);
      });

      test('should handle empty content string', () {
        expect(evaluator.evaluate('admin', ''), isFalse);
        expect(evaluator.evaluate('user', ''), isFalse);
        expect(evaluator.evaluate('guest', ''), isFalse);
      });

      test('should handle role with empty allowed content', () {
        expect(evaluator.evaluate('guest', 'read'), isFalse);
        expect(evaluator.evaluate('guest', 'write'), isFalse);
        expect(evaluator.evaluate('guest', 'any_content'), isFalse);
      });

      test('should handle duplicate content in allowed list', () {
        const duplicatePolicy = Role(
          name: 'duplicate_role',
          allowedContent: ['read', 'read', 'write'],
        );
        const duplicateEvaluator =
            RoleEvaluator({'duplicate_role': duplicatePolicy});

        expect(duplicateEvaluator.evaluate('duplicate_role', 'read'), isTrue);
        expect(duplicateEvaluator.evaluate('duplicate_role', 'write'), isTrue);
        expect(
            duplicateEvaluator.evaluate('duplicate_role', 'delete'), isFalse);
      });

      test('should handle special characters in content', () {
        const specialPolicy = Role(
          name: 'special_role',
          allowedContent: ['read@domain', 'write-file', 'delete_user'],
        );
        const specialEvaluator = RoleEvaluator({'special_role': specialPolicy});

        expect(
            specialEvaluator.evaluate('special_role', 'read@domain'), isTrue);
        expect(specialEvaluator.evaluate('special_role', 'write-file'), isTrue);
        expect(
            specialEvaluator.evaluate('special_role', 'delete_user'), isTrue);
        expect(specialEvaluator.evaluate('special_role', 'read'), isFalse);
      });

      test('should handle whitespace in content', () {
        const whitespacePolicy = Role(
          name: 'whitespace_role',
          allowedContent: ['read file', 'write document', 'delete record'],
        );
        const whitespaceEvaluator =
            RoleEvaluator({'whitespace_role': whitespacePolicy});

        expect(whitespaceEvaluator.evaluate('whitespace_role', 'read file'),
            isTrue);
        expect(
            whitespaceEvaluator.evaluate('whitespace_role', 'write document'),
            isTrue);
        expect(whitespaceEvaluator.evaluate('whitespace_role', 'delete record'),
            isTrue);
        expect(whitespaceEvaluator.evaluate('whitespace_role', 'readfile'),
            isFalse);
      });
    });

    group('Edge cases', () {
      test('should handle very long content strings', () {
        final longContent = 'a' * 10000;
        final longPolicy = Role(
          name: 'long_role',
          allowedContent: [longContent],
        );
        final longEvaluator = RoleEvaluator({'long_role': longPolicy});

        expect(longEvaluator.evaluate('long_role', longContent), isTrue);
        expect(
            longEvaluator.evaluate('long_role', 'different_content'), isFalse);
      });

      test('should handle very long role names', () {
        final longRoleName = 'a' * 1000;
        final longRolePolicy = Role(
          name: longRoleName,
          allowedContent: const ['read'],
        );
        final longRoleEvaluator = RoleEvaluator({longRoleName: longRolePolicy});

        expect(longRoleEvaluator.evaluate(longRoleName, 'read'), isTrue);
        expect(longRoleEvaluator.evaluate(longRoleName, 'write'), isFalse);
      });

      test('should handle large number of allowed content items', () {
        final largeContentList = List.generate(1000, (i) => 'content_$i');
        final largePolicy = Role(
          name: 'large_role',
          allowedContent: largeContentList,
        );
        final largeEvaluator = RoleEvaluator({'large_role': largePolicy});

        expect(largeEvaluator.evaluate('large_role', 'content_500'), isTrue);
        expect(largeEvaluator.evaluate('large_role', 'content_999'), isTrue);
        expect(largeEvaluator.evaluate('large_role', 'content_1000'), isFalse);
        expect(largeEvaluator.evaluate('large_role', 'nonexistent'), isFalse);
      });

      test('should handle unicode characters in content', () {
        const unicodePolicy = Role(
          name: 'unicode_role',
          allowedContent: ['café', 'naïve', 'résumé', 'über'],
        );
        const unicodeEvaluator = RoleEvaluator({'unicode_role': unicodePolicy});

        expect(unicodeEvaluator.evaluate('unicode_role', 'café'), isTrue);
        expect(unicodeEvaluator.evaluate('unicode_role', 'naïve'), isTrue);
        expect(unicodeEvaluator.evaluate('unicode_role', 'résumé'), isTrue);
        expect(unicodeEvaluator.evaluate('unicode_role', 'über'), isTrue);
        expect(unicodeEvaluator.evaluate('unicode_role', 'cafe'), isFalse);
      });

      test('should handle numbers as content', () {
        const numberPolicy = Role(
          name: 'number_role',
          allowedContent: ['123', '456', '789'],
        );
        const numberEvaluator = RoleEvaluator({'number_role': numberPolicy});

        expect(numberEvaluator.evaluate('number_role', '123'), isTrue);
        expect(numberEvaluator.evaluate('number_role', '456'), isTrue);
        expect(numberEvaluator.evaluate('number_role', '789'), isTrue);
        expect(numberEvaluator.evaluate('number_role', '999'), isFalse);
      });

      test('should handle mixed content types', () {
        const mixedPolicy = Role(
          name: 'mixed_role',
          allowedContent: ['read', '123', 'café', 'read@domain', ''],
        );
        const mixedEvaluator = RoleEvaluator({'mixed_role': mixedPolicy});

        expect(mixedEvaluator.evaluate('mixed_role', 'read'), isTrue);
        expect(mixedEvaluator.evaluate('mixed_role', '123'), isTrue);
        expect(mixedEvaluator.evaluate('mixed_role', 'café'), isTrue);
        expect(mixedEvaluator.evaluate('mixed_role', 'read@domain'), isTrue);
        expect(mixedEvaluator.evaluate('mixed_role', ''), isTrue);
        expect(mixedEvaluator.evaluate('mixed_role', 'write'), isFalse);
      });
    });

    group('Performance tests', () {
      test('should handle rapid evaluation calls', () {
        const iterations = 10000;
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < iterations; i++) {
          evaluator.evaluate('admin', 'read');
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds,
            lessThan(1000)); // Should complete within 1 second
      });

      test('should handle evaluation with large policy set', () {
        final largePolicies = <String, Role>{};
        for (int i = 0; i < 1000; i++) {
          largePolicies['role_$i'] = Role(
            name: 'role_$i',
            allowedContent: const ['read', 'write'],
          );
        }
        final largeEvaluator = RoleEvaluator(largePolicies);

        const iterations = 1000;
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < iterations; i++) {
          largeEvaluator.evaluate('role_500', 'read');
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds,
            lessThan(1000)); // Should complete within 1 second
      });
    });

    group('Integration scenarios', () {
      test('should handle typical RBAC scenario', () {
        final rbacPolicies = {
          'super_admin': const Role(
            name: 'super_admin',
            allowedContent: [
              'read',
              'write',
              'delete',
              'execute',
              'manage_users'
            ],
          ),
          'admin': const Role(
            name: 'admin',
            allowedContent: ['read', 'write', 'delete'],
          ),
          'moderator': const Role(
            name: 'moderator',
            allowedContent: ['read', 'write'],
          ),
          'user': const Role(
            name: 'user',
            allowedContent: ['read'],
          ),
          'guest': const Role(
            name: 'guest',
            allowedContent: [],
          ),
        };
        final rbacEvaluator = RoleEvaluator(rbacPolicies);

        // Test super_admin permissions
        expect(rbacEvaluator.evaluate('super_admin', 'read'), isTrue);
        expect(rbacEvaluator.evaluate('super_admin', 'manage_users'), isTrue);

        // Test admin permissions
        expect(rbacEvaluator.evaluate('admin', 'read'), isTrue);
        expect(rbacEvaluator.evaluate('admin', 'delete'), isTrue);
        expect(rbacEvaluator.evaluate('admin', 'manage_users'), isFalse);

        // Test user permissions
        expect(rbacEvaluator.evaluate('user', 'read'), isTrue);
        expect(rbacEvaluator.evaluate('user', 'write'), isFalse);

        // Test guest permissions
        expect(rbacEvaluator.evaluate('guest', 'read'), isFalse);
        expect(rbacEvaluator.evaluate('guest', 'write'), isFalse);
      });

      test('should handle file system permissions scenario', () {
        final filePolicies = {
          'root': const Role(
            name: 'root',
            allowedContent: [
              'read',
              'write',
              'delete',
              'execute',
              'chmod',
              'chown'
            ],
          ),
          'owner': const Role(
            name: 'owner',
            allowedContent: ['read', 'write', 'delete', 'chmod'],
          ),
          'group': const Role(
            name: 'group',
            allowedContent: ['read', 'write'],
          ),
          'other': const Role(
            name: 'other',
            allowedContent: ['read'],
          ),
        };
        final fileEvaluator = RoleEvaluator(filePolicies);

        // Test root permissions
        expect(fileEvaluator.evaluate('root', 'chown'), isTrue);
        expect(fileEvaluator.evaluate('root', 'execute'), isTrue);

        // Test owner permissions
        expect(fileEvaluator.evaluate('owner', 'chmod'), isTrue);
        expect(fileEvaluator.evaluate('owner', 'chown'), isFalse);

        // Test group permissions
        expect(fileEvaluator.evaluate('group', 'write'), isTrue);
        expect(fileEvaluator.evaluate('group', 'delete'), isFalse);

        // Test other permissions
        expect(fileEvaluator.evaluate('other', 'read'), isTrue);
        expect(fileEvaluator.evaluate('other', 'write'), isFalse);
      });
    });

    group('Error handling', () {
      test('should handle null role name gracefully', () {
        expect(() => evaluator.evaluate('', 'read'), returnsNormally);
        expect(evaluator.evaluate('', 'read'), isFalse);
      });

      test('should handle null content gracefully', () {
        expect(() => evaluator.evaluate('admin', ''), returnsNormally);
        expect(evaluator.evaluate('admin', ''), isFalse);
      });

      test('should handle evaluation with empty policies', () {
        const emptyEvaluator = RoleEvaluator({});
        expect(emptyEvaluator.evaluate('any_role', 'any_content'), isFalse);
      });
    });
  });
}
