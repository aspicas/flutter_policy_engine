import 'package:flutter/foundation.dart';
import 'package:flutter_policy_engine/src/core/interfaces/i_policy_evaluator.dart';
import 'package:flutter_policy_engine/src/core/interfaces/i_policy_storage.dart';
import 'package:flutter_policy_engine/src/core/memory_policy_storage.dart';
import 'package:flutter_policy_engine/src/core/role_evaluator.dart';
import 'package:flutter_policy_engine/src/models/role.dart';
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
  Map<String, Role> _roles = {};

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
  Map<String, Role> get roles => Map.unmodifiable(_roles);

  /// Initializes the policy manager with policy data from JSON.
  ///
  /// Parses the provided [jsonPolicies] and loads them into the internal cache.
  /// This method should be called before using any policy-related functionality.
  ///
  /// [jsonPolicies] should be a map where keys are policy identifiers and values
  /// are JSON representations of [Role] objects.
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

      // Create a map of valid policies, skipping invalid ones
      final validPolicies = <String, Map<String, dynamic>>{};

      for (final entry in jsonPolicies.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value == null) {
          LogHandler.warning(
            'Skipping null policy value',
            context: {'role': key},
            operation: 'policy_validation_skip',
          );
          continue;
        }

        if (value is! List) {
          LogHandler.warning(
            'Skipping invalid policy value type',
            context: {
              'role': key,
              'expected_type': 'List',
              'actual_type': value.runtimeType.toString(),
            },
            operation: 'policy_validation_skip',
          );
          continue;
        }

        if (value.any((item) => item is! String)) {
          LogHandler.warning(
            'Skipping policy with non-string content items',
            context: {'role': key},
            operation: 'policy_validation_skip',
          );
          continue;
        }

        // Create the policy and add to valid policies
        final role = Role(
          name: key,
          allowedContent: value.cast<String>(),
        );
        validPolicies[key] = role.toJson();
      }

      _roles = JsonHandler.parseMap(
        validPolicies,
        (json) => Role.fromJson(json),
        context: 'policy_manager',
        allowPartialSuccess: true,
      );

      // Only create evaluator if we have at least some policies
      if (_roles.isNotEmpty) {
        _evaluator = RoleEvaluator(_roles);
        await _storage.savePolicies(_roles);
        _isInitialized = true;

        LogHandler.info(
          'Policy manager initialized successfully',
          context: {
            'loaded_policies': _roles.length,
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

  /// Checks if the specified [role] has access to the given [content].
  ///
  /// Returns `true` if the policy manager is initialized and the evaluator
  /// determines that the [role] is permitted to access the [content].
  /// Returns `false` if the policy manager is not initialized, the evaluator
  /// is not set, or if access is denied.
  ///
  /// Logs an error if called before initialization or if the evaluator is missing.
  bool hasAccess(String role, String content) {
    if (!_isInitialized || _evaluator == null) {
      LogHandler.error(
        'Policy manager not initialized or evaluator not set',
        context: {'role': role, 'content': content},
        operation: 'policy_manager_access_check',
      );
      return false;
    }
    return _evaluator!.evaluate(role, content);
  }
}
