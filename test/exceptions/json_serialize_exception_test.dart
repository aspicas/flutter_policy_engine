import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_policy_engine/src/exceptions/json_serialize_exception.dart';
import 'package:flutter_policy_engine/src/exceptions/i_policy_sdk_exceptions.dart';

void main() {
  group('JsonSerializeException', () {
    test('should create exception with required message', () {
      const message = 'Failed to serialize object to JSON';
      final exception = JsonSerializeException(message);

      expect(exception.message, equals(message));
      expect(exception.key, isNull);
      expect(exception.originalError, isNull);
      expect(exception.errors, isNull);
    });

    test('should create exception with all optional parameters', () {
      const message = 'Failed to serialize object to JSON';
      const key = 'policy_object';
      const originalError = 'Circular reference detected';
      final errors = {
        'field1': 'Non-serializable type',
        'field2': 'Missing toJson method'
      };

      final exception = JsonSerializeException(
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
      const message = 'Failed to serialize object to JSON';
      final exception = JsonSerializeException(message);

      expect(exception, isA<IDetailPolicySDKException>());
      expect(exception, isA<IPolicySDKException>());
    });

    test('should return correct string representation with only message', () {
      const message = 'Failed to serialize object to JSON';
      final exception = JsonSerializeException(message);

      expect(exception.toString(), equals('JsonSerializeException: $message'));
    });

    test('should return correct string representation with key', () {
      const message = 'Failed to serialize object to JSON';
      const key = 'policy_object';
      final exception = JsonSerializeException(message, key: key);

      expect(exception.toString(),
          equals('JsonSerializeException: $message (key: $key)'));
    });

    test('should return correct string representation with original error', () {
      const message = 'Failed to serialize object to JSON';
      const originalError = 'Circular reference detected';
      final exception =
          JsonSerializeException(message, originalError: originalError);

      expect(
          exception.toString(),
          equals(
              'JsonSerializeException: $message (original: $originalError)'));
    });

    test('should return correct string representation with errors', () {
      const message = 'Failed to serialize object to JSON';
      final errors = {
        'field1': 'Non-serializable type',
        'field2': 'Missing toJson method'
      };
      final exception = JsonSerializeException(message, errors: errors);

      expect(exception.toString(),
          equals('JsonSerializeException: $message (2 total errors)'));
    });

    test('should return correct string representation with all parameters', () {
      const message = 'Failed to serialize object to JSON';
      const key = 'policy_object';
      const originalError = 'Circular reference detected';
      final errors = {
        'field1': 'Non-serializable type',
        'field2': 'Missing toJson method'
      };

      final exception = JsonSerializeException(
        message,
        key: key,
        originalError: originalError,
        errors: errors,
      );

      expect(
        exception.toString(),
        equals(
            'JsonSerializeException: $message (key: $key) (original: $originalError) (2 total errors)'),
      );
    });

    test('should handle empty errors map', () {
      const message = 'Failed to serialize object to JSON';
      final errors = <String, String>{};
      final exception = JsonSerializeException(message, errors: errors);

      expect(exception.toString(), equals('JsonSerializeException: $message'));
    });

    test('should handle null optional parameters', () {
      const message = 'Failed to serialize object to JSON';
      final exception = JsonSerializeException(
        message,
        key: null,
        originalError: null,
        errors: null,
      );

      expect(exception.message, equals(message));
      expect(exception.key, isNull);
      expect(exception.originalError, isNull);
      expect(exception.errors, isNull);
      expect(exception.toString(), equals('JsonSerializeException: $message'));
    });

    test('should handle complex original error objects', () {
      const message = 'Failed to serialize object to JSON';
      final originalError = Exception('Complex serialization error');
      final exception =
          JsonSerializeException(message, originalError: originalError);

      expect(exception.originalError, equals(originalError));
      expect(exception.toString(),
          contains('Exception: Complex serialization error'));
    });

    test('should handle special characters in message and key', () {
      const message =
          'Failed to serialize object with special chars: !@#\$%^&*()';
      const key = 'policy_object_with_special_chars: !@#\$%^&*()';
      final exception = JsonSerializeException(message, key: key);

      expect(exception.message, equals(message));
      expect(exception.key, equals(key));
      expect(exception.toString(),
          equals('JsonSerializeException: $message (key: $key)'));
    });

    test('should handle single error in errors map', () {
      const message = 'Failed to serialize object to JSON';
      final errors = {'field1': 'Non-serializable type'};
      final exception = JsonSerializeException(message, errors: errors);

      expect(exception.toString(),
          equals('JsonSerializeException: $message (1 total errors)'));
    });

    test('should handle multiple errors in errors map', () {
      const message = 'Failed to serialize object to JSON';
      final errors = {
        'field1': 'Non-serializable type',
        'field2': 'Missing toJson method',
        'field3': 'Circular reference',
        'field4': 'Invalid data type',
      };
      final exception = JsonSerializeException(message, errors: errors);

      expect(exception.toString(),
          equals('JsonSerializeException: $message (4 total errors)'));
    });
  });
}
