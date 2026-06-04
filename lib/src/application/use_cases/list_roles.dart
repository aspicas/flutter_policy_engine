import 'package:flutter_policy_engine/src/domain/entities/role_entity.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/repositories/i_policy_repository.dart';

/// Returns all currently loaded [RoleEntity] objects from the repository.
final class ListRoles {
  /// Creates a [ListRoles] use case.
  const ListRoles({required IPolicyRepository repository})
      : _repository = repository;

  final IPolicyRepository _repository;

  /// Loads and returns all roles as an unmodifiable list.
  ///
  /// Returns an empty list when no policies have been loaded.
  Future<Result<List<RoleEntity>, DomainFailure>> call() async {
    final loadResult = await _repository.load();
    return switch (loadResult) {
      Err(:final error) => Err(error),
      Ok(:final value) => Ok(List.unmodifiable(value.roles.values.toList())),
    };
  }
}
