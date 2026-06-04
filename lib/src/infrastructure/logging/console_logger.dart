import 'dart:developer' as dev;

import 'package:flutter_policy_engine/src/application/ports/i_logger.dart';

/// A [ILogger] implementation that outputs to the Dart developer console.
///
/// Uses `dart:developer.log` for structured output that is visible in
/// Flutter DevTools and IDEs. All messages are prefixed with [tag].
///
/// By default, all levels are logged in debug mode. Configure [minLevel] to
/// filter messages by severity.
final class ConsoleLogger implements ILogger {
  /// Creates a [ConsoleLogger].
  ///
  /// [tag] is prepended to all log messages (default: `'PolicyEngine'`).
  /// [minLevel] filters messages below this level.
  const ConsoleLogger({
    this.tag = 'PolicyEngine',
    this.minLevel = LogLevel.debug,
  });

  /// The tag prefix for all log output.
  final String tag;

  /// The minimum [LogLevel] to log. Messages below this level are discarded.
  final LogLevel minLevel;

  @override
  void debug(
    String message, {
    Map<String, dynamic>? context,
    String? operation,
  }) {
    if (_shouldLog(LogLevel.debug)) {
      _emit('DEBUG', message, operation: operation, context: context);
    }
  }

  @override
  void info(
    String message, {
    Map<String, dynamic>? context,
    String? operation,
  }) {
    if (_shouldLog(LogLevel.info)) {
      _emit('INFO', message, operation: operation, context: context);
    }
  }

  @override
  void warning(
    String message, {
    Map<String, dynamic>? context,
    String? operation,
    Object? error,
  }) {
    if (_shouldLog(LogLevel.warning)) {
      _emit(
        'WARN',
        message,
        operation: operation,
        context: context,
        error: error,
      );
    }
  }

  @override
  void error(
    String message, {
    Map<String, dynamic>? context,
    String? operation,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (_shouldLog(LogLevel.error)) {
      _emit(
        'ERROR',
        message,
        operation: operation,
        context: context,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  bool _shouldLog(LogLevel level) => level.index >= minLevel.index;

  void _emit(
    String level,
    String message, {
    String? operation,
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final buffer = StringBuffer()
      ..write('[$tag] [$level]')
      ..write(operation != null ? ' [$operation]' : '')
      ..write(' $message');

    if (context != null && context.isNotEmpty) {
      buffer.write(' | context=$context');
    }
    if (error != null) {
      buffer.write(' | error=$error');
    }

    dev.log(
      buffer.toString(),
      name: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
