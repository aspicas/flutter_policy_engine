import 'package:flutter_policy_engine/src/domain/entities/policy.dart';
import 'package:flutter_policy_engine/src/domain/entities/role_entity.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/repositories/i_policy_repository.dart';

/// An in-memory [IPolicyRepository] implementation.
///
/// Stores policies for the object's lifetime. Suitable for:
/// - Unit and integration testing.
/// - Applications that reload policies on each startup.
///
/// Data is lost when the instance is garbage collected.
/// This implementation has no Flutter dependencies and is safe for pure Dart.
final class InMemoryPolicyRepository implements IPolicyRepository {
  /// Creates an [InMemoryPolicyRepository] with an optional initial policy.
  InMemoryPolicyRepository({Policy? initialPolicy})
      : _policy = initialPolicy ?? const Policy(roles: {});

  Policy _policy;

  @override
  Future<Result<void, DomainFailure>> save(Policy policy) async {
    _policy = policy;
    return const Ok(null);
  }

  @override
  Future<Result<Policy, DomainFailure>> load() async {
    return Ok(_deepCopy(_policy));
  }

  @override
  Future<Result<void, DomainFailure>> clear() async {
    _policy = const Policy(roles: {});
    return const Ok(null);
  }

  /// Returns a deep copy so external mutations don't affect stored state.
  Policy _deepCopy(Policy policy) => Policy(
        roles: {
          for (final entry in policy.roles.entries)
            entry.key: RoleEntity(
              name: entry.value.name,
              allowedResources: Set.unmodifiable(entry.value.allowedResources),
            ),
        },
      );
}
