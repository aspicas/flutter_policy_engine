import 'package:flutter/foundation.dart';
import 'package:flutter_policy_engine/src/core/interfaces/i_policy_evaluator.dart';
import 'package:flutter_policy_engine/src/core/interfaces/i_policy_storage.dart';
import 'package:flutter_policy_engine/src/core/memory_policy_storage.dart';
import 'package:flutter_policy_engine/src/core/role_evaluator.dart';
import 'package:flutter_policy_engine/src/models/policy.dart';
import 'package:flutter_policy_engine/src/utils/json_handler.dart';
import 'package:flutter_policy_engine/src/utils/log_handler.dart';

/// Manages policy lifecycle and provides centralized access to policy operations.
///
/// The [PolicyManager] serves as the main entry point for policy-related operations,
/// coordinating between storage, evaluation, and policy state management. It extends
/// [ChangeNotifier] to notify listeners of policy state changes.
///
/// Example usage:
/// ```dart
/// final policyManager = PolicyManager(
///   storage: MyPolicyStorage(),
///   evaluator: MyPolicyEvaluator(),
/// );
///
/// await policyManager.initialize(policyJsonData);
/// ```
class PolicyManager extends ChangeNotifier {
  /// Creates a new [PolicyManager] instance.
  ///
  /// [storage] is responsible for persisting and retrieving policy data.
  /// [evaluator] handles policy evaluation logic and decision making.
  PolicyManager({
    IPolicyStorage? storage,
    IPolicyEvaluator? evaluator,
  })  : _storage = storage ?? MemoryPolicyStorage(),
        _evaluator = evaluator;

  /// The storage implementation for policy persistence.
  final IPolicyStorage _storage;

  /// The evaluator implementation for policy decision making.
  IPolicyEvaluator? _evaluator;

  /// Internal cache of loaded policies, keyed by policy identifier.
  Map<String, Policy> _policies = {};

  /// Indicates whether the policy manager has been initialized with policy data.
  bool _isInitialized = false;

  /// Returns whether the policy manager has been initialized.
  ///
  /// Returns `true` if [initialize] has been called successfully, `false` otherwise.
  bool get isInitialized => _isInitialized;

  /// Returns an unmodifiable view of all loaded policies.
  ///
  /// The returned map cannot be modified directly. Use [initialize] to update
  /// the policy collection.
  Map<String, Policy> get policies => Map.unmodifiable(_policies);

  /// Initializes the policy manager with policy data from JSON.
  ///
  /// Parses the provided [jsonPolicies] and loads them into the internal cache.
  /// This method should be called before using any policy-related functionality.
  ///
  /// [jsonPolicies] should be a map where keys are policy identifiers and values
  /// are JSON representations of [Policy] objects.
  ///
  /// Throws:
  /// - [JsonParseException] if policy parsing fails completely
  /// - [FormatException] if the JSON data is malformed
  /// - [ArgumentError] if policy parsing fails
  Future<void> initialize(Map<String, dynamic> jsonPolicies) async {
    try {
      LogHandler.info(
        'Initializing policy manager',
        context: {
          'policy_count': jsonPolicies.length,
          'policy_keys': jsonPolicies.keys.take(5).toList(),
        },
        operation: 'policy_manager_initialize',
      );

      _policies = JsonHandler.parseMap(
        jsonPolicies,
        (json) => Policy.fromJson(json),
        context: 'policy_manager',
        allowPartialSuccess:
            true, // Allow partial success for graceful degradation
      );

      // Only create evaluator if we have at least some policies
      if (_policies.isNotEmpty) {
        _evaluator = RoleEvaluator(_policies);
        await _storage.savePolicies(_policies);
        _isInitialized = true;

        LogHandler.info(
          'Policy manager initialized successfully',
          context: {
            'loaded_policies': _policies.length,
            'total_policies': jsonPolicies.length,
          },
          operation: 'policy_manager_initialized',
        );
      } else {
        LogHandler.warning(
          'Policy manager initialized with no valid policies',
          context: {
            'total_policies': jsonPolicies.length,
          },
          operation: 'policy_manager_empty',
        );
        // Still mark as initialized but with empty policies
        _isInitialized = true;
      }

      notifyListeners();
    } catch (e, stackTrace) {
      LogHandler.error(
        'Failed to initialize policy manager',
        error: e,
        stackTrace: stackTrace,
        context: {
          'policy_count': jsonPolicies.length,
        },
        operation: 'policy_manager_initialize_error',
      );

      // Re-throw to allow caller to handle the error
      rethrow;
    }
  }
}
