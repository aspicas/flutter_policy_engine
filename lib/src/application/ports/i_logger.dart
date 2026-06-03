/// Log severity levels.
enum LogLevel {
  /// Verbose debugging information.
  debug,

  /// Informational messages about normal operation.
  info,

  /// Potentially harmful situations that do not prevent operation.
  warning,

  /// Errors that may affect functionality.
  error,
}

/// Contract for structured logging within the policy engine.
///
/// Inject an implementation into `PolicyEngine.create()` to observe
/// engine internals. Use `NoopLogger` (the default) for silent operation.
abstract interface class ILogger {
  /// Logs a debug-level [message] with optional [context] and [operation].
  void debug(
    String message, {
    Map<String, dynamic>? context,
    String? operation,
  });

  /// Logs an info-level [message] with optional [context] and [operation].
  void info(
    String message, {
    Map<String, dynamic>? context,
    String? operation,
  });

  /// Logs a warning-level [message] with optional [context], [operation],
  /// and [error].
  void warning(
    String message, {
    Map<String, dynamic>? context,
    String? operation,
    Object? error,
  });

  /// Logs an error-level [message] with optional [context], [operation],
  /// [error], and [stackTrace].
  void error(
    String message, {
    Map<String, dynamic>? context,
    String? operation,
    Object? error,
    StackTrace? stackTrace,
  });
}
