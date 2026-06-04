// ignore_for_file: public_member_api_docs

/// Shared fake/stub implementations and mocktail fallback registrations.
///
/// Call [registerFallbackValues] in `setUpAll` or at the top of `main` in
/// any test file that uses `mocktail` with custom domain types.
library fakes;

import 'package:flutter_policy_engine/src/application/ports/i_asset_loader.dart'
    show IAssetLoader;
import 'package:flutter_policy_engine/src/application/ports/i_asset_loader.dart';
import 'package:flutter_policy_engine/src/domain/entities/access_decision.dart';
import 'package:flutter_policy_engine/src/domain/entities/policy.dart';
import 'package:flutter_policy_engine/src/domain/entities/role_entity.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/value_objects/role_name.dart';
import 'package:mocktail/mocktail.dart';

/// Registers mocktail fallback values for all custom domain types.
///
/// Must be called before any `any()` matcher is used with these types.
void registerFallbackValues() {
  registerFallbackValue(const Policy(roles: {}));
  registerFallbackValue(
    RoleEntity(
      name: RoleName('_fallback'),
      allowedResources: const {},
    ),
  );
  registerFallbackValue(const AccessDecision.granted());
  registerFallbackValue(const PolicyNotFoundFailure('_fallback'));
}

/// A fake [IAssetLoader] that returns preset content from a map.
///
/// Used in contract tests and unit tests for asset loading.
final class FakeAssetLoader implements IAssetLoader {
  /// Creates a [FakeAssetLoader] with an asset map from paths to content.
  const FakeAssetLoader(this._assets);

  final Map<String, String> _assets;

  @override
  Future<Result<String, DomainFailure>> load(String assetPath) async {
    final content = _assets[assetPath];
    if (content == null) {
      return Err(
        StorageFailure('Asset not found: $assetPath'),
      );
    }
    return Ok(content);
  }
}
