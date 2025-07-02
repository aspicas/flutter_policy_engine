#!/bin/bash
set -e

git config commit.template commit-template.txt

# Function to use flutter or fvm flutter
flutter_cmd() {
  if command -v fvm &> /dev/null; then
    fvm flutter "$@"
  else
    flutter "$@"
  fi
}

echo "[1/6] Checking for Flutter..."
if ! command -v flutter &> /dev/null; then
  echo "[ERROR] Flutter is not installed. Please install it before continuing: https://docs.flutter.dev/get-started/install"
  exit 1
fi

echo "[2/6] Checking for FVM..."
if command -v fvm &> /dev/null; then
  echo "FVM is installed. Ensuring project uses FVM-managed Flutter..."
  if [ -f ".fvm/fvm_config.json" ]; then
    FLUTTER_VERSION=$(grep -o '"flutterSdkVersion": *"[^"]*"' .fvm/fvm_config.json | cut -d '"' -f4)
    echo "  Project FVM Flutter version: $FLUTTER_VERSION"
    fvm install "$FLUTTER_VERSION"
    fvm use "$FLUTTER_VERSION"
    echo "  Using FVM Flutter version: $(fvm flutter --version | head -n 1)"
  else
    echo "[Warning] .fvm/fvm_config.json not found. Run 'fvm install stable' to initialize."
  fi
else
  echo "[Warning] FVM is not installed. Consider installing it for version management: https://fvm.app/"
fi

echo "[3/6] Checking for Node.js and npm..."
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
  echo "[ERROR] Node.js and npm are required for JS tooling. Please install Node.js: https://nodejs.org/"
  exit 1
fi

echo "[4/6] Installing Flutter/Dart dependencies..."
flutter_cmd pub get

echo "[5/6] Installing Node.js dependencies (if package.json exists)..."
if [ -f "package.json" ]; then
  npm install
  if grep -q '"husky"' package.json; then
    echo "Initializing Husky..."
    npm run prepare
  fi
fi

echo "[6/6] Ensuring .fvm/ is in .gitignore..."
if [ -f .gitignore ]; then
  if ! grep -q '^.fvm/$' .gitignore; then
    echo ".fvm/" >> .gitignore
    echo "  Added .fvm/ to .gitignore."
  fi
fi

echo "\nSetup completed successfully!"
echo "----------------------------------------"
echo "To run tests:"
echo "  fvm flutter test   # (or 'flutter test' if not using FVM)"
echo "To use Flutter, prefer:"
echo "  fvm flutter <command>"
echo "----------------------------------------"
echo "If using VSCode, restart your terminal to ensure FVM is picked up." 