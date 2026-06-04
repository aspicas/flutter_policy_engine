// Smoke test: verifies the public barrel exports the expected v2 symbols.
// Prevents accidental removal of exported types from the public API.

import 'package:flutter_policy_engine/flutter_policy_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Public barrel exports (v2)', () {
    test('PolicyEngine is exported', () {
      expect(PolicyEngine.withRepository, isA<Function>());
    });

    test('PolicyEngineController is exported', () {
      expect(PolicyEngineController.inMemory, isA<Function>());
    });

    test('PolicyEngineScope is exported', () {
      expect(PolicyEngineScope.new, isA<Function>());
    });

    test('PolicyGate is exported', () {
      expect(PolicyGate.new, isA<Function>());
    });

    test('PolicyBuilder is exported', () {
      expect(PolicyBuilder.new, isA<Function>());
    });

    test('InMemoryPolicyRepository is exported', () {
      expect(InMemoryPolicyRepository.new, isA<Function>());
    });

    test('NoopLogger is exported', () {
      expect(NoopLogger.new, isA<Function>());
    });

    test('ConsoleLogger is exported', () {
      expect(ConsoleLogger.new, isA<Function>());
    });

    test('DomainFailure subtypes are exported', () {
      expect(
        const PolicyNotFoundFailure('role not found'),
        isA<DomainFailure>(),
      );
    });

    test('RoleEntity can be instantiated', () {
      final role = RoleEntity(
        name: RoleName('admin'),
        allowedResources: const {'dashboard'},
      );
      expect(role.name.value, 'admin');
      expect(role.isResourceAllowed('dashboard'), isTrue);
    });

    test('Policy aggregate root is exported', () {
      const policy = Policy(roles: {});
      expect(policy.isEmpty, isTrue);
    });
  });
}
