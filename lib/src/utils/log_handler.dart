import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Configurable log levels
enum LogLevel {
  debug(0),
  info(1),
  warning(2),
  error(3);

  const LogLevel(this.value);
  final int value;
}

/// Structured log data for better debugging
class LogData {
  final String message;
  final LogLevel level;
  final String? tag;
  final String? screen;
  final String? operation;
  final Duration? duration;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;
  final DateTime timestamp;

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

  /// Convert to structured log format
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

class LogHandler {
  static const String _defaultTag = '[PolicyEngine]';
  static bool _isDebugMode = kDebugMode;
  static String _tag = _defaultTag;
  static String _currentScreen = '';
  static bool _includeTimestamp = true;
  static bool _includeStackTrace = true;
  static bool _includeSystemInfo = false;
  static LogLevel _minLogLevel = LogLevel.debug;
  static bool _useStructuredLogging = true;
  static bool _useDeveloperLog = true;

  /// Set the current screen for logging context
  static void setScreen(String screenName) {
    _currentScreen = screenName;
    _updateTag();
  }

  /// Set a custom tag for the current screen
  static void setScreenTag(String screenName, String customTag) {
    _currentScreen = screenName;
    _tag = customTag;
  }

  /// Get the current screen name
  static String get currentScreen => _currentScreen;

  /// Get the current tag
  static String get currentTag => _tag;

  /// Update tag based on current screen
  static void _updateTag() {
    if (_currentScreen.isNotEmpty) {
      _tag = '[$_currentScreen]';
    } else {
      _tag = _defaultTag;
    }
  }

  /// Configure the LogHandler settings
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

  /// Internal method to output logs using dart:developer
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

  /// Generic log method with configurable parameters
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

  /// Convenience methods for different log levels
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

  /// Performance logging with timing
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

  /// Async performance logging
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

  /// Legacy method for backward compatibility
  static void show(String message, {Object? error, StackTrace? stackTrace}) {
    debug(message, error: error, stackTrace: stackTrace);
  }

  /// Reset configuration to defaults
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
