# GitHub Actions Testing Scripts

This directory contains scripts for testing GitHub Actions workflows locally using `act` and Docker.

## 📋 Prerequisites

Before using these scripts, ensure you have the following installed:

### 1. Act CLI

Act is a tool that runs your GitHub Actions locally using Docker.

**macOS:**

```bash
brew install act
```

**Linux:**

```bash
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

**Windows:**

```bash
choco install act-cli
```

### 2. Docker

Make sure Docker is installed and running on your system.

**macOS/Windows:**

- Install Docker Desktop from [docker.com](https://www.docker.com/products/docker-desktop)

**Linux:**

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install docker.io
sudo systemctl start docker
sudo usermod -aG docker $USER
```

### 3. Python 3 (for YAML validation)

The script uses Python 3 for basic YAML validation.

## 🚀 Quick Start

### 1. Setup Environment

Copy the example environment and secrets files:

```bash
# Copy environment file
cp scripts/env.example .env

# Copy secrets file (optional, for workflows that need secrets)
cp scripts/secrets.example .secrets
```

### 2. Customize Configuration

Edit the `.env` and `.secrets` files with your specific values:

```bash
# Edit environment variables
nano .env

# Edit secrets (if needed)
nano .secrets
```

### 3. Test a Workflow

Run the testing script:

```bash
# Test main branch pipeline
./scripts/test_github_actions.sh -w .github/workflows/main-branch-pipeline.yml

# Test develop branch pipeline
./scripts/test_github_actions.sh -w .github/workflows/develop-branch-pipeline.yml

# Test commit validation
./scripts/test_github_actions.sh -w .github/workflows/check-commits.yml
```

## 📖 Usage

### Basic Usage

```bash
./scripts/test_github_actions.sh [OPTIONS] [WORKFLOW_FILE]
```

### Options

| Option                | Description                                       |
| --------------------- | ------------------------------------------------- |
| `-w, --workflow FILE` | Specific workflow file to test                    |
| `-e, --event TYPE`    | Event type to simulate (push, pull_request, etc.) |
| `-b, --branch BRANCH` | Branch name for the event                         |
| `-d, --dry-run`       | Show what would be executed without running       |
| `-v, --verbose`       | Enable verbose output                             |
| `-n, --no-cleanup`    | Don't clean up Docker containers after testing    |
| `-h, --help`          | Show help message                                 |

### Examples

#### Test Main Branch Pipeline

```bash
# Test with pull request from develop branch
./scripts/test_github_actions.sh -w .github/workflows/main-branch-pipeline.yml -e pull_request -b develop

# Dry run to see what would be executed
./scripts/test_github_actions.sh -w .github/workflows/main-branch-pipeline.yml -e pull_request -b develop --dry-run
```

#### Test Develop Branch Pipeline

```bash
# Test with pull request from feature branch
./scripts/test_github_actions.sh -w .github/workflows/develop-branch-pipeline.yml -e pull_request -b feature/new-feature
```

#### Test Commit Validation

```bash
# Test commit message validation
./scripts/test_github_actions.sh -w .github/workflows/check-commits.yml -e push -b feature/test
```

#### Test Release Workflow

```bash
# Test release workflow (requires GH_TOKEN in .secrets)
./scripts/test_github_actions.sh -w .github/workflows/release.yml -e push -b main
```

#### List Available Workflows

```bash
./scripts/test_github_actions.sh --list-workflows
```

## 🔧 Configuration

### Act Configuration

The script automatically creates a `.actrc` file with optimized settings for this project:

- Uses `catthehacker/ubuntu:act-latest` image for better compatibility
- Enables bind mounts for better performance
- Reuses containers when possible
- Shows timestamps in output

### Environment Variables

The `.env` file can contain:

- GitHub configuration (actor, repository, ref, etc.)
- Flutter and Node.js versions
- Test configuration
- CI/CD specific variables

### Secrets

The `.secrets` file can contain:

- GitHub tokens for API access
- NPM tokens for publishing
- Docker credentials
- Other sensitive data

**⚠️ Important:** Never commit the `.secrets` file to version control!

## 🧪 Available Workflows

This project includes the following GitHub Actions workflows:

### 1. Main Branch Pipeline (`.github/workflows/main-branch-pipeline.yml`)

- **Purpose:** Validates PRs to main branch
- **Triggers:** Pull requests to main branch
- **Jobs:**
  - Validate merge source (only develop branch allowed)
  - Validate commit messages
  - Run Flutter tests and coverage

### 2. Develop Branch Pipeline (`.github/workflows/develop-branch-pipeline.yml`)

- **Purpose:** Validates PRs to develop branch
- **Triggers:** Pull requests to develop branch
- **Jobs:**
  - Validate commit messages
  - Run Flutter tests and coverage

### 3. Check Commits (`.github/workflows/check-commits.yml`)

- **Purpose:** Validates commit messages on all branches
- **Triggers:** Push and pull request events
- **Jobs:**
  - Validate commit messages using commitlint

### 4. Release Pipeline (`.github/workflows/release.yml`)

- **Purpose:** Automates releases using semantic-release
- **Triggers:** Push to main branch
- **Jobs:**
  - Run semantic-release for versioning and publishing

## 🐛 Troubleshooting

### Common Issues

#### 1. Act Not Found

```bash
Error: 'act' is not installed.
```

**Solution:** Install act using the instructions in the Prerequisites section.

#### 2. Docker Not Running

```bash
Error: Docker is not running or not accessible.
```

**Solution:** Start Docker Desktop or Docker daemon.

#### 3. Permission Denied

```bash
Error: Not in a git repository.
```

**Solution:** Run the script from the root of your git repository.

#### 4. Workflow File Not Found

```bash
Error: Workflow file 'workflow.yml' not found.
```

**Solution:** Check the workflow file path and use `--list-workflows` to see available workflows.

#### 5. YAML Validation Failed

```bash
Error: Invalid YAML in workflow file
```

**Solution:** Check the workflow file syntax and ensure it's valid YAML.

### Debug Mode

Enable verbose output for debugging:

```bash
./scripts/test_github_actions.sh -w .github/workflows/main-branch-pipeline.yml -v
```

### Dry Run

Test the command without executing:

```bash
./scripts/test_github_actions.sh -w .github/workflows/main-branch-pipeline.yml --dry-run
```

## 🔄 Continuous Integration

You can integrate this testing script into your development workflow:

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Test workflows before committing
./scripts/test_github_actions.sh -w .github/workflows/check-commits.yml -e push -b $(git branch --show-current)
```

### CI Pipeline

Add to your CI pipeline to test workflows:

```yaml
- name: Test GitHub Actions
  run: |
    ./scripts/test_github_actions.sh -w .github/workflows/main-branch-pipeline.yml -e pull_request -b develop
```

## 📚 Additional Resources

- [Act Documentation](https://nektosact.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter CI/CD Best Practices](https://docs.flutter.dev/deployment/ci)
- [Commitlint Documentation](https://commitlint.js.org/)

## 🤝 Contributing

When adding new workflows or modifying existing ones:

1. Test locally using this script
2. Ensure all jobs pass
3. Update this README if needed
4. Consider adding new test cases to the script

## 📄 License

This script is part of the flutter_policy_engine project and follows the same license terms.
