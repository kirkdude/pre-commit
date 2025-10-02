#!/bin/bash
set -e  # Exit on error

# Determine Homebrew bin directory based on architecture
if [[ -d "/opt/homebrew/bin" ]]; then
    # For Apple Silicon Macs
    BREW_BIN="/opt/homebrew/bin"
elif [[ -d "/usr/local/bin" ]]; then
    # For Intel Macs
    BREW_BIN="/usr/local/bin"
else
    echo "Error: Could not determine Homebrew bin directory"
    exit 1
fi

# Packages to install
PACKAGES=(
    "trufflehog"
    "checkmake"
    "pylint"
    "ansible-lint"
    "ansible"
    "pre-commit"
    "black"
    "terraform-docs"
    "tflint"
    "coreutils"
    "gawk"
    "tfsec"
    "hadolint"
    "jq"
    "terrascan"
    "trivy"
    "markdownlint-cli"  # Added for markdown linting
)

# Function for error handling
install_error() {
    echo "Error: Failed to install $1"
    echo "Please check your internet connection and try again"
    exit 1
}

# Check if we're on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Installing packages for macOS..."

    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found. Please install Homebrew first: https://brew.sh/"
        exit 1
    fi

    # Install packages
    for pkg in "${PACKAGES[@]}"; do
        if [ ! -f "${BREW_BIN}/${pkg}" ]; then
            echo "Installing ${pkg}..."
            brew install "${pkg}" || install_error "${pkg}"
        else
            echo "${pkg} already installed"
        fi
    done

    # Install tfenv and latest terraform
    if [ ! -f "${BREW_BIN}/tfenv" ]; then
        echo "Installing tfenv..."
        brew install tfenv || install_error "tfenv"

        echo "Initializing tfenv..."
        tfenv init

        echo "Installing latest Terraform version..."
        LATEST=$(tfenv list-remote | head -1)
        tfenv install "${LATEST}" || install_error "terraform ${LATEST}"
        tfenv use "${LATEST}"
    fi

    # Install infracost
    if [ ! -f "${BREW_BIN}/infracost" ]; then
        echo "Installing infracost..."
        brew install infracost || install_error "infracost"
    fi
else
    echo "Error: This script is for macOS only"
    exit 1
fi

# Check if requirements.txt exists
if [ -f "requirements.txt" ]; then
    echo "Installing Python requirements..."
    python3 -m pip install -r requirements.txt || {
        echo "Error: Failed to install Python requirements"
        exit 1
    }
else
    echo "Warning: requirements.txt not found"
fi

# Configure pre-commit
echo "Configuring pre-commit..."

# Check if git hooks directory exists and install pre-commit hook
if [ -d ".git/hooks" ]; then
    pre-commit uninstall
    pre-commit install || {
        echo "Error: Failed to install pre-commit hook"
        exit 1
    }
    echo "Pre-commit hook installed successfully"
else
    echo "Warning: .git/hooks directory not found. You might not be in a git repository."
fi

# Configure global git template directory for pre-commit
echo "Setting up git template directory..."
TEMPLATE_DIR=~/.git-template
git config --global init.templateDir "${TEMPLATE_DIR}"
pre-commit init-templatedir -t pre-commit "${TEMPLATE_DIR}" || {
    echo "Error: Failed to initialize template directory"
    exit 1
}

echo "Setup completed successfully!"
