import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contract/asset_loader_contract.dart';
import '../../helpers/fakes.dart';

const _validJson = '{"roles": {"admin": {"allowedResources": ["dashboard"]}}}';

void main() {
  group('FakeAssetLoader', () {
    runAssetLoaderContractTests(
      factory: () => const FakeAssetLoader({'policies.json': _validJson}),
      validAssetPath: 'policies.json',
      expectedContent: _validJson,
    );

    test('returns StorageFailure for missing key', () async {
      const loader = FakeAssetLoader({'other.json': '{}'});
      final result = await loader.load('missing.json');
      expect(result.isErr, isTrue);
      expect((result as Err).error, isA<StorageFailure>());
    });
  });
}
