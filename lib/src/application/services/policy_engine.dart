import 'package:flutter_policy_engine/src/application/ports/i_asset_loader.dart';
import 'package:flutter_policy_engine/src/application/ports/i_logger.dart';
import 'package:flutter_policy_engine/src/application/use_cases/add_role.dart';
import 'package:flutter_policy_engine/src/application/use_cases/evaluate_access.dart';
import 'package:flutter_policy_engine/src/application/use_cases/list_roles.dart';
import 'package:flutter_policy_engine/src/application/use_cases/load_policies_from_asset.dart';
import 'package:flutter_policy_engine/src/application/use_cases/load_policies_from_map.dart';
import 'package:flutter_policy_engine/src/application/use_cases/remove_role.dart';
import 'package:flutter_policy_engine/src/application/use_cases/update_role.dart';
import 'package:flutter_policy_engine/src/domain/entities/access_decision.dart';
import 'package:flutter_policy_engine/src/domain/entities/role_entity.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/repositories/i_policy_repository.dart';
import 'package:flutter_policy_engine/src/domain/services/composite_evaluator.dart';
import 'package:flutter_policy_engine/src/domain/services/rbac_evaluator.dart';

/// The application facade for the policy engine.
///
/// Orchestrates all use cases. Create via [PolicyEngine.withRepository]:
/// ```dart
/// final engine = PolicyEngine.withRepository(
///   repository: InMemoryPolicyRepository(),
/// );
/// ```
final class PolicyEngine {
  /// Creates a [PolicyEngine] with explicit dependencies.
  PolicyEngine.withRepository({
    required IPolicyRepository repository,
    ILogger? logger,
    IAssetLoader? assetLoader,
  })  : _evaluateAccess = EvaluateAccess(
          repository: repository,
          evaluator: CompositeEvaluator(
            evaluators: const [RbacEvaluator()],
            strategy: CompositeStrategy.denyOverrides,
          ),
        ),
        _loadFromMap = LoadPoliciesFromMap(
          repository: repository,
          logger: logger,
        ),
        _loadFromAsset = assetLoader != null
            ? LoadPoliciesFromAsset(
                repository: repository,
                assetLoader: assetLoader,
                logger: logger,
              )
            : null,
        _addRole = AddRole(repository: repository),
        _updateRole = UpdateRole(repository: repository),
        _removeRole = RemoveRole(repository: repository),
        _listRoles = ListRoles(repository: repository);

  final EvaluateAccess _evaluateAccess;
  final LoadPoliciesFromMap _loadFromMap;
  final LoadPoliciesFromAsset? _loadFromAsset;
  final AddRole _addRole;
  final UpdateRole _updateRole;
  final RemoveRole _removeRole;
  final ListRoles _listRoles;

  /// Evaluates whether [roleName] can access [resourceId].
  Future<Result<AccessDecision, DomainFailure>> evaluateAccess(
    String roleName,
    String resourceId,
  ) =>
      _evaluateAccess.call(roleName, resourceId);

  /// Loads policies from an in-memory [policyMap] (v2 schema).
  Future<Result<void, DomainFailure>> loadPolicies(
    Map<String, dynamic> policyMap,
  ) =>
      _loadFromMap.call(policyMap);

  /// Loads policies from the asset at [assetPath].
  ///
  /// Returns [Err<InvalidPolicyFailure>] when no [IAssetLoader] was provided.
  Future<Result<void, DomainFailure>> loadPoliciesFromAsset(
    String assetPath,
  ) async {
    if (_loadFromAsset == null) {
      return const Err(
        InvalidPolicyFailure('No IAssetLoader was provided to PolicyEngine'),
      );
    }
    return _loadFromAsset.call(assetPath);
  }

  /// Adds or replaces [role] in the repository.
  Future<Result<void, DomainFailure>> addRole(RoleEntity role) =>
      _addRole.call(role);

  /// Replaces the role named [roleName] with [newRole].
  Future<Result<void, DomainFailure>> updateRole(
    String roleName,
    RoleEntity newRole,
  ) =>
      _updateRole.call(roleName, newRole);

  /// Removes the role named [roleName] from the repository.
  Future<Result<void, DomainFailure>> removeRole(String roleName) =>
      _removeRole.call(roleName);

  /// Returns all currently loaded roles.
  Future<Result<List<RoleEntity>, DomainFailure>> listRoles() =>
      _listRoles.call();
}
