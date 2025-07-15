import 'package:flutter_policy_engine/src/core/interfaces/i_policy_storage.dart';

/// An in-memory implementation of [IPolicyStorage] that stores policies
/// in a Map during the application's runtime.
///
/// This storage implementation is suitable for:
/// - Testing scenarios where persistence is not required
/// - Temporary policy storage during development
/// - Cases where policies are loaded at startup and don't need to persist
///   between application sessions
///
/// **Note:** All data stored in this implementation will be lost when the
/// application is terminated or the object is garbage collected.
class MemoryPolicyStorage implements IPolicyStorage {
  /// Internal storage for policies using a Map with String keys and dynamic values.
  ///
  /// The Map structure allows for flexible policy storage where keys represent
  /// policy identifiers and values contain the policy data.
  Map<String, dynamic> _policies = {};

  /// Loads all stored policies from memory.
  ///
  /// Returns a copy of the internal policies map to prevent external
  /// modifications from affecting the internal state.
  ///
  /// **Returns:** A [Future] that completes with a [Map<String, dynamic>]
  /// containing all stored policies.
  ///
  /// **Example:**
  /// ```dart
  /// final storage = MemoryPolicyStorage();
  /// final policies = await storage.loadPolicies();
  /// print('Loaded ${policies.length} policies');
  /// ```
  @override
  Future<Map<String, dynamic>> loadPolicies() async {
    return Map.from(_policies);
  }

  /// Saves the provided policies to memory storage.
  ///
  /// Creates a deep copy of the input policies to ensure the internal
  /// storage is not affected by subsequent modifications to the input map.
  ///
  /// **Parameters:**
  /// - [policies]: A [Map<String, dynamic>] containing the policies to store.
  ///   Keys should be policy identifiers and values should contain policy data.
  ///
  /// **Example:**
  /// ```dart
  /// final storage = MemoryPolicyStorage();
  /// final policies = {'user_policy': {'role': 'admin'}};
  /// await storage.savePolicies(policies);
  /// ```
  @override
  Future<void> savePolicies(Map<String, dynamic> policies) async {
    _policies = Map.from(policies);
  }

  /// Removes all stored policies from memory.
  ///
  /// This operation is immediate and irreversible. All policy data
  /// will be permanently lost after calling this method.
  ///
  /// **Example:**
  /// ```dart
  /// final storage = MemoryPolicyStorage();
  /// await storage.clearPolicies();
  /// // All policies have been removed
  /// ```
  @override
  Future<void> clearPolicies() async {
    _policies.clear();
  }
}
