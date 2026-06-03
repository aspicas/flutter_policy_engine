#!/usr/bin/env bash
# Verifies that lib/src/domain/ contains no Flutter SDK, dart:ui, or dart:io
# imports. The package's own internal imports (package:flutter_policy_engine/*)
# are allowed.
# Exit code 0 = clean; exit code 1 = violation found.
set -euo pipefail

DOMAIN_DIR="lib/src/domain"

if [ ! -d "$DOMAIN_DIR" ]; then
  echo "ℹ️  Domain directory not yet created — skipping purity check"
  exit 0
fi

# Match only the Flutter SDK imports and dart:io / dart:ui.
# Exclude the package's own imports which happen to contain "flutter" in
# the package name.
VIOLATIONS=$(find "$DOMAIN_DIR" -name '*.dart' -exec grep -l \
  "package:flutter/\|dart:ui\|dart:io" {} \; 2>/dev/null || true)

if [ -n "$VIOLATIONS" ]; then
  echo "❌ Domain purity violation — Flutter/IO imports found in:"
  echo "$VIOLATIONS"
  exit 1
fi

echo "✅ Domain layer is pure Dart"
exit 0
