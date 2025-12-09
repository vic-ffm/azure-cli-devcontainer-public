# Azure Infrastructure Development Container

## Overview

This repository provides a standardised development container for Azure infrastructure management. The container is pre configured with essential tooling for Infrastructure as Code (IaC) workflows, including OpenTofu, Azure CLI, and associated security scanning utilities.

## Getting Started

### Initial Setup

1. Clone this repository to the local workstation
2. Open the repository folder in Visual Studio Code
3. When prompted, select "Reopen in Container" or execute the command `Dev Containers: Reopen in Container` from the Command Palette
4. The container build process will commence automatically


### Authentication Methods

#### Interactive Authentication

For interactive development sessions, device code authentication is recommended:

```bash
az login --use-device-code
```


#### Service Principal Authentication

For automated workflows or when interactive authentication is not feasible, Service Principal credentials may be configured:

1. Copy the template file to create an environment file:

   ```bash
   cp .devcontainer/.env.example .env
   ```

2. Populate the environment file with Service Principal credentials:

   ```bash
   ARM_CLIENT_ID=<application-id>
   ARM_CLIENT_SECRET=<client-secret>
   ARM_TENANT_ID=<tenant-id>
   ARM_SUBSCRIPTION_ID=<subscription-id>
   ```

3. Execute the authentication command:

   ```bash
   azsp
   ```

The `.env` file is excluded from version control via `.gitignore`. Credentials must never be committed to the repository.

## Use Cases

This development container is designed for the following scenarios:

### Appropriate Use Cases

| Scenario                         | Description                                                                 |
| -------------------------------- | --------------------------------------------------------------------------- |
| Azure Resource Provisioning      | OpenTofu deployment of Azure infrastructure components                      |
| Multi-Environment Management     | Managing development, staging, and production infrastructure configurations |
| Infrastructure Security Scanning | Security validation using tfsec                                             |
| Azure Administration             | Azure resource management and automation                                    |
| CI/CD Pipeline Development       | Creating and testing GitHub Actions workflows for infrastructure deployment |
| Infrastructure Documentation     | Automated generation of OpenTofu module documentation                       |
| PowerShell Automation            | Azure automation scripts using Az PowerShell modules                        |

### Example Workflows

**OpenTofu Validation Workflow:**

```bash
tofucheck
```

This command executes format checking, validation, linting, and security scanning in sequence.

**Infrastructure Deployment:**

```bash
tofui                  # Initialise OpenTofu
tofup                  # Generate and review plan
tofua                  # Apply changes
```

**Multi-Module Deployment with Terragrunt:**

```bash
tgrai                  # Initialise all modules
tgrap                  # Plan all modules
tgraa                  # Apply all modules
```

## Included Components

### Command Line Tools

The following tools are installed and configured within the container:

