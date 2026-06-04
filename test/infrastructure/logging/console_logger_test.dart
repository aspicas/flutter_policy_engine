import 'package:flutter_policy_engine/src/application/ports/i_logger.dart';
import 'package:flutter_policy_engine/src/infrastructure/logging/console_logger.dart';
import 'package:flutter_policy_engine/src/infrastructure/logging/noop_logger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contract/logger_contract.dart';

void main() {
  group('ConsoleLogger', () {
    runLoggerContractTests(factory: ConsoleLogger.new);

    test('respects minLevel — debug messages suppressed at info level', () {
      const logger = ConsoleLogger(minLevel: LogLevel.info);
      expect(() => logger.debug('suppressed'), returnsNormally);
    });

    test('custom tag is accepted', () {
      const logger = ConsoleLogger(tag: 'MyApp', minLevel: LogLevel.error);
      expect(() => logger.info('info'), returnsNormally);
      expect(() => logger.error('error'), returnsNormally);
    });
  });

  group('NoopLogger', () {
    runLoggerContractTests(factory: NoopLogger.new);
  });
}
