import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_policy_engine/src/exceptions/i_policy_sdk_exceptions.dart';
import 'package:flutter_policy_engine/src/exceptions/json_parse_exception.dart';
import 'package:flutter_policy_engine/src/exceptions/json_serialize_exception.dart';
import 'package:flutter_policy_engine/src/exceptions/policy_not_initialized_exception.dart';

void main() {
  group('Exceptions Integration Tests', () {
    test('all exceptions should implement IPolicySDKException', () {
      final exceptions = [
        const PolicyNotInitializedException('Test message'),
        JsonParseException('Test message'),
        JsonSerializeException('Test message'),
      ];

      for (final exception in exceptions) {
        expect(exception, isA<IPolicySDKException>());
        expect(exception, isA<Exception>());
      }
    });

    test('detail exceptions should implement IDetailPolicySDKException', () {
      final detailExceptions = [
        JsonParseException('Test message'),
        JsonSerializeException('Test message'),
      ];

      for (final exception in detailExceptions) {
        expect(exception, isA<IDetailPolicySDKException>());
        expect(exception, isA<IPolicySDKException>());
      }
    });

    test('basic exceptions should not implement IDetailPolicySDKException', () {
      const basicException = PolicyNotInitializedException('Test message');

      expect(basicException, isA<IPolicySDKException>());
      expect(basicException, isNot(isA<IDetailPolicySDKException>()));
    });

    test('all exceptions should have consistent message handling', () {
      const testMessage = 'Test error message';

      final exceptions = [
        const PolicyNotInitializedException(testMessage),
        JsonParseException(testMessage),
        JsonSerializeException(testMessage),
      ];

      for (final exception in exceptions) {
        expect(exception.message, equals(testMessage));
        expect(exception.toString(), contains(testMessage));
      }
    });

    test('detail exceptions should handle optional parameters consistently',
        () {
      const message = 'Test error message';
      const key = 'test_key';
      const originalError = 'test_original_error';
      final errors = {'field1': 'error1', 'field2': 'error2'};

      final detailExceptions = [
        JsonParseException(
          message,
          key: key,
          originalError: originalError,
          errors: errors,
        ),
        JsonSerializeException(
          message,
          key: key,
          originalError: originalError,
          errors: errors,
        ),
      ];

      for (final exception in detailExceptions) {
        expect(exception.message, equals(message));
        expect(exception.key, equals(key));
        expect(exception.originalError, equals(originalError));
        expect(exception.errors, equals(errors));
      }
    });

    test('exceptions should have distinct type names in toString', () {
      const message = 'Test error message';

      final exceptions = [
        const PolicyNotInitializedException(message),
        JsonParseException(message),
        JsonSerializeException(message),
      ];

      final typeNames =
          exceptions.map((e) => e.toString().split(':')[0]).toSet();
      expect(typeNames.length, equals(3));
      expect(typeNames, contains('PolicyNotInitializedException'));
      expect(typeNames, contains('JsonParseException'));
      expect(typeNames, contains('JsonSerializeException'));
    });

    test('exceptions should handle null optional parameters gracefully', () {
      const message = 'Test error message';

      final detailExceptions = [
        JsonParseException(
          message,
          key: null,
          originalError: null,
          errors: null,
        ),
        JsonSerializeException(
          message,
          key: null,
          originalError: null,
          errors: null,
        ),
      ];

      for (final exception in detailExceptions) {
        expect(exception.message, equals(message));
        expect(exception.key, isNull);
        expect(exception.originalError, isNull);
        expect(exception.errors, isNull);
        expect(exception.toString(), contains(message));
        expect(exception.toString(), isNot(contains('key:')));
        expect(exception.toString(), isNot(contains('original:')));
        expect(exception.toString(), isNot(contains('total errors')));
      }
    });

    test('exceptions should handle empty errors map correctly', () {
      const message = 'Test error message';
      final emptyErrors = <String, String>{};

      final detailExceptions = [
        JsonParseException(message, errors: emptyErrors),
        JsonSerializeException(message, errors: emptyErrors),
      ];

      for (final exception in detailExceptions) {
        expect(exception.errors, equals(emptyErrors));
        expect(exception.toString(), isNot(contains('total errors')));
      }
    });

    test('exceptions should be throwable and catchable', () {
      const message = 'Test error message';

      final exceptions = [
        const PolicyNotInitializedException(message),
        JsonParseException(message),
        JsonSerializeException(message),
      ];

      for (final exception in exceptions) {
        expect(() => throw exception, throwsA(isA<Exception>()));
        expect(() => throw exception, throwsA(isA<IPolicySDKException>()));
      }
    });

    test('detail exceptions should provide rich error information', () {
      const message = 'Test error message';
      const key = 'test_key';
      const originalError = 'test_original_error';
      final errors = {'field1': 'error1', 'field2': 'error2'};

      final detailExceptions = [
        JsonParseException(
          message,
          key: key,
          originalError: originalError,
          errors: errors,
        ),
        JsonSerializeException(
          message,
          key: key,
          originalError: originalError,
          errors: errors,
        ),
      ];

      for (final exception in detailExceptions) {
        final stringRep = exception.toString();
        expect(stringRep, contains(message));
        expect(stringRep, contains(key));
        expect(stringRep, contains(originalError));
        expect(stringRep, contains('2 total errors'));
      }
    });

    test('exceptions should maintain immutability', () {
      const message = 'Test error message';

      final exceptions = [
        const PolicyNotInitializedException(message),
        JsonParseException(message),
        JsonSerializeException(message),
      ];

      for (final exception in exceptions) {
        expect(exception.message, equals(message));
        // Verify that the message field is final and immutable
        expect(exception.message, isA<String>());
        expect(exception.message, isNot(equals('Modified message')));
      }
    });
  });
}
