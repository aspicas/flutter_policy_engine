// Smoke test: verifies the public barrel exports the expected symbols.
// This prevents accidental removal of exported types from the public API.

import 'package:flutter_policy_engine/flutter_policy_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Public barrel exports', () {
    test('PolicyManager is exported', () {
      expect(PolicyManager.new, isA<Function>());
    });

    test('PolicyProvider is exported', () {
      expect(PolicyProvider.new, isA<Function>());
    });

    test('PolicyWidget is exported', () {
      expect(PolicyWidget.new, isA<Function>());
    });

    test('Role is exported', () {
      expect(Role.new, isA<Function>());
    });

    test('PolicySDKException is exported', () {
      expect(PolicySDKException.new, isA<Function>());
    });

    test('Role can be instantiated with required fields', () {
      const role = Role(name: 'admin', allowedContent: ['dashboard']);
      expect(role.name, equals('admin'));
      expect(role.allowedContent, contains('dashboard'));
    });
  });
}
