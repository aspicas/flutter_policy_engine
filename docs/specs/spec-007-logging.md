# Spec-007: Logging

## Context
v1 used a global static `LogHandler` with mutable state, making test isolation unsafe and logging
non-configurable per engine instance. v2 makes logging injectable.

## ILogger Interface (Port)

```dart
abstract interface class ILogger {
  void debug(String message, {Map<String, dynamic>? context, String? operation});
  void info(String message, {Map<String, dynamic>? context, String? operation});
  void warning(String message, {Map<String, dynamic>? context, String? operation, Object? error});
  void error(String message, {Map<String, dynamic>? context, String? operation, Object? error, StackTrace? stackTrace});
}
```

## ConsoleLogger
1. Implements `ILogger`.
2. Uses `dart:developer.log` (same mechanism as v1) with a configurable tag prefix.
3. Only outputs messages at or above `minLogLevel`.
4. Defaults: `minLogLevel = LogLevel.debug` in debug mode, `LogLevel.error` in release mode.
5. No global state; all configuration is constructor-injected.

## NoopLogger
1. Implements `ILogger`.
2. All methods are no-ops.
3. Used as the **default** when no logger is injected into `PolicyEngine`.
4. Suitable for production use where consumers manage their own logging.

## Rules
1. `PolicyEngine.create()` uses `NoopLogger` by default.
2. Consumers opt in to logging by passing `ConsoleLogger()` or a custom `ILogger`.
3. Log calls must not throw under any circumstances.
4. Log context maps are optional and additive.
5. No log message may contain user-sensitive data (role names and resource IDs are considered safe;
   user credentials or PII are never logged).

## Acceptance Criteria
- [ ] `ILogger` is defined in `application/ports/`.
- [ ] `ConsoleLogger` and `NoopLogger` are in `infrastructure/logging/`.
- [ ] `ConsoleLogger` passes `test/contract/logger_contract.dart`.
- [ ] `NoopLogger` passes `test/contract/logger_contract.dart`.
- [ ] `PolicyEngine` uses `NoopLogger` when no logger is provided.
- [ ] Covered by `test/infrastructure/logging/*_test.dart`.
- [ ] Covered by `test/bdd/logging_feature_test.dart`.
