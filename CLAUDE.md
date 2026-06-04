# CLAUDE.md — flutter_policy_engine

> Guidance for AI assistants working on this repository.

---

## Project Overview

`flutter_policy_engine` is a **Dart/Flutter package** (v2.0.0) that provides a lightweight, extensible authorization engine supporting:

- **RBAC** — role-based access control with deny-by-default semantics
- **ABAC** — attribute-based rules on `Subject` / `Resource`
- **Composite evaluation** — combine RBAC + ABAC with configurable strategies (`denyOverrides`, `allowOverrides`, `anyOf`)
- **Flutter UI integration** — `PolicyGate`, `PolicyBuilder`, `PolicyEngineScope` for reactive access gating

Published to pub.dev. Repository: https://github.com/aspicas/flutter_policy_engine

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| Language | Dart 3.4+ |
| Framework | Flutter ≥1.17.0 |
| Flutter (pinned) | 3.29.3 via FVM (`.fvmrc`) |
| Runtime deps | `collection`, `meta`, `shared_preferences` |
| Dev/test | `mocktail`, `very_good_analysis`, `flutter_test` |
| Release tooling | Node.js + `semantic-release` + `commitlint` + `husky` |

---

## Architecture

The package follows **Clean Architecture** with four layers. The dependency rule is strict: inner layers must not import outer layers.

```
domain  ←  application  ←  infrastructure
                ↑
           presentation
```

### Layer responsibilities

| Layer | Path | Rules |
|-------|------|-------|
| **Domain** | `lib/src/domain/` | Pure Dart only — no Flutter, no `dart:ui`, no `dart:io`. Entities, value objects, failures, evaluator contracts. |
| **Application** | `lib/src/application/` | Use cases, ports (`ILogger`, `IAssetLoader`), `PolicyEngine` facade, `PolicyJsonCodec`. |
| **Infrastructure** | `lib/src/infrastructure/` | Implements ports: loggers, repositories (`InMemory`, `SharedPreferences`), `FlutterAssetLoader`. |
| **Presentation** | `lib/src/presentation/` | `PolicyEngineController` (ChangeNotifier), `PolicyEngineScope` (InheritedNotifier), `PolicyGate`, `PolicyBuilder`. |

### Key types

- `Policy` — holds a map of `RoleName → RoleEntity`
- `RoleEntity` — list of allowed resource IDs
- `Subject` / `Resource` — ABAC attribute carriers
- `AccessDecision` — `allowed | denied`
- `Result<T, DomainFailure>` / `Ok<T>` / `Err<E>` — typed errors, no exceptions across domain boundary
- `DomainFailure` — sealed failure hierarchy
- `PolicyEngineController` — single mutable owner of runtime state; wrap with `PolicyEngineScope` in the widget tree

### Public API

Single barrel export: `lib/flutter_policy_engine.dart`

---

## Repository Layout

```
flutter_policy_engine/
├── lib/
│   ├── flutter_policy_engine.dart   # Public barrel export
│   └── src/
│       ├── domain/
│       ├── application/
│       ├── infrastructure/
│       └── presentation/
├── test/                            # 37 Dart test files
│   ├── domain/
│   ├── application/use_cases/
│   ├── infrastructure/
│   ├── presentation/
│   ├── bdd/                         # spec-001 … spec-008
│   ├── contract/                    # shared interface contracts
│   └── helpers/                     # bdd.dart, builders, fakes
├── example/                         # Runnable Flutter demo app
│   └── test/policy_engine_e2e_test.dart
├── docs/                            # MDX site, specs, ADRs, migration guide
├── scripts/                         # Coverage, local CI (act)
├── tools/
│   └── check_domain_purity.sh
└── .github/workflows/               # CI pipelines
```

---

## Development Commands

> Use `fvm flutter` if FVM is installed; plain `flutter` otherwise. Run `./setup.sh` once after cloning.

```bash
# Bootstrap (first time)
./setup.sh

# Get dependencies
fvm flutter pub get

# Format
fvm dart format lib test

# Analyze
fvm flutter analyze

# Run all tests
fvm flutter test

# Run tests with coverage (generates HTML report)
./scripts/test_with_coverage.sh

# Check domain layer purity (no Flutter/dart:io imports)
./tools/check_domain_purity.sh

# Run example app
cd example && fvm flutter run

# Run example E2E tests
cd example && fvm flutter test
```

