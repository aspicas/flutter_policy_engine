// BDD feature tests for spec-002-abac-evaluation.md

import 'package:flutter_policy_engine/src/domain/entities/abac_policy.dart';
import 'package:flutter_policy_engine/src/domain/entities/resource.dart';
import 'package:flutter_policy_engine/src/domain/entities/subject.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/services/abac_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bdd.dart';

void main() {
  const evaluator = AbacEvaluator();

  group('Feature: ABAC Evaluation (spec-002)', () {
    group('Scenario: region-based access control', () {
      test(
          'Given EU subject and EU resource, '
          'When region rule is applied, Then access is granted', () {
        const policy = AbacPolicy(
          rules: [
            AttributeRule(
              subjectAttribute: 'region',
              resourceAttribute: 'region',
            ),
          ],
        );

        given('EU subject and EU resource')
            .when(
          'evaluating region rule',
          () => evaluator.evaluate(
            const Subject(attributes: {'region': 'eu'}),
            Resource(id: 'report-eu', attributes: const {'region': 'eu'}),
            policy,
          ),
        )
            .then('access is granted', (decision) {
          expect(decision.isGranted, isTrue);
        });
      });

      test(
          'Given EU subject and US resource, '
          'When region rule is applied, Then access is denied', () {
        const policy = AbacPolicy(
          rules: [
            AttributeRule(
              subjectAttribute: 'region',
              resourceAttribute: 'region',
            ),
          ],
        );

        given('EU subject and US resource')
            .when(
          'evaluating region rule',
          () => evaluator.evaluate(
            const Subject(attributes: {'region': 'eu'}),
            Resource(id: 'report-us', attributes: const {'region': 'us'}),
            policy,
          ),
        )
            .then('access is denied', (decision) {
          expect(decision.isDenied, isTrue);
        });
      });
    });

    group('Scenario: open policy (no rules)', () {
      test(
          'Given any subject and any resource, '
          'When policy has zero rules, Then access is always granted', () {
        const openPolicy = AbacPolicy(rules: []);

        given('open policy with zero rules')
            .when(
          'evaluating any access',
          () => evaluator.evaluate(
            const Subject(attributes: {}),
            Resource(id: 'anything'),
            openPolicy,
          ),
        )
            .then('access is granted (open policy)', (decision) {
          expect(decision.isGranted, isTrue);
        });
      });
    });

    group('Scenario: missing subject attribute', () {
      test(
          'Given subject without required attribute, '
          'When rule requires it, Then MissingAttributeFailure is returned',
          () {
        const policy = AbacPolicy(
          rules: [AttributeRule(subjectAttribute: 'department')],
        );

        given('subject without department attribute')
            .when(
          'evaluating department rule',
          () => evaluator.evaluate(
            const Subject(attributes: {'role': 'user'}),
            Resource(id: 'hr-report'),
            policy,
          ),
        )
            .then('MissingAttributeFailure on subject', (decision) {
          expect(decision.failure, isA<MissingAttributeFailure>());
          final failure = decision.failure! as MissingAttributeFailure;
          expect(failure.target, equals('subject'));
        });
      });
    });

    group('Scenario: premium role gate', () {
      test(
          'Given premium subject, '
          'When role=premium rule is present, Then access is granted', () {
        const policy = AbacPolicy(
          rules: [
            AttributeRule(
              subjectAttribute: 'subscription',
              expectedValue: 'premium',
            ),
          ],
        );

        given('subject with subscription=premium')
            .when(
          'evaluating premium gate',
          () => evaluator.evaluate(
            const Subject(attributes: {'subscription': 'premium'}),
            Resource(id: 'premium-content'),
            policy,
          ),
        )
            .then('access is granted', (decision) {
          expect(decision.isGranted, isTrue);
        });
      });

      test(
          'Given basic subject, '
          'When role=premium rule is present, Then access is denied', () {
        const policy = AbacPolicy(
          rules: [
            AttributeRule(
              subjectAttribute: 'subscription',
              expectedValue: 'premium',
            ),
          ],
        );

        given('subject with subscription=basic')
            .when(
          'evaluating premium gate',
          () => evaluator.evaluate(
            const Subject(attributes: {'subscription': 'basic'}),
            Resource(id: 'premium-content'),
            policy,
          ),
        )
            .then('access is denied', (decision) {
          expect(decision.isDenied, isTrue);
        });
      });
    });
  });
}
