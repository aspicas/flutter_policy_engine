// ignore_for_file: public_member_api_docs

/// Contract tests for [ILogger].
///
/// Any implementation of [ILogger] must pass these tests.
///
/// Usage:
/// ```dart
/// void main() {
///   runLoggerContractTests(factory: ConsoleLogger.new);
/// }
/// ```
library logger_contract;

import 'package:flutter_policy_engine/src/application/ports/i_logger.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs the full [ILogger] contract test suite.
///
/// [factory] must return a new logger instance for each test.
void runLoggerContractTests({
  required ILogger Function() factory,
}) {
  late ILogger logger;

  setUp(() {
    logger = factory();
  });

  group('ILogger contract', () {
    test('debug does not throw', () {
      expect(() => logger.debug('debug message'), returnsNormally);
    });

    test('info does not throw', () {
      expect(() => logger.info('info message'), returnsNormally);
    });

    test('warning does not throw', () {
      expect(
        () => logger.warning('warning message', error: Exception('oops')),
        returnsNormally,
      );
    });

    test('error does not throw', () {
      expect(
        () => logger.error(
          'error message',
          error: Exception('fatal'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });

    test('log calls with context do not throw', () {
      expect(
        () => logger.info(
          'message with context',
          context: {'key': 'value', 'count': 42},
          operation: 'test_operation',
        ),
        returnsNormally,
      );
    });

    test('log calls with null optional params do not throw', () {
      expect(
        () => logger.error('error without extras'),
        returnsNormally,
      );
    });
  });
}
