import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';

/// Contract for loading raw text assets by path.
///
/// The default Flutter implementation (`FlutterAssetLoader`) uses
/// `rootBundle`. In tests, inject a fake that returns JSON strings directly.
abstract interface class IAssetLoader {
  /// Loads the text content of the asset at [assetPath].
  ///
  /// Returns [Ok<String>] with the raw text content, or
  /// [Err<StorageFailure>] when the asset cannot be read.
  Future<Result<String, DomainFailure>> load(String assetPath);
}
