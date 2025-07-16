import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Configurable log levels for the policy engine logging system.
///
/// Log levels are ordered from least to most severe:
/// - [debug]: Detailed information for debugging purposes
/// - [info]: General information about application flow
/// - [warning]: Indicates a potential issue that doesn't stop execution
/// - [error]: Indicates an error that may affect functionality
enum LogLevel {
  /// Detailed information for debugging purposes
  debug(0),

  /// General information about application flow
  info(1),

  /// Indicates a potential issue that doesn't stop execution
  warning(2),

  /// Indicates an error that may affect functionality
  error(3);

  const LogLevel(this.value);

  /// The numeric value representing the log level severity
  final int value;
}

/// Structured log data container for enhanced debugging and monitoring.
///
/// This class encapsulates all relevant information for a log entry,
/// including contextual data, timing information, and error details.
/// It provides a consistent structure for logging across the policy engine.
class LogData {
  /// Creates a new LogData instance with the specified parameters.
  ///
  /// [message] The main log message
  /// [level] The severity level of the log entry
  /// [tag] Optional tag for categorizing logs
  /// [screen] Current screen or context where the log was generated
  /// [operation] Specific operation being performed
  /// [duration] Duration of the operation (for performance logging)
  /// [error] Associated error object, if any
  /// [stackTrace] Stack trace for error logging
  /// [context] Additional contextual data as key-value pairs
  /// [timestamp] Timestamp when the log entry was created (defaults to current time)
  LogData({
    required this.message,
    required this.level,
    this.tag,
    this.screen,
    this.operation,
    this.duration,
    this.error,
    this.stackTrace,
    this.context,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// The main log message
  final String message;

  /// The severity level of the log entry
  final LogLevel level;

  /// Optional tag for categorizing logs
  final String? tag;

  /// Current screen or context where the log was generated
  final String? screen;

  /// Specific operation being performed
  final String? operation;

  /// Duration of the operation (for performance logging)
  final Duration? duration;

  /// Associated error object, if any
  final Object? error;

  /// Stack trace for error logging
  final StackTrace? stackTrace;

  /// Additional contextual data as key-value pairs
  final Map<String, dynamic>? context;

  /// Timestamp when the log entry was created
  final DateTime timestamp;

  /// Converts the log data to a structured format suitable for external logging systems.
  ///
  /// Returns a [Map] containing all relevant log information in a standardized format.
  /// This is particularly useful for integration with external monitoring tools.
  Map<String, dynamic> toStructuredLog() {
    return {
      'message': message,
      'level': level.name,
      'timestamp': timestamp.toIso8601String(),
      if (tag != null) 'tag': tag,
      if (screen != null) 'screen': screen,
      if (operation != null) 'operation': operation,
      if (duration != null) 'duration_ms': duration!.inMilliseconds,
      if (error != null) 'error': error.toString(),
      if (context != null && context!.isNotEmpty) 'context': context,
    };
  }
}

/// Centralized logging handler for the Flutter Policy Engine.
///
/// This class provides a comprehensive logging solution with the following features:
/// - Configurable log levels and filtering
/// - Structured logging for better debugging
/// - Performance timing capabilities
/// - Screen/context-aware logging
/// - Integration with Flutter's developer tools
///
/// The LogHandler is designed to be used statically throughout the application
/// and can be configured once at startup for consistent logging behavior.
class LogHandler {
  static const String _defaultTag = '[PolicyEngine]';
  static bool _isDebugMode = kDebugMode;
  static String _tag = _defaultTag;
  static String _currentScreen = '';
  // ignore: unused_field
  static bool _includeTimestamp = true;
  // ignore: unused_field
  static bool _includeStackTrace = true;
  // ignore: unused_field
  static bool _includeSystemInfo = false;
  static LogLevel _minLogLevel = LogLevel.debug;
  static bool _useStructuredLogging = true;
  static bool _useDeveloperLog = true;

  /// Sets the current screen context for all subsequent log entries.
  ///
  /// This method updates the logging context to include the current screen name,
  /// which helps in debugging by providing better context for log entries.
  ///
  /// [screenName] The name of the current screen or context
  static void setScreen(String screenName) {
    _currentScreen = screenName;
    _updateTag();
  }

  /// Sets a custom tag for a specific screen while maintaining screen context.
  ///
  /// This method allows for more granular control over log categorization
  /// by providing a custom tag for specific screens or contexts.
  ///
  /// [screenName] The name of the current screen or context
  /// [customTag] The custom tag to use for this screen
  static void setScreenTag(String screenName, String customTag) {
    _currentScreen = screenName;
    _tag = customTag;
  }

  /// Gets the current screen name being used for logging context.
  static String get currentScreen => _currentScreen;

  /// Gets the current tag being used for log categorization.
  static String get currentTag => _tag;

  /// Updates the tag based on the current screen context.
  ///
  /// This internal method ensures that the tag reflects the current screen
  /// when no custom tag has been explicitly set.
  static void _updateTag() {
    if (_currentScreen.isNotEmpty) {
      _tag = '[$_currentScreen]';
    } else {
      _tag = _defaultTag;
    }
  }

  /// Configures the LogHandler with custom settings.
  ///
  /// This method allows for comprehensive configuration of the logging system.
  /// All parameters are optional and will use sensible defaults if not provided.
  ///
  /// [tag] Custom tag for log categorization
  /// [screen] Initial screen context
  /// [isDebugMode] Whether to enable debug mode logging
  /// [includeTimestamp] Whether to include timestamps in log entries
  /// [includeStackTrace] Whether to include stack traces for errors
  /// [includeSystemInfo] Whether to include system information in logs
  /// [minLogLevel] Minimum log level to output (filters out lower levels)
  /// [useStructuredLogging] Whether to use structured logging format
  /// [useDeveloperLog] Whether to use Flutter's developer.log
  static void configure({
    String? tag,
    String? screen,
    bool? isDebugMode,
    bool? includeTimestamp,
    bool? includeStackTrace,
    bool? includeSystemInfo,
    LogLevel? minLogLevel,
    bool? useStructuredLogging,
    bool? useDeveloperLog,
  }) {
    _tag = tag ?? _defaultTag;
    _currentScreen = screen ?? '';
    _isDebugMode = isDebugMode ?? kDebugMode;
    _includeTimestamp = includeTimestamp ?? true;
    _includeStackTrace = includeStackTrace ?? true;
    _includeSystemInfo = includeSystemInfo ?? false;
    _minLogLevel = minLogLevel ?? LogLevel.debug;
    _useStructuredLogging = useStructuredLogging ?? true;
    _useDeveloperLog = useDeveloperLog ?? true;

    // Only update tag if no custom tag was provided
    if (screen != null && tag == null) {
      _updateTag();
    }
  }

  /// Internal method to output logs using Flutter's developer.log.
  ///
  /// This method handles the actual log output using Flutter's built-in
  /// developer tools for better debugging experience.
  ///
  /// [logData] The structured log data to output
  static void _logWithDeveloper(LogData logData) {
    if (!_useDeveloperLog) return;

    final structuredData = logData.toStructuredLog();

    // Use developer.log with structured data
    developer.log(
      logData.message,
      name: logData.tag ?? _tag,
      error: logData.error,
      stackTrace: logData.stackTrace,
      time: logData.timestamp,
    );

    // Log structured data as separate entries for better debugging
    if (_useStructuredLogging && structuredData.length > 2) {
      developer.log(
        'Structured Data: ${structuredData.toString()}',
        name: '${logData.tag ?? _tag}_structured',
        time: logData.timestamp,
      );
    }
  }

  /// Generic log method with configurable parameters.
  ///
  /// This is the core logging method that handles all log entry creation
  /// and output. It respects the current configuration settings and
  /// only outputs logs that meet the minimum level requirements.
  ///
  /// [message] The main log message
  /// [level] The severity level of the log entry
  /// [error] Associated error object, if any
  /// [stackTrace] Stack trace for error logging
  /// [context] Additional contextual data
  /// [operation] Specific operation being performed
  /// [duration] Duration of the operation (for performance logging)
  /// [screenOverride] Override the current screen context
  static void output(
    String message, {
    LogLevel level = LogLevel.debug,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? operation,
    Duration? duration,
    String? screenOverride,
  }) {
    if (!_isDebugMode || level.value < _minLogLevel.value) return;

    final logData = LogData(
      message: message,
      level: level,
      tag: screenOverride != null ? '[$screenOverride]' : _tag,
      screen: screenOverride ?? _currentScreen,
      operation: operation,
      duration: duration,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );

    // Use developer.log for better debugging experience
    _logWithDeveloper(logData);
  }

  /// Logs a debug-level message.
  ///
  /// Debug logs provide detailed information useful for debugging
  /// and development purposes. These are typically filtered out in production.
  ///
  /// [message] The debug message
  /// [error] Associated error object, if any
  /// [stackTrace] Stack trace for error logging
  /// [context] Additional contextual data
  /// [operation] Specific operation being performed
  /// [duration] Duration of the operation
  /// [screenOverride] Override the current screen context
  static void debug(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? operation,
    Duration? duration,
    String? screenOverride,
  }) {
    output(
      message,
      level: LogLevel.debug,
      error: error,
      stackTrace: stackTrace,
      context: context,
      operation: operation,
      duration: duration,
      screenOverride: screenOverride,
    );
  }

  /// Logs an info-level message.
  ///
  /// Info logs provide general information about application flow
  /// and are useful for understanding normal operation.
  ///
  /// [message] The info message
  /// [error] Associated error object, if any
  /// [stackTrace] Stack trace for error logging
  /// [context] Additional contextual data
  /// [operation] Specific operation being performed
  /// [duration] Duration of the operation
  /// [screenOverride] Override the current screen context
  static void info(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? operation,
    Duration? duration,
    String? screenOverride,
  }) {
    output(
      message,
      level: LogLevel.info,
      error: error,
      stackTrace: stackTrace,
      context: context,
      operation: operation,
      duration: duration,
      screenOverride: screenOverride,
    );
  }

