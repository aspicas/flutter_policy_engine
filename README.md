# flutter_policy_engine

A lightweight, extensible policy engine for Flutter that supports **Role-Based
Access Control (RBAC)** and basic **Attribute-Based Access Control (ABAC)** with
Clean Architecture, injectable logging, and optional persistent storage.

[![pub package](https://img.shields.io/pub/v/flutter_policy_engine.svg)](https://pub.dev/packages/flutter_policy_engine)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Features

- **RBAC** — map roles to allowed resources; deny by default.
- **ABAC** — match subject/resource attributes against declarative rules.
- **Composite evaluation** — combine RBAC + ABAC with `denyOverrides`,
  `allowOverrides`, or `anyOf` strategies.
- **Injectable logger** — `ILogger` port with `ConsoleLogger` and `NoopLogger`
  adapters.
- **Flexible storage** — `InMemoryPolicyRepository` (default) or
  `SharedPreferencesPolicyRepository` for persistence across restarts.
- **Flutter asset loading** — load policies from a bundled JSON asset via
  `FlutterAssetLoader`.
- **Reactive widgets** — `PolicyEngineScope`, `PolicyGate`, and `PolicyBuilder`
  integrate with the widget tree and rebuild automatically on policy changes.
- **Zero global state** — all state is owned by `PolicyEngineController`.

---

## Quick start

### 1. Add the dependency

```yaml
dependencies:
  flutter_policy_engine: ^2.0.0
```

### 2. Define policies inline (RBAC)

```dart
import 'package:flutter_policy_engine/flutter_policy_engine.dart';

Future<void> main() async {
  final controller = PolicyEngineController.inMemory();

  await controller.loadPolicies({
    'roles': {
      'admin':  {'allowedResources': ['dashboard', 'settings', 'users']},
      'viewer': {'allowedResources': ['dashboard']},
      'guest':  {'allowedResources': []},
    },
  });

  final result = await controller.evaluateAccess('admin', 'settings');
  result.when(
    ok:  (decision) => print('Granted: ${decision.isGranted}'),
    err: (failure)  => print('Error: ${failure.message}'),
  );
}
```

### 3. Wrap the widget tree

```dart
PolicyEngineScope(
  controller: PolicyEngineController.inMemory(),
  child: MyApp(),
)
```

### 4. Gate content

```dart
PolicyGate(
  roleName: 'admin',
  resourceId: 'settings',
  child: const SettingsScreen(),
  fallback: const Text('Access denied'),
)
```

### 5. Build conditionally

```dart
PolicyBuilder(
  roleName: currentUser.role,
  resourceId: 'reports',
  builder: (context, decision) {
    if (decision == null) return const CircularProgressIndicator();
    return decision.isGranted ? const ReportsScreen() : const UpgradePrompt();
  },
)
```

---

## Loading policies from a JSON asset

Create an asset following the **v2 canonical schema**:

```json
{
  "roles": {
    "admin":  { "allowedResources": ["dashboard", "settings"] },
    "viewer": { "allowedResources": ["dashboard"] }
  }
}
```

Then load it at startup:

```dart
final controller = PolicyEngineController.withRepository(
  repository: InMemoryPolicyRepository(),
  assetLoader: const FlutterAssetLoader(),
);

await controller.loadPoliciesFromAsset('assets/policies/roles.json');
```

---

## ABAC example

```dart
import 'package:flutter_policy_engine/flutter_policy_engine.dart';

Future<void> main() async {
  // ABAC policy: only subjects from 'eu' region may access 'gdpr_data'.
  final abacPolicy = AbacPolicy(
    rules: const [
      AttributeRule(
        subjectAttribute: 'region',
        requiredValue: 'eu',
        resourceId: 'gdpr_data',
      ),
    ],
  );

  final evaluator = CompositeEvaluator(
    evaluators: [
      const RbacEvaluator(),
      AbacEvaluator(policy: abacPolicy),
    ],
    strategy: CompositeStrategy.denyOverrides,
  );

  final repository = InMemoryPolicyRepository();
  await repository.save(
    Policy(
      roles: {
        'analyst': RoleEntity(
          name: RoleName('analyst'),
          allowedResources: const {'gdpr_data'},
        ),
      },
    ),
  );

  final euSubject = Subject(
    id: 'alice',
    attributes: const {'region': 'eu'},
  );
  final resource = Resource(id: 'gdpr_data');

  final decision = await evaluator.evaluate(
    await repository.load().then((r) => r.getOrElse(const Policy(roles: {}))),
    'analyst',
    resource.id,
    subject: euSubject,
    resource: resource,
  );

  print(decision.isGranted); // true
}
```

---

## Persistent storage

```dart
final prefs = await SharedPreferences.getInstance();
final repo   = SharedPreferencesPolicyRepository(prefs);

final controller = PolicyEngineController.withRepository(
  repository: repo,
  assetLoader: const FlutterAssetLoader(),
);

// Loads persisted policy if available, otherwise loads from asset.
final stored = await repo.load();
if (stored.getOrElse(const Policy(roles: {})).isEmpty) {
  await controller.loadPoliciesFromAsset('assets/policies/roles.json');
}
```

---

## Role management

```dart
// Add a role
await controller.addRole(
  RoleEntity(
    name: RoleName('editor'),
    allowedResources: const {'posts', 'drafts'},
  ),
);

// Update a role
await controller.updateRole(
  'editor',
  RoleEntity(
    name: RoleName('editor'),
    allowedResources: const {'posts', 'drafts', 'published'},
  ),
);

// Remove a role
await controller.removeRole('editor');

// List all roles
final result = await controller.listRoles();
```

---

## Architecture

```
lib/src/
  domain/          ← pure Dart — entities, value objects, evaluators, failures
  application/     ← use cases, PolicyEngine facade, ILogger / IAssetLoader ports
  infrastructure/  ← ConsoleLogger, NoopLogger, InMemoryPolicyRepository,
                     SharedPreferencesPolicyRepository, FlutterAssetLoader,
                     PolicyJsonCodec
  presentation/    ← PolicyEngineController, PolicyEngineScope,
                     PolicyGate, PolicyBuilder
```

Key design decisions:
- **No global state** — `PolicyEngineController` owns all mutable state.
- **Result<T, DomainFailure>** — no exceptions escape the domain boundary.
- **InheritedNotifier** — `PolicyEngineScope` rebuilds dependants automatically
  (fixes the v1 `PolicyProvider` rebuild bug).
- **Explicit DI** — no service locator or code generation required.

---

## Migrating from v1

See [docs/migration-v1-to-v2.md](docs/migration-v1-to-v2.md) for the full
mapping table with before/after examples.

---

## License

MIT — see [LICENSE](LICENSE).
