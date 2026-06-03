import 'package:flutter_policy_engine/src/application/ports/i_asset_loader.dart';
import 'package:flutter_policy_engine/src/application/use_cases/load_policies_from_asset.dart';
import 'package:flutter_policy_engine/src/application/use_cases/load_policies_from_map.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/repositories/i_policy_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

class _MockRepository extends Mock implements IPolicyRepository {}

class _MockAssetLoader extends Mock implements IAssetLoader {}

const _validJson = '''
{
  "roles": {
    "admin": {
      "allowedResources": ["dashboard", "users"]
    },
    "user": {
      "allowedResources": ["dashboard"]
    }
  }
}
''';

void main() {
  setUpAll(registerFallbackValues);

  late _MockRepository repository;

  setUp(() {
    repository = _MockRepository();
    when(() => repository.save(any())).thenAnswer((_) async => const Ok(null));
  });

  group('LoadPoliciesFromMap', () {
    late LoadPoliciesFromMap useCase;

    setUp(() {
      useCase = LoadPoliciesFromMap(repository: repository);
    });

    test('saves parsed roles to repository', () async {
      final result = await useCase.call({
        'roles': {
          'admin': {
            'allowedResources': ['dashboard', 'users'],
          },
        },
      });

      expect(result.isOk, isTrue);
      verify(() => repository.save(any())).called(1);
    });

    test('returns ParseFailure when roles key is missing', () async {
      final result = await useCase
          .call(<String, dynamic>{'wrong_key': <String, dynamic>{}});

      expect(result.isErr, isTrue);
      expect(result, isA<Err<void, DomainFailure>>());
      final err = result as Err<void, DomainFailure>;
      expect(err.error, isA<ParseFailure>());
    });

    test('returns ParseFailure for empty map', () async {
      final result = await useCase.call({});

      expect(result.isErr, isTrue);
    });

    test('skips invalid role entries and loads valid ones', () async {
      final result = await useCase.call(<String, dynamic>{
        'roles': <String, dynamic>{
          '': <String, dynamic>{'allowedResources': <String>[]},
          'admin': <String, dynamic>{
            'allowedResources': <String>['dashboard'],
          },
        },
      });

      expect(result.isOk, isTrue);
      verify(() => repository.save(any())).called(1);
    });
  });

  group('LoadPoliciesFromAsset', () {
    late _MockAssetLoader assetLoader;
    late LoadPoliciesFromAsset useCase;

    setUp(() {
      assetLoader = _MockAssetLoader();
      useCase = LoadPoliciesFromAsset(
        repository: repository,
        assetLoader: assetLoader,
      );
    });

    test('loads asset, parses, and saves policy', () async {
      when(() => assetLoader.load(any()))
          .thenAnswer((_) async => const Ok(_validJson));

      final result = await useCase.call('assets/policies.json');

      expect(result.isOk, isTrue);
      verify(() => assetLoader.load('assets/policies.json')).called(1);
      verify(() => repository.save(any())).called(1);
    });

    test('returns StorageFailure when asset cannot be read', () async {
      when(() => assetLoader.load(any())).thenAnswer(
        (_) async => const Err(StorageFailure('not found')),
      );

      final result = await useCase.call('missing.json');

      expect(result.isErr, isTrue);
      expect((result as Err).error, isA<StorageFailure>());
    });

    test('returns ParseFailure when asset JSON is malformed', () async {
      when(() => assetLoader.load(any()))
          .thenAnswer((_) async => const Ok('not json'));

      final result = await useCase.call('bad.json');

      expect(result.isErr, isTrue);
    });
  });
}
