# Migration Guide — v1 → v2

This document maps every v1 public API symbol to its v2 equivalent and explains
the changes needed to upgrade.

---

## Breaking changes summary

| v1 symbol | v2 equivalent | Notes |
|---|---|---|
| `PolicyManager` | `PolicyEngineController` + `PolicyEngine` | God object split into controller (state) + facade (logic) + 6 use cases |
| `PolicyProvider` | `PolicyEngineScope` | `InheritedNotifier` — fixes rebuild bug |
| `PolicyWidget` | `PolicyGate` / `PolicyBuilder` | Two focused widgets replace one |
| `Role` | `RoleEntity` + `RoleName` | Name is a validated value object |
| `IPolicyStorage` / `MemoryPolicyStorage` | `IPolicyRepository` / `InMemoryPolicyRepository` | Renamed; returns `Result` |
| `IPolicyEvaluator` / `RoleEvaluator` | `PolicyEvaluator` / `RbacEvaluator` | Domain interface + RBAC/ABAC/Composite |
| `LogHandler` (static) | `ILogger` port + `ConsoleLogger` / `NoopLogger` | Injectable, no static state |
| `JsonHandler` (static) | `PolicyJsonCodec` | Instance class; single v2 schema |
| `ExternalAssetHandler` | `FlutterAssetLoader` | Implements `IAssetLoader` port |
| `PolicySDKException` | `DomainFailure` sealed class | Pattern-matched subtypes; no exceptions in domain |
| `PolicyNotInitializedException` | `EngineNotInitializedFailure` | Returned as `Err`, never thrown |
| JSON key `allowedContent` | JSON key `allowedResources` | Schema change in v2 |

---

## Step-by-step upgrade

### 1. Replace `PolicyManager` with `PolicyEngineController`

**Before (v1):**
```dart
final manager = PolicyManager();
await manager.initialize({
  'admin': ['dashboard', 'settings'],
});
```

**After (v2):**
```dart
final controller = PolicyEngineController.inMemory();
await controller.loadPolicies({
  'roles': {
    'admin': {'allowedResources': ['dashboard', 'settings']},
  },
});
```

Key differences:
- Policies are now nested under the `"roles"` key.
- Resource lists use `"allowedResources"` instead of `"allowedContent"`.
- `loadPolicies` returns `Result<void, DomainFailure>` — check for failures.

---

### 2. Replace `PolicyProvider` with `PolicyEngineScope`

**Before (v1):**
```dart
PolicyProvider(
  policyManager: manager,
  child: MyApp(),
)
```

**After (v2):**
```dart
PolicyEngineScope(
  controller: controller,
  child: MyApp(),
)
```

`PolicyEngineScope` uses `InheritedNotifier`, so descendant widgets that call
`PolicyEngineScope.of(context)` rebuild automatically whenever the controller
notifies — the v1 rebuild bug is fixed.

---

### 3. Replace `PolicyWidget` with `PolicyGate` or `PolicyBuilder`

**Before (v1):**
```dart
PolicyWidget(
  role: 'admin',
  content: 'settings',
  child: const SettingsPage(),
  fallback: const AccessDenied(),
  onAccessDenied: () => showDeniedSnackBar(),
)
```

**After (v2) — simple gate:**
```dart
PolicyGate(
  roleName: 'admin',
  resourceId: 'settings',
  child: const SettingsPage(),
  fallback: const AccessDenied(),
  onDenied: (failure) => showDeniedSnackBar(),
)
```

**After (v2) — full builder with decision:**
```dart
PolicyBuilder(
  roleName: 'admin',
  resourceId: 'settings',
  builder: (context, decision) {
    if (decision == null) return const CircularProgressIndicator();
    return decision.isGranted ? const SettingsPage() : const AccessDenied();
  },
)
```

---

### 4. Replace `Role` with `RoleEntity` + `RoleName`

**Before (v1):**
```dart
const role = Role(name: 'admin', allowedContent: ['dashboard']);
```

**After (v2):**
```dart
final role = RoleEntity(
  name: RoleName('admin'),
  allowedResources: const {'dashboard'},
);
```

`allowedResources` is a `Set<String>` (unordered, no duplicates).
`RoleName` validates that the name is non-empty and trims whitespace.

---

### 5. Replace `LogHandler` with `ILogger`

**Before (v1):**
```dart
LogHandler.log('Something happened'); // static, always prints
```

**After (v2):**
```dart
// Inject a ConsoleLogger for development:
final controller = PolicyEngineController.withRepository(
  repository: InMemoryPolicyRepository(),
  logger: ConsoleLogger(minLevel: LogLevel.debug),
);

// Or a NoopLogger for production (the default):
final controller = PolicyEngineController.inMemory(); // uses NoopLogger
```

---

### 6. Update JSON asset schema

**Before (v1 schema):**
```json
{
  "admin": { "allowedContent": ["dashboard", "settings"] },
  "viewer": { "allowedContent": ["dashboard"] }
}
```

**After (v2 canonical schema):**
```json
{
  "roles": {
    "admin":  { "allowedResources": ["dashboard", "settings"] },
    "viewer": { "allowedResources": ["dashboard"] }
  }
}
```

Changes:
- Roles are nested under the `"roles"` key.
- `"allowedContent"` is renamed to `"allowedResources"`.

---

### 7. Load policies from an asset (v2)

**Before (v1):**
```dart
await manager.initializeFromJsonAssets('assets/policies/roles.json');
```

**After (v2):**
```dart
final controller = PolicyEngineController.withRepository(
  repository: InMemoryPolicyRepository(),
  assetLoader: const FlutterAssetLoader(),
);
await controller.loadPoliciesFromAsset('assets/policies/roles.json');
```

---

### 8. Handle errors

**Before (v1):**
```dart
try {
  await manager.initialize(policies);
} on PolicySDKException catch (e) {
  print(e.message);
}
```

**After (v2):**
```dart
final result = await controller.loadPolicies(policies);
switch (result) {
  case Ok():  print('Loaded successfully');
  case Err(:final error): print('Failed: ${error.message}');
}
```

`DomainFailure` subtypes:
| Subtype | Meaning |
|---|---|
| `PolicyNotFoundFailure` | No role found for the given name |
| `ResourceNotAllowedFailure` | Role exists but resource is not allowed |
| `InvalidPolicyFailure` | Policy map is malformed |
| `ParseFailure` | JSON decoding failed |
| `StorageFailure` | Repository read/write error |
| `EngineNotInitializedFailure` | `evaluateAccess` called before `loadPolicies` |
| `MissingAttributeFailure` | ABAC attribute absent from subject/resource |

---

### 9. Evaluate access directly

**Before (v1):**
```dart
final hasAccess = await manager.isAllowed('admin', 'dashboard');
```

**After (v2):**
```dart
final result = await controller.evaluateAccess('admin', 'dashboard');
final decision = result.getOrElse(AccessDecision.denied(
  const PolicyNotFoundFailure('unknown'),
));
if (decision.isGranted) {
  // access granted
}
```

---

## Removed APIs (no v2 equivalent)

| v1 symbol | Reason removed |
|---|---|
| `PolicyManager.roles` (direct map access) | Access roles via `listRoles()` use case |
| `LogHandler._includeTimestamp` etc. | Logger is now injected; configure the implementation directly |
| `JsonParseException` / `JsonSerializeException` | Replaced by `ParseFailure` / `InvalidPolicyFailure` inside `Result` |
| `IPolicySdkExceptions` interface | Replaced by `DomainFailure` sealed class |
