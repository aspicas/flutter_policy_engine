# Flutter Policy Engine

[![Pub Version](https://img.shields.io/pub/v/flutter_policy_engine)](https://pub.dev/packages/flutter_policy_engine)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.4.1+-blue.svg)](https://flutter.dev)

A lightweight, extensible policy engine for Flutter applications. Define, manage, and evaluate access control rules declaratively using **ABAC** (Attribute-Based Access Control) or **RBAC** (Role-Based Access Control) models with a clean, intuitive API.

## ✨ Features

- **🔐 Dual Access Control Models**: Support for both Role-Based (RBAC) and Attribute-Based (ABAC) access control
- **🎯 Declarative Policy Definitions**: Define access rules using simple, readable configurations
- **🏗️ Modular Architecture**: Extensible design with clear separation of concerns
- **⚡ Lightweight & Fast**: Minimal overhead with efficient policy evaluation
- **🔄 Real-time Updates**: Dynamic policy updates without app restarts
- **🎨 Flutter-Native**: Built specifically for Flutter with widget integration
- **📱 Easy Integration**: Simple setup with minimal boilerplate code
- **🧪 Comprehensive Testing**: Full test coverage with examples

## 🚀 Quick Start

### Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_policy_engine: ^1.0.1
```

Run the installation:

```bash
flutter pub get
```

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:flutter_policy_engine/flutter_policy_engine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize policy manager
  final policyManager = PolicyManager();
  await policyManager.initialize({
    "admin": ["dashboard", "users", "settings", "reports"],
    "manager": ["dashboard", "users", "reports"],
    "user": ["dashboard"],
    "guest": ["login"]
  });

  runApp(MyApp(policyManager: policyManager));
}

class MyApp extends StatelessWidget {
  final PolicyManager policyManager;

  const MyApp({super.key, required this.policyManager});

  @override
  Widget build(BuildContext context) {
    return PolicyProvider(
      policyManager: policyManager,
      child: MaterialApp(
        title: 'Policy Engine Demo',
        home: HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: Column(
        children: [
          // Only show for admin and manager roles
          PolicyWidget(
            role: "admin",
            content: "users",
            child: UserManagementCard(),
            fallback: AccessDeniedWidget(),
          ),

          // Show for all authenticated users
          PolicyWidget(
            role: "user",
            content: "dashboard",
            child: DashboardCard(),
          ),
        ],
      ),
    );
  }
}
```

## 📚 Core Concepts

### Policy Manager

The central orchestrator that manages all access control logic:

```dart
final policyManager = PolicyManager();

// Initialize with role definitions
await policyManager.initialize({
  "admin": ["dashboard", "users", "settings"],
  "user": ["dashboard"],
});

// Check access programmatically
bool hasAccess = policyManager.evaluateAccess("admin", "users"); // true
bool canAccess = policyManager.evaluateAccess("user", "settings"); // false
```

### Policy Widget

Conditionally render content based on user roles:

```dart
PolicyWidget(
  role: "admin",
  content: "settings",
  child: SettingsPage(),
  fallback: AccessDeniedWidget(),
)
```

### Role Management

Create and manage roles dynamically:

```dart
// Add a new role
await policyManager.addRole("moderator", ["dashboard", "comments"]);

// Update existing role
await policyManager.updateRole("user", ["dashboard", "profile"]);

// Remove a role
await policyManager.removeRole("guest");
```

## 🧪 Testing

### Local Testing

Run tests with coverage:

```bash
# Using the provided script (recommended)
./scripts/test_with_coverage.sh

# Or manually
fvm flutter test --coverage
lcov --summary coverage/lcov.info
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Example App

Explore the interactive example app:

```bash
cd example
flutter run
```

The example includes:

- Basic policy demonstrations
- Role management interface
- Real-time policy updates
- Access control scenarios

## 📚 Documentation

- **[Quick Start Guide](docs/quick-start.mdx)** - Get up and running in minutes
- **[Core Concepts](docs/core-concepts/)** - Deep dive into policy management
- **[Examples](docs/examples/)** - Practical usage examples

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

```bash
# Clone the repository
git clone https://github.com/aspicas/flutter_policy_engine.git
cd flutter_policy_engine

# Run the setup script
./setup.sh

# Run tests
./scripts/test_with_coverage.sh
```

### Code Style

- Follow the existing code patterns and style
- Write clear commit messages (Commitlint enabled)
- Add tests for new features
- Ensure all tests pass before submitting PRs

## 📄 License

MIT © 2025 David Alejandro Garcia Ruiz

---

> **💡 Tip**: If you use VSCode, restart your terminal after setup to ensure FVM is properly detected.
