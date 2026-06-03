import 'package:flutter_policy_engine/src/infrastructure/storage/in_memory_policy_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contract/policy_repository_contract.dart';

void main() {
  group('InMemoryPolicyRepository', () {
    runPolicyRepositoryContractTests(
      factory: InMemoryPolicyRepository.new,
    );
  });
}
