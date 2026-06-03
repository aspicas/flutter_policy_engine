// ignore_for_file: public_member_api_docs

/// Test builders for constructing domain objects with sensible defaults.
///
/// Provides factory helpers that keep test setup readable and DRY.
/// Import this file in any test that needs to construct domain objects:
/// ```dart
/// import '../helpers/builders.dart';
/// ```
library test_builders;

// Builders for v2 domain types
export 'domain_builders.dart';
// Builders for legacy v1 types (used until Phase 5 removes them)
export 'legacy_builders.dart';
