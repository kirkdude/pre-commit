#!/bin/bash
set -e  # Exit on error

# Function for error handling
install_error() {
    echo "Error: Failed to install $1"
    echo "Please check your internet connection and try again"
    exit 1
}

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root or with sudo"
    exit 1
fi

# Install base packages based on distribution
if [ -x "$(command -v apt)" ]; then
    echo "Debian-based system detected"
    export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true

    echo "Updating package lists..."
    apt update -y || install_error "apt update"

    echo "Installing base packages..."
    apt install -y unzip command-not-found git curl vim sudo python3-pip pylint \
      ansible-lint ansible pre-commit black coreutils gawk gnupg \
      software-properties-common golang-go ssh markdownlint || \
      install_error "base packages"

    echo "Installing TFLint..."
    curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash || \
      install_error "tflint"

    echo "Installing TFSec..."
    curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash || \
      install_error "tfsec"

    # Current version for hadolint
    HADOLINT_VERSION="v2.12.0"
    echo "Installing Hadolint version ${HADOLINT_VERSION}..."
    if [ ! -f "/bin/hadolint" ]; then
        wget -O /bin/hadolint "https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-Linux-x86_64" || \
          install_error "hadolint download"
        chmod +x /bin/hadolint || install_error "hadolint permissions"
    else
        echo "Hadolint already installed"
    fi

    # Current version for terraform-docs
    TERRAFORM_DOCS_VERSION="v0.16.0"
    echo "Installing Terraform-docs version ${TERRAFORM_DOCS_VERSION}..."
    if [ ! -f "/usr/local/bin/terraform-docs" ]; then
        curl -Lo ./terraform-docs.tar.gz "https://github.com/terraform-docs/terraform-docs/releases/download/${TERRAFORM_DOCS_VERSION}/terraform-docs-${TERRAFORM_DOCS_VERSION}-$(uname)-amd64.tar.gz" || \
          install_error "terraform-docs download"
        tar -xzf terraform-docs.tar.gz || install_error "terraform-docs extract"
        chmod +x terraform-docs || install_error "terraform-docs permissions"
        mv terraform-docs /usr/local/bin/ || install_error "terraform-docs move"
        rm -f terraform-docs.tar.gz
    else
        echo "Terraform-docs already installed"
    fi

    echo "Installing Terraform..."
    if ! command -v terraform &> /dev/null; then
        wget -O- https://apt.releases.hashicorp.com/gpg | \
          gpg --dearmor | \
          tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null || \
          install_error "hashicorp gpg key"

        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
          https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
          tee /etc/apt/sources.list.d/hashicorp.list > /dev/null || \
          install_error "hashicorp apt repository"

        apt update -y || install_error "apt update after adding hashicorp repository"
        apt install -y terraform || install_error "terraform"
    else
        echo "Terraform already installed"
    fi

    echo "Installing Python packages..."
    pip3 install --ignore-installed checkov || install_error "checkov"
    pip3 install --ignore-installed pre-commit || install_error "pre-commit"

    echo "Verifying pre-commit installation..."
    pre-commit --version
    which pre-commit

    echo "Installing Infracost..."
    curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh || \
      install_error "infracost"

elif [ -x "$(command -v yum)" ]; then
    echo "RPM-based system detected"

    echo "Updating package lists..."
    yum update -y || install_error "yum update"

    echo "Installing EPEL repository..."
    yum install -y epel-release || install_error "epel-release"

    echo "Installing base packages..."
    yum install -y git python3-pip || install_error "base packages"

    echo "Installing pre-commit..."
    pip3 install pre-commit || install_error "pre-commit"

    echo "For additional tools, please consider adding them manually or extending this script."

else
    echo "Error: Unsupported Linux distribution"
    echo "This script supports Debian/Ubuntu and RHEL/CentOS/Fedora systems"
    exit 1
fi

# Check if requirements.txt exists
if [ -f "requirements.txt" ]; then
    echo "Installing Python requirements..."
    pip3 install --ignore-installed -r requirements.txt || install_error "python requirements"
elif [ -f "scripts/requirements.txt" ]; then
    echo "Installing Python requirements from scripts/requirements.txt..."
    pip3 install --ignore-installed -r scripts/requirements.txt || install_error "python requirements"
else
    echo "Warning: requirements.txt not found"
fi

# Only generate SSH key if it doesn't exist and user confirms
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "No SSH key found. Do you want to generate one? (y/n)"
    read -r GENERATE_KEY
    if [[ "$GENERATE_KEY" =~ ^[Yy]$ ]]; then
        echo "Generating SSH key..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" || install_error "ssh key generation"
        echo "SSH key generated at ~/.ssh/id_rsa"
    fi
else
    echo "SSH key already exists at ~/.ssh/id_rsa"
fi

# Run pre-commit if git repository exists
if [ -d ".git" ]; then
    echo "Running pre-commit..."
    if command -v pre-commit &> /dev/null; then
        pre-commit run -a || {
            echo "Warning: pre-commit run had errors. This is expected for initial setup."
        }
    else
        echo "Error: pre-commit not found in PATH"
    fi
else
    echo "Warning: .git directory not found. Cannot run pre-commit."
fi

echo "Setup completed successfully!"
