# Azure Infrastructure Distrobox

This directory contains configuration for running the Azure infrastructure development environment using [Distrobox](https://distrobox.it/) instead of a devcontainer.

## Overview

Distrobox provides a way to run containerised development environments that integrate seamlessly with your host system. This configuration creates a Debian Bookworm-based environment with all the same tools as the devcontainer.

## Prerequisites

1. **Distrobox** installed on your system

   ```bash
   # Fedora
   sudo dnf install distrobox

   # Ubuntu/Debian
   sudo apt install distrobox
   ```

2. **Podman** (recommended) or Docker

   ```bash
   # Fedora (usually pre-installed)
   sudo dnf install podman

   # Enable podman socket for docker CLI compatibility
   systemctl --user enable --now podman.socket
   ```

3. Minimum 4GB RAM and 32GB storage available

## Quick Start

```bash
# From the repository root
bash distrobox/create.sh

# Enter the distrobox
distrobox enter azure-infra
```

## Management Commands

```bash
# Enter the distrobox
distrobox enter azure-infra

# Stop the distrobox
distrobox stop azure-infra

# List all distroboxes
distrobox list
```

## Updating Tools

All tools are installed at their latest versions during creation. To update to newer versions, exit the distrobox and recreate it from the host:

```bash
exit  # if inside the distrobox
bash distrobox/create.sh
```

The script will prompt to remove the existing distrobox before recreating it with the latest tool versions.

## Installed Tools

| Tool           | Purpose                                        |
| -------------- | ---------------------------------------------- |
| Azure CLI      | Azure resource management with extensions      |
| OpenTofu       | Infrastructure as Code (Terraform alternative) |
| TFLint         | IaC linting and best practices                 |
| Terragrunt     | IaC wrapper for DRY configurations             |
| tfsec          | Security scanning for IaC                      |
| terraform-docs | Documentation generation                       |
| GitHub CLI     | GitHub integration                             |
| PowerShell     | Scripting and automation                       |
| Docker CLI     | Container management (via host podman)         |

### Azure CLI Extensions

- `account` - Subscription management
- `resource-graph` - Resource Graph queries
- `containerapp` - Container Apps
- `aks-preview` - AKS preview features
- `front-door` - Front Door configuration

## Command Reference

### OpenTofu

| Alias       | Command               | Description                  |
| ----------- | --------------------- | ---------------------------- |
| `tofui`     | `tofu init`           | Initialise working directory |
| `tofup`     | `tofu plan`           | Generate execution plan      |
| `tofua`     | `tofu apply`          | Apply changes                |
| `tofud`     | `tofu destroy`        | Destroy infrastructure       |
| `tofuv`     | `tofu validate`       | Validate configuration       |
| `tofuf`     | `tofu fmt -recursive` | Format files                 |
| `tofucheck` | _function_            | Format, validate, lint, scan |

### Terragrunt

| Alias   | Command                    | Description       |
| ------- | -------------------------- | ----------------- |
| `tgi`   | `terragrunt init`          | Initialise module |
| `tgp`   | `terragrunt plan`          | Generate plan     |
| `tga`   | `terragrunt apply`         | Apply changes     |
| `tgrai` | `terragrunt run-all init`  | Init all modules  |
| `tgrap` | `terragrunt run-all plan`  | Plan all modules  |
| `tgraa` | `terragrunt run-all apply` | Apply all modules |

### Azure CLI

| Alias    | Command                      | Description             |
| -------- | ---------------------------- | ----------------------- |
| `azld`   | `az login --use-device-code` | Device code login       |
| `azctx`  | _function_                   | Show current context    |
| `azsw`   | _function_                   | Switch subscription     |
| `azsp`   | _function_                   | Service Principal login |
| `azaccl` | `az account list -o table`   | List subscriptions      |

## Authentication

### Interactive Login

```bash
azld  # or: az login --use-device-code
```

### Service Principal

Set environment variables and use `azsp`:

```bash
export ARM_CLIENT_ID="<client-id>"
export ARM_CLIENT_SECRET="<client-secret>"
export ARM_TENANT_ID="<tenant-id>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"
azsp
```

Or create a `.env` file in your project directory:

```bash
ARM_CLIENT_ID=<client-id>
ARM_CLIENT_SECRET=<client-secret>
ARM_TENANT_ID=<tenant-id>
ARM_SUBSCRIPTION_ID=<subscription-id>
```

Then source it: `source .env && azsp`

## Data Persistence

| Data             | Location                                                 | Notes                    |
| ---------------- | -------------------------------------------------------- | ------------------------ |
| Azure CLI tokens | `~/.local/share/distrobox/azure-infra-home/.azure/`      | Persists across restarts |
| OpenTofu plugins | `~/.local/share/distrobox/azure-infra-home/.opentofu.d/` | Cached providers         |
| Shell history    | `~/.local/share/distrobox/azure-infra-home/.zsh_history` | Persists across restarts |
| SSH keys         | `~/.ssh/`                                                | Shared from host         |

## Docker/Podman Integration

The distrobox mounts the host's podman socket, allowing `docker` commands to work seamlessly:

```bash
docker ps
docker build -t myimage .
docker-compose up
```

## File Structure

```
distrobox/
├── create.sh               # Creation script (use this)
├── distrobox.ini           # Container definition (for reference)
├── scripts/
│   ├── setup.sh            # Main setup orchestrator
│   ├── install-tools.sh    # Tool installation
│   └── configure-shell.sh  # Shell configuration
├── config/
│   └── zshrc-azure.zsh     # Custom aliases/functions
└── README.md               # This file
```
