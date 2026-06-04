import 'package:flutter_policy_engine/src/domain/entities/access_decision.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/repositories/i_policy_repository.dart';
import 'package:flutter_policy_engine/src/domain/services/policy_evaluator.dart';

/// Evaluates whether a role is allowed to access a resource.
///
/// Loads the current policy from the repository and delegates the decision
/// to the evaluator.
final class EvaluateAccess {
  /// Creates an [EvaluateAccess] use case.
  const EvaluateAccess({
    required IPolicyRepository repository,
    required PolicyEvaluator evaluator,
  })  : _repository = repository,
        _evaluator = evaluator;

  final IPolicyRepository _repository;
  final PolicyEvaluator _evaluator;

  /// Returns an [AccessDecision] for [roleName] accessing [resourceId].
  ///
  /// Returns [Err] propagating any [DomainFailure] from the repository.
  Future<Result<AccessDecision, DomainFailure>> call(
    String roleName,
    String resourceId,
  ) async {
    final loadResult = await _repository.load();
    return switch (loadResult) {
      Err(:final error) => Err(error),
      Ok(:final value) => Ok(_evaluator.evaluate(roleName, resourceId, value)),
    };
  }
}