---

## Testing Conventions

- Mirrors the Clean Architecture layer structure
- **BDD specs** in `test/bdd/` cover specs `001`–`008` using the lightweight DSL in `test/helpers/bdd.dart`
- **Contract tests** in `test/contract/` ensure all port implementations satisfy the same invariants
- **Mocking** via `mocktail` — prefer fakes from `test/helpers/fakes.dart` before creating new mocks
- **Coverage** gate: ≥80% line coverage enforced in CI via `very_good_coverage`
- Test file naming: `<unit_under_test>_test.dart`

When adding a new use case or evaluator, also add:
1. A unit test in the matching layer folder
2. A BDD scenario in the relevant `test/bdd/spec-0XX_*.dart` file (or a new spec file)

---

## Branching & Release Strategy

| Branch | Purpose | Merge from |
|--------|---------|-----------|
| `develop` | Active development | Feature branches (PRs) |
| `main` | Stable / releases | `develop` only (CI-enforced) |

Releases are **fully automated** via `semantic-release` on push to `main`:
- Bumps `pubspec.yaml` version
- Updates `CHANGELOG.md`
- Creates GitHub Release

**Never bump the version manually.** Let semantic-release derive it from commits.

---

## Commit Conventions

Uses [Conventional Commits](https://www.conventionalcommits.org/) enforced by `commitlint`.

| Type | Release impact |
|------|---------------|
| `feat` | minor bump |
| `fix`, `perf` | patch bump |
| `BREAKING CHANGE` footer | major bump |
| `chore`, `docs`, `style`, `refactor`, `test` | no release |

A commit template is configured via `./setup.sh` (`commit-template.txt`).

```
# Good examples
feat(rbac): support wildcard resource IDs
fix(abac): normalize attribute keys before comparison
test(bdd): add spec-009 for composite deny-override scenario
docs(migration): clarify v1 removal of PolicyWidget
```

---

## CI Quality Gates

All pull requests must pass:

1. **Domain purity** — `lib/src/domain/` must not import Flutter, `dart:ui`, or `dart:io`
2. **Formatting** — `dart format --set-exit-if-changed`
3. **Analysis** — `flutter analyze` (zero issues, `very_good_analysis` ruleset)
4. **Tests** — all unit + widget tests green
5. **Coverage** — ≥80% line coverage
6. **Example tests** — E2E test suite in `example/test/`
7. **Commit messages** — `commitlint` on the PR commit range

PRs to `main` are additionally gated so only `develop` may be the source branch.

---

## Code Style Rules

Enforced by `analysis_options.yaml` (extends `very_good_analysis`):

- Single quotes for strings
- All public APIs must have doc comments (`public_member_api_docs: true`)
- Strict casts and inference (no implicit dynamics)
- One-member abstracts are **allowed** (ports/interfaces are intentionally single-method)
- No raw types

### Patterns to follow

- Return `Result<T, DomainFailure>` from domain and application methods — never throw across layer boundaries
- Use `Ok(value)` / `Err(failure)` constructors; pattern-match with `switch` or `.fold()`
- Prefer immutable entities; use named constructors or factory methods for controlled creation
- Use `RoleName` value object instead of raw `String` when passing role identifiers

### Patterns to avoid

- Do not import `package:flutter/` or any Flutter SDK inside `lib/src/domain/`
- Do not add global/static mutable state
- Do not expose v1 API names (`PolicyManager`, `PolicyProvider`, `PolicyWidget`) — they were removed in v2

---

## JSON Policy Schema (v2)

```json
{
  "roles": {
    "admin": {
      "allowedResources": ["dashboard", "settings", "reports"]
    },
    "viewer": {
      "allowedResources": ["dashboard"]
    }
  }
}
```

> v1 used `"allowedContent"` — this key is **no longer accepted**.

See `example/assets/policies/user_roles.json` for a canonical sample.

---

## Useful References

- **Architecture decisions:** `docs/adr/`
- **Feature specs:** `docs/specs/spec-001-rbac-evaluation.md` … `spec-008-error-model.md`
- **v1 → v2 migration:** `docs/migration-v1-to-v2.md`
- **Hosted docs:** https://docs.page/aspicas/flutter_policy_engine
- **Local CI simulation:** `scripts/README.md` (uses `act` + Docker)
