/// Base sealed class for all domain-layer failures.
///
/// Use exhaustive `switch` expressions on subtypes to handle every case:
/// ```dart
/// final label = switch (failure) {
///   PolicyNotFoundFailure() => 'not_found',
///   ResourceNotAllowedFailure() => 'resource_not_allowed',
///   // ...
/// };
/// ```
sealed class DomainFailure {
  /// Creates a [DomainFailure].
  const DomainFailure();

  /// The human-readable description of the failure.
  abstract final String message;

  @override
  String toString() => message;
}

/// No role/policy was found for the given name.
final class PolicyNotFoundFailure extends DomainFailure {
  /// Creates a [PolicyNotFoundFailure] with an explanatory [message].
  const PolicyNotFoundFailure(this.message);

  @override
  final String message;
}

/// The role exists but the requested resource is not in its allowed list.
final class ResourceNotAllowedFailure extends DomainFailure {
  /// Creates a [ResourceNotAllowedFailure] for [roleName] and [resourceId].
  const ResourceNotAllowedFailure({
    required this.roleName,
    required this.resourceId,
  });

  /// The name of the role that attempted access.
  final String roleName;

  /// The identifier of the resource that was denied.
  final String resourceId;

  @override
  String get message =>
      'Role "$roleName" is not allowed to access resource "$resourceId"';
}

/// The input was malformed (e.g., empty role name or invalid structure).
final class InvalidPolicyFailure extends DomainFailure {
  /// Creates an [InvalidPolicyFailure] with an explanatory [message].
  const InvalidPolicyFailure(this.message);

  @override
  final String message;
}

/// JSON or asset parsing failed.
final class ParseFailure extends DomainFailure {
  /// Creates a [ParseFailure] with an explanatory [message] and optional
  /// [cause].
  const ParseFailure(this.message, {this.cause});

  @override
  final String message;

  /// The underlying exception that caused the parse failure, if available.
  final Object? cause;
}

/// A storage read/write operation failed.
final class StorageFailure extends DomainFailure {
  /// Creates a [StorageFailure] with an explanatory [message] and optional
  /// [cause].
  const StorageFailure(this.message, {this.cause});

  @override
  final String message;

  /// The underlying exception that caused the storage failure, if available.
  final Object? cause;
}

/// The engine was used before any policies were loaded.
final class EngineNotInitializedFailure extends DomainFailure {
  /// Creates an [EngineNotInitializedFailure].
  const EngineNotInitializedFailure();

  @override
  String get message =>
      'Policy engine has not been initialized with any policies';
}

/// A required ABAC attribute is absent from the subject or resource.
final class MissingAttributeFailure extends DomainFailure {
  /// Creates a [MissingAttributeFailure] for [attributeKey] and [target].
  const MissingAttributeFailure({
    required this.attributeKey,
    required this.target,
  });

  /// The attribute key that was expected but not found.
  final String attributeKey;

  /// Whether the missing attribute was expected on the 'subject' or 'resource'.
  final String target;

  @override
  String get message =>
      'Required attribute "$attributeKey" is missing from $target';
}

// ─── Result type ─────────────────────────────────────────────────────────────

/// A discriminated union representing either a successful value or a failure.
///
/// Use [Ok] for success and [Err] for failure.
/// Helper methods: [isOk], [isErr], [getOrElse], [mapOk].
sealed class Result<T, E> {
  const Result();
}

/// Successful result carrying [value].
final class Ok<T, E> extends Result<T, E> {
  /// Creates an [Ok] with [value].
  const Ok(this.value);

  /// The successful value.
  final T value;
}

/// Failed result carrying [error].
final class Err<T, E> extends Result<T, E> {
  /// Creates an [Err] with [error].
  const Err(this.error);

  /// The failure value.
  final E error;
}

/// Extension helpers on [Result].
extension ResultExtensions<T, E> on Result<T, E> {
  /// Returns `true` if this is an [Ok].
  bool get isOk => this is Ok<T, E>;

  /// Returns `true` if this is an [Err].
  bool get isErr => this is Err<T, E>;

  /// Returns the [Ok.value] or [fallback] on [Err].
  T getOrElse(T fallback) => switch (this) {
        Ok(:final value) => value,
        Err() => fallback,
      };

  /// Transforms the ok value with [fn]; passes through [Err] unchanged.
  Result<R, E> mapOk<R>(R Function(T value) fn) => switch (this) {
        Ok(:final value) => Ok(fn(value)),
        Err(:final error) => Err(error),
      };
}
