# Spec-003: Policy Loading — Canonical JSON Schema v2

## Context
v1 had two incompatible initialization paths (`initialize(Map)` accepting `List<String>` values vs
`initializeFromJsonAssets` expecting `Map` values with `roleName`/`allowedContent` keys). v2 defines
a single canonical JSON schema for all loading sources.

## Canonical Schema v2

```json
{
  "roles": {
    "<roleName>": {
      "allowedResources": ["resource-a", "resource-b"],
      "metadata": {}
    }
  }
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `roles` | `Map<String, RoleJson>` | Yes | Top-level key |
| `<roleName>` | string key | Yes | Role identifier |
| `allowedResources` | `List<String>` | Yes | May be empty |
| `metadata` | `Map<String, dynamic>` | No | Defaults to `{}` |

## In-code Map Loading
`LoadPoliciesFromMap` accepts `Map<String, dynamic>` matching the same schema (parsed or directly
constructed). The `roles` top-level key is required.

## Asset Loading
`LoadPoliciesFromAsset(assetPath)` reads the file, delegates to `PolicyJsonCodec`, and calls
`LoadPoliciesFromMap` internally. Any I/O error is a `StorageFailure`; any parse error is a
`ParseFailure`.

## Parse Rules
1. Missing `roles` key → `ParseFailure`.
2. A role entry where `allowedResources` is not a `List<String>` → that role is skipped with a
   warning log; remaining roles are loaded (partial success is the default).
3. A role entry where the key is empty → skipped with warning.
4. Unknown keys in the schema are **ignored** (forward-compatibility).

## Acceptance Criteria
- [ ] `PolicyJsonCodec.decode` converts v2 JSON string → `Map<String, Policy>`.
- [ ] `PolicyJsonCodec.encode` round-trips to v2 format.
- [ ] Missing `roles` key emits `ParseFailure`.
- [ ] Invalid role entries are skipped, valid ones loaded.
- [ ] Covered by `test/infrastructure/serialization/policy_json_codec_test.dart`.
- [ ] Covered by `test/bdd/policy_loading_feature_test.dart`.
