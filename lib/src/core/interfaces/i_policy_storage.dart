import 'package:meta/meta.dart';

/// Abstract interface for policy storage operations.
///
/// This interface defines the contract for storing and retrieving policy data
/// in the Flutter Policy Engine. Implementations can provide different storage
/// backends such as local file storage, secure storage, or remote storage.
///
/// All methods are asynchronous to support various storage mechanisms that
/// may require I/O operations.
@immutable
abstract class IPolicyStorage {
  /// Loads all policies from storage.
  ///
  /// Returns a [Map<String, dynamic>] containing the policy data where:
  /// - Keys represent policy identifiers
  /// - Values represent the policy configuration and rules
  ///
  /// Throws a [StateError] if the storage is not accessible or corrupted.
  /// Returns an empty map if no policies are stored.
  Future<Map<String, dynamic>> loadPolicies();

  /// Saves policies to storage.
  ///
  /// [policies] should be a [Map<String, dynamic>] where:
  /// - Keys represent policy identifiers
  /// - Values represent the policy configuration and rules
  ///
  /// This method will overwrite any existing policies in storage.
  /// Throws a [StateError] if the storage is not writable or if the data
  /// format is invalid.
  Future<void> savePolicies(Map<String, dynamic> policies);

  /// Removes all policies from storage.
  ///
  /// This operation is irreversible and will permanently delete all stored
  /// policy data. Use with caution.
  ///
  /// Throws a [StateError] if the storage is not accessible or if the
  /// clear operation fails.
  Future<void> clearPolicies();
}
