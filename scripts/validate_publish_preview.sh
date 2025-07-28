#!/bin/bash

# Flutter Policy Engine - Publish Preview Validation Script
# This script validates the package before publishing by running:
# - flutter packages pub publish --dry-run
# - flutter analyze
# - flutter test

set -e  # Exit on any error

echo "🚀 Starting Flutter Policy Engine publish preview validation..."

# Check if we're in the correct directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found. Please run this script from the project root."
    exit 1
fi

echo "📝 Running dart doc to generate documentation..."
dart doc
if [ $? -eq 0 ]; then
    echo "✅ Documentation generated successfully"
else
    echo "❌ Documentation generation failed"
    exit 1
fi

echo "📦 Running flutter packages pub publish --dry-run..."
flutter packages pub publish --dry-run
if [ $? -eq 0 ]; then
    echo "✅ Dry-run publish validation passed"
else
    echo "❌ Dry-run publish validation failed"
    exit 1
fi

echo "🔍 Running flutter analyze..."
flutter analyze
if [ $? -eq 0 ]; then
    echo "✅ Code analysis passed"
else
    echo "❌ Code analysis failed"
    exit 1
fi

echo "🎉 All validation checks passed! Package is ready for publishing."
