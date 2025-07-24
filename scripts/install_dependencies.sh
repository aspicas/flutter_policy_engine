#!/bin/bash

# Installation script for GitHub Actions testing dependencies
# This script helps set up act, Docker, and other required tools

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}${NC}"
}

# Function to detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)    echo "macos";;
        Linux*)     echo "linux";;
        CYGWIN*|MINGW*|MSYS*) echo "windows";;
        *)          echo "unknown";;
    esac
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install act on macOS
install_act_macos() {
    print_status $BLUE "Installing act on macOS..."
    
    if command_exists brew; then
        brew install act
        print_status $GREEN "✓ act installed successfully via Homebrew"
    else
        print_status $RED "Error: Homebrew is not installed."
        echo "Please install Homebrew first:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
}

# Function to install act on Linux
install_act_linux() {
    print_status $BLUE "Installing act on Linux..."
    
    # Try to detect package manager
    if command_exists apt-get; then
        # Ubuntu/Debian
        print_status $YELLOW "Detected apt package manager"
        curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
    elif command_exists yum; then
        # CentOS/RHEL
        print_status $YELLOW "Detected yum package manager"
        curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
    elif command_exists dnf; then
        # Fedora
        print_status $YELLOW "Detected dnf package manager"
        curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
    else
        print_status $RED "Error: Unsupported package manager."
        echo "Please install act manually:"
        echo "  curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash"
        exit 1
    fi
    
    print_status $GREEN "✓ act installed successfully"
}

# Function to install act on Windows
install_act_windows() {
    print_status $BLUE "Installing act on Windows..."
    
    if command_exists choco; then
        choco install act-cli
        print_status $GREEN "✓ act installed successfully via Chocolatey"
    else
        print_status $RED "Error: Chocolatey is not installed."
        echo "Please install Chocolatey first:"
        echo "  Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
        exit 1
    fi
}

# Function to install Docker
install_docker() {
    local os=$(detect_os)
    
    print_status $BLUE "Installing Docker on $os..."
    
    case "$os" in
        macos)
            print_status $YELLOW "Please install Docker Desktop manually:"
            echo "  Visit: https://www.docker.com/products/docker-desktop"
            echo "  Download and install Docker Desktop for Mac"
            ;;
        linux)
            if command_exists apt-get; then
                # Ubuntu/Debian
                sudo apt-get update
                sudo apt-get install -y docker.io
                sudo systemctl start docker
                sudo usermod -aG docker "$USER"
                print_status $GREEN "✓ Docker installed successfully"
                print_status $YELLOW "Note: You may need to log out and back in for group changes to take effect"
            elif command_exists yum; then
                # CentOS/RHEL
                sudo yum install -y docker
                sudo systemctl start docker
                sudo usermod -aG docker "$USER"
                print_status $GREEN "✓ Docker installed successfully"
                print_status $YELLOW "Note: You may need to log out and back in for group changes to take effect"
            else
                print_status $RED "Error: Unsupported package manager for Docker installation"
                echo "Please install Docker manually: https://docs.docker.com/engine/install/"
                exit 1
            fi
            ;;
        windows)
            print_status $YELLOW "Please install Docker Desktop manually:"
            echo "  Visit: https://www.docker.com/products/docker-desktop"
            echo "  Download and install Docker Desktop for Windows"
            ;;
        *)
            print_status $RED "Error: Unsupported operating system"
            echo "Please install Docker manually: https://docs.docker.com/engine/install/"
            exit 1
            ;;
    esac
}

# Function to install Python dependencies
install_python_deps() {
    print_status $BLUE "Installing Python dependencies..."
    
    if command_exists python3; then
        # Try to install PyYAML for better YAML validation
        if python3 -c "import yaml" 2>/dev/null; then
            print_status $GREEN "✓ PyYAML already installed"
        else
            print_status $YELLOW "Installing PyYAML for YAML validation..."
            if command_exists pip3; then
                pip3 install PyYAML
                print_status $GREEN "✓ PyYAML installed successfully"
            else
                print_status $YELLOW "Warning: pip3 not found, PyYAML not installed"
                print_status $YELLOW "The script will still work but with basic YAML validation"
            fi
        fi
    else
        print_status $YELLOW "Warning: Python 3 not found"
        print_status $YELLOW "The script will still work but with basic YAML validation"
    fi
}

