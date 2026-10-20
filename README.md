<p align="center">
  <img src="docs/assets/logo.png" width="160" alt="flutter_policy_engine logo">
</p>

# flutter_policy_engine

A lightweight, extensible policy engine for Flutter that supports **Role-Based
Access Control (RBAC)** and basic **Attribute-Based Access Control (ABAC)** with
Clean Architecture, injectable logging, and optional persistent storage.

[![pub package](https://img.shields.io/pub/v/flutter_policy_engine.svg)](https://pub.dev/packages/flutter_policy_engine)
[![Documentation](https://img.shields.io/badge/docs-docs.page-blue.svg)](https://docs.page/aspicas/flutter_policy_engine)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

📖 **Full documentation: [docs.page/aspicas/flutter_policy_engine](https://docs.page/aspicas/flutter_policy_engine)**

---

## Features

- **RBAC** — map roles to allowed resources; deny by default.
- **ABAC** — match subject/resource attributes against declarative rules.
- **Composite evaluation** — combine `PolicyEvaluator`s with `denyOverrides` or
  `allowOverrides` via `CompositeEvaluator`.
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
  switch (result) {
    case Ok(:final value):
      print('Granted: ${value.isGranted}');
    case Err(:final error):
      print('Error: ${error.message}');
  }
}
```

### 3. Wrap the widget tree

Create the controller once (e.g. in `main` or a `State`'s `initState`) and
provide it to the tree:

```dart
PolicyEngineScope(
  controller: controller,
  child: MyApp(),
)
```

### 4. Gate content

```dart
PolicyGate(
  roleName: 'admin',
  resourceId: 'settings',
  fallback: const Text('Access denied'),
  child: const SettingsScreen(),
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

Declare it under `flutter.assets` in `pubspec.yaml`, then load it at startup:

```dart
final controller = PolicyEngineController.inMemory(
  assetLoader: const FlutterAssetLoader(),
);

await controller.loadPoliciesFromAsset('assets/policies/roles.json');
```

---

## ABAC example

```dart
import 'package:flutter_policy_engine/flutter_policy_engine.dart';

void main() {
  // Every rule must pass for access to be granted.
  const abacPolicy = AbacPolicy(
    rules: [
      // Only subjects from the 'eu' region…
      AttributeRule(subjectAttribute: 'region', expectedValue: 'eu'),
      // …whose department matches the resource's department.
      AttributeRule(
        subjectAttribute: 'department',
        resourceAttribute: 'department',
      ),
    ],
  );

  const subject = Subject(
    attributes: {'region': 'eu', 'department': 'legal'},
  );
  final resource = Resource(
    id: 'gdpr_data',
    attributes: {'department': 'legal'},
  );

  final decision = const AbacEvaluator().evaluate(subject, resource, abacPolicy);
  print(decision.isGranted); // true
}
```

`PolicyEngineController` and the widgets evaluate RBAC only. To require both
RBAC and ABAC, run `controller.evaluateAccess` first and then `AbacEvaluator` —
see [Access Evaluation](https://docs.page/aspicas/flutter_policy_engine/core-concepts/access-evaluation).

---

## Persistent storage

```dart
final repository = await SharedPreferencesPolicyRepository.create();

final controller = PolicyEngineController.withRepository(
  repository: repository,
  assetLoader: const FlutterAssetLoader(),
);

final stored = (await repository.load()).getOrElse(const Policy(roles: {}));
if (stored.isEmpty) {
  // First launch: seed from the bundled asset.
  await controller.loadPoliciesFromAsset('assets/policies/roles.json');
} else {
  // Later launches: re-load the persisted policy so the controller is
  // initialised (evaluateAccess fails with EngineNotInitializedFailure until a
  // load call succeeds).
  await controller.loadPolicies({
    'roles': {
      for (final MapEntry(:key, :value) in stored.roles.entries)
        key: {'allowedResources': value.allowedResources.toList()},
    },
  });
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

Every successful mutation notifies listeners, so `PolicyGate` and
`PolicyBuilder` re-evaluate automatically.

---

## Architecture

```
lib/src/
  domain/          ← pure Dart — entities, value objects, evaluators, failures
  application/     ← use cases, PolicyEngine facade, PolicyJsonCodec,
                     ILogger / IAssetLoader ports
  infrastructure/  ← ConsoleLogger, NoopLogger, InMemoryPolicyRepository,
                     SharedPreferencesPolicyRepository, FlutterAssetLoader
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

## Documentation

The full guide lives at
**[docs.page/aspicas/flutter_policy_engine](https://docs.page/aspicas/flutter_policy_engine)**:

- [Quick Start](https://docs.page/aspicas/flutter_policy_engine/quick-start)
- [Policies & Roles](https://docs.page/aspicas/flutter_policy_engine/core-concepts/policy-management)
- [Access Evaluation](https://docs.page/aspicas/flutter_policy_engine/core-concepts/access-evaluation)
- [Error Handling](https://docs.page/aspicas/flutter_policy_engine/core-concepts/error-handling)
- [Widgets & Controller](https://docs.page/aspicas/flutter_policy_engine/flutter/widgets)
- [Storage & Persistence](https://docs.page/aspicas/flutter_policy_engine/guides/persistence)
- [Testing](https://docs.page/aspicas/flutter_policy_engine/guides/testing)

---

## Migrating from v1

See the [migration guide](https://docs.page/aspicas/flutter_policy_engine/migration-v1-to-v2)
for the full mapping table with before/after examples.

---

## License

MIT — see [LICENSE](LICENSE).
