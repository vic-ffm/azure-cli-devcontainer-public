#!/bin/bash
# Azure Infrastructure Distrobox - Shell Configuration Script
# Sets up Zsh with Oh My Zsh and custom configuration
#
# This script should be run inside the distrobox.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"
ZSHRC="$HOME/.zshrc"

echo "Configuring shell environment..."
echo ""

# ============================================
# Install Oh My Zsh
# ============================================
echo "Installing Oh My Zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "  Oh My Zsh already installed."
else
    # Install Oh My Zsh non-interactively
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "  Oh My Zsh installed."
fi

# ============================================
# Configure .zshrc
# ============================================
echo "Configuring .zshrc..."

# Set theme to bira (works well on both light and dark terminals)
if grep -q "^ZSH_THEME=" "$ZSHRC"; then
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="bira"/' "$ZSHRC"
else
    echo 'ZSH_THEME="bira"' >> "$ZSHRC"
fi
echo "  Theme set to bira."

# Configure plugins
PLUGINS="git azure docker docker-compose gh z colored-man-pages sudo history jsontools"
if grep -q "^plugins=" "$ZSHRC"; then
    sed -i "s/^plugins=.*/plugins=($PLUGINS)/" "$ZSHRC"
else
    echo "plugins=($PLUGINS)" >> "$ZSHRC"
fi
echo "  Plugins configured: $PLUGINS"

# ============================================
# Add custom configuration
# ============================================
echo "Adding custom Azure infrastructure configuration..."

# Check if custom config is already sourced
if ! grep -q "zshrc-azure.zsh" "$ZSHRC" 2>/dev/null; then
    # Copy custom config to home directory
    mkdir -p "$HOME/.config/zsh"
    cp "$CONFIG_DIR/zshrc-azure.zsh" "$HOME/.config/zsh/zshrc-azure.zsh"

    # Add source line to .zshrc
    cat >> "$ZSHRC" << 'EOF'

# ============================================
# Azure Infrastructure Custom Configuration
# ============================================
[ -f "$HOME/.config/zsh/zshrc-azure.zsh" ] && source "$HOME/.config/zsh/zshrc-azure.zsh"
EOF
    echo "  Custom configuration added."
else
    # Update the config file
    cp "$CONFIG_DIR/zshrc-azure.zsh" "$HOME/.config/zsh/zshrc-azure.zsh"
    echo "  Custom configuration updated."
fi

# ============================================
# Set Zsh as default shell (if not already)
# ============================================
echo "Setting Zsh as default shell..."
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
if [ "$CURRENT_SHELL" != "/bin/zsh" ] && [ "$CURRENT_SHELL" != "/usr/bin/zsh" ]; then
    if command -v chsh &> /dev/null; then
        sudo chsh -s /bin/zsh "$USER" 2>/dev/null || echo "  Could not change default shell (may need manual configuration)"
    fi
fi
echo "  Default shell configured."

# ============================================
# Configure .bashrc for bash fallback
# ============================================
BASHRC="$HOME/.bashrc"
if [ -f "$BASHRC" ]; then
    if ! grep -q 'PATH=.*\.local/bin' "$BASHRC"; then
        echo "" >> "$BASHRC"
        echo "# Add user-local bin to PATH" >> "$BASHRC"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$BASHRC"
        echo "  Bash fallback configured."
    fi
fi

echo ""
echo "Shell configuration complete!"