| Tool           | Purpose                                                   | Documentation                                                            |
| -------------- | --------------------------------------------------------- | ------------------------------------------------------------------------ |
| OpenTofu       | Infrastructure as Code provisioning (open-source)         | [OpenTofu Docs](https://opentofu.org/docs/)                              |
| Azure CLI      | Azure resource management and automation                  | [Microsoft Docs](https://learn.microsoft.com/en-us/cli/azure/)           |
| TFLint         | OpenTofu/Terraform linting and best practices enforcement | [TFLint Docs](https://github.com/terraform-linters/tflint)               |
| Terragrunt     | OpenTofu wrapper for DRY configurations                   | [Terragrunt Docs](https://terragrunt.gruntwork.io/docs/)                 |
| tfsec          | Infrastructure as Code security scanner                   | [tfsec Docs](https://aquasecurity.github.io/tfsec/)                      |
| terraform-docs | Automated documentation generation for OpenTofu modules   | [terraform-docs](https://terraform-docs.io/)                             |
| GitHub CLI     | GitHub repository and workflow management                 | [GitHub CLI Docs](https://cli.github.com/manual/)                        |
| PowerShell     | Scripting and automation                                  | [PowerShell Docs](https://learn.microsoft.com/en-us/powershell/)         |
| Docker CLI     | Container management (Docker-in-Docker)                   | [Docker Docs](https://docs.docker.com/engine/reference/commandline/cli/) |
| Docker Compose | Multi container application orchestration                 | [Compose Docs](https://docs.docker.com/compose/)                         |

### Azure CLI Extensions

The following Azure CLI extensions are installed:

| Extension        | Purpose                                   |
| ---------------- | ----------------------------------------- |
| `account`        | Subscription and account management       |
| `resource-graph` | Azure Resource Graph queries              |
| `containerapp`   | Azure Container Apps management           |
| `aks-preview`    | Azure Kubernetes Service preview features |
| `front-door`     | Azure Front Door configuration            |

### Visual Studio Code Extensions

**Infrastructure as Code**

| Extension | Identifier                 | Purpose                                                 |
| --------- | -------------------------- | ------------------------------------------------------- |
| OpenTofu  | `opentofu.vscode-opentofu` | OpenTofu language support, IntelliSense, and formatting |
| tfsec     | `tfsec.tfsec`              | Security scanning integration                           |

**Azure Development**

| Extension       | Identifier                                 | Purpose                                                |
| --------------- | ------------------------------------------ | ------------------------------------------------------ |
| Azure Resources | `ms-azuretools.vscode-azureresourcegroups` | Azure authentication, resource explorer and management |

**Container Development**

| Extension | Identifier                    | Purpose                          |
| --------- | ----------------------------- | -------------------------------- |
| Docker    | `ms-azuretools.vscode-docker` | Dockerfile and container support |

**PowerShell Development**

| Extension  | Identifier             | Purpose                     |
| ---------- | ---------------------- | --------------------------- |
| PowerShell | `ms-vscode.powershell` | PowerShell language support |

**Version Control**

| Extension            | Identifier                          | Purpose                  |
| -------------------- | ----------------------------------- | ------------------------ |
| GitLens              | `eamodio.gitlens`                   | Enhanced Git integration |
| Git Graph            | `mhutchie.git-graph`                | Visual Git history       |
| GitHub Actions       | `github.vscode-github-actions`      | Workflow editing support |
| GitHub Pull Requests | `github.vscode-pull-request-github` | Pull request management  |

**Code Quality**

| Extension          | Identifier                              | Purpose                        |
| ------------------ | --------------------------------------- | ------------------------------ |
| YAML               | `redhat.vscode-yaml`                    | YAML validation and formatting |
| Prettier           | `esbenp.prettier-vscode`                | Code formatting                |
| EditorConfig       | `EditorConfig.EditorConfig`             | Consistent editor settings     |
| ShellCheck         | `timonwong.shellcheck`                  | Shell script analysis          |
| Error Lens         | `usernamehw.errorlens`                  | Inline error display           |
| Todo Tree          | `Gruntfuggly.todo-tree`                 | TODO comment tracking          |
| Code Spell Checker | `streetsidesoftware.code-spell-checker` | Spelling verification          |

### Shell Environment

The container is configured with zsh as the default shell, enhanced with Oh My Zsh and Powerlevel10k.

**Theme:** Powerlevel10k (ASCII mode, no special fonts required)

The prompt displays the current directory, git status, and contextual information including Azure subscription and OpenTofu workspace when relevant commands are executed.

**Enabled Plugins:**

- git
- azure
- docker
- docker-compose
- gh
- z
- colored-man-pages
- sudo
- history
- jsontools
- terraform
- ansible
- pip
- extract
- encode64


## Security Considerations

The following security measures are implemented within this container:

### Container Hardening

| Measure                         | Implementation                                              |
| ------------------------------- | ----------------------------------------------------------- |
| Non-Root Execution              | Container processes execute as the `vscode` user (UID 1000) |
| Capability Restrictions         | `--cap-drop=ALL` with minimal capability additions          |
| Privilege Escalation Prevention | `--security-opt=no-new-privileges:true`                     |
| Isolated Credential Storage     | Azure CLI tokens stored in Docker named volumes             |

### Credential Management

| Asset                         | Protection Method                                       |
| ----------------------------- | ------------------------------------------------------- |
| Azure CLI Tokens              | Stored in isolated Docker volume, not mounted from host |
| Service Principal Credentials | Environment variables via git-ignored `.env` file       |
| SSH Keys                      | Mounted read-only from host                             |
| OpenTofu State                | Excluded from version control via `.gitignore`          |

### Git-Ignored Sensitive Files

The following patterns are excluded from version control:

- `.azure/` - Azure CLI configuration and tokens
- `.env` - Environment variables containing credentials
- `*.tfstate` - OpenTofu state files
- `*.tfvars` - OpenTofu variable files (except examples)
- `.opentofu/` - OpenTofu provider binaries and cache
- `.terraform/` - Legacy provider cache (for compatibility)
- `*.tfplan` - OpenTofu plan files

## Command Reference

### OpenTofu Aliases

| Alias    | Command                 | Description                  |
| -------- | ----------------------- | ---------------------------- |
| `tofu`   | `tofu`                  | OpenTofu CLI                 |
| `tofui`  | `tofu init`             | Initialise working directory |
| `tofup`  | `tofu plan`             | Generate execution plan      |
| `tofua`  | `tofu apply`            | Apply changes                |
| `tofud`  | `tofu destroy`          | Destroy infrastructure       |
| `tofuv`  | `tofu validate`         | Validate configuration       |
| `tofuf`  | `tofu fmt -recursive`   | Format configuration files   |
| `tofuo`  | `tofu output`           | Display outputs              |
| `tofus`  | `tofu state list`       | List state resources         |
| `tofuss` | `tofu state show`       | Show resource state          |
| `tofuw`  | `tofu workspace`        | Workspace management         |
| `tofuwl` | `tofu workspace list`   | List workspaces              |
| `tofuws` | `tofu workspace select` | Select workspace             |

### Terragrunt Aliases

| Alias   | Command                    | Description            |
| ------- | -------------------------- | ---------------------- |
| `tg`    | `terragrunt`               | Terragrunt CLI         |
| `tgi`   | `terragrunt init`          | Initialise module      |
| `tgp`   | `terragrunt plan`          | Generate plan          |
| `tga`   | `terragrunt apply`         | Apply changes          |
| `tgd`   | `terragrunt destroy`       | Destroy resources      |
| `tgra`  | `terragrunt run-all`       | Run across all modules |
| `tgrai` | `terragrunt run-all init`  | Initialise all modules |
| `tgrap` | `terragrunt run-all plan`  | Plan all modules       |
| `tgraa` | `terragrunt run-all apply` | Apply all modules      |

### Azure CLI Aliases

| Alias    | Command                         | Description             |
| -------- | ------------------------------- | ----------------------- |
| `azl`    | `az login`                      | Interactive login       |
| `azld`   | `az login --use-device-code`    | Device code login       |
| `azacc`  | `az account show`               | Display current account |
| `azaccs` | `az account set --subscription` | Set subscription        |
| `azaccl` | `az account list -o table`      | List subscriptions      |
| `azrg`   | `az group list -o table`        | List resource groups    |

### Ansible Aliases

| Alias | Command                                   | Description               |
| ----- | ----------------------------------------- | ------------------------- |
| `ap`  | `ansible-playbook`                        | Execute playbook          |
| `av`  | `ansible-vault`                           | Vault management          |
| `ave` | `ansible-vault edit`                      | Edit encrypted file       |
| `avv` | `ansible-vault view`                      | View encrypted file       |
| `avc` | `ansible-vault create`                    | Create encrypted file     |
| `al`  | `ansible-lint`                            | Lint playbooks            |
| `ag`  | `ansible-galaxy`                          | Galaxy management         |
| `agi` | `ansible-galaxy install -r requirements.yml` | Install role dependencies |

### Docker Aliases

| Alias    | Command                    | Description              |
| -------- | -------------------------- | ------------------------ |
| `dps`    | `docker ps` (formatted)    | List running containers  |
| `dpsa`   | `docker ps -a` (formatted) | List all containers      |
| `dimg`   | `docker images`            | List images              |
| `dprune` | `docker system prune -af`  | Remove unused resources  |
| `dlogs`  | `docker logs -f`           | Follow container logs    |
| `dexec`  | `docker exec -it`          | Execute interactive shell |

### Docker Compose Aliases

| Alias | Command                  | Description      |
| ----- | ------------------------ | ---------------- |
| `dcu` | `docker compose up -d`   | Start services   |
| `dcd` | `docker compose down`    | Stop services    |
| `dcl` | `docker compose logs -f` | Follow logs      |
| `dcb` | `docker compose build`   | Build images     |
| `dcr` | `docker compose restart` | Restart services |

### Custom Functions

| Function      | Description                                                     |
| ------------- | --------------------------------------------------------------- |
| `infrahelp`   | Display quick reference for common commands                     |
| `infoctx`     | Display current Azure, OpenTofu, and Docker context             |
| `tofucheck`   | Execute format check, validation, linting, and security scan    |
| `tofuready`   | Execute init, validate, and plan in sequence                    |
| `tofuclean`   | Remove local state files and caches                             |
| `azctx`       | Display current Azure subscription context                      |
| `azsw`        | Interactive subscription switching                              |
| `azsp`        | Authenticate using Service Principal from environment variables |
| `azres`       | List all resources in current subscription                      |
| `azrgl`       | List resources in specified resource group                      |
| `tfscan`      | Execute Trivy security scan                                     |
| `tofudocs`    | Generate OpenTofu documentation                                 |

## Maintenance

### Updating the Container

To incorporate updates to the devcontainer configuration:

1. Pull the latest changes from the repository
2. Execute `Dev Containers: Rebuild Container` from the Command Palette

### Clearing Cached Data

To reset the container to a clean state:

```bash
# Remove Azure CLI token cache
docker volume rm $(docker volume ls -q | grep azure-cli-config)

# Remove OpenTofu plugin cache
docker volume rm $(docker volume ls -q | grep opentofu-plugin-cache)
```

### Tool Version Updates

Tool versions are managed via the devcontainer features and post-create script. To update to latest versions, rebuild the container.

## Repository Structure

```text
.
├── .devcontainer/
│   ├── devcontainer.json      # Container configuration
│   ├── Dockerfile             # Base image configuration
│   ├── p10k.zsh               # Powerlevel10k theme configuration
│   ├── .env.example           # Environment variable template
│   ├── config/
│   │   └── zshrc-infra.zsh    # Infrastructure shell configuration
│   └── scripts/
│       ├── post-create.sh     # One-time setup script
│       └── post-start.sh      # Container startup script
├── .gitignore                 # Version control exclusions
└── README.md                  # This documentation
```

## Contributing

Modifications to the devcontainer configuration should be submitted via pull request. All changes must be tested by rebuilding the container and verifying tool functionality.

## Licence

Copyright (c) 2025-Present State Government of Victoria.

This project is licenced under the MIT Licence. See [LICENSE](LICENSE) for details.
