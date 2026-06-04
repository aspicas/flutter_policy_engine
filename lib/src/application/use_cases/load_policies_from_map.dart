import 'package:flutter_policy_engine/src/application/ports/i_logger.dart';
import 'package:flutter_policy_engine/src/application/services/policy_json_codec.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/repositories/i_policy_repository.dart';

/// Loads and persists policies from an in-memory [Map<String, dynamic>].
///
/// The map must conform to the canonical v2 schema (see spec-003).
final class LoadPoliciesFromMap {
  /// Creates a [LoadPoliciesFromMap] use case.
  const LoadPoliciesFromMap({
    required IPolicyRepository repository,
    ILogger? logger,
  })  : _repository = repository,
        _logger = logger;

  final IPolicyRepository _repository;
  final ILogger? _logger;
  static const _codec = PolicyJsonCodec();

  /// Parses [policyMap] and saves to the repository.
  ///
  /// Returns [Err<ParseFailure>] when the map does not conform to the schema.
  /// Returns [Err<StorageFailure>] when the save operation fails.
  Future<Result<void, DomainFailure>> call(
    Map<String, dynamic> policyMap,
  ) async {
    if (!policyMap.containsKey('roles')) {
      return const Err(
        ParseFailure('Missing required "roles" key in policy map'),
      );
    }

    final decodeResult = _codec.decodeFromMap(
      policyMap,
      onWarning: (msg) =>
          _logger?.warning(msg, operation: 'LoadPoliciesFromMap'),
    );

    return switch (decodeResult) {
      Err(:final error) => Err(error),
      Ok(:final value) => _repository.save(value),
    };
  }
}
