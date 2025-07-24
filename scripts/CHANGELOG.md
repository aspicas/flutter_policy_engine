# GitHub Actions Testing Scripts Changelog

## [1.0.0] - 2025-07-24

### Added

- **GitHub Actions Testing Script** (`test_github_actions.sh`)

  - Comprehensive script to test GitHub Actions workflows locally using `act` and Docker
  - Support for all project workflows: main-branch-pipeline, develop-branch-pipeline, check-commits, and release
  - Dry-run mode for safe testing without execution
  - Verbose output for debugging
  - Automatic workflow validation and syntax checking
  - Smart defaults based on workflow type
  - Colored output with timestamps
  - Automatic cleanup of Docker containers

- **Dependency Installation Script** (`install_dependencies.sh`)

  - Cross-platform installation of `act` CLI tool
  - Docker installation and setup guidance
  - Python dependencies management (PyYAML for YAML validation)
  - Automatic environment file setup (.env and .secrets)
  - Installation verification and health checks
  - Support for macOS, Linux, and Windows

- **Configuration Files**

  - `.actrc` - Optimized act configuration for the project
  - `env.example` - Template for environment variables
  - `secrets.example` - Template for secrets configuration
  - Comprehensive documentation in `README.md`

- **Documentation**
  - Detailed usage guide with examples
  - Troubleshooting section
  - Integration examples for CI/CD pipelines
  - Pre-commit hook examples
  - Cross-platform installation instructions

### Features

- **Workflow Testing**: Test any GitHub Actions workflow locally before pushing
- **Event Simulation**: Simulate push, pull_request, and other GitHub events
- **Branch Support**: Test workflows with different branch scenarios
- **Validation**: YAML syntax validation and workflow correctness checking
- **Performance**: Optimized Docker image usage and container reuse
- **Safety**: Dry-run mode prevents accidental execution
- **Debugging**: Verbose mode for detailed troubleshooting

### Supported Workflows

1. **Main Branch Pipeline** - Validates PRs to main branch
2. **Develop Branch Pipeline** - Validates PRs to develop branch
3. **Check Commits** - Validates commit messages on all branches
4. **Release Pipeline** - Tests semantic-release automation

### Prerequisites

- Docker (running)
- Git repository
- act CLI (auto-installed by script)
- Python 3 (optional, for enhanced YAML validation)

### Quick Start

```bash
# Install dependencies
./scripts/install_dependencies.sh

# Test a workflow
./scripts/test_github_actions.sh -w .github/workflows/check-commits.yml --dry-run

# List available workflows
./scripts/test_github_actions.sh --list-workflows
```

### Breaking Changes

None - This is a new feature addition.

### Deprecations

None.

### Removed

None.

### Fixed

None.

### Security

- Secure handling of secrets through `.secrets` file
- Automatic cleanup of Docker containers
- Validation of workflow files before execution
- Safe defaults for environment variables

### Performance

- Optimized Docker image selection (`catthehacker/ubuntu:act-latest`)
- Container reuse for faster subsequent runs
- Bind mounts for better performance
- Efficient workflow parsing and validation

### Documentation

- Comprehensive README with examples
- Inline help for all scripts
- Troubleshooting guide
- Integration examples
- Cross-platform installation instructions