  /// Logs a warning-level message.
  ///
  /// Warning logs indicate potential issues that don't stop execution
  /// but should be investigated.
  ///
  /// [message] The warning message
  /// [error] Associated error object, if any
  /// [stackTrace] Stack trace for error logging
  /// [context] Additional contextual data
  /// [operation] Specific operation being performed
  /// [duration] Duration of the operation
  /// [screenOverride] Override the current screen context
  static void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? operation,
    Duration? duration,
    String? screenOverride,
  }) {
    output(
      message,
      level: LogLevel.warning,
      error: error,
      stackTrace: stackTrace,
      context: context,
      operation: operation,
      duration: duration,
      screenOverride: screenOverride,
    );
  }

  /// Logs an error-level message.
  ///
  /// Error logs indicate actual errors that may affect functionality
  /// and should be addressed immediately.
  ///
  /// [message] The error message
  /// [error] Associated error object, if any
  /// [stackTrace] Stack trace for error logging
  /// [context] Additional contextual data
  /// [operation] Specific operation being performed
  /// [duration] Duration of the operation
  /// [screenOverride] Override the current screen context
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? operation,
    Duration? duration,
    String? screenOverride,
  }) {
    output(
      message,
      level: LogLevel.error,
      error: error,
      stackTrace: stackTrace,
      context: context,
      operation: operation,
      duration: duration,
      screenOverride: screenOverride,
    );
  }

  /// Executes a callback function and logs its execution time.
  ///
  /// This method is useful for performance monitoring and debugging.
  /// It automatically logs the duration of the operation upon completion.
  ///
  /// [operation] Name of the operation being timed
  /// [callback] The function to execute and time
  static void time(String operation, void Function() callback) {
    final stopwatch = Stopwatch()..start();
    try {
      callback();
    } finally {
      stopwatch.stop();
      info(
        'Operation completed',
        operation: operation,
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Executes an async callback function and logs its execution time.
  ///
  /// This method is useful for performance monitoring of asynchronous operations.
  /// It automatically logs the duration of the operation upon completion.
  ///
  /// [operation] Name of the operation being timed
  /// [callback] The async function to execute and time
  /// Returns the result of the async operation
  static Future<T> timeAsync<T>(
    String operation,
    Future<T> Function() callback,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await callback();
      return result;
    } finally {
      stopwatch.stop();
      info(
        'Async operation completed',
        operation: operation,
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Legacy method for backward compatibility.
  ///
  /// This method maintains compatibility with existing code that uses
  /// the old logging interface. It delegates to the debug method.
  ///
  /// [message] The log message
  /// [error] Associated error object, if any
  /// [stackTrace] Stack trace for error logging
  static void show(String message, {Object? error, StackTrace? stackTrace}) {
    debug(message, error: error, stackTrace: stackTrace);
  }

  /// Resets the LogHandler configuration to default values.
  ///
  /// This method restores all configuration settings to their initial
  /// default values, which is useful for testing or resetting the
  /// logging system to a known state.
  static void reset() {
    _tag = _defaultTag;
    _currentScreen = '';
    _isDebugMode = kDebugMode;
    _includeTimestamp = true;
    _includeStackTrace = true;
    _includeSystemInfo = false;
    _minLogLevel = LogLevel.debug;
    _useStructuredLogging = true;
    _useDeveloperLog = true;
  }
}
