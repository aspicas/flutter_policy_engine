# flutter_policy_engine

flutter_policy_engine is a lightweight and extensible policy engine for Flutter that lets you define, manage, and evaluate access control rules declaratively using ABAC (Attribute-Based Access Control) or RBAC models.

## Installation

Make sure you have [Flutter](https://docs.flutter.dev/get-started/install) and [Dart](https://dart.dev/get-dart) installed. It is recommended to use [FVM](https://fvm.app/) for Flutter version management.

```bash
# Clone the repository and enter the directory
# git clone <repo-url>
cd flutter_policy_engine

# Run the setup script (requires bash, Flutter, Node.js, and npm)
./setup.sh
```

The setup script will:

- Check for Flutter and FVM installation
- Install the Flutter version defined in `.fvm/fvm_config.json` (if present)
- Install Dart/Flutter dependencies (`pub get`)
- Install Node.js dependencies (if `package.json` exists)
- Initialize Husky for git hooks (if present)
- Add `.fvm/` to `.gitignore` if needed

## Scripts & Tooling

- `./setup.sh`: Automates environment setup.
- `fvm flutter test` or `flutter test`: Runs tests.
- Husky and Commitlint are set up for commit quality (requires Node.js).

## Linting

This project uses [flutter_lints](https://pub.dev/packages/flutter_lints) to enforce good coding practices. You can customize rules in `analysis_options.yaml`.

## License

MIT © 2025 David Alejandro Garcia Ruiz

---

> If you use VSCode, restart your terminal after setup to ensure FVM is properly detected.
