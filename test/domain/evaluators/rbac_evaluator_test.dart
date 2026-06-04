import 'package:flutter_policy_engine/src/domain/entities/policy.dart';
import 'package:flutter_policy_engine/src/domain/entities/role_entity.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/services/rbac_evaluator.dart';
import 'package:flutter_policy_engine/src/domain/value_objects/role_name.dart';
import 'package:flutter_test/flutter_test.dart';

Policy _buildPolicy() => Policy(
      roles: {
        'admin': RoleEntity(
          name: RoleName('admin'),
          allowedResources: const {'dashboard', 'users', 'settings'},
        ),
        'user': RoleEntity(
          name: RoleName('user'),
          allowedResources: const {'dashboard'},
        ),
        'guest': RoleEntity(
          name: RoleName('guest'),
          allowedResources: const {},
        ),
      },
    );

void main() {
  late RbacEvaluator evaluator;

  setUp(() {
    evaluator = const RbacEvaluator();
  });

  group('RbacEvaluator — granted', () {
    test('grants access when role has the resource', () {
      final decision = evaluator.evaluate('admin', 'dashboard', _buildPolicy());
      expect(decision.isGranted, isTrue);
    });

    test('grants access for another resource in the same role', () {
      final decision = evaluator.evaluate('admin', 'settings', _buildPolicy());
      expect(decision.isGranted, isTrue);
    });

    test('grants access for user role', () {
      final decision = evaluator.evaluate('user', 'dashboard', _buildPolicy());
      expect(decision.isGranted, isTrue);
    });
  });

  group('RbacEvaluator — denied', () {
    test('denies when role lacks resource', () {
      final decision = evaluator.evaluate('user', 'settings', _buildPolicy());
      expect(decision.isDenied, isTrue);
      expect(decision.failure, isA<ResourceNotAllowedFailure>());
    });

    test('denies when role has empty allowed list', () {
      final decision = evaluator.evaluate('guest', 'dashboard', _buildPolicy());
      expect(decision.isDenied, isTrue);
      expect(decision.failure, isA<ResourceNotAllowedFailure>());
    });

    test('denies with PolicyNotFoundFailure for unknown role', () {
      final decision = evaluator.evaluate('ghost', 'anything', _buildPolicy());
      expect(decision.isDenied, isTrue);
      expect(decision.failure, isA<PolicyNotFoundFailure>());
    });
  });

  group('RbacEvaluator — edge cases', () {
    test('empty roleName returns InvalidPolicyFailure', () {
      final decision = evaluator.evaluate('', 'dashboard', _buildPolicy());
      expect(decision.failure, isA<InvalidPolicyFailure>());
    });

    test('empty resourceId returns InvalidPolicyFailure', () {
      final decision = evaluator.evaluate('admin', '', _buildPolicy());
      expect(decision.failure, isA<InvalidPolicyFailure>());
    });

    test('matching is case-sensitive', () {
      final decision = evaluator.evaluate('admin', 'Dashboard', _buildPolicy());
      expect(decision.isDenied, isTrue);
    });

    test('evaluates correctly against empty policy', () {
      final decision =
          evaluator.evaluate('admin', 'dashboard', const Policy(roles: {}));
      expect(decision.failure, isA<PolicyNotFoundFailure>());
    });
  });

  group('RbacEvaluator — ResourceNotAllowedFailure context', () {
    test('failure carries role name and resource id', () {
      final decision =
          evaluator.evaluate('user', 'admin_panel', _buildPolicy());
      final failure = decision.failure! as ResourceNotAllowedFailure;
      expect(failure.roleName, equals('user'));
      expect(failure.resourceId, equals('admin_panel'));
    });
  });
}
