import 'package:flutter_policy_engine/src/application/ports/i_logger.dart';
import 'package:flutter_policy_engine/src/application/services/policy_engine.dart'
    show PolicyEngine;
import 'package:flutter_policy_engine/src/infrastructure/logging/console_logger.dart'
    show ConsoleLogger;
import 'package:meta/meta.dart';

/// A no-operation [ILogger] that discards all log messages.
///
/// Used as the default logger in [PolicyEngine] for zero-overhead production
/// use. Replace with [ConsoleLogger] or a custom implementation when
/// observability is needed.
@immutable
final class NoopLogger implements ILogger {
  /// Creates a [NoopLogger].
  const NoopLogger();

  @override
  void debug(
    String message, {
    Map<String, dynamic>? context,
    String? operation,
  }) {}

  @override
  void info(
    String message, {
    Map<String, dynamic>? context,
    String? operation,
  }) {}

  @override
  void warning(
    String message, {
    Map<String, dynamic>? context,
    String? operation,
    Object? error,
  }) {}

  @override
  void error(
    String message, {
    Map<String, dynamic>? context,
    String? operation,
    Object? error,
    StackTrace? stackTrace,
  }) {}
}
