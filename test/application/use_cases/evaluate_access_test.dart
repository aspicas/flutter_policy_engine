import 'package:flutter_policy_engine/src/application/use_cases/evaluate_access.dart';
import 'package:flutter_policy_engine/src/domain/entities/access_decision.dart';
import 'package:flutter_policy_engine/src/domain/entities/policy.dart';
import 'package:flutter_policy_engine/src/domain/entities/role_entity.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/repositories/i_policy_repository.dart';
import 'package:flutter_policy_engine/src/domain/services/rbac_evaluator.dart';
import 'package:flutter_policy_engine/src/domain/value_objects/role_name.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

class _MockRepository extends Mock implements IPolicyRepository {}

Policy _buildPolicy() => Policy(
      roles: {
        'admin': RoleEntity(
          name: RoleName('admin'),
          allowedResources: const {'dashboard', 'users'},
        ),
        'user': RoleEntity(
          name: RoleName('user'),
          allowedResources: const {'dashboard'},
        ),
      },
    );

void main() {
  setUpAll(registerFallbackValues);

  late _MockRepository repository;
  late EvaluateAccess useCase;

  setUp(() {
    repository = _MockRepository();
    useCase = EvaluateAccess(
      repository: repository,
      evaluator: const RbacEvaluator(),
    );
  });

  group('EvaluateAccess', () {
    test('returns granted when role has resource', () async {
      when(() => repository.load()).thenAnswer((_) async => Ok(_buildPolicy()));

      final result = await useCase.call('admin', 'dashboard');

      expect(result.isOk, isTrue);
      final decision = result.getOrElse(
        const AccessDecision.denied(
          PolicyNotFoundFailure('fallback'),
        ),
      );
      expect(decision.isGranted, isTrue);
    });

    test('returns denied when role lacks resource', () async {
      when(() => repository.load()).thenAnswer((_) async => Ok(_buildPolicy()));

      final result = await useCase.call('user', 'users');

      expect(result.isOk, isTrue);
      final decision = result.getOrElse(
        const AccessDecision.denied(
          PolicyNotFoundFailure('fallback'),
        ),
      );
      expect(decision.isDenied, isTrue);
    });

    test('returns Err when repository fails to load', () async {
      when(() => repository.load()).thenAnswer(
        (_) async => const Err(StorageFailure('disk error')),
      );

      final result = await useCase.call('admin', 'dashboard');

      expect(result.isErr, isTrue);
    });

    test('returns EngineNotInitializedFailure when policy is empty', () async {
      when(() => repository.load())
          .thenAnswer((_) async => const Ok(Policy(roles: {})));

      final result = await useCase.call('admin', 'dashboard');

      expect(result.isOk, isTrue);
      final decision = result.getOrElse(
        const AccessDecision.denied(
          PolicyNotFoundFailure('fallback'),
        ),
      );
      expect(decision.isDenied, isTrue);
    });
  });
}
