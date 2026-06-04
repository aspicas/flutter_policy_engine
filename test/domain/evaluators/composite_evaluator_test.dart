import 'package:flutter_policy_engine/src/domain/entities/access_decision.dart';
import 'package:flutter_policy_engine/src/domain/entities/policy.dart';
import 'package:flutter_policy_engine/src/domain/entities/role_entity.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/services/composite_evaluator.dart';
import 'package:flutter_policy_engine/src/domain/services/policy_evaluator.dart';
import 'package:flutter_policy_engine/src/domain/value_objects/role_name.dart';
import 'package:flutter_test/flutter_test.dart';

/// A test evaluator that always grants.
final class _AlwaysGrantEvaluator implements PolicyEvaluator {
  const _AlwaysGrantEvaluator();

  @override
  AccessDecision evaluate(
    String roleName,
    String resourceId,
    Policy policy,
  ) =>
      const AccessDecision.granted();
}

/// A test evaluator that always denies.
final class _AlwaysDenyEvaluator implements PolicyEvaluator {
  const _AlwaysDenyEvaluator();

  @override
  AccessDecision evaluate(
    String roleName,
    String resourceId,
    Policy policy,
  ) =>
      const AccessDecision.denied(PolicyNotFoundFailure('always deny'));
}

Policy _buildPolicy() => Policy(
      roles: {
        'admin': RoleEntity(
          name: RoleName('admin'),
          allowedResources: const {'dashboard'},
        ),
      },
    );

void main() {
  group('CompositeEvaluator — denyOverrides', () {
    test('grants when all evaluators grant', () {
      final composite = CompositeEvaluator(
        evaluators: const [
          _AlwaysGrantEvaluator(),
          _AlwaysGrantEvaluator(),
        ],
        strategy: CompositeStrategy.denyOverrides,
      );
      final decision = composite.evaluate('admin', 'dashboard', _buildPolicy());
      expect(decision.isGranted, isTrue);
    });

    test('denies when any evaluator denies', () {
      final composite = CompositeEvaluator(
        evaluators: const [
          _AlwaysGrantEvaluator(),
          _AlwaysDenyEvaluator(),
        ],
        strategy: CompositeStrategy.denyOverrides,
      );
      final decision = composite.evaluate('admin', 'dashboard', _buildPolicy());
      expect(decision.isDenied, isTrue);
    });
  });

  group('CompositeEvaluator — allowOverrides', () {
    test('grants when any evaluator grants', () {
      final composite = CompositeEvaluator(
        evaluators: const [
          _AlwaysDenyEvaluator(),
          _AlwaysGrantEvaluator(),
        ],
        strategy: CompositeStrategy.allowOverrides,
      );
      final decision = composite.evaluate('admin', 'dashboard', _buildPolicy());
      expect(decision.isGranted, isTrue);
    });

    test('denies when all evaluators deny', () {
      final composite = CompositeEvaluator(
        evaluators: const [
          _AlwaysDenyEvaluator(),
          _AlwaysDenyEvaluator(),
        ],
        strategy: CompositeStrategy.allowOverrides,
      );
      final decision = composite.evaluate('admin', 'dashboard', _buildPolicy());
      expect(decision.isDenied, isTrue);
    });
  });

  group('CompositeEvaluator — edge cases', () {
    test('empty evaluators list denies (safe default)', () {
      final composite = CompositeEvaluator(
        evaluators: const [],
        strategy: CompositeStrategy.denyOverrides,
      );
      final decision = composite.evaluate('admin', 'dashboard', _buildPolicy());
      expect(decision.isDenied, isTrue);
    });

    test('single evaluator works correctly', () {
      final composite = CompositeEvaluator(
        evaluators: const [_AlwaysGrantEvaluator()],
        strategy: CompositeStrategy.denyOverrides,
      );
      final decision = composite.evaluate('admin', 'dashboard', _buildPolicy());
      expect(decision.isGranted, isTrue);
    });
  });
}
