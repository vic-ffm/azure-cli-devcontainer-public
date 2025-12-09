FROM mcr.microsoft.com/devcontainers/base:bookworm

# Create directories for volume mounts with correct ownership
# This must happen before volumes are mounted to preserve vscode ownership
RUN mkdir -p /home/vscode/.local/share/mise \
    && mkdir -p /home/vscode/.opentofu.d/plugin-cache \
    && mkdir -p /home/vscode/.azure \
    && mkdir -p /home/vscode/.config/gh \
    && chown -R vscode:vscode /home/vscode/.local \
    && chown -R vscode:vscode /home/vscode/.opentofu.d \
    && chown -R vscode:vscode /home/vscode/.azure \
    && chown -R vscode:vscode /home/vscode/.config

WORKDIR /workspaces

USER vscode
