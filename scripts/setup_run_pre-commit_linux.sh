#!/bin/bash
# Check if the system is Debian-based
if [ -x "$(command -v apt)" ]; then
  echo "Debian-based system detected"
  export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
  apt update -y
  apt install unzip command-not-found git curl vim sudo python3-pip pylint ansible-lint ansible pre-commit black coreutils gawk gnupg software-properties-common golang-go ssh -y

  # tflint
  curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

  # tfsec
  curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash

  # hadolint
  sudo wget -O /bin/hadolint https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64
  sudo chmod +x /bin/hadolint

  # terraform-docs
  curl -Lo ./terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/download/v0.16.0/terraform-docs-v0.16.0-$(uname)-amd64.tar.gz
  tar xvfz terraform-docs.tar.gz
  chmod +x terraform-docs
  mv terraform-docs /usr/local/terraform-docs

  # terraform
  wget -O- https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor | \
  sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
  gpg --no-default-keyring \
  --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
  --fingerprint
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt update
  sudo apt-get install terraform

  # checkov
  pip3 install checkov

  # pre-commit
  pip3 install pre-commit
  pre-commit --version
  type pre-commit

  # infracost
  curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh

elif [ -x "$(command -v yum)" ]; then
  echo "RPM-based system detected."
  yum update -y
  yum install -y pre-commit

else
  echo "System unsupported, update this script"
  exit 1
fi

ssh-keygen -q -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

/usr/bin/pre-commit run -a
