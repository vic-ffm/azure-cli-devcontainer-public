#!/bin/bash
# Create the Azure Infrastructure Distrobox
# This script automatically detects the repo location and configures the distrobox.
#
# Usage: bash distrobox/create.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SETUP_SCRIPT="$SCRIPT_DIR/scripts/setup.sh"

echo "========================================"
echo "Azure Infrastructure Distrobox Creator"
echo "========================================"
echo ""
echo "Repository: $REPO_DIR"
echo "Setup script: $SETUP_SCRIPT"
echo ""

# Check prerequisites
if ! command -v distrobox &> /dev/null; then
    echo "Error: distrobox is not installed"
    echo "Install with: sudo dnf install distrobox (Fedora) or sudo apt install distrobox (Debian/Ubuntu)"
    exit 1
fi

if ! command -v podman &> /dev/null && ! command -v docker &> /dev/null; then
    echo "Error: Neither podman nor docker is installed"
    exit 1
fi

# Check if podman socket is enabled (for docker CLI compatibility)
if command -v podman &> /dev/null; then
    if ! systemctl --user is-active podman.socket &> /dev/null; then
        echo "Warning: podman.socket is not active"
        echo "Enable with: systemctl --user enable --now podman.socket"
        echo ""
    fi
fi

# Check if distrobox already exists
if distrobox list | grep -q "azure-infra"; then
    echo "Distrobox 'azure-infra' already exists."
    read -p "Remove and recreate? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing existing distrobox..."
        distrobox rm azure-infra --force
        echo "Cleaning home directory..."
        rm -rf ~/.local/share/distrobox/azure-infra-home
    else
        echo "Aborted."
        exit 0
    fi
fi

# Get UID for podman socket path
USER_UID=$(id -u)

echo "Creating distrobox..."
distrobox create \
    --name azure-infra \
    --image docker.io/library/debian:bookworm \
    --pull \
    --home ~/.local/share/distrobox/azure-infra-home \
    --volume "/run/user/${USER_UID}/podman/podman.sock:/var/run/docker.sock:rw" \
    --additional-packages "zsh git curl wget unzip jq gnupg ca-certificates apt-transport-https lsb-release software-properties-common sudo file" \
    --init-hooks "bash '$SETUP_SCRIPT' || echo 'Setup script failed - run manually after entering'"

echo ""
echo "========================================"
echo "Distrobox created successfully!"
echo "========================================"
echo ""
echo "Enter with: distrobox enter azure-infra"
echo ""
