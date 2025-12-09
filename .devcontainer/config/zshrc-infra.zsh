# ============================================
# Infrastructure Development Shell Config
# Additional aliases, functions, and completions
# for Azure, OpenTofu, Ansible, and Docker workflows
# ============================================

# --- Ansible Aliases ---
alias ap='ansible-playbook'
alias av='ansible-vault'
alias ave='ansible-vault edit'
alias avv='ansible-vault view'
alias avc='ansible-vault create'
alias al='ansible-lint'
alias ag='ansible-galaxy'
alias agi='ansible-galaxy install -r requirements.yml'

# --- Docker Aliases ---
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dpsa='docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dimg='docker images'
alias dprune='docker system prune -af'
alias dlogs='docker logs -f'
alias dexec='docker exec -it'

# --- Docker Compose ---
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'
alias dcb='docker compose build'
alias dcr='docker compose restart'

# --- Enhanced Azure Functions ---
# List all resources in current subscription
azres() {
  az resource list --query "[].{Name:name, Type:type, RG:resourceGroup}" -o table
}

# List resources in a specific resource group
azrgl() {
  az resource list --resource-group "$1" -o table
}

# Show resource group tags
azrgtags() {
  az group show -n "$1" --query tags -o table
}

# --- OpenTofu/Terraform Workflow Helpers ---
# Full workflow: init with upgrade, validate, plan
tofuready() {
  tofu init -upgrade && tofu validate && tofu plan
}

# Show current workspace
tofuworkspace() {
  tofu workspace show
}

# Clean all local terraform/tofu state (use with caution!)
tofuclean() {
  rm -rf .terraform .terraform.lock.hcl *.tfstate* .terragrunt-cache
  echo "Cleaned local state files"
}

# Format all .tf files recursively
tofufmtall() {
  tofu fmt -recursive
}

# List all outputs as names only
tofuouts() {
  tofu output -json | jq -r 'keys[]'
}

# --- ZSH Completion Enhancements ---
# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Menu-style completion with selection
zstyle ':completion:*' menu select

# Colored completion (uses LS_COLORS)
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Group completions by category
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'

# --- Environment Helpers ---
# Show current infrastructure context
infoctx() {
  echo "=== Infrastructure Context ==="
  echo "Azure:     $(az account show --query name -o tsv 2>/dev/null || echo 'Not logged in')"
  echo "Tofu WS:   $(tofu workspace show 2>/dev/null || echo 'N/A')"
  echo "Docker:    $(docker context show 2>/dev/null || echo 'default')"
}

# Quick reference for common commands
infrahelp() {
  cat << 'EOF'
=== Quick Reference ===
Azure:    azl (login) | azctx (context) | azsw (switch sub) | azres (list resources)
Tofu:     tofup (plan) | tofua (apply) | tofucheck (validate) | tofuready (init+plan)
Ansible:  ap (playbook) | ave (vault edit) | al (lint) | agi (galaxy install)
Docker:   dps (list) | dcu (up) | dcd (down) | dcl (logs)
EOF
}
