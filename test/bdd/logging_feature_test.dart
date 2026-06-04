// BDD feature tests for spec-007-logging.md

import 'package:flutter_policy_engine/src/application/ports/i_logger.dart';
import 'package:flutter_policy_engine/src/infrastructure/logging/console_logger.dart';
import 'package:flutter_policy_engine/src/infrastructure/logging/noop_logger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bdd.dart';

void main() {
  group('Feature: Logging (spec-007)', () {
    group('Scenario: NoopLogger discards all messages silently', () {
      test(
          'Given NoopLogger, '
          'When any log method is called, Then no exception is thrown', () {
        const logger = NoopLogger();

        given('NoopLogger').when('calling all log methods', () {
          logger
            ..debug('debug')
            ..info('info')
            ..warning('warn', error: Exception('e'))
            ..error(
              'error',
              error: Exception('e'),
              stackTrace: StackTrace.current,
            );
          return true;
        }).then('no exception thrown', (success) {
          expect(success, isTrue);
        });
      });
    });

    group('Scenario: ConsoleLogger respects minLevel filter', () {
      test(
          'Given ConsoleLogger with minLevel=error, '
          'When info is called, Then it silently does nothing (no throw)', () {
        const logger = ConsoleLogger(minLevel: LogLevel.error);

        given('ConsoleLogger at error level').when(
          'calling info (below minLevel)',
          () {
            logger.info('this should be suppressed');
            return true;
          },
        ).then('no exception thrown', (success) {
          expect(success, isTrue);
        });
      });

      test(
          'Given ConsoleLogger with minLevel=debug, '
          'When error is called, Then it executes without throwing', () {
        const logger = ConsoleLogger();

        given('ConsoleLogger at debug level').when(
          'calling error (above minLevel)',
          () {
            logger.error('critical error', error: Exception('oops'));
            return true;
          },
        ).then('no exception thrown', (success) {
          expect(success, isTrue);
        });
      });
    });

    group('Scenario: ILogger contract - all implementations are safe', () {
      for (final entry in {
        'NoopLogger': const NoopLogger() as ILogger,
        'ConsoleLogger': const ConsoleLogger() as ILogger,
      }.entries) {
        test('${entry.key} log calls never throw', () {
          given('${entry.key} instance').when(
            'calling all log levels',
            () {
              entry.value.debug('d', context: <String, dynamic>{'k': 'v'});
              entry.value.info('i', operation: 'op');
              entry.value.warning('w', error: Exception('e'));
              entry.value.error(
                'e',
                error: Exception('e'),
                stackTrace: StackTrace.current,
              );
              return true;
            },
          ).then('no exception', (r) => expect(r, isTrue));
        });
      }
    });
  });
}
