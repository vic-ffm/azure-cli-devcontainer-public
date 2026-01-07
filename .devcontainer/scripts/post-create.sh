#!/bin/env bash
# SPDX-License-Identifier: NCSA
# Copyright (c) State Government of Victoria 2025-2026. See LICENSE for details.
set -euo pipefail

echo "=== Azure CLI DevContainer Setup ==="

# Create directories
mkdir -p /home/vscode/.opentofu.d/plugin-cache
mkdir -p /home/vscode/.terragrunt-cache
mkdir -p /home/vscode/.local/share/mise/state

# Secure permissions
chmod 700 /home/vscode/.azure 2>/dev/null || true
chmod 700 /home/vscode/.ssh 2>/dev/null || true

# Find workspace directory dynamically
WORKSPACE_DIR=$(find /workspaces -maxdepth 1 -type d ! -name workspaces 2>/dev/null | head -1)
if [ -z "$WORKSPACE_DIR" ]; then
    WORKSPACE_DIR="/workspaces"
fi

# Install tools via mise (reads from mise.toml)
echo "Installing tools via mise..."
if [ -d "$WORKSPACE_DIR" ] && [ -f "$WORKSPACE_DIR/mise.toml" ]; then
    cd "$WORKSPACE_DIR"
    mise install --yes
    # Add mise shims to PATH so tools are available immediately
    export PATH="/home/vscode/.local/share/mise/shims:$PATH"
    echo "  Tools installed from mise.toml"
else
    echo "  No mise.toml found, skipping mise install"
fi

# Initialize TFLint plugins
echo "Initializing TFLint plugins..."
if [ -f "$WORKSPACE_DIR/.tflint.hcl" ]; then
    tflint --init --config="$WORKSPACE_DIR/.tflint.hcl" || echo "  TFLint init skipped (may need network)"
fi

# Install pre-commit hooks
echo "Installing pre-commit hooks..."
if [ -f "$WORKSPACE_DIR/.pre-commit-config.yaml" ]; then
    cd "$WORKSPACE_DIR"
    pre-commit install
    echo "  Pre-commit hooks installed"
fi

# Configure Powerlevel10k (ASCII mode - no special fonts required)
ZSHRC="/home/vscode/.zshrc"

# Copy p10k config from devcontainer
if [ -f "$WORKSPACE_DIR/.devcontainer/p10k.zsh" ]; then
    cp "$WORKSPACE_DIR/.devcontainer/p10k.zsh" /home/vscode/.p10k.zsh
    echo "Powerlevel10k configuration installed (ASCII mode)"
fi

# Ensure p10k is sourced in .zshrc
if ! grep -q "p10k.zsh" "$ZSHRC" 2>/dev/null; then
    echo '' >> "$ZSHRC"
    echo '# Powerlevel10k configuration' >> "$ZSHRC"
    echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> "$ZSHRC"
fi

# Configure oh-my-zsh plugins
# Note: terraform plugin works for both terraform and tofu
PLUGINS="git azure docker docker-compose gh z colored-man-pages sudo history jsontools terraform ansible pip extract encode64"
sed -i "s/^plugins=.*/plugins=($PLUGINS)/" "$ZSHRC"

# Add custom aliases and functions
cat >> "$ZSHRC" << 'ALIASES'

# ============================================
# Azure CLI DevContainer - Custom Config
# ============================================

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

# Security scanning (Trivy)
alias tfscan='trivy config .'
alias tfscanmed='trivy config . --severity MEDIUM,HIGH,CRITICAL'
alias tfscanhigh='trivy config . --severity HIGH,CRITICAL'

# Documentation
alias tofudocs='terraform-docs markdown table .'
alias tofudocsmd='terraform-docs markdown .'

# Quick validation workflow (mirrors CI)
tofucheck() {
    echo "=== Formatting ===" && tofu fmt -check -recursive
    echo "=== Validating ===" && tofu validate
    echo "=== Linting ===" && tflint
    echo "=== Security Scan ===" && trivy config . --severity HIGH,CRITICAL
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

# Login with managed identity (for VM-based development)
azmi() {
    az login --identity
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

# Source infrastructure-specific config (additional aliases, functions, completions)
if [ -f "$WORKSPACE_DIR/.devcontainer/config/zshrc-infra.zsh" ]; then
    cat "$WORKSPACE_DIR/.devcontainer/config/zshrc-infra.zsh" >> "$ZSHRC"
    echo "Infrastructure shell enhancements loaded"
fi

# Source .env file if it exists in the workspace
echo "" >> "$ZSHRC"
echo "# Load environment variables from .env if present" >> "$ZSHRC"
echo "[ -f \"$WORKSPACE_DIR/.env\" ] && source \"$WORKSPACE_DIR/.env\"" >> "$ZSHRC"

# Configure .bashrc for bash users - ensure mise is activated
BASHRC="/home/vscode/.bashrc"
if [ -f "$BASHRC" ]; then
    # Remove any existing mise activation to avoid duplicates
    sed -i '/# Mise activation/d' "$BASHRC"
    sed -i '/eval "$(.*mise activate bash.*)"/d' "$BASHRC"

    echo "" >> "$BASHRC"
    echo "# Mise activation - adds tools from mise.toml to PATH" >> "$BASHRC"
    echo 'eval "$(mise activate bash)"' >> "$BASHRC"
fi

# Configure .zshrc for zsh users - ensure mise is activated
if [ -f "$ZSHRC" ]; then
    # Check if mise activation already exists
    if ! grep -q 'mise activate zsh' "$ZSHRC" 2>/dev/null; then
        echo "" >> "$ZSHRC"
        echo "# Mise activation - adds tools from mise.toml to PATH" >> "$ZSHRC"
        echo 'eval "$(mise activate zsh)"' >> "$ZSHRC"
    fi
fi

# Also create a profile.d script for non-interactive shells
mkdir -p /home/vscode/.local/share/mise/profile.d
cat > /home/vscode/.local/share/mise/profile.d/mise-path.sh << 'MISE_PATH'
# Add mise shims to PATH for non-interactive shells
export PATH="/home/vscode/.local/share/mise/shims:$PATH"
MISE_PATH

# Source the profile.d script from .profile for login shells
PROFILE="/home/vscode/.profile"
if [ -f "$PROFILE" ]; then
    if ! grep -q 'mise/profile.d' "$PROFILE" 2>/dev/null; then
        echo "" >> "$PROFILE"
        echo "# Mise shims for non-interactive shells" >> "$PROFILE"
        echo '[ -f "$HOME/.local/share/mise/profile.d/mise-path.sh" ] && . "$HOME/.local/share/mise/profile.d/mise-path.sh"' >> "$PROFILE"
    fi
fi

echo "=== Post-Create Setup Complete ==="
echo ""
echo "Tools installed via mise (from mise.toml):"
echo "  - OpenTofu, Terragrunt, TFLint, Trivy, Just, terraform-docs"
echo "  - Ansible, ansible-lint, yamllint, pre-commit"
echo ""
echo "Available commands:"
echo "  infrahelp  - Show quick reference for all commands"
echo "  infoctx    - Show current Azure/Tofu/Docker context"
echo "  tofucheck  - Run format, validate, lint, and security scan"
echo "  tofuready  - Run init, validate, and plan"
echo "  azctx      - Show current Azure context"
echo "  azsw       - Switch Azure subscription interactively"
echo "  azsp       - Login with Service Principal (requires ARM_* env vars)"
echo "  azmi       - Login with Managed Identity (for Azure VMs)"
echo "  tfscan     - Run Trivy security scan"
echo "  tofudocs   - Generate OpenTofu documentation"
echo ""
