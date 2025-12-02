# ============================================
# Azure Infrastructure Management - Custom Config
# ============================================
# This file is sourced by .zshrc for Azure/OpenTofu development

# Add user-local bin to PATH (for tools installed without sudo)
export PATH="$HOME/.local/bin:$PATH"

# ============================================
# Environment Variables
# ============================================
export AZURE_CONFIG_DIR="$HOME/.azure"
export AZURE_CORE_COLLECT_TELEMETRY=false
export TF_PLUGIN_CACHE_DIR="$HOME/.opentofu.d/plugin-cache"
export TOFU_PLUGIN_CACHE_DIR="$HOME/.opentofu.d/plugin-cache"
export ARM_SKIP_PROVIDER_REGISTRATION=true
export CHECKPOINT_DISABLE=true

# ============================================
# OpenTofu aliases
# ============================================
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

# ============================================
# Terragrunt aliases (works with OpenTofu)
# ============================================
alias tg='terragrunt'
alias tgi='terragrunt init'
alias tgp='terragrunt plan'
alias tga='terragrunt apply'
alias tgd='terragrunt destroy'
alias tgra='terragrunt run-all'
alias tgrai='terragrunt run-all init'
alias tgrap='terragrunt run-all plan'
alias tgraa='terragrunt run-all apply'

# ============================================
# Azure CLI aliases
# ============================================
alias azl='az login'
alias azld='az login --use-device-code'
alias azacc='az account show'
alias azaccs='az account set --subscription'
alias azaccl='az account list -o table'
alias azrg='az group list -o table'

# ============================================
# Security scanning
# ============================================
alias tfscan='tfsec .'
alias tfscanmed='tfsec . --minimum-severity MEDIUM'
alias tfscanhigh='tfsec . --minimum-severity HIGH'

# ============================================
# Documentation
# ============================================
alias tofudocs='terraform-docs markdown table .'
alias tofudocsmd='terraform-docs markdown .'

# ============================================
# Custom Functions
# ============================================

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

# ============================================
# History settings
# ============================================
export HISTSIZE=50000
export SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY

# ============================================
# Directory navigation
# ============================================
setopt AUTO_CD
setopt AUTO_PUSHD

# ============================================
# Load .env file if present in current directory
# ============================================
load_env() {
    if [ -f ".env" ]; then
        set -a
        source .env
        set +a
        echo "Loaded environment from .env"
    fi
}

# Auto-load .env when entering a directory (optional, uncomment to enable)
# chpwd() { load_env }
