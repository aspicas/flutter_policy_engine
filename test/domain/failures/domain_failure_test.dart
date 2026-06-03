import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DomainFailure', () {
    group('PolicyNotFoundFailure', () {
      test('carries message', () {
        const failure = PolicyNotFoundFailure('role "ghost" not found');
        expect(failure.message, equals('role "ghost" not found'));
      });

      test('toString includes message', () {
        const failure = PolicyNotFoundFailure('not found');
        expect(failure.toString(), contains('not found'));
      });

      test('sealed switch is exhaustive', () {
        const DomainFailure failure = PolicyNotFoundFailure('test');
        final label = switch (failure) {
          PolicyNotFoundFailure() => 'not_found',
          ResourceNotAllowedFailure() => 'resource_not_allowed',
          InvalidPolicyFailure() => 'invalid',
          ParseFailure() => 'parse',
          StorageFailure() => 'storage',
          EngineNotInitializedFailure() => 'not_initialized',
          MissingAttributeFailure() => 'missing_attribute',
        };
        expect(label, equals('not_found'));
      });
    });

    group('ResourceNotAllowedFailure', () {
      test('carries role name and resource id', () {
        const failure = ResourceNotAllowedFailure(
          roleName: 'user',
          resourceId: 'settings',
        );
        expect(failure.roleName, equals('user'));
        expect(failure.resourceId, equals('settings'));
      });
    });

    group('InvalidPolicyFailure', () {
      test('carries message', () {
        const failure = InvalidPolicyFailure('name cannot be empty');
        expect(failure.message, contains('empty'));
      });
    });

    group('ParseFailure', () {
      test('carries message and optional cause', () {
        const failure = ParseFailure('bad JSON');
        expect(failure.message, equals('bad JSON'));
        expect(failure.cause, isNull);
      });

      test('can carry a cause', () {
        final cause = Exception('original');
        final failure = ParseFailure('bad JSON', cause: cause);
        expect(failure.cause, isNotNull);
      });
    });

    group('StorageFailure', () {
      test('carries message', () {
        const failure = StorageFailure('write failed');
        expect(failure.message, isNotEmpty);
      });
    });

    group('EngineNotInitializedFailure', () {
      test('has fixed message', () {
        const failure = EngineNotInitializedFailure();
        expect(failure.message, isNotEmpty);
      });
    });

    group('MissingAttributeFailure', () {
      test('carries attribute key and target', () {
        const failure = MissingAttributeFailure(
          attributeKey: 'region',
          target: 'subject',
        );
        expect(failure.attributeKey, equals('region'));
        expect(failure.target, equals('subject'));
      });
    });
  });

  group('Result', () {
    test('Ok holds value', () {
      const result = Ok<int, DomainFailure>(42);
      expect(result.value, equals(42));
      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
    });

    test('Err holds failure', () {
      const result = Err<int, DomainFailure>(
        PolicyNotFoundFailure('not found'),
      );
      expect(result.error, isA<PolicyNotFoundFailure>());
      expect(result.isOk, isFalse);
      expect(result.isErr, isTrue);
    });

    test('getOrElse returns value on Ok', () {
      const result = Ok<int, DomainFailure>(10);
      expect(result.getOrElse(0), equals(10));
    });

    test('getOrElse returns fallback on Err', () {
      const result = Err<int, DomainFailure>(PolicyNotFoundFailure('x'));
      expect(result.getOrElse(99), equals(99));
    });

    test('mapOk transforms value on Ok', () {
      const result = Ok<int, DomainFailure>(5);
      final mapped = result.mapOk((v) => v * 2);
      expect(mapped.getOrElse(0), equals(10));
    });

    test('mapOk is identity on Err', () {
      const result = Err<int, DomainFailure>(PolicyNotFoundFailure('x'));
      final mapped = result.mapOk((v) => v * 2);
      expect(mapped.isErr, isTrue);
    });
  });
}
