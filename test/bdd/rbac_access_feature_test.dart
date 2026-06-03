// BDD feature tests for spec-001-rbac-evaluation.md

import 'package:flutter_policy_engine/src/domain/entities/policy.dart';
import 'package:flutter_policy_engine/src/domain/entities/role_entity.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/services/rbac_evaluator.dart';
import 'package:flutter_policy_engine/src/domain/value_objects/role_name.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bdd.dart';

Policy _buildPolicy() => Policy(
      roles: {
        'admin': RoleEntity(
          name: RoleName('admin'),
          allowedResources: const {'dashboard', 'users', 'settings', 'reports'},
        ),
        'manager': RoleEntity(
          name: RoleName('manager'),
          allowedResources: const {'dashboard', 'users', 'reports'},
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
  const evaluator = RbacEvaluator();
  final policy = _buildPolicy();

  group('Feature: RBAC Evaluation (spec-001)', () {
    group('Scenario: admin accesses allowed resource', () {
      test('Given admin role, When accessing dashboard, Then access is granted',
          () {
        given('admin role with dashboard in allowed resources')
            .when(
          'evaluating access to dashboard',
          () => evaluator.evaluate('admin', 'dashboard', policy),
        )
            .then('access is granted', (decision) {
          expect(decision.isGranted, isTrue);
        });
      });
    });

    group('Scenario: user accesses denied resource', () {
      test(
          'Given user role without settings, '
          'When accessing settings, Then access is denied', () {
        given('user role with only dashboard')
            .when(
          'evaluating access to settings',
          () => evaluator.evaluate('user', 'settings', policy),
        )
            .then('access is denied with ResourceNotAllowedFailure',
                (decision) {
          expect(decision.isDenied, isTrue);
          expect(decision.failure, isA<ResourceNotAllowedFailure>());
        });
      });
    });

    group('Scenario: unknown role is evaluated', () {
      test(
          'Given a non-existent role, '
          'When evaluating access, Then PolicyNotFoundFailure is returned', () {
        given('unknown role ghost')
            .when(
          'evaluating access to anything',
          () => evaluator.evaluate('ghost', 'dashboard', policy),
        )
            .then('PolicyNotFoundFailure is the failure', (decision) {
          expect(decision.failure, isA<PolicyNotFoundFailure>());
        });
      });
    });

    group('Scenario: guest role has no permissions', () {
      test(
          'Given guest role with empty allowed list, '
          'When accessing any resource, Then access is denied', () {
        for (final resource in ['dashboard', 'users', 'settings']) {
          given('guest role with empty allowedResources')
              .when(
            'evaluating access to $resource',
            () => evaluator.evaluate('guest', resource, policy),
          )
              .then('access is denied', (decision) {
            expect(decision.isDenied, isTrue,
                reason: '$resource should be denied for guest',);
          });
        }
      });
    });

    group('Scenario: empty inputs are rejected', () {
      test('Given empty roleName, Then InvalidPolicyFailure is returned', () {
        given('empty role name')
            .when(
          'evaluating',
          () => evaluator.evaluate('', 'dashboard', policy),
        )
            .then('InvalidPolicyFailure', (decision) {
          expect(decision.failure, isA<InvalidPolicyFailure>());
        });
      });

      test('Given empty resourceId, Then InvalidPolicyFailure is returned', () {
        given('empty resource id')
            .when(
          'evaluating',
          () => evaluator.evaluate('admin', '', policy),
        )
            .then('InvalidPolicyFailure', (decision) {
          expect(decision.failure, isA<InvalidPolicyFailure>());
        });
      });
    });

    group('Scenario: case sensitivity', () {
      test(
          'Given resource "Dashboard" (capital D), '
          'When role only has "dashboard", Then access is denied', () {
        given('role admin with lowercase dashboard')
            .when(
          'evaluating access to Dashboard (capital D)',
          () => evaluator.evaluate('admin', 'Dashboard', policy),
        )
            .then('access is denied — case-sensitive match', (decision) {
          expect(decision.isDenied, isTrue);
        });
      });
    });
  });
}
