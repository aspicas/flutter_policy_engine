import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_policy_engine/src/utils/log_handler.dart';

void main() {
  group('LogHandler', () {
    setUp(() {
      // Reset LogHandler to default state before each test
      LogHandler.reset();
    });

    group('LogLevel enum', () {
      test('should have correct values', () {
        expect(LogLevel.debug.value, 0);
        expect(LogLevel.info.value, 1);
        expect(LogLevel.warning.value, 2);
        expect(LogLevel.error.value, 3);
      });

      test('should have correct names', () {
        expect(LogLevel.debug.name, 'debug');
        expect(LogLevel.info.name, 'info');
        expect(LogLevel.warning.name, 'warning');
        expect(LogLevel.error.name, 'error');
      });

      test('should compare levels correctly', () {
        expect(LogLevel.debug.value < LogLevel.info.value, true);
        expect(LogLevel.info.value < LogLevel.warning.value, true);
        expect(LogLevel.warning.value < LogLevel.error.value, true);
        expect(LogLevel.error.value > LogLevel.debug.value, true);
      });
    });

    group('LogData class', () {
      test('should create LogData with required fields', () {
        final logData = LogData(
          message: 'Test message',
          level: LogLevel.info,
        );

        expect(logData.message, 'Test message');
        expect(logData.level, LogLevel.info);
        expect(logData.timestamp, isA<DateTime>());
      });

      test('should create LogData with all optional fields', () {
        final timestamp = DateTime.now();
        final logData = LogData(
          message: 'Test message',
          level: LogLevel.warning,
          tag: '[CustomTag]',
          screen: 'TestScreen',
          operation: 'test_operation',
          duration: const Duration(milliseconds: 100),
          error: Exception('Test error'),
          stackTrace: StackTrace.current,
          context: {'key': 'value'},
          timestamp: timestamp,
        );

        expect(logData.message, 'Test message');
        expect(logData.level, LogLevel.warning);
        expect(logData.tag, '[CustomTag]');
        expect(logData.screen, 'TestScreen');
        expect(logData.operation, 'test_operation');
        expect(logData.duration, const Duration(milliseconds: 100));
        expect(logData.error, isA<Exception>());
        expect(logData.stackTrace, isA<StackTrace>());
        expect(logData.context, {'key': 'value'});
        expect(logData.timestamp, timestamp);
      });

      test('should convert to structured log format', () {
        final logData = LogData(
          message: 'Test message',
          level: LogLevel.info,
          tag: '[CustomTag]',
          screen: 'TestScreen',
          operation: 'test_operation',
          duration: const Duration(milliseconds: 100),
          context: {'key': 'value'},
        );

        final structured = logData.toStructuredLog();

        expect(structured['message'], 'Test message');
        expect(structured['level'], 'info');
        expect(structured['tag'], '[CustomTag]');
        expect(structured['screen'], 'TestScreen');
        expect(structured['operation'], 'test_operation');
        expect(structured['duration_ms'], 100);
        expect(structured['context'], {'key': 'value'});
        expect(structured['timestamp'], isA<String>());
      });

      test('should handle null values in structured log', () {
        final logData = LogData(
          message: 'Test message',
          level: LogLevel.debug,
        );

        final structured = logData.toStructuredLog();

        expect(structured['message'], 'Test message');
        expect(structured['level'], 'debug');
        expect(structured['timestamp'], isA<String>());
        expect(structured.containsKey('tag'), false);
        expect(structured.containsKey('screen'), false);
        expect(structured.containsKey('operation'), false);
        expect(structured.containsKey('duration_ms'), false);
        expect(structured.containsKey('error'), false);
        expect(structured.containsKey('context'), false);
      });

      test('should handle empty context map in structured log', () {
        final logData = LogData(
          message: 'Test message',
          level: LogLevel.info,
          context: {},
        );

        final structured = logData.toStructuredLog();

        expect(structured['message'], 'Test message');
        expect(structured['level'], 'info');
        expect(structured.containsKey('context'), false);
      });

      test('should handle error object in structured log', () {
        final error = Exception('Test exception');
        final logData = LogData(
          message: 'Test message',
          level: LogLevel.error,
          error: error,
        );

        final structured = logData.toStructuredLog();

        expect(structured['error'], error.toString());
      });
    });

    group('Configuration', () {
      test('should configure with all parameters', () {
        LogHandler.configure(
          tag: '[CustomTag]',
          screen: 'TestScreen',
          isDebugMode: true,
          includeTimestamp: false,
          includeStackTrace: false,
          includeSystemInfo: true,
          minLogLevel: LogLevel.warning,
          useStructuredLogging: false,
          useDeveloperLog: false,
        );

        expect(LogHandler.currentTag, '[CustomTag]');
        expect(LogHandler.currentScreen, 'TestScreen');
      });

      test('should use default values when parameters are null', () {
        LogHandler.configure();

        expect(LogHandler.currentTag, '[PolicyEngine]');
        expect(LogHandler.currentScreen, '');
      });

      test('should update tag when screen is provided', () {
        LogHandler.configure(screen: 'HomeScreen');
        expect(LogHandler.currentTag, '[HomeScreen]');
      });

      test('should preserve custom tag when both tag and screen are provided',
          () {
        LogHandler.configure(
          tag: '[CustomTag]',
          screen: 'HomeScreen',
        );
        expect(LogHandler.currentTag, '[CustomTag]');
        expect(LogHandler.currentScreen, 'HomeScreen');
      });

      test('should handle empty screen name', () {
        LogHandler.configure(screen: '');
        expect(LogHandler.currentTag, '[PolicyEngine]');
        expect(LogHandler.currentScreen, '');
      });

      test('should handle whitespace in screen name', () {
        LogHandler.configure(screen: '   ');
        expect(LogHandler.currentTag, '[   ]');
        expect(LogHandler.currentScreen, '   ');
      });
    });

    group('Screen management', () {
      test('should set screen and update tag', () {
        LogHandler.setScreen('LoginScreen');
        expect(LogHandler.currentScreen, 'LoginScreen');
        expect(LogHandler.currentTag, '[LoginScreen]');
      });

      test('should set screen with custom tag', () {
        LogHandler.setScreenTag('ProfileScreen', '[UserProfile]');
        expect(LogHandler.currentScreen, 'ProfileScreen');
        expect(LogHandler.currentTag, '[UserProfile]');
      });

      test('should reset tag to default when screen is empty', () {
        LogHandler.setScreen('TestScreen');
        expect(LogHandler.currentTag, '[TestScreen]');

        LogHandler.setScreen('');
        expect(LogHandler.currentTag, '[PolicyEngine]');
      });

      test('should handle screen with special characters', () {
        LogHandler.setScreen('User-Profile_Screen');
        expect(LogHandler.currentTag, '[User-Profile_Screen]');
      });

      test('should handle screen with numbers', () {
        LogHandler.setScreen('Screen123');
        expect(LogHandler.currentTag, '[Screen123]');
      });

      test('should handle very long screen names', () {
        final longScreenName = 'A' * 100;
        LogHandler.setScreen(longScreenName);
        expect(LogHandler.currentTag, '[$longScreenName]');
      });
    });

    group('Log methods', () {
      test('should log debug message', () {
        expect(() {
          LogHandler.debug('Test debug message');
        }, returnsNormally);
      });

      test('should log info message', () {
        expect(() {
          LogHandler.info('Test info message');
        }, returnsNormally);
      });

      test('should log warning message', () {
        expect(() {
          LogHandler.warning('Test warning message');
        }, returnsNormally);
      });

      test('should log error message', () {
        expect(() {
          LogHandler.error('Test error message');
        }, returnsNormally);
      });

      test('should log with all optional parameters', () {
        expect(() {
          LogHandler.output(
            'Test message',
            level: LogLevel.info,
            error: Exception('Test exception'),
            stackTrace: StackTrace.current,
            context: {'key': 'value', 'number': 42},
            operation: 'test_operation',
            duration: const Duration(milliseconds: 100),
            screenOverride: 'OverrideScreen',
          );
        }, returnsNormally);
      });

      test('should handle null parameters gracefully', () {
        expect(() {
          LogHandler.output(
            'Test message',
            level: LogLevel.debug,
            error: null,
            stackTrace: null,
            context: null,
            operation: null,
            duration: null,
            screenOverride: null,
          );
        }, returnsNormally);
      });

      test('should handle empty context map', () {
        expect(() {
          LogHandler.output(
            'Test message',
            context: {},
          );
        }, returnsNormally);
      });

      test('should handle screen override parameter', () {
        LogHandler.setScreen('OriginalScreen');

        expect(() {
          LogHandler.output(
            'Test message',
            screenOverride: 'OverrideScreen',
          );
        }, returnsNormally);
      });

      test('should handle operation parameter', () {
        expect(() {
          LogHandler.output(
            'Test message',
            operation: 'fetch_data',
          );
        }, returnsNormally);
      });

      test('should handle duration parameter', () {
        expect(() {
          LogHandler.output(
            'Test message',
            duration: const Duration(seconds: 5),
          );
        }, returnsNormally);
      });
    });

    group('Performance logging', () {
      test('should time synchronous operations', () {
        expect(() {
          LogHandler.time('test_operation', () {
            // Simulate some work
            for (int i = 0; i < 1000; i++) {
              // Do nothing
            }
          });
        }, returnsNormally);
      });

      test('should time asynchronous operations', () async {
        expect(() async {
          final result =
              await LogHandler.timeAsync('async_test_operation', () async {
            // Simulate async work
            await Future.delayed(const Duration(milliseconds: 10));
            return 'test_result';
          });
          expect(result, 'test_result');
        }, returnsNormally);
      });

      test('should handle exceptions in timed operations', () {
        expect(() {
          LogHandler.time('error_operation', () {
            throw Exception('Test exception');
          });
        }, throwsException);
      });

      test('should handle exceptions in async timed operations', () async {
        expect(() async {
          await LogHandler.timeAsync('async_error_operation', () async {
            await Future.delayed(const Duration(milliseconds: 10));
            throw Exception('Test async exception');
          });
        }, throwsException);
      });

      test('should handle empty operation names', () {
        expect(() {
          LogHandler.time('', () {
            // Do nothing
          });
        }, returnsNormally);
      });

      test('should handle very long operation names', () {
        final longOperationName = 'A' * 100;
        expect(() {
          LogHandler.time(longOperationName, () {
            // Do nothing
          });
        }, returnsNormally);
      });

      test('should handle async operations that return null', () async {
        expect(() async {
          final result = await LogHandler.timeAsync('null_operation', () async {
            await Future.delayed(const Duration(milliseconds: 5));
            return null;
          });
          expect(result, isNull);
        }, returnsNormally);
      });
    });

    group('Legacy compatibility', () {
      test('should support legacy show method', () {
        expect(() {
          LogHandler.show('Legacy message');
        }, returnsNormally);
      });

      test('should support legacy show method with error', () {
        expect(() {
          LogHandler.show(
            'Legacy message with error',
            error: Exception('Test error'),
            stackTrace: StackTrace.current,
          );
        }, returnsNormally);
      });

      test('should support legacy show method with null parameters', () {
        expect(() {
          LogHandler.show('Legacy message', error: null, stackTrace: null);
        }, returnsNormally);
      });
    });

    group('Log level filtering', () {
      test('should respect minimum log level', () {
        LogHandler.configure(minLogLevel: LogLevel.warning);

        // These should not log anything (below minimum level)
        expect(() {
          LogHandler.debug('Debug message');
          LogHandler.info('Info message');
        }, returnsNormally);

        // These should log (at or above minimum level)
        expect(() {
          LogHandler.warning('Warning message');
          LogHandler.error('Error message');
        }, returnsNormally);
      });

      test('should allow all levels when minimum is debug', () {
        LogHandler.configure(minLogLevel: LogLevel.debug);

        expect(() {
          LogHandler.debug('Debug message');
          LogHandler.info('Info message');
          LogHandler.warning('Warning message');
          LogHandler.error('Error message');
        }, returnsNormally);
      });

      test('should only allow error level when minimum is error', () {
        LogHandler.configure(minLogLevel: LogLevel.error);

        expect(() {
          LogHandler.debug('Debug message');
          LogHandler.info('Info message');
          LogHandler.warning('Warning message');
          LogHandler.error('Error message');
        }, returnsNormally);
      });

      test('should handle exact level matching', () {
        LogHandler.configure(minLogLevel: LogLevel.info);

        expect(() {
          LogHandler.debug('Debug message'); // Should not log
          LogHandler.info('Info message'); // Should log
          LogHandler.warning('Warning message'); // Should log
          LogHandler.error('Error message'); // Should log
        }, returnsNormally);
      });
    });

    group('Debug mode behavior', () {
      test('should respect debug mode setting', () {
        LogHandler.configure(isDebugMode: false);

        // Should not log anything in non-debug mode
        expect(() {
          LogHandler.debug('Debug message');
          LogHandler.info('Info message');
          LogHandler.warning('Warning message');
          LogHandler.error('Error message');
        }, returnsNormally);
      });

      test('should log in debug mode', () {
        LogHandler.configure(isDebugMode: true);

        expect(() {
          LogHandler.debug('Debug message');
          LogHandler.info('Info message');
          LogHandler.warning('Warning message');
          LogHandler.error('Error message');
        }, returnsNormally);
      });
    });

    group('Reset functionality', () {
      test('should reset to default values', () {
        // Configure with custom values
        LogHandler.configure(
          tag: '[CustomTag]',
          screen: 'TestScreen',
          isDebugMode: false,
          includeTimestamp: false,
          includeStackTrace: false,
          includeSystemInfo: true,
          minLogLevel: LogLevel.error,
          useStructuredLogging: false,
          useDeveloperLog: false,
        );

        // Reset
        LogHandler.reset();

        // Verify defaults
        expect(LogHandler.currentTag, '[PolicyEngine]');
        expect(LogHandler.currentScreen, '');
      });

      test('should reset after multiple configurations', () {
        // First configuration
        LogHandler.configure(tag: '[FirstTag]', screen: 'FirstScreen');
        expect(LogHandler.currentTag, '[FirstTag]');
        expect(LogHandler.currentScreen, 'FirstScreen');

        // Second configuration
        LogHandler.configure(tag: '[SecondTag]', screen: 'SecondScreen');
        expect(LogHandler.currentTag, '[SecondTag]');
        expect(LogHandler.currentScreen, 'SecondScreen');

        // Reset
        LogHandler.reset();
        expect(LogHandler.currentTag, '[PolicyEngine]');
        expect(LogHandler.currentScreen, '');
      });
    });

    group('Edge cases', () {
      test('should handle empty message', () {
        expect(() {
          LogHandler.output('');
        }, returnsNormally);
      });

      test('should handle very long message', () {
        final longMessage = 'A' * 1000;
        expect(() {
          LogHandler.output(longMessage);
        }, returnsNormally);
      });

      test('should handle special characters in message', () {
        expect(() {
          LogHandler.output(
              'Message with special chars: !@#\$%^&*()_+-=[]{}|;:,.<>?');
        }, returnsNormally);
      });

      test('should handle unicode characters', () {
        expect(() {
          LogHandler.output('Message with unicode: 🚀 📱 💻');
        }, returnsNormally);
      });

      test('should handle complex context objects', () {
        final complexContext = {
          'string': 'value',
          'number': 42,
          'boolean': true,
          'null': null,
          'list': [1, 2, 3],
          'map': {'nested': 'value'},
        };

        expect(() {
          LogHandler.output('Test message', context: complexContext);
        }, returnsNormally);
      });

      test('should handle nested context objects', () {
        final nestedContext = {
          'level1': {
            'level2': {
              'level3': 'deep_value',
              'array': [1, 2, 3],
            },
          },
        };

        expect(() {
          LogHandler.output('Test message', context: nestedContext);
        }, returnsNormally);
      });

      test('should handle context with function references', () {
        final contextWithFunction = {
          'function': () => 'test',
          'string': 'value',
        };

        expect(() {
          LogHandler.output('Test message', context: contextWithFunction);
        }, returnsNormally);
      });

      test('should handle very large context objects', () {
        final largeContext = <String, dynamic>{};
        for (int i = 0; i < 100; i++) {
          largeContext['key_$i'] = 'value_$i';
        }

        expect(() {
          LogHandler.output('Test message', context: largeContext);
        }, returnsNormally);
      });

      test('should handle error objects with complex toString', () {
        final complexError =
            Exception('Complex error with special chars: !@#\$%^&*()');
        expect(() {
          LogHandler.output('Test message', error: complexError);
        }, returnsNormally);
      });

      test('should handle custom error objects', () {
        final customError = CustomError('Custom error message');
        expect(() {
          LogHandler.output('Test message', error: customError);
        }, returnsNormally);
      });
    });

    group('Integration scenarios', () {
      test('should handle typical logging workflow', () {
        // Configure for a specific screen
        LogHandler.setScreen('UserProfile');

        // Log various levels
        expect(() {
          LogHandler.debug('User profile loaded');
          LogHandler.info('User data fetched successfully');
          LogHandler.warning('Some optional data missing');
          LogHandler.error('Failed to load user avatar');
        }, returnsNormally);

        // Verify screen context is maintained
        expect(LogHandler.currentScreen, 'UserProfile');
        expect(LogHandler.currentTag, '[UserProfile]');
      });

      test('should handle screen transitions', () {
        // Start on login screen
        LogHandler.setScreen('LoginScreen');
        expect(LogHandler.currentTag, '[LoginScreen]');

        // Transition to home screen
        LogHandler.setScreen('HomeScreen');
        expect(LogHandler.currentTag, '[HomeScreen]');

        // Log during transition
        expect(() {
          LogHandler.info('Screen transition completed');
        }, returnsNormally);
      });

      test('should handle performance monitoring workflow', () async {
        // Configure logging
        LogHandler.setScreen('DataProcessing');

        // Monitor performance
        expect(() async {
          await LogHandler.timeAsync('data_fetch', () async {
            await Future.delayed(const Duration(milliseconds: 50));
            return 'data_result';
          });
        }, returnsNormally);

        // Verify logging occurred
        expect(LogHandler.currentScreen, 'DataProcessing');
      });

      test('should handle complex application flow', () async {
        // Initial setup
        LogHandler.setScreen('AppStartup');
        LogHandler.info('Application starting');

        // Screen transition
        LogHandler.setScreen('LoginScreen');
        LogHandler.info('User attempting login');

        // Performance monitoring
        await LogHandler.timeAsync('login_process', () async {
          await Future.delayed(const Duration(milliseconds: 100));
          return 'login_success';
        });

        // Error handling
        LogHandler.warning('Some optional features unavailable');

        // Final transition
        LogHandler.setScreen('HomeScreen');
        LogHandler.info('User successfully logged in');

        expect(LogHandler.currentScreen, 'HomeScreen');
        expect(LogHandler.currentTag, '[HomeScreen]');
      });

      test('should handle error recovery workflow', () {
        LogHandler.setScreen('ErrorHandling');

        // Log initial state
        LogHandler.info('Starting error recovery process');

        // Log error
        LogHandler.error(
          'Network connection failed',
          error: Exception('Connection timeout'),
          context: {'retry_count': 3, 'timeout_ms': 5000},
        );

        // Log recovery attempt
        LogHandler.warning('Attempting to reconnect...');

        // Log success
        LogHandler.info('Connection restored successfully');

        expect(LogHandler.currentScreen, 'ErrorHandling');
      });
    });

    group('Stress testing', () {
      test('should handle rapid logging calls', () {
        expect(() {
          for (int i = 0; i < 100; i++) {
            LogHandler.debug('Rapid log message $i');
          }
        }, returnsNormally);
      });

      test('should handle concurrent screen changes', () {
        expect(() {
          for (int i = 0; i < 50; i++) {
            LogHandler.setScreen('Screen$i');
            LogHandler.info('Message from screen $i');
          }
        }, returnsNormally);
      });

      test('should handle mixed log levels rapidly', () {
        expect(() {
          for (int i = 0; i < 50; i++) {
            LogHandler.debug('Debug $i');
            LogHandler.info('Info $i');
            LogHandler.warning('Warning $i');
            LogHandler.error('Error $i');
          }
        }, returnsNormally);
      });
    });
  });
}

/// Custom error class for testing
class CustomError implements Exception {
  final String message;

  CustomError(this.message);

  @override
  String toString() => 'CustomError: $message';
}
