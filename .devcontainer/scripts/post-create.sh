#!/bin/bash
set -euo pipefail

echo "=== Azure Infrastructure DevContainer Setup ==="

# Create directories
mkdir -p /home/vscode/.opentofu.d/plugin-cache
mkdir -p /home/vscode/.terragrunt-cache
mkdir -p /home/vscode/.local/bin

# Secure permissions
chmod 700 /home/vscode/.azure 2>/dev/null || true
chmod 700 /home/vscode/.ssh 2>/dev/null || true

# Install additional infrastructure tools (not from HashiCorp)
echo "Installing additional infrastructure tools..."

# User-local bin directory (no sudo required, follows least-privilege principle)
LOCAL_BIN="/home/vscode/.local/bin"

# Install TFLint (from terraform-linters, not HashiCorp)
echo "  Installing TFLint..."
TFLINT_VERSION=$(curl -s https://api.github.com/repos/terraform-linters/tflint/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
curl -sL "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip" -o /tmp/tflint.zip
unzip -o -q /tmp/tflint.zip -d /tmp
chmod +x /tmp/tflint
mv /tmp/tflint "$LOCAL_BIN/tflint"
rm -f /tmp/tflint.zip

# Install Terragrunt (from Gruntwork, not HashiCorp)
echo "  Installing Terragrunt..."
TERRAGRUNT_VERSION=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
curl -sL "https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64" -o "$LOCAL_BIN/terragrunt"
chmod +x "$LOCAL_BIN/terragrunt"

# Install tfsec (from Aqua Security, not HashiCorp)
echo "  Installing tfsec..."
TFSEC_VERSION=$(curl -s https://api.github.com/repos/aquasecurity/tfsec/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
curl -sL "https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-amd64" -o "$LOCAL_BIN/tfsec"
chmod +x "$LOCAL_BIN/tfsec"

# Install terraform-docs (from terraform-docs org, not HashiCorp)
echo "  Installing terraform-docs..."
TFDOCS_VERSION=$(curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
curl -sL "https://github.com/terraform-docs/terraform-docs/releases/download/v${TFDOCS_VERSION}/terraform-docs-v${TFDOCS_VERSION}-linux-amd64.tar.gz" | tar -xz -C /tmp
chmod +x /tmp/terraform-docs
mv /tmp/terraform-docs "$LOCAL_BIN/terraform-docs"

echo "  Tools installation complete."

# Configure oh-my-zsh
ZSHRC="/home/vscode/.zshrc"

# Set theme
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' "$ZSHRC"

# Configure plugins (removed terraform plugin as it's HashiCorp-specific)
PLUGINS="git azure docker docker-compose gh z colored-man-pages sudo history jsontools"
sed -i "s/^plugins=.*/plugins=($PLUGINS)/" "$ZSHRC"

# Add custom aliases and functions
cat >> "$ZSHRC" << 'ALIASES'

# ============================================
# Azure Infrastructure Management - Custom Config
# ============================================

# Add user-local bin to PATH (for tools installed without sudo)
export PATH="$HOME/.local/bin:$PATH"

# OpenTofu aliases
alias tofu='tofu'
alias tofui='tofu init'
alias tofup='tofu plan'
alias tofua='tofu apply'
alias tofud='tofu destroy'
alias tofuv='tofu validate'
alias tofuf='tofu fmt -recursive'
alias tofuo='tofu output'
alias tofus='tofu state list'
alias tofuss='tofu state show'
alias tofuw='tofu workspace'
alias tofuwl='tofu workspace list'
alias tofuws='tofu workspace select'

# Terragrunt aliases (works with OpenTofu)
alias tg='terragrunt'
alias tgi='terragrunt init'
alias tgp='terragrunt plan'
alias tga='terragrunt apply'
alias tgd='terragrunt destroy'
alias tgra='terragrunt run-all'
alias tgrai='terragrunt run-all init'
alias tgrap='terragrunt run-all plan'
alias tgraa='terragrunt run-all apply'

# Azure CLI aliases
alias azl='az login'
alias azld='az login --use-device-code'
alias azacc='az account show'
alias azaccs='az account set --subscription'
alias azaccl='az account list -o table'
alias azrg='az group list -o table'

# Security scanning
alias tfscan='tfsec .'
alias tfscanmed='tfsec . --minimum-severity MEDIUM'
alias tfscanhigh='tfsec . --minimum-severity HIGH'

# Documentation
alias tofudocs='terraform-docs markdown table .'
alias tofudocsmd='terraform-docs markdown .'

# Quick validation workflow
tofucheck() {
    echo "=== Formatting ===" && tofu fmt -check -recursive
    echo "=== Validating ===" && tofu validate
    echo "=== Linting ===" && tflint
    echo "=== Security Scan ===" && tfsec . --minimum-severity MEDIUM
}

# Plan with output file
tofupo() {
    tofu plan -out="${1:-tofuplan}" "${@:2}"
}

# Apply from plan file
tofuao() {
    tofu apply "${1:-tofuplan}"
}

# Show current Azure context
azctx() {
    echo "=== Current Azure Context ==="
    az account show --query "{Name:name, ID:id, Tenant:tenantId}" -o table
}

# Switch Azure subscription interactively
azsw() {
    az account list --query "[].{Name:name, ID:id, Default:isDefault}" -o table
    echo ""
    read -p "Enter subscription ID or name to switch: " sub
    az account set --subscription "$sub"
    azctx
}

# Login with Service Principal from environment
azsp() {
    if [ -z "${ARM_CLIENT_ID:-}" ] || [ -z "${ARM_CLIENT_SECRET:-}" ] || [ -z "${ARM_TENANT_ID:-}" ]; then
        echo "Error: ARM_CLIENT_ID, ARM_CLIENT_SECRET, and ARM_TENANT_ID must be set"
        return 1
    fi
    az login --service-principal \
        -u "$ARM_CLIENT_ID" \
        -p "$ARM_CLIENT_SECRET" \
        --tenant "$ARM_TENANT_ID"
    if [ -n "${ARM_SUBSCRIPTION_ID:-}" ]; then
        az account set --subscription "$ARM_SUBSCRIPTION_ID"
    fi
    azctx
}

# History settings
export HISTSIZE=50000
export SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY

# Directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD
ALIASES

# Source .env file if it exists in the workspace
WORKSPACE_DIR=$(find /workspaces -maxdepth 1 -type d ! -name workspaces 2>/dev/null | head -1)
if [ -n "$WORKSPACE_DIR" ]; then
    echo "" >> "$ZSHRC"
    echo "# Load environment variables from .env if present" >> "$ZSHRC"
    echo "[ -f \"$WORKSPACE_DIR/.env\" ] && source \"$WORKSPACE_DIR/.env\"" >> "$ZSHRC"
fi

# Configure .bashrc for bash users (add ~/.local/bin to PATH)
BASHRC="/home/vscode/.bashrc"
if [ -f "$BASHRC" ]; then
    echo "" >> "$BASHRC"
    echo "# Add user-local bin to PATH" >> "$BASHRC"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$BASHRC"
fi

echo "=== Post-Create Setup Complete ==="
echo ""
echo "Available commands:"
echo "  tofucheck  - Run format, validate, lint, and security scan"
echo "  azctx      - Show current Azure context"
echo "  azsw       - Switch Azure subscription interactively"
echo "  azsp       - Login with Service Principal from ARM_* environment variables"
echo "  tfscan     - Run tfsec security scan"
echo "  tofudocs   - Generate OpenTofu documentation"
echo ""
