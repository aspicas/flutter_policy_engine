# Migration Guide: v1 → v2

> This document is updated incrementally as each phase is completed.
> Check back after each release for the latest migration steps.

## Overview
v2.0.0 introduces Clean Architecture with four explicit layers (Domain, Application,
Infrastructure, Presentation), RBAC and ABAC support, an injectable logger, and a persistent
storage adapter.

The public API has changed. This guide provides a 1:1 mapping of v1 symbols to their v2
equivalents.

---

## Status: Work in progress

This migration guide will be completed in Phase 5.

### API Equivalence Table (to be filled in)

| v1 Symbol | v2 Equivalent | Notes |
|-----------|--------------|-------|
| `PolicyManager` | `PolicyEngine` + `PolicyEngineController` | God object split into facade + state |
| `PolicyProvider` | `PolicyEngineScope` | `InheritedNotifier` instead of `InheritedWidget` |
| `PolicyWidget` | `PolicyGate` / `PolicyBuilder` | Two specialized widgets |
| `Role` | `Role` | Same name, different package path |
| `PolicySDKException` | `PolicyEngineException` | Carries `DomainFailure` |
| `policyManager.initialize(map)` | `controller.loadPolicies(map)` | New JSON schema (see spec-003) |
| `policyManager.initializeFromJsonAssets(path)` | `controller.loadPoliciesFromAsset(path)` | Unified schema |
| `policyManager.hasAccess(role, content)` | `engine.evaluateAccess(role, resource).isGranted` | Returns `AccessDecision` |
| `policyManager.addRole(role)` | `controller.addRole(role)` | Same semantics |
| `policyManager.removeRole(name)` | `controller.removeRole(name)` | Same semantics |
| `policyManager.updateRole(name, role)` | `controller.updateRole(name, role)` | Same semantics |

---

## Breaking Changes Summary

1. **JSON schema changed**: the `initialize(Map)` path accepted `{"roleName": List<String>}`;
   v2 requires `{"roles": {"roleName": {"allowedResources": [...]}}}`. See spec-003.
2. **Exception type renamed**: `PolicySDKException` → `PolicyEngineException`.
3. **Widget names changed**: `PolicyWidget` → `PolicyGate`, `PolicyProvider` → `PolicyEngineScope`.
4. **Public barrel path**: same package name `flutter_policy_engine`, different exported types.
5. **`hasAccess` removed**: replaced by `evaluateAccess` returning `AccessDecision`.

---

## Step-by-step migration

> _To be written once Phase 5 implementation is complete._
