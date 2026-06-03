// ignore_for_file: public_member_api_docs

/// Contract tests for `IAssetLoader`.
///
/// Usage: provide a `factory` that returns a loader pre-configured with a
/// known asset path mapped to known content. Also provide `validAssetPath`
/// and `expectedContent` so the contract can verify correctness.
///
/// ```dart
/// void main() {
///   runAssetLoaderContractTests(
///     factory: () => FakeAssetLoader({'p.json': '{"roles": {}}'}),
///     validAssetPath: 'p.json',
///     expectedContent: '{"roles": {}}',
///   );
/// }
/// ```
library asset_loader_contract;

import 'package:flutter_policy_engine/src/application/ports/i_asset_loader.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs the full [IAssetLoader] contract test suite.
void runAssetLoaderContractTests({
  required IAssetLoader Function() factory,
  required String validAssetPath,
  required String expectedContent,
}) {
  late IAssetLoader loader;

  setUp(() {
    loader = factory();
  });

  group('IAssetLoader contract', () {
    test('load returns Ok with content for valid path', () async {
      final result = await loader.load(validAssetPath);

      expect(result.isOk, isTrue);
      expect(result.getOrElse(''), equals(expectedContent));
    });

    test('load returns Err<StorageFailure> for missing asset', () async {
      final result = await loader.load('__non_existent__.json');

      expect(result.isErr, isTrue);
      expect((result as Err).error, isA<StorageFailure>());
    });
  });
}
