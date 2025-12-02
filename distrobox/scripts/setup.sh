#!/bin/bash
# Azure Infrastructure Distrobox - Main Setup Script
# This script orchestrates the installation of all tools and configuration
#
# Usage: bash setup.sh
# The script is idempotent and can be run multiple times safely.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_MARKER="$HOME/.setup-complete"

echo "=========================================="
echo "Azure Infrastructure Distrobox Setup"
echo "=========================================="
echo ""

# Check if already set up
if [ -f "$SETUP_MARKER" ]; then
    echo "Setup has already been completed."
    echo "To force re-run, delete: $SETUP_MARKER"
    echo ""
    read -p "Do you want to run setup again? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting."
        exit 0
    fi
fi

# Create required directories
echo "Creating directory structure..."
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.azure"
mkdir -p "$HOME/.opentofu.d/plugin-cache"
mkdir -p "$HOME/.terragrunt-cache"

# Secure permissions
chmod 700 "$HOME/.azure" 2>/dev/null || true
chmod 700 "$HOME/.ssh" 2>/dev/null || true

# Run tool installation
echo ""
echo "Installing tools..."
echo "-------------------------------------------"
bash "$SCRIPT_DIR/install-tools.sh"

# Run shell configuration
echo ""
echo "Configuring shell..."
echo "-------------------------------------------"
bash "$SCRIPT_DIR/configure-shell.sh"

# Mark setup as complete
date > "$SETUP_MARKER"

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "To use the environment:"
echo "  1. Exit and re-enter the distrobox: exit && distrobox enter azure-infra"
echo "  2. Or source your shell config: source ~/.zshrc"
echo ""
echo "Quick commands:"
echo "  azld       - Azure login with device code"
echo "  azctx      - Show current Azure context"
echo "  tofucheck  - Run format, validate, lint, and security scan"
echo "  tfscan     - Run tfsec security scan"
echo ""
