import 'package:flutter_policy_engine/src/domain/value_objects/role_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoleName', () {
    test('creates from non-empty string', () {
      final name = RoleName('admin');
      expect(name.value, equals('admin'));
    });

    test('trims whitespace', () {
      final name = RoleName('  admin  ');
      expect(name.value, equals('admin'));
    });

    test('throws on empty string', () {
      expect(() => RoleName(''), throwsArgumentError);
    });

    test('throws on whitespace-only string', () {
      expect(() => RoleName('   '), throwsArgumentError);
    });

    test('equality by value', () {
      expect(RoleName('admin'), equals(RoleName('admin')));
      expect(RoleName('admin'), isNot(equals(RoleName('user'))));
    });

    test('hashCode consistent with equality', () {
      expect(RoleName('admin').hashCode, equals(RoleName('admin').hashCode));
    });

    test('toString returns value', () {
      expect(RoleName('admin').toString(), equals('admin'));
    });

    test('allows unicode role names', () {
      final name = RoleName('管理者');
      expect(name.value, equals('管理者'));
    });
  });
}
