import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_policy_engine/src/exceptions/json_parse_exception.dart';
import 'package:flutter_policy_engine/src/exceptions/i_policy_sdk_exceptions.dart';

void main() {
  group('JsonParseException', () {
    test('should create exception with required message', () {
      const message = 'Failed to parse JSON';
      final exception = JsonParseException(message);

      expect(exception.message, equals(message));
      expect(exception.key, isNull);
      expect(exception.originalError, isNull);
      expect(exception.errors, isNull);
    });

    test('should create exception with all optional parameters', () {
      const message = 'Failed to parse JSON';
      const key = 'policy_data';
      const originalError = 'Invalid JSON format';
      final errors = {
        'field1': 'Invalid type',
        'field2': 'Missing required field'
      };

      final exception = JsonParseException(
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

    test('should implement IDetailPolicySDKException interface', () {
      const message = 'Failed to parse JSON';
      final exception = JsonParseException(message);

      expect(exception, isA<IDetailPolicySDKException>());
      expect(exception, isA<IPolicySDKException>());
    });

    test('should return correct string representation with only message', () {
      const message = 'Failed to parse JSON';
      final exception = JsonParseException(message);

      expect(exception.toString(), equals('JsonParseException: $message'));
    });

    test('should return correct string representation with key', () {
      const message = 'Failed to parse JSON';
      const key = 'policy_data';
      final exception = JsonParseException(message, key: key);

      expect(exception.toString(),
          equals('JsonParseException: $message (key: $key)'));
    });

    test('should return correct string representation with original error', () {
      const message = 'Failed to parse JSON';
      const originalError = 'Invalid JSON format';
      final exception =
          JsonParseException(message, originalError: originalError);

      expect(exception.toString(),
          equals('JsonParseException: $message (original: $originalError)'));
    });

    test('should return correct string representation with errors', () {
      const message = 'Failed to parse JSON';
      final errors = {
        'field1': 'Invalid type',
        'field2': 'Missing required field'
      };
      final exception = JsonParseException(message, errors: errors);

      expect(exception.toString(),
          equals('JsonParseException: $message (2 total errors)'));
    });

    test('should return correct string representation with all parameters', () {
      const message = 'Failed to parse JSON';
      const key = 'policy_data';
      const originalError = 'Invalid JSON format';
      final errors = {
        'field1': 'Invalid type',
        'field2': 'Missing required field'
      };

      final exception = JsonParseException(
        message,
        key: key,
        originalError: originalError,
        errors: errors,
      );

      expect(
          exception.toString(),
          equals(
              'JsonParseException: $message (key: $key) (original: $originalError) (2 total errors)'));
    });

    test('should handle empty errors map', () {
      const message = 'Failed to parse JSON';
      final errors = <String, String>{};
      final exception = JsonParseException(message, errors: errors);

      expect(exception.toString(), equals('JsonParseException: $message'));
    });

    test('should handle null optional parameters', () {
      const message = 'Failed to parse JSON';
      final exception = JsonParseException(
        message,
        key: null,
        originalError: null,
        errors: null,
      );

      expect(exception.message, equals(message));
      expect(exception.key, isNull);
      expect(exception.originalError, isNull);
      expect(exception.errors, isNull);
      expect(exception.toString(), equals('JsonParseException: $message'));
    });

    test('should handle complex original error objects', () {
      const message = 'Failed to parse JSON';
      final originalError = Exception('Complex error object');
      final exception =
          JsonParseException(message, originalError: originalError);

      expect(exception.originalError, equals(originalError));
      expect(exception.toString(), contains('Exception: Complex error object'));
    });

    test('should handle special characters in message and key', () {
      const message = 'Failed to parse JSON with special chars: !@#\$%^&*()';
      const key = 'policy_data_with_special_chars: !@#\$%^&*()';
      final exception = JsonParseException(message, key: key);

      expect(exception.message, equals(message));
      expect(exception.key, equals(key));
      expect(exception.toString(),
          equals('JsonParseException: $message (key: $key)'));
    });
  });
}
