#!/bin/bash

# Flutter Policy Engine - Test with Coverage Script
# This script runs all tests and generates coverage reports

set -e  # Exit on any error

echo "🧪 Running Flutter tests with coverage..."

# Run tests with coverage
fvm flutter test --coverage

echo "📊 Generating coverage summary..."
lcov --summary coverage/lcov.info

echo "🌐 Generating HTML coverage report..."
genhtml coverage/lcov.info -o coverage/html

echo "✅ Coverage report generated successfully!"
echo "📁 HTML report available at: coverage/html/index.html"

# Open the coverage report in browser (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🔗 Opening coverage report in browser..."
    open coverage/html/index.html
else
    echo "📖 To view the coverage report, open: coverage/html/index.html"
fi

echo "🎉 Test coverage process completed!" 