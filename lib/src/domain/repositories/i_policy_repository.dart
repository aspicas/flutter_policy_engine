import 'package:flutter_policy_engine/src/domain/entities/policy.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';

/// Contract for reading and writing the [Policy] aggregate.
///
/// Implementations can store policies in memory, shared preferences,
/// a file, or any remote storage.
abstract interface class IPolicyRepository {
  /// Persists [policy] to the underlying storage.
  ///
  /// Returns [Ok<void>] on success or [Err<StorageFailure>] on failure.
  Future<Result<void, DomainFailure>> save(Policy policy);

  /// Loads the stored [Policy].
  ///
  /// Returns [Ok<Policy>] with the stored policy, or [Ok<Policy>] with an
  /// empty [Policy] when nothing has been saved yet.
  /// Returns [Err<StorageFailure>] on I/O or parse failure.
  Future<Result<Policy, DomainFailure>> load();

  /// Removes all stored policy data.
  ///
  /// Returns [Ok<void>] on success or [Err<StorageFailure>] on failure.
  Future<Result<void, DomainFailure>> clear();
}
