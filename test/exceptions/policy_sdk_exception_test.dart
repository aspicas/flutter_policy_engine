import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_policy_engine/src/exceptions/policy_sdk_exception.dart';
import 'package:flutter_policy_engine/src/exceptions/i_policy_sdk_exceptions.dart';

// Helper classes for testing
class _CustomException implements Exception {
  final String detail;
  _CustomException(this.detail);

  @override
  String toString() => 'CustomException: $detail';
}

class _NullToStringException implements Exception {
  @override
  String toString() => '';
}

class _ComplexException implements Exception {
  final Map<String, dynamic> data;
  _ComplexException(this.data);

  @override
  String toString() => 'ComplexException: ${data.toString()}';
}

void main() {
  group('PolicySDKException', () {
    test('should create exception with required message and exception', () {
      const message = 'Failed to load policy configuration';
      final underlyingException = Exception('Network error');
      final exception = PolicySDKException(
        message,
        exception: underlyingException,
      );

      expect(exception.message, equals(message));
      expect(exception.exception, equals(underlyingException));
    });

    test('should create exception with null underlying exception', () {
      const message = 'Failed to load policy configuration';
      final exception = PolicySDKException(
        message,
        exception: null,
      );

      expect(exception.message, equals(message));
      expect(exception.exception, isNull);
    });

    test('should implement IPolicySDKException interface', () {
      const message = 'Failed to load policy configuration';
      final underlyingException = Exception('Network error');
      final exception = PolicySDKException(
        message,
        exception: underlyingException,
      );

      expect(exception, isA<IPolicySDKException>());
      expect(exception, isA<Exception>());
    });

    test(
        'should return correct string representation with underlying exception',
        () {
      const message = 'Failed to load policy configuration';
      final underlyingException = Exception('Network error');
      final exception = PolicySDKException(
        message,
        exception: underlyingException,
      );

      expect(
        exception.toString(),
        equals('SDKException: $message\nExtra info: Exception: Network error'),
      );
    });

    test(
        'should return correct string representation without underlying exception',
        () {
      const message = 'Failed to load policy configuration';
      final exception = PolicySDKException(
        message,
        exception: null,
      );

      expect(exception.toString(), equals('SDKException: $message'));
    });

    test('should handle different types of underlying exceptions', () {
      const message = 'Failed to load policy configuration';

      // Test with FormatException
      final formatError = FormatException('Invalid format');
      final exceptionWithFormatError = PolicySDKException(
        message,
        exception: formatError,
      );

      expect(exceptionWithFormatError.exception, equals(formatError));
      expect(
        exceptionWithFormatError.toString(),
        contains('FormatException: Invalid format'),
      );

      // Test with another Exception type
      final timeoutError = TimeoutException('Operation timed out');
      final exceptionWithTimeoutError = PolicySDKException(
        message,
        exception: timeoutError,
      );

      expect(exceptionWithTimeoutError.exception, equals(timeoutError));
      expect(
        exceptionWithTimeoutError.toString(),
        contains('TimeoutException: Operation timed out'),
      );
    });

    test('should handle custom exception types', () {
      const message = 'Failed to load policy configuration';

      final customError = _CustomException('Custom error detail');
      final exception = PolicySDKException(
        message,
        exception: customError,
      );

      expect(exception.exception, equals(customError));
      expect(
        exception.toString(),
        equals(
            'SDKException: $message\nExtra info: CustomException: Custom error detail'),
      );
    });

    test('should handle special characters in message', () {
      const message = 'Failed to load policy with special chars: !@#\$%^&*()';
      final underlyingException = Exception('Special error: !@#\$%^&*()');
      final exception = PolicySDKException(
        message,
        exception: underlyingException,
      );

      expect(exception.message, equals(message));
      expect(exception.exception, equals(underlyingException));
      expect(
        exception.toString(),
        equals(
            'SDKException: $message\nExtra info: Exception: Special error: !@#\$%^&*()'),
      );
    });

    test('should handle empty message', () {
      const message = '';
      final underlyingException = Exception('Network error');
      final exception = PolicySDKException(
        message,
        exception: underlyingException,
      );

      expect(exception.message, equals(message));
      expect(exception.exception, equals(underlyingException));
      expect(
        exception.toString(),
        equals('SDKException: \nExtra info: Exception: Network error'),
      );
    });

    test('should handle multiline message', () {
      const message =
          'Failed to load policy configuration\nThis is a multiline error message';
      final underlyingException = Exception('Network error');
      final exception = PolicySDKException(
        message,
        exception: underlyingException,
      );

      expect(exception.message, equals(message));
      expect(exception.exception, equals(underlyingException));
      expect(
        exception.toString(),
        equals('SDKException: $message\nExtra info: Exception: Network error'),
      );
    });

    test('should handle exception with null toString() result', () {
      const message = 'Failed to load policy configuration';

      final nullToStringError = _NullToStringException();
      final exception = PolicySDKException(
        message,
        exception: nullToStringError,
      );

      expect(exception.exception, equals(nullToStringError));
      expect(
        exception.toString(),
        equals('SDKException: $message\nExtra info: '),
      );
    });

    test('should handle exception with complex toString() result', () {
      const message = 'Failed to load policy configuration';

      final complexError = _ComplexException({
        'errorCode': 500,
        'details': ['detail1', 'detail2'],
        'timestamp': DateTime.now(),
      });

      final exception = PolicySDKException(
        message,
        exception: complexError,
      );

      expect(exception.exception, equals(complexError));
      expect(
        exception.toString(),
        contains('SDKException: $message\nExtra info: ComplexException:'),
      );
    });

    test('should be immutable after creation', () {
      const message = 'Failed to load policy configuration';
      final underlyingException = Exception('Network error');
      final exception = PolicySDKException(
        message,
        exception: underlyingException,
      );

      // Verify that the exception object is immutable
      expect(exception.message, equals(message));
      expect(exception.exception, equals(underlyingException));

      // The fields should remain the same after multiple accesses
      expect(exception.message, equals(message));
      expect(exception.exception, equals(underlyingException));
    });

    test('should handle multiple exceptions with same message', () {
      const message = 'Failed to load policy configuration';
      final exception1 = Exception('Network error 1');
      final exception2 = Exception('Network error 2');

      final sdkException1 = PolicySDKException(
        message,
        exception: exception1,
      );

      final sdkException2 = PolicySDKException(
        message,
        exception: exception2,
      );

      expect(sdkException1.message, equals(sdkException2.message));
      expect(sdkException1.exception, isNot(equals(sdkException2.exception)));
      expect(sdkException1.toString(), isNot(equals(sdkException2.toString())));
    });
  });
}
