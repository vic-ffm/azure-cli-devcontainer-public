#!/bin/bash
# Azure Infrastructure Distrobox - Tool Installation Script
# Installs all required infrastructure tools
#
# This script requires sudo access and should be run inside the distrobox.

set -euo pipefail

LOCAL_BIN="$HOME/.local/bin"
ARCH=$(dpkg --print-architecture)

# Helper function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Helper function to get latest GitHub release version
get_latest_release() {
    curl -s "https://api.github.com/repos/$1/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/'
}

echo "Installing infrastructure tools..."
echo ""

# Ensure apt cache is updated
echo "[1/8] Updating package cache..."
sudo apt-get update -qq

# ============================================
# Azure CLI
# ============================================
echo "[2/8] Installing Azure CLI..."
if command_exists az; then
    echo "  Azure CLI already installed: $(az version --query '"azure-cli"' -o tsv 2>/dev/null || echo 'unknown')"
else
    # Install via Microsoft's official script
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi

# Install Azure CLI extensions
echo "  Installing Azure CLI extensions..."
az extension add --name account --yes --only-show-errors 2>/dev/null || true
az extension add --name resource-graph --yes --only-show-errors 2>/dev/null || true
az extension add --name containerapp --yes --only-show-errors 2>/dev/null || true
az extension add --name aks-preview --yes --only-show-errors 2>/dev/null || true
az extension add --name front-door --yes --only-show-errors 2>/dev/null || true
echo "  Azure CLI extensions installed."

# ============================================
# OpenTofu
# ============================================
echo "[3/8] Installing OpenTofu..."
if command_exists tofu; then
    echo "  OpenTofu already installed: $(tofu version -json 2>/dev/null | jq -r '.opentofu_version' 2>/dev/null || tofu version 2>/dev/null | head -1)"
else
    # Install via official installer script
    curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o /tmp/install-opentofu.sh
    chmod +x /tmp/install-opentofu.sh
    sudo /tmp/install-opentofu.sh --install-method deb
    rm -f /tmp/install-opentofu.sh
fi

# ============================================
# GitHub CLI
# ============================================
echo "[4/8] Installing GitHub CLI..."
if command_exists gh; then
    echo "  GitHub CLI already installed: $(gh --version 2>/dev/null | head -1)"
else
    # Add GitHub CLI repository
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y gh
fi

# ============================================
# PowerShell
# ============================================
echo "[5/8] Installing PowerShell..."
if command_exists pwsh; then
    echo "  PowerShell already installed: $(pwsh --version 2>/dev/null)"
else
    # Add Microsoft repository
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg 2>/dev/null || true
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/microsoft-debian-bookworm-prod bookworm main" | sudo tee /etc/apt/sources.list.d/microsoft.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y powershell
fi

# ============================================
# TFLint (from GitHub releases)
# ============================================
echo "[6/8] Installing TFLint..."
if command_exists tflint && [ -f "$LOCAL_BIN/tflint" ]; then
    echo "  TFLint already installed: $(tflint --version 2>/dev/null | head -1)"
else
    TFLINT_VERSION=$(get_latest_release "terraform-linters/tflint")
    echo "  Downloading TFLint v${TFLINT_VERSION}..."
    curl -sL "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip" -o /tmp/tflint.zip
    unzip -o -q /tmp/tflint.zip -d /tmp
    chmod +x /tmp/tflint
    mv /tmp/tflint "$LOCAL_BIN/tflint"
    rm -f /tmp/tflint.zip
    echo "  TFLint v${TFLINT_VERSION} installed."
fi

# ============================================
# Terragrunt (from GitHub releases)
# ============================================
echo "[7/8] Installing Terragrunt, tfsec, terraform-docs..."

# Terragrunt
if command_exists terragrunt && [ -f "$LOCAL_BIN/terragrunt" ]; then
    echo "  Terragrunt already installed: $(terragrunt --version 2>/dev/null | head -1)"
else
    TERRAGRUNT_VERSION=$(get_latest_release "gruntwork-io/terragrunt")
    echo "  Downloading Terragrunt v${TERRAGRUNT_VERSION}..."
    curl -sL "https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64" -o "$LOCAL_BIN/terragrunt"
    chmod +x "$LOCAL_BIN/terragrunt"
    echo "  Terragrunt v${TERRAGRUNT_VERSION} installed."
fi

# tfsec
if command_exists tfsec && [ -f "$LOCAL_BIN/tfsec" ]; then
    echo "  tfsec already installed: $(tfsec --version 2>/dev/null)"
else
    TFSEC_VERSION=$(get_latest_release "aquasecurity/tfsec")
    echo "  Downloading tfsec v${TFSEC_VERSION}..."
    curl -sL "https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-amd64" -o "$LOCAL_BIN/tfsec"
    chmod +x "$LOCAL_BIN/tfsec"
    echo "  tfsec v${TFSEC_VERSION} installed."
fi

# terraform-docs
if command_exists terraform-docs && [ -f "$LOCAL_BIN/terraform-docs" ]; then
    echo "  terraform-docs already installed: $(terraform-docs --version 2>/dev/null)"
else
    TFDOCS_VERSION=$(get_latest_release "terraform-docs/terraform-docs")
    echo "  Downloading terraform-docs v${TFDOCS_VERSION}..."
    curl -sL "https://github.com/terraform-docs/terraform-docs/releases/download/v${TFDOCS_VERSION}/terraform-docs-v${TFDOCS_VERSION}-linux-amd64.tar.gz" | tar -xz -C /tmp
    chmod +x /tmp/terraform-docs
    mv /tmp/terraform-docs "$LOCAL_BIN/terraform-docs"
    echo "  terraform-docs v${TFDOCS_VERSION} installed."
fi

# ============================================
# Docker CLI (for host podman integration)
# ============================================
echo "[8/8] Installing Docker CLI..."
if command_exists docker; then
    echo "  Docker CLI already installed: $(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',')"
else
    sudo apt-get install -y docker.io
fi

echo ""
echo "Tool installation complete!"
echo ""
echo "Installed tools:"
echo "  - Azure CLI:      $(az version --query '"azure-cli"' -o tsv 2>/dev/null || echo 'N/A')"
echo "  - OpenTofu:       $(tofu version -json 2>/dev/null | jq -r '.opentofu_version' 2>/dev/null || echo 'N/A')"
echo "  - GitHub CLI:     $(gh --version 2>/dev/null | head -1 | awk '{print $3}' || echo 'N/A')"
echo "  - PowerShell:     $(pwsh --version 2>/dev/null | awk '{print $2}' || echo 'N/A')"
echo "  - TFLint:         $(tflint --version 2>/dev/null | head -1 | awk '{print $3}' || echo 'N/A')"
echo "  - Terragrunt:     $(terragrunt --version 2>/dev/null | head -1 | awk '{print $3}' || echo 'N/A')"
echo "  - tfsec:          $(tfsec --version 2>/dev/null || echo 'N/A')"
echo "  - terraform-docs: $(terraform-docs --version 2>/dev/null | awk '{print $3}' || echo 'N/A')"
echo "  - Docker CLI:     $(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo 'N/A')"
