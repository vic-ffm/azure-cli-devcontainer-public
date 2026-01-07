#!/bin/env bash
# SPDX-License-Identifier: NCSA
# Copyright (c) State Government of Victoria 2025-2026. See LICENSE for details.
set -e

# Activate mise to ensure tools are available in non-interactive shell
if command -v mise &>/dev/null; then
    eval "$(mise activate bash)"
fi

echo ""
echo "=== Azure CLI DevContainer Environment ==="
echo ""
echo "Tools:"
echo "  OpenTofu:       $(tofu version 2>/dev/null | head -1 | sed 's/OpenTofu //' || echo 'N/A')"
echo "  TFLint:         $(tflint --version 2>/dev/null | head -1 || echo 'N/A')"
echo "  Terragrunt:     $(terragrunt --version 2>/dev/null | head -1 || echo 'N/A')"
echo "  Trivy:          $(trivy --version 2>/dev/null | head -1 || echo 'N/A')"
echo "  terraform-docs: $(terraform-docs --version 2>/dev/null || echo 'N/A')"
echo "  Azure CLI:      $(az version --query '"azure-cli"' -o tsv 2>/dev/null || echo 'N/A')"
echo "  GitHub CLI:     $(gh --version 2>/dev/null | head -1 || echo 'N/A')"
echo "  PowerShell:     $(pwsh --version 2>/dev/null || echo 'N/A')"
echo "  Docker:         $(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo 'N/A')"
echo ""

# Check Azure authentication status
echo "=== Authentication Status ==="
if az account show &>/dev/null; then
    ACCOUNT_NAME=$(az account show --query 'name' -o tsv 2>/dev/null)
    USER_NAME=$(az account show --query 'user.name' -o tsv 2>/dev/null)
    echo "Azure: Authenticated"
    echo "  Account: $ACCOUNT_NAME"
    echo "  User: $USER_NAME"
else
    echo "Azure: Not authenticated"
fi

# Authentication options
echo ""
echo "Authentication options:"
echo "  Interactive:       az login --use-device-code"
echo "  Service Principal: azsp (requires ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID)"
echo "  Managed Identity:  azmi (for Azure VM-based development)"

# Check Service Principal environment variables
if [ -n "${ARM_CLIENT_ID:-}" ] && [ -n "${ARM_CLIENT_SECRET:-}" ] && [ -n "${ARM_TENANT_ID:-}" ]; then
    echo ""
    echo "Service Principal: Credentials detected in environment"
    echo "  Run 'azsp' to authenticate with Service Principal"
fi

# Check GitHub CLI authentication
echo ""
if gh auth status &>/dev/null 2>&1; then
    echo "GitHub CLI: Authenticated"
else
    echo "GitHub CLI: Not authenticated (run 'gh auth login')"
fi

echo ""
echo "=== Quick Commands ==="
echo "  infrahelp  - Show quick reference for all commands"
echo "  infoctx    - Show current Azure/Tofu/Docker context"
echo "  tofucheck  - Format, validate, lint, and security scan"
echo "  tofuready  - Run init, validate, and plan"
echo "  azctx      - Show current Azure context"
echo "  azsw       - Switch Azure subscription"
echo "  azsp       - Login with Service Principal"
echo "  azmi       - Login with Managed Identity"
echo "  tfscan     - Run Trivy security scan"
echo "  tofudocs   - Generate OpenTofu documentation"
echo ""
