import 'package:flutter_policy_engine/src/domain/entities/access_decision.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccessDecision', () {
    test('granted decision is granted', () {
      const decision = AccessDecision.granted();
      expect(decision.isGranted, isTrue);
      expect(decision.isDenied, isFalse);
      expect(decision.failure, isNull);
    });

    test('denied decision is denied', () {
      const denied = AccessDecision.denied(
        PolicyNotFoundFailure('role not found'),
      );
      expect(denied.isGranted, isFalse);
      expect(denied.isDenied, isTrue);
      expect(denied.failure, isA<PolicyNotFoundFailure>());
    });

    test('denied carries failure message', () {
      const denied = AccessDecision.denied(
        ResourceNotAllowedFailure(roleName: 'user', resourceId: 'admin_panel'),
      );
      expect(denied.failure!.message, isNotEmpty);
    });

    test('equality — two granted decisions are equal', () {
      const a = AccessDecision.granted();
      const b = AccessDecision.granted();
      expect(a, equals(b));
    });

    test('equality — granted != denied', () {
      const granted = AccessDecision.granted();
      const denied = AccessDecision.denied(PolicyNotFoundFailure('x'));
      expect(granted, isNot(equals(denied)));
    });

    test('toString indicates grant/deny status', () {
      expect(
        const AccessDecision.granted().toString(),
        contains('granted'),
      );
      expect(
        const AccessDecision.denied(PolicyNotFoundFailure('x')).toString(),
        contains('denied'),
      );
    });
  });
}
