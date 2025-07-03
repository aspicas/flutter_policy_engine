# Contributing to flutter_policy_engine

Thank you for your interest in contributing! We welcome contributions from everyone. If you are not a direct collaborator, please follow the **fork-and-pull-request** workflow described below.

## Branch Strategy

- **develop**: All external pull requests must target the `develop` branch. This is where active development happens.
- **main**: The `main` branch is reserved for stable releases. It is updated internally by the maintainers via a pull request from `develop` to `main`.
- **Do not submit pull requests directly to `main`.**

## 1. Prerequisites

- Ensure you have a [GitHub account](https://github.com/).
- Install [Git](https://git-scm.com/) and [Flutter](https://flutter.dev/docs/get-started/install) on your machine.
- Familiarize yourself with our [README.md](./README.md) and project structure.

## 2. Forking the Repository

- Navigate to the [flutter_policy_engine GitHub page](https://github.com/your-org/flutter_policy_engine).
- Click the **Fork** button (top right) to create your own copy of the repository.

## 3. Cloning Your Fork

- Clone your fork to your local machine:
  ```sh
  git clone https://github.com/your-username/flutter_policy_engine.git
  cd flutter_policy_engine
  ```

## 4. Creating a Feature Branch

- Always create a new branch for your work:
  ```sh
  git checkout -b feature/your-feature-name
  ```
- Use descriptive branch names (e.g., `feature/add-logging`, `fix/null-pointer-issue`).

## 5. Making Changes

- Make your changes in the appropriate files.
- Follow the language and framework conventions (Dart/Flutter best practices).
- Write clear, self-documenting code. Add docstrings for public APIs and explain the "why" in comments if needed.
- Add or update tests for your changes.

## 6. Keeping Your Fork Up to Date

- Sync your fork with the upstream repository to avoid merge conflicts:
  ```sh
  git remote add upstream https://github.com/your-org/flutter_policy_engine.git
  git fetch upstream
  git merge upstream/develop
  ```

## 7. Commit Messages

- Write concise, meaningful commit messages.
- Use the present tense (e.g., "Add feature X", "Fix bug Y").
- Group related changes into a single commit when possible.

## 8. Submitting a Pull Request

- Push your branch to your fork:
  ```sh
  git push origin feature/your-feature-name
  ```
- Go to your fork on GitHub and click **Compare & pull request**.
- **Set the base branch to `develop` in the main repository.**
- Fill out the PR template, describing your changes and referencing any related issues.
- Submit the pull request to the `develop` branch.

## 9. Code Review Process

- Your PR will be reviewed by maintainers.
- Be responsive to feedback and make requested changes.
- Once approved, your PR will be merged into `develop`.
- The `main` branch is updated internally by maintainers via a separate pull request from `develop` to `main`.

## 10. Additional Guidelines

- Ensure all tests pass before submitting your PR.
- Follow our code style and linting rules (see `analysis_options.yaml`).
- Do not include unrelated changes in your PR.
- If your change is significant, consider updating the documentation.

## 11. Contact

If you have questions, open an issue or contact the maintainers via GitHub Discussions or Issues.

---

Thank you for helping make this project better!
