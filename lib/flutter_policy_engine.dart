// Application layer — ports and facade
export 'src/application/ports/i_asset_loader.dart';
export 'src/application/ports/i_logger.dart';
export 'src/application/services/policy_engine.dart';

// Domain layer — entities, value objects, failures, evaluators
export 'src/domain/entities/abac_policy.dart';
export 'src/domain/entities/access_decision.dart';
export 'src/domain/entities/policy.dart';
export 'src/domain/entities/resource.dart';
export 'src/domain/entities/role_entity.dart';
export 'src/domain/entities/subject.dart';
export 'src/domain/failures/domain_failure.dart';
export 'src/domain/repositories/i_policy_repository.dart';
export 'src/domain/services/abac_evaluator.dart';
export 'src/domain/services/composite_evaluator.dart';
export 'src/domain/services/policy_evaluator.dart';
export 'src/domain/services/rbac_evaluator.dart';
export 'src/domain/value_objects/role_name.dart';

// Infrastructure layer — adapters
export 'src/infrastructure/asset_loaders/flutter_asset_loader.dart';
export 'src/infrastructure/logging/console_logger.dart';
export 'src/infrastructure/logging/noop_logger.dart';
export 'src/infrastructure/storage/in_memory_policy_repository.dart';
export 'src/infrastructure/storage/shared_preferences_policy_repository.dart';

// Presentation layer — widgets and state
export 'src/presentation/providers/policy_engine_scope.dart';
export 'src/presentation/state/policy_engine_controller.dart';
export 'src/presentation/widgets/policy_builder.dart';
export 'src/presentation/widgets/policy_gate.dart';
