import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/repositories/i_policy_repository.dart';

/// Removes a role by name from the policy store.
///
/// No-op if the role does not exist.
final class RemoveRole {
  /// Creates a [RemoveRole] use case.
  const RemoveRole({required IPolicyRepository repository})
      : _repository = repository;

  final IPolicyRepository _repository;

  /// Removes the role named [roleName] from the repository.
  ///
  /// Returns [Err<InvalidPolicyFailure>] if [roleName] is empty.
  Future<Result<void, DomainFailure>> call(String roleName) async {
    if (roleName.trim().isEmpty) {
      return const Err(InvalidPolicyFailure('Role name cannot be empty'));
    }

    final loadResult = await _repository.load();
    return switch (loadResult) {
      Err(:final error) => Err(error),
      Ok(:final value) => _repository.save(value.withoutRole(roleName)),
    };
  }
}
