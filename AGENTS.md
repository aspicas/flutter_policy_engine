# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

Flutter Policy Engine (`flutter_policy_engine`) is a Dart/Flutter package providing RBAC/ABAC access control. It is a **library** (not a multi-service app) — no databases, Docker, or external services required.

### Flutter SDK

Flutter 3.29.3 is installed at `/opt/flutter`. The PATH is configured in `~/.bashrc`. The `.fvmrc` specifies the version; FVM is not installed but plain `flutter` commands work equivalently.

### Key commands

| Task | Command |
|---|---|
| Install Dart deps | `flutter pub get` |
| Install npm deps | `npm install` |
| Run lint/analysis | `dart analyze` |
| Check formatting | `dart format --set-exit-if-changed lib/ test/` |
| Run all tests | `flutter test` |
| Run tests with coverage | `./scripts/test_with_coverage.sh` |
| Run example app (web) | `cd example && flutter run -d chrome --web-port=8080` |

### Gotchas

- The pre-commit hook (`.husky/pre-commit`) runs `npm test`, which currently just echoes an error message — this is expected and does not block commits.
- The commit-msg hook enforces [Conventional Commits](https://www.conventionalcommits.org/) via commitlint. Use commit messages like `feat: ...`, `fix: ...`, `chore: ...`, etc.
- Android and Linux desktop toolchains are not installed; `flutter doctor` will report warnings for these — they are irrelevant for this package library.
- The example app runs on Flutter web (Chrome). No emulators or physical devices needed.
