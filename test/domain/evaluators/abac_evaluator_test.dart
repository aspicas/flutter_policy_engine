import 'package:flutter_policy_engine/src/domain/entities/abac_policy.dart';
import 'package:flutter_policy_engine/src/domain/entities/resource.dart';
import 'package:flutter_policy_engine/src/domain/entities/subject.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/services/abac_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AbacEvaluator evaluator;

  setUp(() {
    evaluator = const AbacEvaluator();
  });

  group('AbacEvaluator — granted', () {
    test('grants when all rules satisfied', () {
      const subject = Subject(attributes: {'role': 'admin', 'region': 'eu'});
      final resource =
          Resource(id: 'report-eu', attributes: const {'region': 'eu'});
      const abacPolicy = AbacPolicy(
        rules: [
          AttributeRule(
            subjectAttribute: 'region',
            resourceAttribute: 'region',
          ),
        ],
      );
      final decision = evaluator.evaluate(subject, resource, abacPolicy);
      expect(decision.isGranted, isTrue);
    });

    test('grants with zero rules (open policy)', () {
      final decision = evaluator.evaluate(
        const Subject(attributes: {}),
        Resource(id: 'anything'),
        const AbacPolicy(rules: []),
      );
      expect(decision.isGranted, isTrue);
    });

    test('grants when subject attribute matches expected value', () {
      const subject = Subject(attributes: {'role': 'premium'});
      const policy = AbacPolicy(
        rules: [
          AttributeRule(
            subjectAttribute: 'role',
            expectedValue: 'premium',
          ),
        ],
      );
      final decision = evaluator.evaluate(
        subject,
        Resource(id: 'feature'),
        policy,
      );
      expect(decision.isGranted, isTrue);
    });
  });

  group('AbacEvaluator — denied', () {
    test('denies when subject attribute does not match expected value', () {
      const subject = Subject(attributes: {'role': 'basic'});
      const policy = AbacPolicy(
        rules: [
          AttributeRule(
            subjectAttribute: 'role',
            expectedValue: 'premium',
          ),
        ],
      );
      final decision = evaluator.evaluate(
        subject,
        Resource(id: 'feature'),
        policy,
      );
      expect(decision.isDenied, isTrue);
      expect(decision.failure, isA<MissingAttributeFailure>());
    });

    test('denies when subject is missing required attribute', () {
      const subject = Subject(attributes: {'country': 'es'});
      const policy = AbacPolicy(
        rules: [
          AttributeRule(subjectAttribute: 'region'),
        ],
      );
      final decision = evaluator.evaluate(
        subject,
        Resource(id: 'x'),
        policy,
      );
      expect(decision.failure, isA<MissingAttributeFailure>());
    });

    test('denies when resource attribute does not match subject', () {
      const subject = Subject(attributes: {'region': 'eu'});
      final resource =
          Resource(id: 'report-us', attributes: const {'region': 'us'});
      const policy = AbacPolicy(
        rules: [
          AttributeRule(
            subjectAttribute: 'region',
            resourceAttribute: 'region',
          ),
        ],
      );
      final decision = evaluator.evaluate(subject, resource, policy);
      expect(decision.isDenied, isTrue);
    });

    test('denies on first failing rule (short-circuit)', () {
      const subject = Subject(attributes: {'role': 'admin', 'region': 'us'});
      final resource =
          Resource(id: 'report-eu', attributes: const {'region': 'eu'});
      const policy = AbacPolicy(
        rules: [
          AttributeRule(
            subjectAttribute: 'role',
            expectedValue: 'admin',
          ),
          AttributeRule(
            subjectAttribute: 'region',
            resourceAttribute: 'region',
          ),
        ],
      );
      final decision = evaluator.evaluate(subject, resource, policy);
      expect(decision.isDenied, isTrue);
    });
  });

  group('AbacEvaluator — MissingAttributeFailure context', () {
    test('failure carries attribute key and target', () {
      const subject = Subject(attributes: {});
      const policy = AbacPolicy(
        rules: [AttributeRule(subjectAttribute: 'role')],
      );
      final decision = evaluator.evaluate(
        subject,
        Resource(id: 'x'),
        policy,
      );
      final failure = decision.failure! as MissingAttributeFailure;
      expect(failure.attributeKey, equals('role'));
      expect(failure.target, equals('subject'));
    });
  });
}
