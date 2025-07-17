import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_policy_engine/src/exceptions/i_policy_sdk_exceptions.dart';

void main() {
  group('IPolicySDKException', () {
    test('should create exception with message', () {
      const message = 'Test error message';
      const exception = TestPolicySDKException(message);

      expect(exception.message, equals(message));
    });

    test('should return correct string representation', () {
      const message = 'Test error message';
      const exception = TestPolicySDKException(message);

      expect(exception.toString(), equals('PolicySDKException: $message'));
    });

    test('should implement Exception interface', () {
      const message = 'Test error message';
      const exception = TestPolicySDKException(message);

      expect(exception, isA<Exception>());
    });
  });

  group('IDetailPolicySDKException', () {
    test('should create exception with required message', () {
      const message = 'Test error message';
      const exception = TestDetailPolicySDKException(message);

      expect(exception.message, equals(message));
      expect(exception.key, isNull);
      expect(exception.originalError, isNull);
      expect(exception.errors, isNull);
    });

    test('should create exception with all optional parameters', () {
      const message = 'Test error message';
      const key = 'test_key';
      const originalError = 'original error';
      final errors = {'field1': 'error1', 'field2': 'error2'};

      final exception = TestDetailPolicySDKException(
        message,
        key: key,
        originalError: originalError,
        errors: errors,
      );

      expect(exception.message, equals(message));
      expect(exception.key, equals(key));
      expect(exception.originalError, equals(originalError));
      expect(exception.errors, equals(errors));
    });

    test('should implement IPolicySDKException interface', () {
      const message = 'Test error message';
      const exception = TestDetailPolicySDKException(message);

      expect(exception, isA<IPolicySDKException>());
    });

    test('should handle null optional parameters', () {
      const message = 'Test error message';
      const exception = TestDetailPolicySDKException(
        message,
        key: null,
        originalError: null,
        errors: null,
      );

      expect(exception.message, equals(message));
      expect(exception.key, isNull);
      expect(exception.originalError, isNull);
      expect(exception.errors, isNull);
    });
  });
}

/// Test implementation of IPolicySDKException for testing purposes
class TestPolicySDKException implements IPolicySDKException {
  const TestPolicySDKException(this.message);

  @override
  final String message;

  @override
  String toString() => 'PolicySDKException: $message';
}

/// Test implementation of IDetailPolicySDKException for testing purposes
class TestDetailPolicySDKException implements IDetailPolicySDKException {
  const TestDetailPolicySDKException(
    this.message, {
    this.key,
    this.originalError,
    this.errors,
  });

  @override
  final String message;

  @override
  final String? key;

  @override
  final Object? originalError;

  @override
  final Map<String, String>? errors;

  @override
  String toString() => 'TestDetailPolicySDKException: $message';
}
