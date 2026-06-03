// BDD feature tests for spec-003-policy-loading.md

import 'package:flutter_policy_engine/src/application/services/policy_json_codec.dart';
import 'package:flutter_policy_engine/src/domain/entities/policy.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bdd.dart';

const _validV2Json = '''
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
  const codec = PolicyJsonCodec();

  group('Feature: Policy Loading (spec-003)', () {
    group('Scenario: valid v2 JSON is decoded', () {
      test(
          'Given valid v2 JSON, '
          'When decoded, Then all roles are available', () {
        given('valid v2 JSON with admin and user roles')
            .when(
          'decoding',
          () => codec.decode(_validV2Json),
        )
            .then('policy contains admin and user roles', (result) {
          expect(result.isOk, isTrue);
          final policy = result.getOrElse(const Policy(roles: {}));
          expect(policy.roleFor('admin'), isNotNull);
          expect(policy.roleFor('user'), isNotNull);
        });
      });
    });

    group('Scenario: missing roles key', () {
      test(
          'Given JSON without "roles" key, '
          'When decoded, Then ParseFailure is returned', () {
        given('JSON without roles key')
            .when(
          'decoding',
          () => codec.decode('{"wrong": {}}'),
        )
            .then('ParseFailure is returned', (result) {
          expect(result.isErr, isTrue);
          expect((result as Err<Policy, DomainFailure>).error,
              isA<ParseFailure>(),);
        });
      });
    });

    group('Scenario: malformed JSON', () {
      test(
          'Given invalid JSON string, '
          'When decoded, Then ParseFailure is returned', () {
        given('invalid JSON')
            .when(
          'decoding',
          () => codec.decode('not json at all'),
        )
            .then('ParseFailure is returned', (result) {
          expect(result.isErr, isTrue);
          expect(
            (result as Err<Policy, DomainFailure>).error,
            isA<ParseFailure>(),
          );
        });
      });
    });

    group('Scenario: partial success with invalid role entries', () {
      test(
          'Given JSON with one invalid and one valid role, '
          'When decoded, Then valid role is loaded', () {
        const partialJson = '''
{
  "roles": {
    "": {"allowedResources": []},
    "admin": {"allowedResources": ["dashboard"]}
  }
}
''';
        given('JSON with empty-name role and valid admin')
            .when(
          'decoding',
          () => codec.decode(partialJson),
        )
            .then('admin role is loaded, empty name is skipped', (result) {
          expect(result.isOk, isTrue);
          final policy = result.getOrElse(const Policy(roles: {}));
          expect(policy.roleFor('admin'), isNotNull);
          expect(policy.roles.length, equals(1));
        });
      });
    });

    group('Scenario: round-trip encode/decode', () {
      test(
          'Given a decoded policy, '
          'When re-encoded and decoded again, Then data is preserved', () {
        final decodeResult = codec.decode(_validV2Json);
        final policy = decodeResult.getOrElse(const Policy(roles: {}));
        final encoded = codec.encode(policy);
        final roundTripped = codec.decode(encoded);

        expect(roundTripped.isOk, isTrue);
        final rt = roundTripped.getOrElse(const Policy(roles: {}));
        expect(rt.roleFor('admin'), isNotNull);
        expect(
          rt.roleFor('admin')!.allowedResources,
          containsAll(['dashboard', 'users']),
        );
      });
    });

    group('Scenario: unknown keys are ignored', () {
      test(
          'Given JSON with extra unknown keys, '
          'When decoded, Then known roles are loaded without error', () {
        const jsonWithExtras = '''
{
  "roles": {
    "admin": {
      "allowedResources": ["dashboard"],
      "future_field": "ignored",
      "metadata": {"env": "prod"}
    }
  },
  "version": 2,
  "description": "test policies"
}
''';
        given('JSON with extra unknown keys')
            .when(
          'decoding',
          () => codec.decode(jsonWithExtras),
        )
            .then('admin role is loaded normally', (result) {
          expect(result.isOk, isTrue);
          final policy = result.getOrElse(const Policy(roles: {}));
          expect(policy.roleFor('admin'), isNotNull);
        });
      });
    });
  });
}
