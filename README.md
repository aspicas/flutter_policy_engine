# flutter_policy_engine

A lightweight, extensible policy engine for Flutter. Define, manage, and evaluate access control rules declaratively using ABAC (Attribute-Based Access Control) or RBAC (Role-Based Access Control) models.

## Features

- Attribute-Based and Role-Based Access Control (ABAC/RBAC)
- Declarative rule definitions
- Extensible and modular design
- Easy integration with Flutter apps

## Installation

Ensure you have [Flutter](https://docs.flutter.dev/get-started/install) and [Dart](https://dart.dev/get-dart) installed. [FVM](https://fvm.app/) is recommended for managing Flutter versions.

```bash
# Clone the repository and enter the directory
git clone <repo-url>
cd flutter_policy_engine

# Run the setup script (requires bash, Flutter, Node.js, and npm)
./setup.sh
```

The setup script will:

- Check for Flutter and FVM
- Install the Flutter version from `.fvm/fvm_config.json` (if present)
- Install Dart/Flutter dependencies (`pub get`)
- Install Node.js dependencies (if `package.json` exists)
- Initialize Husky for git hooks (if present)
- Add `.fvm/` to `.gitignore` if needed

## Contributing

Contributions are welcome! Please:

- Follow the existing code style and patterns
- Write clear commit messages (Commitlint and Husky are enabled)
- Add or update tests for new features or bug fixes
- Open a pull request with a clear description

## License

MIT © 2025 David Alejandro Garcia Ruiz

---

> **Tip:** If you use VSCode, restart your terminal after setup to ensure FVM is properly detected.
