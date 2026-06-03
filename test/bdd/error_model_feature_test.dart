// BDD feature tests for spec-008-error-model.md

import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bdd.dart';

void main() {
  group('Feature: Error Model (spec-008)', () {
    group('Scenario: Result.Ok carries value', () {
      test(
          'Given Ok(42), '
          'When accessing value, Then 42 is returned', () {
        given('Ok(42)').when(
          'accessing value',
          () => const Ok<int, DomainFailure>(42),
        ).then('value is 42', (result) {
          expect(result.isOk, isTrue);
          expect(result.getOrElse(0), equals(42));
        });
      });
    });

    group('Scenario: Result.Err carries failure', () {
      test(
          'Given Err with PolicyNotFoundFailure, '
          'When inspecting, Then isErr is true and failure matches', () {
        given('Err(PolicyNotFoundFailure)').when(
          'creating error result',
          () => const Err<int, DomainFailure>(
            PolicyNotFoundFailure('test failure'),
          ),
        ).then('isErr is true and error type matches', (result) {
          expect(result.isErr, isTrue);
          expect((result as Err).error, isA<PolicyNotFoundFailure>());
        });
      });
    });

    group('Scenario: getOrElse fallback behavior', () {
      test(
          'Given Err result, '
          'When calling getOrElse(99), Then 99 is returned', () {
        given('Err result').when(
          'calling getOrElse with fallback',
          () => const Err<int, DomainFailure>(PolicyNotFoundFailure('x'))
              .getOrElse(99),
        ).then('fallback 99 is returned', (value) {
          expect(value, equals(99));
        });
      });
    });

    group('Scenario: DomainFailure sealed exhaustive match', () {
      test(
          'Given every DomainFailure subtype, '
          'When matched exhaustively, Then all cases are covered', () {
        final failures = <DomainFailure>[
          const PolicyNotFoundFailure('not found'),
          const ResourceNotAllowedFailure(roleName: 'r', resourceId: 'x'),
          const InvalidPolicyFailure('invalid'),
          const ParseFailure('parse'),
          const StorageFailure('storage'),
          const EngineNotInitializedFailure(),
          const MissingAttributeFailure(attributeKey: 'k', target: 'subject'),
        ];

        for (final failure in failures) {
          given('a ${failure.runtimeType}').when(
            'matching exhaustively',
            () => switch (failure) {
              PolicyNotFoundFailure() => 'not_found',
              ResourceNotAllowedFailure() => 'resource_not_allowed',
              InvalidPolicyFailure() => 'invalid',
              ParseFailure() => 'parse',
              StorageFailure() => 'storage',
              EngineNotInitializedFailure() => 'not_initialized',
              MissingAttributeFailure() => 'missing_attribute',
            },
          ).then('a non-empty label is returned', (label) {
            expect(label, isNotEmpty);
          });
        }
      });
    });

    group('Scenario: EngineNotInitializedFailure message', () {
      test(
          'Given EngineNotInitializedFailure, '
          'When reading message, Then it is descriptive', () {
        given('EngineNotInitializedFailure').when(
          'reading message',
          () => const EngineNotInitializedFailure(),
        ).then('message is non-empty', (failure) {
          expect(failure.message, isNotEmpty);
        });
      });
    });
  });
}
