import 'package:flutter/foundation.dart';
import 'package:flutter_policy_engine/src/application/ports/i_asset_loader.dart';
import 'package:flutter_policy_engine/src/application/ports/i_logger.dart';
import 'package:flutter_policy_engine/src/application/services/policy_engine.dart';
import 'package:flutter_policy_engine/src/domain/entities/access_decision.dart';
import 'package:flutter_policy_engine/src/domain/entities/role_entity.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/repositories/i_policy_repository.dart';
import 'package:flutter_policy_engine/src/infrastructure/logging/noop_logger.dart';
import 'package:flutter_policy_engine/src/infrastructure/storage/in_memory_policy_repository.dart';

/// Mutable state controller for the policy engine.
///
/// Wraps [PolicyEngine] and exposes reactive state for the widget tree.
/// Notify listeners after any mutation so [PolicyEngineScope] rebuilds its
/// dependants automatically.
final class PolicyEngineController extends ChangeNotifier {
  /// Creates a [PolicyEngineController] with an explicit [engine].
  PolicyEngineController({required PolicyEngine engine}) : _engine = engine;

  /// Creates a [PolicyEngineController] using an in-memory repository.
  ///
  /// Suitable for most cases where persistence across app restarts is not
  /// required.
  factory PolicyEngineController.inMemory({
    ILogger? logger,
    IAssetLoader? assetLoader,
  }) {
    return PolicyEngineController(
      engine: PolicyEngine.withRepository(
        repository: InMemoryPolicyRepository(),
        logger: logger ?? const NoopLogger(),
        assetLoader: assetLoader,
      ),
    );
  }

  /// Creates a [PolicyEngineController] with a custom [IPolicyRepository].
  factory PolicyEngineController.withRepository({
    required IPolicyRepository repository,
    ILogger? logger,
    IAssetLoader? assetLoader,
  }) {
    return PolicyEngineController(
      engine: PolicyEngine.withRepository(
        repository: repository,
        logger: logger ?? const NoopLogger(),
        assetLoader: assetLoader,
      ),
    );
  }

  final PolicyEngine _engine;

  bool _initialized = false;

  /// Whether the controller has been initialised with at least one policy load.
  bool get isInitialized => _initialized;

  /// Loads policies from an in-memory [policyMap] (v2 schema).
  ///
  /// Notifies listeners on success.
  Future<Result<void, DomainFailure>> loadPolicies(
    Map<String, dynamic> policyMap,
  ) async {
    final result = await _engine.loadPolicies(policyMap);
    if (result.isOk) {
      _initialized = true;
      notifyListeners();
    }
    return result;
  }

  /// Loads policies from the Flutter asset at [assetPath].
  ///
  /// Notifies listeners on success. Requires an [IAssetLoader] to have been
  /// provided at construction time.
  Future<Result<void, DomainFailure>> loadPoliciesFromAsset(
    String assetPath,
  ) async {
    final result = await _engine.loadPoliciesFromAsset(assetPath);
    if (result.isOk) {
      _initialized = true;
      notifyListeners();
    }
    return result;
  }

  /// Evaluates whether [roleName] can access [resourceId].
  ///
  /// Returns [Err<EngineNotInitializedFailure>] when the controller has not
  /// been initialised yet.
  Future<Result<AccessDecision, DomainFailure>> evaluateAccess(
    String roleName,
    String resourceId,
  ) {
    if (!_initialized) {
      return Future.value(
        const Err(
          EngineNotInitializedFailure(
            'Call loadPolicies or loadPoliciesFromAsset before evaluating.',
          ),
        ),
      );
    }
    return _engine.evaluateAccess(roleName, resourceId);
  }

  /// Adds or replaces [role] in the repository and notifies listeners.
  Future<Result<void, DomainFailure>> addRole(RoleEntity role) async {
    final result = await _engine.addRole(role);
    if (result.isOk) notifyListeners();
    return result;
  }

  /// Replaces the role named [roleName] with [newRole] and notifies listeners.
  Future<Result<void, DomainFailure>> updateRole(
    String roleName,
    RoleEntity newRole,
  ) async {
    final result = await _engine.updateRole(roleName, newRole);
    if (result.isOk) notifyListeners();
    return result;
  }

  /// Removes the role named [roleName] and notifies listeners.
  Future<Result<void, DomainFailure>> removeRole(String roleName) async {
    final result = await _engine.removeRole(roleName);
    if (result.isOk) notifyListeners();
    return result;
  }

  /// Returns all currently loaded roles.
  Future<Result<List<RoleEntity>, DomainFailure>> listRoles() =>
      _engine.listRoles();
}
