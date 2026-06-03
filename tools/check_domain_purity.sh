#!/usr/bin/env bash
# Verifies that lib/src/domain/ contains no Flutter, dart:ui, or dart:io imports.
# Exit code 0 = clean; exit code 1 = violation found.
set -euo pipefail

DOMAIN_DIR="lib/src/domain"

if [ ! -d "$DOMAIN_DIR" ]; then
  echo "ℹ️  Domain directory not yet created — skipping purity check"
  exit 0
fi

VIOLATIONS=$(find "$DOMAIN_DIR" -name '*.dart' -exec grep -l \
  "package:flutter\|dart:ui\|dart:io" {} \; 2>/dev/null || true)

if [ -n "$VIOLATIONS" ]; then
  echo "❌ Domain purity violation — Flutter/IO imports found in:"
  echo "$VIOLATIONS"
  exit 1
fi

echo "✅ Domain layer is pure Dart"
exit 0
