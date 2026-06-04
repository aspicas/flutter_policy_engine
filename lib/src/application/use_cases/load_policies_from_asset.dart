import 'package:flutter_policy_engine/src/application/ports/i_asset_loader.dart';
import 'package:flutter_policy_engine/src/application/ports/i_logger.dart';
import 'package:flutter_policy_engine/src/application/services/policy_json_codec.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/repositories/i_policy_repository.dart';

/// Loads and persists policies from a JSON asset file.
///
/// Reads the asset via [IAssetLoader], decodes with [PolicyJsonCodec], and
/// persists to [IPolicyRepository].
final class LoadPoliciesFromAsset {
  /// Creates a [LoadPoliciesFromAsset] use case.
  const LoadPoliciesFromAsset({
    required IPolicyRepository repository,
    required IAssetLoader assetLoader,
    ILogger? logger,
  })  : _repository = repository,
        _assetLoader = assetLoader,
        _logger = logger;

  final IPolicyRepository _repository;
  final IAssetLoader _assetLoader;
  final ILogger? _logger;
  static const _codec = PolicyJsonCodec();

  /// Loads the asset at [assetPath] and saves the parsed policy.
  ///
  /// Returns [Err<StorageFailure>] when the asset cannot be read.
  /// Returns [Err<ParseFailure>] when the JSON is malformed.
  Future<Result<void, DomainFailure>> call(String assetPath) async {
    final loadResult = await _assetLoader.load(assetPath);
    if (loadResult.isErr) return loadResult.mapOk((_) {});

    final source = (loadResult as Ok<String, DomainFailure>).value;

    final decodeResult = _codec.decode(
      source,
      onWarning: (msg) => _logger?.warning(
        msg,
        operation: 'LoadPoliciesFromAsset',
      ),
    );

    return switch (decodeResult) {
      Err(:final error) => Err(error),
      Ok(:final value) => _repository.save(value),
    };
  }
}
