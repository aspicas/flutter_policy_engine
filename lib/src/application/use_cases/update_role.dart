import 'package:flutter_policy_engine/src/application/use_cases/add_role.dart'
    show AddRole;
import 'package:flutter_policy_engine/src/domain/entities/role_entity.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/repositories/i_policy_repository.dart';

/// Replaces an existing role by name, or adds it if it does not yet exist.
///
/// Semantically equivalent to [AddRole] with an explicit name override.
final class UpdateRole {
  /// Creates an [UpdateRole] use case.
  const UpdateRole({required IPolicyRepository repository})
      : _repository = repository;

  final IPolicyRepository _repository;

  /// Updates the role named [roleName] with [newRole] data.
  ///
  /// If [roleName] does not exist, [newRole] is added.
  Future<Result<void, DomainFailure>> call(
    String roleName,
    RoleEntity newRole,
  ) async {
    final loadResult = await _repository.load();
    return switch (loadResult) {
      Err(:final error) => Err(error),
      Ok(:final value) => _repository.save(
          value.withoutRole(roleName).withRole(newRole),
        ),
    };
  }
}
