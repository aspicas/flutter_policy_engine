import 'package:flutter_policy_engine/src/domain/entities/role_entity.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/repositories/i_policy_repository.dart';

/// Adds a [RoleEntity] to the policy store, overwriting any existing role
/// with the same name.
final class AddRole {
  /// Creates an [AddRole] use case.
  const AddRole({required IPolicyRepository repository})
      : _repository = repository;

  final IPolicyRepository _repository;

  /// Adds or replaces [role] in the repository.
  Future<Result<void, DomainFailure>> call(RoleEntity role) async {
    final loadResult = await _repository.load();
    return switch (loadResult) {
      Err(:final error) => Err(error),
      Ok(:final value) => _repository.save(value.withRole(role)),
    };
  }
}
