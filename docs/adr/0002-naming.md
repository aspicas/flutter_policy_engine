# ADR-0002: Naming Conventions for v2

## Status
Accepted

## Date
2026-06-03

## Context
v1 had several naming inconsistencies:
- The class was named `Role` but docs and some comments used "Policy" interchangeably.
- `PolicyManager` mixed "policy" (access-control) with "manager" (lifecycle).
- Exceptions used mixed `I` prefix conventions without a clear pattern.
- Widget names (`PolicyWidget`, `PolicyProvider`) were ambiguous about their Flutter nature.

## Decision

### File names
Dart file names follow `snake_case`, one type per file, file name = type name.

### Type names

| Layer | Pattern | Examples |
|-------|---------|---------|
| Domain entities | Noun | `Role`, `Policy`, `Subject`, `Resource`, `AccessDecision` |
| Domain value objects | Noun | `RoleName`, `PolicyId`, `AttributeSet` |
| Domain failures | Noun + sealed suffix | `DomainFailure` (sealed base), `PolicyNotFoundFailure`, `InvalidPolicyFailure` |
| Domain evaluators (interface) | `PolicyEvaluator` | — |
| Domain evaluators (concrete) | `RbacEvaluator`, `AbacEvaluator`, `CompositeEvaluator` | — |
| Application ports (interfaces) | `I` prefix | `ILogger`, `IAssetLoader`, `IPolicyRepository` |
| Application use cases | Verb + noun | `EvaluateAccess`, `LoadPoliciesFromMap`, `AddRole` |
| Application facade | `PolicyEngine` | — |
| Infrastructure adapters | Qualifier + base noun | `ConsoleLogger`, `InMemoryPolicyRepository` |
| Infrastructure codecs | Noun + `Codec` | `PolicyJsonCodec` |
| Presentation controller | `PolicyEngineController` | — |
| Presentation scope | `PolicyEngineScope` | — |
| Presentation widgets | `PolicyGate`, `PolicyBuilder` | — |
| Exceptions (public) | `PolicyEngineException` | — |

### Language
- All identifiers and doc comments in English. No Spanish strings in source code.
- Documentation files (`docs/`, `CHANGELOG.md`) may be bilingual during transition.

## Consequences
Consistent terminology removes ambiguity between the access-control "policy" concept and the
lifecycle "manager" concept. The `I`-prefix convention on ports makes it easy to distinguish
contracts from implementations throughout the codebase.
