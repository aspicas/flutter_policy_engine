# ADR-0001: Adopt Clean Architecture for flutter_policy_engine v2

## Status
Accepted

## Date
2026-06-03

## Context
The v1 codebase grew organically around a single `PolicyManager` god object (~464 LOC) that
combined: RBAC evaluation, policy storage, asset loading, JSON parsing, structured logging, state
notifications, and widget-tree integration via `ChangeNotifier`. This coupling made the code hard to
test in isolation, difficult to extend (e.g., adding ABAC required editing the manager directly), and
produced two divergent JSON init paths with incompatible schemas.

Global static state in `LogHandler` and `JsonHandler` introduced hidden dependencies between
components and made parallel test execution unsafe.

## Decision
We adopt **Clean Architecture** organized in four concentric layers:

1. **Domain** — Pure Dart. Business entities (`Role`, `Policy`, `Subject`, `Resource`), domain
   services (evaluators), repository interfaces, and a `Result<T, DomainFailure>` error model. No
   Flutter imports allowed.
2. **Application** — Orchestration. Use cases, port interfaces (`ILogger`, `IAssetLoader`,
   `IPolicyRepository`), and the `PolicyEngine` facade. Depends only on Domain.
3. **Infrastructure** — Adapters. Concrete implementations of ports: `ConsoleLogger`,
   `FlutterAssetLoader`, `InMemoryPolicyRepository`, `SharedPreferencesPolicyRepository`,
   `PolicyJsonCodec`. May import Flutter packages.
4. **Presentation** — Flutter UI. `PolicyEngineController`, `PolicyEngineScope`, `PolicyGate`,
   `PolicyBuilder`. Depends on Application.

The dependency rule: inner layers never import outer layers. Domain knows nothing about Flutter.

## Consequences
- **Positive**: Each layer is independently testable. Infrastructure adapters can be swapped without
  touching domain or application logic. Widget tests can use real evaluators without Flutter binding
  mocks for business logic.
- **Positive**: ABAC and future evaluation strategies are plug-in extensions (Composite + Strategy),
  not edits to a monolithic manager.
- **Negative**: More files and types than the v1 flat structure. Mitigated by keeping use cases ≤80
  LOC and grouping by feature inside each layer.
- **Migration**: v1 API is a breaking change; migration guide is published in
  `docs/migration-v1-to-v2.md`.
