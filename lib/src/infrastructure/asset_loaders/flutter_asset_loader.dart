import 'package:flutter/services.dart';
import 'package:flutter_policy_engine/src/application/ports/i_asset_loader.dart';
import 'package:flutter_policy_engine/src/application/use_cases/load_policies_from_asset.dart'
    show LoadPoliciesFromAsset;
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';

/// An [IAssetLoader] that reads Flutter asset bundle files via [rootBundle].
///
/// Inject this into [LoadPoliciesFromAsset] to load JSON policy files declared
/// in `pubspec.yaml` under the `flutter.assets` section.
final class FlutterAssetLoader implements IAssetLoader {
  /// Creates a [FlutterAssetLoader] using the default [rootBundle].
  const FlutterAssetLoader();

  @override
  Future<Result<String, DomainFailure>> load(String assetPath) async {
    try {
      final content = await rootBundle.loadString(assetPath);
      return Ok(content);
    } catch (e) {
      return Err(
        StorageFailure(
          'Failed to load asset "$assetPath": $e',
          cause: e,
        ),
      );
    }
  }
}
