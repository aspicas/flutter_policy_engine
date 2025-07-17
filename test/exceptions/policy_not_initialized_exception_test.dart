import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_policy_engine/src/exceptions/policy_not_initialized_exception.dart';
import 'package:flutter_policy_engine/src/exceptions/i_policy_sdk_exceptions.dart';

void main() {
  group('PolicyNotInitializedException', () {
    test('should create exception with required message', () {
      const message = 'Policy engine must be initialized before use';
      const exception = PolicyNotInitializedException(message);

      expect(exception.message, equals(message));
    });

    test('should implement IPolicySDKException interface', () {
      const message = 'Policy engine must be initialized before use';
      const exception = PolicyNotInitializedException(message);

      expect(exception, isA<IPolicySDKException>());
      expect(exception, isA<Exception>());
    });

    test('should return correct string representation', () {
      const message = 'Policy engine must be initialized before use';
      const exception = PolicyNotInitializedException(message);

      expect(exception.toString(),
          equals('PolicyNotInitializedException: $message'));
    });

    test('should handle empty message', () {
      const message = '';
      const exception = PolicyNotInitializedException(message);

      expect(exception.message, equals(message));
      expect(exception.toString(),
          equals('PolicyNotInitializedException: $message'));
    });

    test('should handle special characters in message', () {
      const message =
          'Policy engine must be initialized before use! @#\$%^&*()';
      const exception = PolicyNotInitializedException(message);

      expect(exception.message, equals(message));
      expect(exception.toString(),
          equals('PolicyNotInitializedException: $message'));
    });

    test('should handle long message', () {
      const message =
          'This is a very long error message that describes in detail why the policy engine '
          'must be properly initialized before any operations can be performed, including policy '
          'evaluation, permission checks, and other related functionality.';
      const exception = PolicyNotInitializedException(message);

      expect(exception.message, equals(message));
      expect(exception.toString(),
          equals('PolicyNotInitializedException: $message'));
    });

    test('should handle message with newlines', () {
      const message = 'Policy engine must be initialized before use.\n'
          'Please call initialize() method first.';
      const exception = PolicyNotInitializedException(message);

      expect(exception.message, equals(message));
      expect(exception.toString(),
          equals('PolicyNotInitializedException: $message'));
    });

    test('should handle message with unicode characters', () {
      const message = 'Policy engine must be initialized before use: 🚀✨🎯';
      const exception = PolicyNotInitializedException(message);

      expect(exception.message, equals(message));
      expect(exception.toString(),
          equals('PolicyNotInitializedException: $message'));
    });

    test('should be const constructible', () {
      const message = 'Policy engine must be initialized before use';
      const exception1 = PolicyNotInitializedException(message);
      const exception2 = PolicyNotInitializedException(message);

      expect(identical(exception1, exception2), isTrue);
    });

    test('should have consistent hash codes for same message', () {
      const message = 'Policy engine must be initialized before use';
      const exception1 = PolicyNotInitializedException(message);
      const exception2 = PolicyNotInitializedException(message);

      expect(exception1.hashCode, equals(exception2.hashCode));
    });

    test('should have different hash codes for different messages', () {
      const message1 = 'Policy engine must be initialized before use';
      const message2 = 'Different error message';
      const exception1 = PolicyNotInitializedException(message1);
      const exception2 = PolicyNotInitializedException(message2);

      expect(exception1.hashCode, isNot(equals(exception2.hashCode)));
    });

    test('should be equal to itself', () {
      const message = 'Policy engine must be initialized before use';
      const exception = PolicyNotInitializedException(message);

      expect(exception, equals(exception));
    });

    test('should be equal to another exception with same message', () {
      const message = 'Policy engine must be initialized before use';
      const exception1 = PolicyNotInitializedException(message);
      const exception2 = PolicyNotInitializedException(message);

      expect(exception1, equals(exception2));
    });

    test('should not be equal to exception with different message', () {
      const message1 = 'Policy engine must be initialized before use';
      const message2 = 'Different error message';
      const exception1 = PolicyNotInitializedException(message1);
      const exception2 = PolicyNotInitializedException(message2);

      expect(exception1, isNot(equals(exception2)));
    });

    test('should not be equal to different exception types', () {
      const message = 'Policy engine must be initialized before use';
      const exception = PolicyNotInitializedException(message);
      final otherException = Exception(message);

      expect(exception, isNot(equals(otherException)));
    });
  });
}