# Function to setup environment files
setup_environment() {
    print_status $BLUE "Setting up environment files..."
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root="$(dirname "$script_dir")"
    
    # Copy environment file if it doesn't exist
    if [[ ! -f "$project_root/.env" ]]; then
        if [[ -f "$script_dir/env.example" ]]; then
            cp "$script_dir/env.example" "$project_root/.env"
            print_status $GREEN "✓ Created .env file from template"
        else
            print_status $YELLOW "Warning: env.example not found, creating basic .env file"
            cat > "$project_root/.env" << EOF
# Environment variables for local GitHub Actions testing
GITHUB_ACTOR=test-user
GITHUB_REPOSITORY=your-username/flutter_policy_engine
GITHUB_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
GITHUB_REF=refs/heads/develop
GITHUB_EVENT_NAME=pull_request
CI=true
ACT=true
EOF
            print_status $GREEN "✓ Created basic .env file"
        fi
    else
        print_status $YELLOW "✓ .env file already exists"
    fi
    
    # Copy secrets file if it doesn't exist
    if [[ ! -f "$project_root/.secrets" ]]; then
        if [[ -f "$script_dir/secrets.example" ]]; then
            cp "$script_dir/secrets.example" "$project_root/.secrets"
            print_status $GREEN "✓ Created .secrets file from template"
            print_status $YELLOW "⚠️  Remember to update .secrets with your actual values"
        else
            print_status $YELLOW "Warning: secrets.example not found, creating basic .secrets file"
            cat > "$project_root/.secrets" << EOF
# Secrets file for local GitHub Actions testing
# WARNING: Never commit this file to version control
GH_TOKEN=your-github-token-here
EOF
            print_status $GREEN "✓ Created basic .secrets file"
            print_status $YELLOW "⚠️  Remember to update .secrets with your actual values"
        fi
    else
        print_status $YELLOW "✓ .secrets file already exists"
    fi
}

# Function to verify installation
verify_installation() {
    print_status $BLUE "Verifying installation..."
    
    local all_good=true
    
    # Check act
    if command_exists act; then
        print_status $GREEN "✓ act is installed"
    else
        print_status $RED "✗ act is not installed"
        all_good=false
    fi
    
    # Check Docker
    if command_exists docker; then
        if docker info >/dev/null 2>&1; then
            print_status $GREEN "✓ Docker is installed and running"
        else
            print_status $RED "✗ Docker is installed but not running"
            all_good=false
        fi
    else
        print_status $RED "✗ Docker is not installed"
        all_good=false
    fi
    
    # Check Python
    if command_exists python3; then
        print_status $GREEN "✓ Python 3 is installed"
        if python3 -c "import yaml" 2>/dev/null; then
            print_status $GREEN "✓ PyYAML is installed"
        else
            print_status $YELLOW "⚠ PyYAML is not installed (optional)"
        fi
    else
        print_status $YELLOW "⚠ Python 3 is not installed (optional)"
    fi
    
    # Check git
    if command_exists git; then
        print_status $GREEN "✓ Git is installed"
    else
        print_status $RED "✗ Git is not installed"
        all_good=false
    fi
    
    if [[ "$all_good" == true ]]; then
        print_status $GREEN "🎉 All required dependencies are installed and ready!"
        echo
        print_status $BLUE "Next steps:"
        echo "  1. Update .env and .secrets files with your values"
        echo "  2. Run: ./scripts/test_github_actions.sh --help"
        echo "  3. Test a workflow: ./scripts/test_github_actions.sh -w .github/workflows/check-commits.yml --dry-run"
    else
        print_status $RED "❌ Some dependencies are missing or not working properly"
        echo
        print_status $YELLOW "Please fix the issues above and run this script again"
        exit 1
    fi
}

# Main installation function
main() {
    print_status $BLUE "🚀 GitHub Actions Testing Dependencies Installer"
    echo
    
    local os=$(detect_os)
    print_status $BLUE "Detected OS: $os"
    echo
    
    # Install act
    if command_exists act; then
        print_status $GREEN "✓ act is already installed"
    else
        case "$os" in
            macos) install_act_macos ;;
            linux) install_act_linux ;;
            windows) install_act_windows ;;
            *) 
                print_status $RED "Error: Unsupported operating system"
                exit 1
                ;;
        esac
    fi
    
    # Install Docker
    if command_exists docker && docker info >/dev/null 2>&1; then
        print_status $GREEN "✓ Docker is already installed and running"
    else
        install_docker
    fi
    
    # Install Python dependencies
    install_python_deps
    
    # Setup environment files
    setup_environment
    
    echo
    verify_installation
}

# Parse command line arguments
case "${1:-}" in
    --help|-h)
        cat << EOF
Usage: $0 [OPTIONS]

Install dependencies for GitHub Actions testing with act and Docker.

OPTIONS:
    --help, -h    Show this help message
    --verify      Only verify installation without installing

EXAMPLES:
    # Install all dependencies
    $0

    # Verify installation only
    $0 --verify

EOF
        exit 0
        ;;
    --verify)
        verify_installation
        exit 0
        ;;
    "")
        main
        ;;
    *)
        print_status $RED "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac 